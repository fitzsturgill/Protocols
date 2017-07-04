%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms neral Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
function CuedOutcome_odor_complete
    % Cued outcome task
    % Written by Fitz Sturgill 3/2016.

    % Photometry with LED light sources, 2Channels
   
    
    global BpodSystem nidaq

    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S


    defaults = {... % If settings file was an empty struct, populate struct with default settings
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 0;...
        'GUI.PhotometryOn', 1;...
        'GUI.mu_iti', 6;... % 6;... % approximate mean iti duration
        'GUI.highValueOdorValve', 5;... % output pin on the slave arduino switching a particular odor valve
        'GUI.lowValueOdorValve', 6;...
        'GUI.Delay', 1;...
        'GUI.Epoch', 1;...
        'GUI.highValuePunishFraction', 0.10;...
        'GUI.lowValuePunishFraction', 0.55;...
        'GUI.PunishValveTime', 0.2;... %s        
        'GUI.Reward', 8;...
        'GUI.OdorTime', 1;... % 0.5s tone, 1s delay        
        'GUI.Delay', 1;... %  time after odor and before US delivery (or omission)
        'GUI.PunishOn', 1;...
%         'GUI.phRasterScaling', 4;...        
        
        'NoLick', 0;... % forget the nolick
        'ITI', [];... %ITI duration is set to be exponentially distributed later
        'RewardValveCode', 1;... % why do I have these? 
        'PunishValveCode', 2;... % seems uncessary (redundant and currently incorrect)
        'currentValve', [];... % holds odor valve # for current trial
        'RewardValveTime',  [];... %GetValveTimes('GUI.Reward, S.RewardValveCode);

        % state durations in behavioral protocol
        'PreCsRecording ', 4;... % After ITI        was 3
        'PostUsRecording', 4;... % After trial before exit    was 5

        'ToneFreq', 10000;... % frequency of neutral tone signaling onset of U.S.
        'ToneDuration', 0.1;... % duration of neutral tone
    };
    S = setBpodDefaultSettings(S, defaults);


    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;

    S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);
    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.GUI.OdorTime + S.GUI.Delay + S.PostUsRecording;
    startX = 0 - S.PreCsRecording - S.GUI.OdorTime - S.GUI.Delay; % 0 defined as time from reinforcement
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode    
        S = initPhotometry(S);
    end

    %% Initialize Sound Stimuli
    SF = 192000; 
    % linear ramp of sound for 10ms at onset and offset
    neutralTone = taperedSineWave(SF, S.ToneFreq, S.ToneDuration, 0.01); % 10ms taper
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, neutralTone);
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Initialize olfactometer and point grey camera
    % retrieve machine specific olfactometer settings
    addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    olfSettings = machineSpecific_Olfactometer;
    rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict

    % retrieve machine specific point grey camera settings
    addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    pgSettings = machineSpecific_pointGrey;
    rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict    

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



    %% Init Plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        scrsz = get(groot,'ScreenSize'); 

        BpodSystem.ProtocolFigures.NIDAQFig       = figure(...
            'Position', [25 scrsz(4)*2/3-100 scrsz(3)/2-50  scrsz(4)/3],'Name','NIDAQ plot','numbertitle','off');
        BpodSystem.ProtocolFigures.NIDAQPanel1     = subplot(2,1,1);
        BpodSystem.ProtocolFigures.NIDAQPanel2     = subplot(2,1,2);
    end

    %% initialize trial types and outcomes
    MaxTrials = 1000;    
    TrialType = [];
    TrialOutcome = [];  % remember! these can't be left as zeros because they are used as indexes by processAnalysis_Photometry
    OdorValve = [];
    Us = {};
    Cs = {};
    % initialize BpodSystem.Data fields
    BpodSystem.Data.TrialTypes = [];
    BpodSystem.Data.TrialOutcome = [];
    BpodSystem.Data.OdorValve = [];
    BpodSystem.Data.Epoch = [];
    BpodSystem.Data.Cs = {};
    BpodSystem.Data.Us = {};


    %% init outcome plot

    scrsz = get(groot,'ScreenSize');
    % i need to mimic bpod integrated figures (see other protocols) so it
    % is closed properly on bpod protocol stop
    outcomeFig = ensureFigure('Outcome_plot', 1);
    set(outcomeFig, 'Position', [25 scrsz(4)/2-150 scrsz(3)-50  scrsz(4)/6],'numbertitle','off', 'MenuBar', 'none'); %, 'Resize', 'off');    
    outcomeAxes = axes('Parent', outcomeFig);
%     placeHolder = line([1 1], [min(unique(TrialTypes)) max(unique(TrialTypes))], 'Color', [0.8 0.8 0.8], 'LineWidth', 4, 'Parent', outcomeAxes);    
    outcomesHandle = scatter([], []);
    outcomeSpan = 20;
%     set(outcomeAxes, 'XLim', [0 outcomeSpan]);

%% init lick raster plot, uses session analysis functions (~Winter-Spring, 2016)
    lickRasterPlot = struct(...
        'lickRasterFig', [],...
        'Ax', [],...
        'Types', [],...
        'Outcomes', []...
        );
    lickRasterPlot.lickRasterFig = ensureFigure('lickRaster', 1);
    lickRasterPlot.Ax(1) = subplot(2,1,1); title('High Value');
    lickRasterPlot.Ax(2) = subplot(2,1,2); title('Low Value');
    lickRasterPlot.Types{1} = [1 2 3]; % 
    lickRasterPlot.Types{2} = [4 5 6];
    lickRasterPlot.Outcomes{1} =  [1 2 3];
    lickRasterPlot.Outcomes{2} = [1 2 3];
%% init lick hist plot
    preUs = S.PreCsRecording + S.GUI.OdorTime + S.GUI.Delay;
    postUs = S.PostUsRecording;
    binWidth = 0.5;
    lickHistPlot.lickHistFig = ensureFigure('lickHist', 1);
    lickHistPlot.ax = axes('TickDir', 'out');
    lickHistPlot.Types = {[1 2 3], [4 5 6], [], [], []};
    lickHistPlot.Outcomes = {[], [], 1, 2, 3};
    lickHistPlot.zeroField = repmat({'Us'}, 1, 5);
    lickHistPlot.startField = {'PreCsRecording', 'PreCsRecording', 'Us', 'Us', 'Us'};
    lickHistPlot.endField = {'Delay', 'Delay', 'PostUsRecording', 'PostUsRecording', 'PostUsRecording'};
    lickHistPlot.binSpecs = {[-preUs 0 binWidth], [-preUs 0 binWidth], [0 postUs binWidth], [0 postUs binWidth], [0 postUs binWidth]};
%%  Initialize photometry session analysis plots 
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        BpodSystem.PluginObjects.Photometry.blF = []; %[nTrials, nDemodChannels]
        BpodSystem.PluginObjects.Photometry.baselinePeriod = [1 S.PreCsRecording];
        BpodSystem.PluginObjects.Photometry.trialDFF = {}; % 1 x nDemodChannels cell array, fill with nTrials x nSamples dFF matrix for now to make it easy to pull out raster data
        if S.GUI.PunishOn
            BpodSystem.ProtocolFigures.phRaster.types = {1, 2, 3, 4, 5, 6, 7, 8, 9};
        else
            BpodSystem.ProtocolFigures.phRaster.types = {1, 3, 7, 9};
        end

        if S.GUI.LED1_amp > 0
            BpodSystem.ProtocolFigures.phRaster.fig_ch1 = ensureFigure('phRaster_ch1', 1);
            BpodSystem.ProtocolFigures.phRaster.ax_ch1 = zeros(1, length(BpodSystem.ProtocolFigures.phRaster.types));
            for i = 1:length(BpodSystem.ProtocolFigures.phRaster.types)
                BpodSystem.ProtocolFigures.phRaster.ax_ch1(i) = subplot(2, ceil(length(BpodSystem.ProtocolFigures.phRaster.types)/2), i);
                set(gca, 'YDir', 'Reverse');
                title(['Type: ' num2str(BpodSystem.ProtocolFigures.phRaster.types{i})]);
            end
        end
        if S.GUI.LED2_amp > 0
            BpodSystem.ProtocolFigures.phRaster.fig_ch2 = ensureFigure('phRaster', 1);
            BpodSystem.ProtocolFigures.phRaster.ax_ch2 = zeros(1, length(BpodSystem.ProtocolFigures.phRaster.types));
            for i = 1:length(BpodSystem.ProtocolFigures.phRaster.types)
                BpodSystem.ProtocolFigures.phRaster.ax_ch2(i) = subplot(2, ceil(length(BpodSystem.ProtocolFigures.phRaster.types)/2), i);
                set(gca, 'YDir', 'Reverse');
            end
        end
    end
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin 
        
        %% determine trial type on the fly
        pfh = S.GUI.highValuePunishFraction;
        pfl = S.GUI.lowValuePunishFraction;
        if S.GUI.PunishOn
            typeMatrix = [...
                % high value odor
                1, 0.425 * (1 - pfh - 0.1);... %  reward
                2, 0.425 * pfh;...  % punish
                3, 0.425 * 0.1;... % omit- signal with neutral cue (tone)
                % low value odor
                4, 0.425 * (1 - pfl - 0.1);... %  reward
                5, 0.425 * pfl;... % punish
                6, 0.425 * 0.1;... % omit
                % uncued
                7, 0.05;... % reward
                8, 0.05;... % punish
                9, 0.05;... % neutral
                ];
        else
            typeMatrix = [...
                % high value odor (no punish)
                1, 0.8 * 0.9;... %  reward
                3, 0.8 * 0.1;...  % omit 
                % uncued
                7, 0.1;...  % reward
                9, 0.1;...  % neutral
                ];
        end        
        TrialType = defineRandomizedTrials(typeMatrix, 1);
        %% define outcomes, sound durations, and valve times

        % determine outcomes
        if ismember(TrialType, [1 4 7])
            TrialOutcome = 1; % reward
            Us = 'Reward';
            UsAction = {'ValveState', S.RewardValveCode, 'SoftCode', 1};
            UsTime = S.RewardValveTime;
        elseif ismember(TrialType, [2 5 8])
            TrialOutcome = 2; % punish
            Us = 'Punish';    
            UsAction = {'ValveState', S.PunishValveCode, 'SoftCode', 1};
            UsTime = S.GUI.PunishValveTime;
        else % implicitly TrialType must be one of [3 6 9] 
            TrialOutcome = 3; % omit
            Us = 'Omit';        
            UsAction = {'SoftCode', 1};
            UsTime = (S.RewardValveTime + S.GUI.PunishValveTime)/2; % split the difference, both should be very short            
        end

        % determine cue
        if ismember(TrialType, [1 2 3])
            OdorValve = S.GUI.highValueOdorValve;
            Cs = 'highValue';
        elseif ismember(TrialType, [4 5 6])
            OdorValve = S.GUI.lowValueOdorValve;        
            Cs = 'lowValue';
        else
            OdorValve = 0; % no odor cue
            Cs = 'uncued';
        end    
        
        % update outcome plot to reflect currently executed trial
        trialSpan = 10;
        trialsBack = currentTrial - max(1, currentTrial - trialSpan);
        if trialsBack % greater than 0
            YData = [BpodSystem.Data.TrialTypes((currentTrial - trialsBack + 1):end) TrialType]; % add current trial type prior to sending state matrix and processing
            XData = (currentTrial - trialsBack + 1):currentTrial;
        else % it's the first trial
            YData = TrialType;
            XData = 1;
        end
        outcomesHandle.XData = XData;
        outcomesHandle.YData = YData;
%         set(outcomeAxes, 'XLim', [max(0, currentTrial - outcomeSpan), currentTrial]);
%         set(placeHolder, 'XData', [currentTrial currentTrial]);   
        set(outcomeAxes, 'YLim', [0 10], 'YGrid', 'on');
        
        % update odor valve number for current trial
        slaveResponse = updateValveSlave(valveSlave, OdorValve); 
        S.currentValve = slaveResponse;
        if isempty(slaveResponse);
            disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
            continue
        else
            disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
        end

        S.ITI = inf;
        while S.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
            S.ITI = exprnd(S.GUI.mu_iti);
        end

        BpodSystem.Data.Settings = S; % is this necessary???
        sma = NewStateMatrix(); % Assemble state matrix
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {}); 
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer',S.ITI,...
            'StateChangeConditions', {'Tup', 'StartRecording'},...
            'OutputActions',{});
% trigger nidaq and point grey: my 2 bpods have different issues, for one,
% bnc2 doesn't work, for the other, the wire outputs don't work. npgBNCArg
% and npgWireArg provide a merged solution for this conflict that depends
% on a initializion function provided in the settings directory
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'BNCState', npgBNCArg, 'WireState', npgWireArg});         
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','Cue'},...
            'OutputActions',{});
        sma = AddState(sma, 'Name', 'Cue', ... 
            'Timer', S.GUI.OdorTime,...
            'StateChangeConditions', {'Tup','Delay'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});
        sma = AddState(sma, 'Name', 'Delay', ... 
            'Timer', S.GUI.Delay,...
            'StateChangeConditions', {'Tup', 'Us'},...
            'OutputActions', {});         
        sma = AddState(sma,'Name', 'Us', ...
            'Timer',UsTime,... % time will be 0 for omission
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', UsAction);
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',S.PostUsRecording,...  
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{});

        %%
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SendStateMatrix(sma);

        %% prep data acquisition
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode        
            preparePhotometryAcq(S);
        end

        %% Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
        
        %% Stop Photometry session
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode        
            stopPhotometryAcq;
        end
        
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            %% Process NIDAQ session
            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode            
                processPhotometryAcq(currentTrial);
                %% online plotting
                try
                    processPhotometryOnline(currentTrial);
                    updatePhotometryPlot(startX);    
                catch
                end
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;
            BpodSystem.Data.OdorValve(end + 1) =  OdorValve;
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;
            BpodSystem.Data.Us{end + 1} = Us;
            BpodSystem.Data.Cs{end + 1} = Cs;            

            if ismember(TrialType, [1 4 7])
                TotalRewardDisplay('add', S.GUI.Reward); 
            end
            
            bpLickRaster(BpodSystem.Data, lickRasterPlot.Types{1}, lickRasterPlot.Outcomes{1}, 'Us', [], lickRasterPlot.Ax(1));
            set(gca, 'XLim', [-6, 4]);
            bpLickRaster(BpodSystem.Data, lickRasterPlot.Types{2}, lickRasterPlot.Outcomes{2}, 'Us', [], lickRasterPlot.Ax(2));            
            set(gca, 'XLim', [-6, 4]);
            
            %% update lick histograms
            axes(lickHistPlot.ax);
            cla;
            linecolors = {'c', 'm', 'b', 'r', 'k'};
            for i = 1:length(lickHistPlot.Types);
                bpLickHist(BpodSystem.Data, lickHistPlot.Types(i), lickHistPlot.Outcomes(i), lickHistPlot.binSpecs{i},...
                    lickHistPlot.zeroField{i}, lickHistPlot.startField{i}, lickHistPlot.endField{i}, linecolors(i), [], gca);
            end
            %% update photometry rasters
            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode            
                try
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
            end
            
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            if ~BpodSystem.EmulatorMode            
                fclose(valveSlave);
                delete(valveSlave);
            end
            return
        end 
    end
end

% Index exceeds matrix dimensions.
% 
% Error in phDemodOnline (line 10)
%         nidaq.online.currentDemodData{1} = phDemod(nidaq.ai_data(:,1), nidaq.ao_data(:,1),
%         nidaq.sample_rate, LED1_f, lowCutoff);
% 
% Error in processPhotometryOnline (line 7)
%     phDemodOnline(currentTrial);
% 
% Error in CuedOutcome_odor_complete (line 368)
%             processPhotometryOnline(currentTrial);
% 
% Error in run (line 96)
% evalin('caller', [script ';']);
% 
% Error in LaunchManager>pushbutton1_Callback (line 300)
%         run(ProtocolPath);
% 
% Error in gui_mainfcn (line 95)
%         feval(varargin{:});
% 
% Error in LaunchManager (line 61)
%     gui_mainfcn(gui_State, varargin{:});
% 
% Error in
% matlab.graphics.internal.figfile.FigFile/read>@(hObject,eventdata)LaunchManager('pushbutton1_Callback',hObject,eventdata,guidata(hObject)) 
% Error while evaluating DestroyedObject Callback