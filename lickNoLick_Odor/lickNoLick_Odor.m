function lickNoLick_Odor
% instrumental odor discrimination task with positive and negative
% reinforcement outcomes
% Photometry support

    global BpodSystem
    
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S


    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.Epoch = 1;
        S.GUI.LED1_amp = 1.5;
        S.GUI.LED2_amp = 0;
        S.GUI.NoLick = 1.5; % mouse must stop licking for this period to advance to the next trial
        S.GUI.AnswerDelay = 1; % post-odor, time until answer period
        S.GUI.Answer = 1; % answer period duration
        S.GUI.PunishValveTime = 0.2; %s        
        S.GUI.Reward = 8;
        S.GUI.PunishOn = 0;  % during training, initially present CS+ trials only
        S.GUI.Odor1Valve = 5;
        S.GUI.Odor2Valve = 6;
        % parameters controling reversals
        S.BlockFirstReverseCorrect = 30; % number of correct responses necessary prior to initial reversal
        S.IsFirstReverse = 1; % are we evaluating initial reversal? % this will be saved across sessions
        S.BlockCountCorrect = 0; % tally of correct responses prior to a reversal
        S.BlockMinCorrect = 10;
        S.BlockMeanAdditionalCorrect = 10;
        S.BlockMaxAdditionalCorrect = S.BlockMeanAdditionalCorrect * 2;
        S.BlockAdditionalCorrect = []; % determined adaptively
%         S.GUI.Reverse = 0; % determined adaptively, do I need this?

        S.OdorTime = 1;
        S.PreCsRecording = 4;
        S.PostOutcomeRecording = 3;
        S.currentValve = []; % holds odor valve # for current trial
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);
        S.RewardValveCode = 1;
        S.PunishValveCode = 2;
    end

    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;


    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.OdorTime + S.GUI.AnswerDelay + S.GUI.Answer + S.PostUsRecording;
    startX = 0 - S.PreCsRecording - S.GUI.OdorTime - S.GUI.Delay; % 0 defined as time from reinforcement
    S = initPhotometry(S);

    %% Initialize Sound Stimuli
    SF = 192000; 
    
    % linear ramp of sound for 10ms at onset and offset
    neutralTone = taperedSineWave(SF, S.ToneFreq, S.ToneDuration, 0.01); % 10ms taper
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, neutralTone);
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
    
    % brown noise (house light equivalent) signaling intertrial interval
%     S.GUI.NoLick = length of sounds
%     use quentin's sound generator function???

    
    %% Initialize olfactometer and point grey camera
    % retrieve machine specific olfactometer settings
    addpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    olfSettings = machineSpecific_Olfactometer;
    rmpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict

    % retrieve machine specific point grey camera settings
    addpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    pgSettings = machineSpecific_pointGrey;
    rmpath(genpath(fullfile(BpodSystem.BpodPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict    

    % initialize olfactometer slave arduino
    valveSlave = initValveSlave(olfSettings.portName);
    if isempty(valveSlave)
        BpodSystem.BeingUsed = 0;
        error('*** Failure to initialize valve slave ***');
    end    

    % determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    switch pgSettings.triggerType
        case 'WireState'
            npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
        case 'BNCState'
            npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
    end
    olfWireArg = 0;
    olfBNCArg = 0;
    switch olfSettings.triggerType
        case 'WireState'
            olfWireArg = bitset(olfWireArg, olfSettings.triggerNumber);
        case 'BNCState'
            olfBNCArg = bitset(olfBNCArg, olfSettings.triggerNumber);
    end
    
    %% initialize trial types and outcomes
    MaxTrials = 1000;
    if S.GUI.PunishOn
        TrialTypesSimple = randi(2, 1, MaxTrials); % 1 = Odor1, 2 = Odor2
    else
        TrialTypesSimple = ones(1, MaxTrials); % during training, initially present CS+ trials only
    end
    isReverse = zeros(1, MaxTrials); % 0 = no reverse, 1 = reversed contingencies
    TrialTypes = TrialTypesSimple; % 1=0dor1, CS+ 2=Odor2, CS-, 3=Odor1, CS-, 4=Odor2, CS+, this array (extended for plotting) will be updated dynamically
    Outcomes = NaN(1, MaxTrials); % NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 

    
    BpodSystem.Data.TrialTypes = [];
    BpodSystem.Data.TrialOutcome = [];
    BpodSystem.Data.TrialTypesSimple = [];    
    BpodSystem.Data.OdorValve = [];
    BpodSystem.Data.Epoch = [];
    BpodSystem.Data.isReverse = [];
    
    lickOutcome = '';
    noLickOutcome = '';
    
     
%%  Initialize photometry session analysis plots    
    BpodSystem.PluginObjects.Photometry.blF = []; %[nTrials, nDemodChannels]
    BpodSystem.PluginObjects.Photometry.baselinePeriod = [1 S.PreCsRecording];
    BpodSystem.PluginObjects.Photometry.trialDFF = {}; % 1 x nDemodChannels cell array, fill with nTrials x nSamples dFF matrix for now to make it easy to pull out raster data
    if S.GUI.PunishOn
        BpodSystem.ProtocolFigures.phRaster.TypesOutcomes = {1, [0 1]};
    else
        BpodSystem.ProtocolFigures.phRaster.TypesOutcomes = {1, [0 1]; ... % type, outcomes associated with a split photometry raster plot
                                                            2, [-1 2]; ...
                                                            3, [-1 2]; ...
                                                            4, [0 1]};
    end
%% Define the axes matrix positions on the figure

%     matpos_big = [0 .1 1 .9];
    matpos_lickRaster = [0 0.1 2/5 0.6 * 0.9]; % 2/3 * 0.9,  2/3 of fig height discounting height of title axis
    matpos_phRaster = [2/5 0.1 3/5 0.6 * 0.9];
    matpos_avgs = [0 (0.6 * 0.9 + .1) 1 0.4 * 0.9];
%     matpos_Ph = [0 .5 1 .5];
   
  
    if S.GUI.LED1_amp > 0
        BpodSystem.ProtocolFigures.phRaster.fig_ch1 = ensureFigure('phRaster_ch1', 1);        
        nAxes = size(BpodSystem.ProtocolFigures.phRaster.TypesOutcomes, 1);        
        % params.matpos defines position of axesmatrix [LEFT TOP WIDTH HEIGHT].    
        params.cellmargin = [0.05 0.05 0.05 0.05];   
        params.matpos = [0 0 0.2 1];
        hAx = axesmatrix(1, 1, 1, params, gcf); % axis for cumulative nCorrect plot that resets with reversal
        params.matpos = [0.2 0 0.8 1];        
        hAx = horzcat(hAx, axesmatrix(1, nAxes, 1:nAxes, params, gcf));            
        BpodSystem.ProtocolFigures.phRaster.ax_ch1 = hAx;
        set(hAx, 'YDir', 'Reverse');
    end
    
    if S.GUI.LED2_amp > 0
        BpodSystem.ProtocolFigures.phRaster.fig_ch2 = ensureFigure('phRaster_ch2', 1);        
        nAxes = size(BpodSystem.ProtocolFigures.phRaster.TypesOutcomes, 1);        
        % params.matpos defines position of axesmatrix [LEFT TOP WIDTH HEIGHT].    
        params.cellmargin = [0.05 0.05 0.05 0.05];   
        params.matpos = [0 0 0.2 1];
        hAx = axesmatrix(1, 1, 1, params, gcf); % axis for cumulative nCorrect plot that resets with reversal
        params.matpos = [0.2 0 0.8 1];    
        hAx = horzcat(hAx, axesmatrix(1, nAxes, 1:nAxes, params, gcf));            
        BpodSystem.ProtocolFigures.phRaster.ax_ch2 = hAx;
        set(hAx, 'YDir', 'Reverse');
    end    
    


    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        TrialType = TrialTypes(currentTrial);
        
        %% determine odor cues and outcomes for current trial
        switch TrialType
            case 1
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';
            case 2
                OdorValve = S.GUI.Odor2Valve;
                lickOutcome = 'Punish';
                noLickOutcome = 'Neutral';
            case 3
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = 'Punish';
                noLickOutcome = 'Neutral';
            case 4
                OdorValve = S.GUI.Odor2Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';
            otherwise
        end

        %% update odor valve number for current trial
        slaveResponse = updateValveSlave(valveSlave, OdorValve); 
        S.currentValve = slaveResponse;
        if isempty(slaveResponse);
            disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
            continue
        else
            disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
        end
        
        %% TO DO
        % setup global counter to track number of licks during answer
        % period
        
        BpodSystem.Data.Settings = S; % is this necessary???
        %% Assemble state matrix
        sma = NewStateMatrix(); 
        sma = SetGlobalTimer(sma,1,S.GUI.Answer); % post cue   
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {});         
        sma = AddState(sma,'Name', 'NoLick', ...
            'Timer', S.GUI.NoLick,...
            'StateChangeConditions', {'Tup', 'PreCsRecording','Port1In','RestartNoLick'},...
            'OutputActions', {}); % Sound on, to do
        sma = AddState(sma,'Name', 'RestartNoLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick',},...
            'OutputActions', {}); % Sound on, to do
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'BNCState', npgBNCArg, 'WireState', npgWireArg});
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','Cue'},...
            'OutputActions',{});
        sma = AddState(sma, 'Name', 'Cue', ... 
            'Timer', S.OdorTime,...
            'StateChangeConditions', {'Tup','Delay'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});
        sma = AddState(sma, 'Name', 'AnswerDelay', ... 
            'Timer', S.GUI.AnswerDelay,...
            'StateChangeConditions', {'Tup', 'AnswerStart'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'AnswerStart', ... 
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'AnswerNoLick'},...
            'OutputActions', {'GlobalTimerTrig', 1});
        sma = AddState(sma, 'Name', 'AnswerNoLick', ... 
            'Timer', 0,...
            'StateChangeConditions', {'Port1In', 'AnswerLick', 'GlobalTimer1_End', noLickOutcome},...
            'OutputActions', {});     
        sma = AddState(sma, 'Name', 'AnswerLick', ... 
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer1_End', lickOutcome},...
            'OutputActions', {});             
        sma = AddState(sma, 'Name', 'NoLickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', noLickOutcome});
        sma = AddState(sma, 'Name', 'LickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', lickOutcome});        
        sma = AddState(sma,'Name', 'Reward', ...
            'Timer', S.RewardValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.RewardValveCode, 'SoftCode', 1});
        sma = AddState(sma,'Name', 'Punish', ...
            'Timer', S.GUI.PunishValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.PunishValveCode, 'SoftCode', 1});
        sma = AddState(sma,'Name', 'Neutral', ...
            'Timer', (S.RewardValveTime + S.GUI.PunishValveTime)/2,...
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'SoftCode', 1});
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',S.PostUsRecording,...  
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{});
        %%
        SendStateMatrix(sma);

        %% prep data acquisition
        preparePhotometryAcq(S);

        %% Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
        
        %% Stop Photometry session
        stopPhotometryAcq;        
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            %% Process NIDAQ session
            processPhotometryAcq(currentTrial);
            %% online plotting
            processPhotometryOnline(currentTrial);
            updatePhotometryPlot(startX);         
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            

            % determine outcome
            if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Reward(1))
                TrialOutcome = 1; % hit
                TotalRewardDisplay('add', S.GUI.Reward); % update reward display                
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Punish(1))
                TrialOutcome = 0; % false alarm
            else
                switch lickOutcome
                    case 'Punish'
                        TrialOutcome = 2; % correct rejection
                    case 'Reward'
                        TrialOutcome = -1; % miss
                end
            end
            
            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialTypesSimple(end + 1) = TrialTypesSimple(currentTrial);                
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.OdorValve(end + 1) =  OdorValve;
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            BpodSystem.Data.isReverse(end + 1) = isReverse(currentTrial);
    

            
            

            
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            
           %% adaptive code or function to determine if a reversal is necessary 
%         % parameters controling reversals
%         S.BlockFirstReverseCorrect = 30; % number of correct responses necessary prior to initial reversal
%         S.IsFirstReverse = 1; % are we evaluating initial reversal? % this will be saved across sessions
%         S.BlockCountCorrect = 0; % tally of correct responses prior to a reversal
%         S.BlockMinCorrect = 10;
%         S.BlockMeanAdditionalCorrect = 10;
%         S.BlockMaxAdditionalCorrect = S.BlockMeanAdditionalCorrect * 2;
%         S.BlockAdditionalCorrect = []; % determined adaptively
%         S.GUI.Reverse = 0; % determined adaptively, do I need this?   
            
            if S.GUI.PunishOn
                lastReverse = find(diff(BpodSystem.Data.isReverse));
                if isempty(lastReverse)
                    lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
                else
                    lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
                end
                if lastReverse == 1;
                    nCorrectNeeded = S.BlockFirstReverseCorrect;
                end
                nCorrect = length(find(BpodSystem.Data.TrialOutcome(lastReverse:end) == 1));
                if nCorrect == nCorrectNeeded % reverse next trial
    %                 Determine nCorrectNeeded for next block
                    p = 1/(S.BlockMeanAdditionalCorrect + 1); % for geometric distribution, mean = (1-p) / p
                    additionalCorrectNeeded = Inf;
                    while additionalCorrectNeeded > S.BlockMaxAdditionalCorrect
                        additionalCorrectNeeded = geornd(p); % geometric distribution with probability = p of success on each trial
                    end
                    nCorrectNeeded = S.BlockMinCorrect + additionalCorrectNeeded;
                    if isReverse(currentTrial)
                        isReverse((currentTrial + 1):end) = 0;
                    else
                        isReverse((currentTrial + 1):end) = 1;
                    end
                    TrialTypes = TrialTypesSimple + isReverse * 2; % shift the trialtype up by 2 for reversals...
                    warning('make sure syncing to parameter gui is working!');                
                    S.GUI.Epoch = S.GUI.Epoch + 1; % increment the epoch/ block number (make sure this works with syncing to GUI!!!!)
                    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
                end
            end

    %        if necessary, increment epoch and toggle isReversal for future
    %        trials            
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        

    end
end

function updatePhotometryRasters
    global BpodSystem nidaq
    
% ensureFigure('test', 1);
% 
% ha = axes('YDir', 'Reverse');
% 
% nTrials = length(find(trialsByType{1}));
% xData = TE.Photometry.xData;
% cData = TE.Photometry.data(1).dFF(trialsByType{1}, :);
% nSamples = size(cData, 2);
% %%
% outcome = logical(randi(2, nTrials, 1) - 1);
% cData2 = NaN(nTrials, size(cData, 2) * 2);
% %%
% cData2(outcome, (nSamples+1):end) = cData(outcome, :);
% cData2(~outcome, (1:nSamples)) = fliplr(cData(~outcome, :));
% ih = image('YData', [1 size(cData, 1)],...
%     'CData', cData2, 'CDataMapping', 'Scaled', 'Parent', gca);
% 
% set(gca, 'YLim', [1 size(cData2, 1)], 'CLim', [-0.0075 0.0095]);    
    
            %% update photometry rasters
            displaySampleRate = nidaq.sample_rate / nidaq.online.decimationFactor;
            x1 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(1), displaySampleRate, 0);
            x2 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(2), displaySampleRate, 0);        
            types = BpodSystem.ProtocolFigures.phRaster.types;
%             lookupFactor = S.GUI.phRasterScaling;
            lookupFactor = 4;
            xData = [min(nidaq.online.trialXData) max(nidaq.online.trialXData)] + startX;
            for i = 1:length(types)
                if S.GUI.LED1_amp > 0
                    phMean = mean(mean(BpodSystem.PluginObjects.Photometry.trialDFF{1}(:,x1:x2)));
                    phStd = mean(std(BpodSystem.PluginObjects.Photometry.trialDFF{1}(:,x1:x2)));    
                    ax = BpodSystem.ProtocolFigures.phRaster.ax_ch1(i);
                    trials = onlineFilterTrials(types{i},[],[]);
                    nidaq.online.trialXData
                    CData = BpodSystem.PluginObjects.Photometry.trialDFF{1}(trials, :);
                    image('XData', xData,...
                        'YData', [1 size(CData, 1)],...
                        'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
                    set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd]);
                end
                if S.GUI.LED2_amp > 0
                    phMean = mean(mean(BpodSystem.PluginObjects.Photometry.trialDFF{2}(:,x1:x2)));
                    phStd = mean(std(BpodSystem.PluginObjects.Photometry.trialDFF{2}(:,x1:x2)));    
                    ax = BpodSystem.ProtocolFigures.phRaster.ax_ch2(i);
                    trials = onlineFilterTrials(types{i},[],[]);
                    nidaq.online.trialXData
                    CData = BpodSystem.PluginObjects.Photometry.trialDFF{2}(trials, :);
                    image('XData', xData,...
                        'YData', [1 size(CData, 1)],...
                        'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
                    set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd]);
                end                
            end
end

        
        
        
