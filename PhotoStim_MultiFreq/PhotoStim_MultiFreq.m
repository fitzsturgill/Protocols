function PhotoStim_MultiFreq
% PhotoStim w/ multiple frequencies for optogenetic tagging
% Written by Torben Ott 11/2017

global BpodSystem
global TaskParameters
TaskParameters = BpodSystem.ProtocolSettings;

if isempty(fieldnames(TaskParameters))
    TaskParameters.GUI.NTrials = 160;
    
    TaskParameters.GUI.StimFreq.Freq = [10, 10, 10, 40, 80]';
    TaskParameters.GUI.StimFreq.Active = [1 1 1 0 0]';
    TaskParameters.GUI.StimFreq.Amplitude = [2 2.5 3 1 1]';
    TaskParameters.GUIMeta.StimFreq.Style = 'table';
    TaskParameters.GUIMeta.StimFreq.String = 'Stim Freq';
    TaskParameters.GUIMeta.OdorTable.ColumnLabel = {'Freq','Active','Amplitude'};
    TaskParameters.GUI.PulsePalTriggerChannel = 1;
    TaskParameters.GUI.PulsePalOutputChannels = 34; % not really 34, stands for 3 and 4
    TaskParameters.GUI.PulsePalOutputTTL = 3; % this, when specified as a channel, overrides PulsePalOutputChannels with respect to voltage amplitude, makes voltage 5V (TTL logic)
    TaskParameters.GUI.BpodTriggerChannel = 2;
    TaskParameters.GUI.ITI = 3;
    
    TaskParameters.GUIPanels.GeneralParams = {'NTrials','ITI','BpodTriggerChannel','PulsePalTriggerChannel','PulsePalOutputChannels','PulsePalOutputTTL'};
     TaskParameters.GUIPanels.StimFreqTable ={'StimFreq'};
    
    TaskParameters.GUI.NPulses = 20;
    TaskParameters.GUI.PulseDuration_ms = 1;
    TaskParameters.GUIPanels.TrainParams = {'NPulses','PulseDuration_ms'};
    
end
%% Pause and wait for user to edit parameter GUI 
BpodParameterGUI('init', TaskParameters);
BpodSystem.Pause = 1;
HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
TaskParameters = BpodParameterGUI('sync', TaskParameters); % Sync parameters with BpodParameterGUI plugin
BpodSystem.ProtocolSettings = TaskParameters; % copy settings back prior to saving
SaveBpodProtocolSettings;

%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [400 600 1000 200],'Name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot.HandleOutcome = axes('Position', [.075 .3 .89 .6]);
OutcomePlot_PhotoStim(BpodSystem.GUIHandles.OutcomePlot,'init');

% load default PulsePal stimulus train matrix
load('LightTrain.mat')
ParameterMatrixDefault = ParameterMatrix;

%% Main trial loop
iTrial = 1;
while iTrial <= TaskParameters.GUI.NTrials
    
    TaskParameters = BpodParameterGUI('sync', TaskParameters); % Sync parameters with BpodParameterGUI plugin
    
    %update current trial fields
    ActiveFreqIdx = find(logical(TaskParameters.GUI.StimFreq.Active));
    idx = mod(iTrial,length(ActiveFreqIdx));
    if idx == 0
        idx=length(ActiveFreqIdx);
    end
    StimFreq = TaskParameters.GUI.StimFreq.Freq(ActiveFreqIdx(idx));
    StimAmp = TaskParameters.GUI.StimFreq.Amplitude(ActiveFreqIdx(idx));
    BpodSystem.Data.StimFreq(iTrial) = StimFreq;
    BpodSystem.Data.StimFreqIdx(iTrial) = ActiveFreqIdx(idx);
    BpodSystem.Data.StimAmp(iTrial) = StimAmp;
    BpodSystem.Data.iTrial(iTrial) = iTrial;
    
    
    %Program PulsePal
    ParameterMatrix = ParameterMatrixDefault;
    OutputChannels = [1:4] .* ismember('1234',num2str(TaskParameters.GUI.PulsePalOutputChannels));
    OutputChannels = OutputChannels(OutputChannels>0);
    OutputChannels = union(OutputChannels, TaskParameters.GUI.PulsePalOutputTTL); % add the output TTL if not already specified in output channels    
    %TriggerChannel
    if TaskParameters.GUI.PulsePalTriggerChannel == 1
        ParameterMatrix(13,OutputChannels+1) = {1};
        ParameterMatrix(14,OutputChannels+1) = {0};
    elseif TaskParameters.GUI.PulsePalTriggerChannel == 2
        ParameterMatrix(13,OutputChannels+1) = {0};
        ParameterMatrix(14,OutputChannels+1) = {1};
    else
        error('Unknown trigger channel')
    end
    %just one pulse? (e.g. using power meter)
    if TaskParameters.GUI.NPulses == 1
        onePulse = true;
    else
        onePulse = false;
    end
    if ~onePulse
        %Inter-pulse interval
        ParameterMatrix(8,OutputChannels+1)={1./StimFreq - TaskParameters.GUI.PulseDuration_ms/1000};
        %Burst Duration
        ParameterMatrix(9,OutputChannels+1)={1./StimFreq*TaskParameters.GUI.NPulses};
        %stimulus train duration
        ParameterMatrix(11,OutputChannels+1)={1./StimFreq*TaskParameters.GUI.NPulses};
    else
        %Inter-pulse interval
        ParameterMatrix(8,OutputChannels+1)={0};
        %Burst Duration
        ParameterMatrix(9,OutputChannels+1)={TaskParameters.GUI.PulseDuration_ms/1000};
        %stimulus train duration
        ParameterMatrix(11,OutputChannels+1)={TaskParameters.GUI.PulseDuration_ms/1000};
    end
    %single pulse duration
    ParameterMatrix(5,OutputChannels+1)={TaskParameters.GUI.PulseDuration_ms/1000};
    %amplitude
    ParameterMatrix(3,OutputChannels+1)={StimAmp};
    %override amplitude for TTL
    ParameterMatrix(3,TaskParameters.GUI.PulsePalOutputTTL) = {5}; % 5V for TTL logic
    
    ProgramPulsePal(ParameterMatrix);
    
    %Build state matrix
    
    sma = NewStateMatrix();
    if BpodSystem.Data.StimFreqIdx(iTrial)==1
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'LightTrain_1'},...
            'OutputActions', {});
    elseif BpodSystem.Data.StimFreqIdx(iTrial)==2
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'LightTrain_2'},...
            'OutputActions', {});
    elseif BpodSystem.Data.StimFreqIdx(iTrial)==3
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'LightTrain_3'},...
            'OutputActions', {});
    elseif BpodSystem.Data.StimFreqIdx(iTrial)==4
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'LightTrain_4'},...
            'OutputActions', {});
    elseif BpodSystem.Data.StimFreqIdx(iTrial)==5
        sma = AddState(sma, 'Name', 'DeliverStimulus', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'LightTrain_5'},...
            'OutputActions', {});
    else
        errror('Unknown freq stimulus when builiding state matrix.')
    end
    sma = AddState(sma, 'Name', 'LightTrain_1', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',TaskParameters.GUI.BpodTriggerChannel});
    sma = AddState(sma, 'Name', 'LightTrain_2', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',TaskParameters.GUI.BpodTriggerChannel});
    sma = AddState(sma, 'Name', 'LightTrain_3', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',TaskParameters.GUI.BpodTriggerChannel});
    sma = AddState(sma, 'Name', 'LightTrain_4', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',TaskParameters.GUI.BpodTriggerChannel});
    sma = AddState(sma, 'Name', 'LightTrain_5', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',TaskParameters.GUI.BpodTriggerChannel});
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', TaskParameters.GUI.ITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {});
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        % BpodSystem.Data = BpodNotebook(BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(iTrial) = TaskParameters; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        if ~isnan(BpodSystem.Data.RawEvents.Trial{iTrial}.States.DeliverStimulus(1))
            BpodSystem.Data.Outcomes(iTrial) = 1;
        else
            BpodSystem.Data.Outcomes(iTrial) = 0;
        end
        
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    OutcomePlot_PhotoStim(BpodSystem.GUIHandles.OutcomePlot,'update');
    iTrial = iTrial+1;

end

