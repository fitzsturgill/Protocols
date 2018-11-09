function lickNoLick_Odor_v2
    % Protocol for pavlovian and odor conditioning
    % Written by Fitz Sturgill circa 2017.
    global BpodSystem
    
    %% CS valence is important-   explain here!!!
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    blockFunctionList = {'two_cue_states'};
    PhotometryRasterFcnList = {'lickNoLick_Odor_PhotometryRasters', 'LNL_odor_pRasters_3odors', 'LNL_pRasters_byOdor'};
    defaults = {...
        'GUIPanels.Photometry', {'LED1_amp', 'LED2_amp', 'PhotometryOn'};...
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 0;...
        'GUI.PhotometryOn', 1;...
        
        'GUIPanels.Timing', {'Epoch', 'ITI', 'mu_iti', 'NoLick', 'stateDelay', 'OutcomeDelay', 'Answer'};...
        'GUI.Epoch', 1;...
        'GUI.ITI', 0;... % reserved for future use
        'GUI.stateDelay',2; ...
        'GUI.mu_iti', 6;... % if > 0, determines random ITI
        'GUI.NoLick', 0;... % mouse must stop licking for this period to advance to the next trial
%         'GUI.AnswerDelay', 0;... % post-odor, time until answer period, (in future may be updated trial-by-trial)
        % !!!! set OutcomeDelay = Answer for fixed timing (as in pavlovian
        % conditioning)!!!
        'GUI.OutcomeDelay', 1;... % response (lick) to reinforcement delay, (in future may be updated trial-by-trial)
        'GUI.Answer', 1;... % answer period duration

        'GUIPanels.Stimuli', {'PunishValveTime', 'Reward', 'UsePulsePal', 'Odor1Valve', 'Odor2Valve', 'Odor3Valve', 'neutralToneOn'};...
        'GUI.PunishValveTime', 0.2;... %s        
        'GUI.Reward', 8;...
        'GUI.UsePulsePal', 0;...
        'GUI.Odor1Valve', 5;...
        'GUI.Odor2Valve', 6;...
        'GUI.Odor3Valve', 7;...
        'GUI.neutralToneOn', 0;...
        'GUIMeta.neutralToneOn.Style', 'checkbox';...      

        'GUIPanels.Blocks', {'BlockFcn', 'PhotometryRasterFcn', 'Block'};...
        'GUI.BlockFcn', 'two_cue_states';...
        'GUIMeta.BlockFcn.Style', 'popupmenutext';...
        'GUIMeta.BlockFcn.String',  blockFunctionList;...
        'GUI.PhotometryRasterFcn', 'lickNoLick_Odor_PhotometryRasters';...
        'GUIMeta.PhotometryRasterFcn.Style', 'popupmenutext';...
        'GUIMeta.PhotometryRasterFcn.String', PhotometryRasterFcnList;...
        'GUI.Block', 1;...
        
        'GUITabs.General', {'Photometry'};...
        'GUITabs.Timing', {'Timing'};...
        'GUITabs.Stimuli', {'Stimuli'};...
        'GUITabs.Blocks', {'Blocks'};...
%         'GUI.Hit_RewardFraction', 0.7;...
%         'GUI.FA_RewardFraction', 0.3;...
%         'GUI.Hit_PunishFraction', 0;...
%         'GUI.FA_PunishFraction', 0;...
        
        
        % parameters for adaptive reversals 

        % common across LinkTo functions
        'reversalCriterion', [];... % criterion for reversal, plotted online
        
        % number correct dictates reversal, LinkToFcn =
        % blockSwitchFunction_nCorrect
        'SwFcn_nC_MinCorrect', 10;... 
        'SwFcn_nC_MeanAdditionalCorrect', 10;...
        'SwFcn_nC_MaxAdditionalCorrect', 20;...
        
        % response rate difference dictates reversal, LinkToFcn =
        % blockSwitchFunction_responseRateDifference
        'SwFcn_BlockRRD_minDiff', 0.5;...
        'SwFcn_BlockRRD_minTrials', 20;...
       
        'OdorTime', 1;...
        'PreCsRecording', 4;...
        'PostUsRecording', 4;...
        'currentValve', [];... % holds odor valve # for current trial
        'RewardValveCode', 1;...
        'PunishValveCode', 2;...
        'RewardValveTime', [];...
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
    %% Load Tables
    bfh = str2func(S.GUI.BlockFcn);
    try
        S.Tables = bfh();
    catch
        error('** block function error ***');
    end
    
    %% init photometry raster function handle
    prfh = str2func(S.GUI.PhotometryRasterFcn);
    
    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.OdorTime + S.GUI.stateDelay + S.GUI.Answer + S.PostUsRecording;
    startX = 0 - S.PreCsRecording; % 0 defined as time from cue (because reward time can be variable depending upon outcomedelay)
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry(S);
    end
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        updatePhotometryPlot('init');
        prfh('init', 'baselinePeriod', [1 S.PreCsRecording])
    end
    %% lick rasters for cs1 and cs2
    BpodSystem.ProtocolFigures.lickRaster.fig = ensureFigure('lick_raster', 1);        
    BpodSystem.ProtocolFigures.lickRaster.AxOdor1 = subplot(1, 4, 1); title('Odor 1');
    BpodSystem.ProtocolFigures.lickRaster.AxOdor2 = subplot(1, 4, 2); title('Odor 2');
    BpodSystem.ProtocolFigures.lickRaster.AxOdor3 = subplot(1, 4, 3); title('Odor 3');
    BpodSystem.ProtocolFigures.lickRaster.AxOdor4 = subplot(1, 4, 4); title('Odor 4');

    %% Initialize Sound Stimuli
    if ~BpodSystem.EmulatorMode
        SF = 192000;

        % linear ramp of sound for 10ms at onset and offset
        neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
        % kludge
        neutralTone = neutralTone / 100;
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, neutralTone);
        
        % white noise for punishment
        wn_duration = 1;
        wn_amplitude = 2;
        whiteNoise = (rand(1, wn_duration * SF) - 0.5) * wn_amplitude;
        PsychToolboxSoundServer('Load', 2, whiteNoise);
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Generate feedback white noise
        

        load('PulsePalParamFeedback.mat');
        if S.GUI.UsePulsePal
            soundArg = bitset(0, 2); % kludge to get pulse pal to work on top rig but not disrupt bottom rig
            try
                ProgramPulsePal(PulsePalParamFeedback);        
            catch % if you're a dolt and forgot to start pulse pal
                PulsePal;
                ProgramPulsePal(PulsePalParamFeedback);        
            end
                maxLineLevel = 1; % e.g. +/- 1V command signal to an amplified speaker
                nPulses = 1000;
                SendCustomWaveform(1, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %
                SendCustomWaveform(2, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %        
        else
            soundArg = 0;
        end

    
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
    end

    % determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    olfWireArg = 0;
    olfBNCArg = 0;
    if ~BpodSystem.EmulatorMode
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
    end
    %% initialize trial types and outcomes
    MaxTrials = 1000;

    % Outcomes -> NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 
% % %     ReinforcementOutcome = []; % local version of BposSystem.Data.ReinforcementOutcome
    
    BpodSystem.Data.TrialTypes = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.TrialOutcome = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.CS1Valence = [];
    BpodSystem.Data.CS2Valence = []; % 1 = CS+, -1 = CS-, 0 = unCued or a 'control' odorant that doesn't affect outcomes or adaptive reversals
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. Reward, Punish, WNoise, or Neutral
    BpodSystem.Data.LickAction = []; % 'lick' or 'noLick' 
    BpodSystem.Data.OdorValve1 = []; % e.g. 1st odor = V5, or V6,
    BpodSystem.Data.OdorValve2 = []; % 
    BpodSystem.Data.OdorValveIndex = []; % 1st odor, 2nd odor
    BpodSystem.Data.Epoch = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.BlockNumber = [];
    BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
    BpodSystem.Data.SwitchParameterCriterion = [];
    BpodSystem.Data.AnswerLicks = struct('count', [], 'rate', [], 'duration', []); % number of licks during answer period, nTrials x 1
    BpodSystem.Data.AnswerLicksROC = struct('auROC', [], 'pVal', [], 'CI', []); 
% % %     Outcome = '';
% % %     lickAction = '';
    %% Outcome Plot
% % %     trialsToShow = 50;
% % %     TrialTypes = [];
% % %     TrialOutcomes = [];
% % %     BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
% % %     BpodSystem.GUIHandles.OutcomePlot = axes;
% % %     TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', BpodSystem.Data.TrialTypes);%, 'ntrials', trialsToShow);
    
    %% testing auROC plotting
    BpodSystem.ProtocolFigures.auROC.fig = ensureFigure('auROC_plot', 1); % still a kludge, assumes that I'm using correct block switch funtion currently... (4/2018)
    BpodSystem.ProtocolFigures.auROC.ax = subplot(2,1,1, 'NextPlot', 'add');
    BpodSystem.ProtocolFigures.auROC.sh = scatter([], [], 20, [], 'Parent', BpodSystem.ProtocolFigures.auROC.ax); 
    ylabel('auROC');
    BpodSystem.ProtocolFigures.auROC.ax2 = subplot(2,1,2, 'NextPlot', 'add'); % plot switchParameter
    BpodSystem.ProtocolFigures.auROC.clh = line(0,0, 'Parent', BpodSystem.ProtocolFigures.auROC.ax2, 'Color', 'g');
    BpodSystem.ProtocolFigures.auROC.splh = line(0,0, 'Parent', BpodSystem.ProtocolFigures.auROC.ax2, 'Color', 'k');
    ylabel('Fraction significant'); xlabel('trial number');
    
% % %     Outcome = '';
% % %     lickAction = '';
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table); % trial type chosen on the fly based upon current Protocol Settings
% % %         TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',... % update outcome plot to show trial type of current trial with outcome undefined (NaN)
% % %             currentTrial, [BpodSystem.Data.TrialTypes TrialType], [BpodSystem.Data.TrialOutcome NaN]);            
        
        
        switch S.Block.Table.CS1(TrialType)
            case 0
                OdorValve1 = 0; % uncued
            case 1
                OdorValve1 = S.GUI.Odor1Valve;
            case 2
                OdorValve1 = S.GUI.Odor2Valve;
            case 3
                OdorValve1 = S.GUI.Odor3Valve;
            case 4
                OdorValve1 = S.Gui.Odor4Valve;
        end
        
        switch S.Block.Table.CS2(TrialType)
            case 0
                OdorValve2 = 0; % uncued
            case 1
                OdorValve2 = S.GUI.Odor1Valve;
            case 2
                OdorValve2 = S.GUI.Odor2Valve;
            case 3
                OdorValve2 = S.GUI.Odor3Valve;
            case 4
                OdorValve2 = S.Gui.Odor4Valve;
        end
        
        Outcome = S.Block.Table.US{TrialType};
        
        
        if S.GUI.neutralToneOn
            neutralCode = 1;
        else
            neutralCode = 0;
        end
        
        %% update odor valve number for current trial
        if ~BpodSystem.EmulatorMode
            slaveResponse = updateValveSlave(valveSlave, [OdorValve1 OdorValve2]); 
            S.currentValve = slaveResponse;
            if isempty(slaveResponse)
                disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
                continue
            else
                disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
            end
        end
        disp(['*** Trial Type = ' num2str(TrialType) ' Block = ' num2str(S.GUI.Block) ' ***']);
        S.Block.Table % display current block (should have this be in a GUI window eventually)
        %% Expotentially distributed ITIs
        if S.GUI.mu_iti
            S.GUI.ITI = inf;
            while S.GUI.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                S.GUI.ITI = exprnd(S.GUI.mu_iti);
            end        
        end
        %% TO DO
        % setup global counter to track number of licks during answer
        % period
        
        BpodSystem.Data.Settings = S; % SAVE SETTINGS, USED BY UPDATEPHOTOMETRYRASTERS SUBFUNCTION CURRENTLY, but redundant with trialSettings        
        
       %% Assemble state matrix
        sma = NewStateMatrix(); 
        sma = SetGlobalTimer(sma,1,S.GUI.Answer); % post cue   
        sma = SetGlobalTimer(sma,2,S.nidaq.duration); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {}); 
        
        sma = AddState(sma,'Name', 'ITI', ...
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'NoLick'},...
            'OutputActions', {}); 
        
        sma = AddState(sma,'Name', 'NoLick', ...
            'Timer', S.GUI.NoLick,...
            'StateChangeConditions', {'Tup', 'StartRecording','Port1In','RestartNoLick'},...
            'OutputActions', {'WireState', bitset(0, 2)}); % Pulse Pal sound on
        
        sma = AddState(sma,'Name', 'RestartNoLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick'},...
            'OutputActions', {}); %
        
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'BNCState', npgBNCArg, 'WireState', npgWireArg}); % trigger photometry acq global timer, nidaq trigger, point grey camera
       
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','Cue1'},...
            'OutputActions',{});
        
        sma = AddState(sma, 'Name', 'Cue1', ... 
            'Timer', S.OdorTime,...
            'StateChangeConditions', {'Tup','stateDelay'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg,});
        
        sma = AddState(sma, 'Name','stateDelay',...
            'Timer',S.GUI.stateDelay,...
            'StateChangeConditions',{'Tup','Cue2'},...
            'OutputActions',{});

        sma = AddState(sma, 'Name', 'Cue2', ... 
            'Timer', S.OdorTime,...
            'StateChangeConditions', {'Tup','Outcome'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});           
        
        sma = AddState(sma, 'Name', 'Outcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', Outcome},...
            'OutputActions', {});  
        
        sma = AddState(sma,'Name', 'Reward', ... % 4 possible outcome states: Reward (H2O + tone), Punish (air puff + tone), WNoise (white noise), Neutral (tone)
            'Timer', S.RewardValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.RewardValveCode, 'SoftCode', 1});
        
        sma = AddState(sma,'Name', 'Punish', ...
            'Timer', S.GUI.PunishValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.PunishValveCode, 'SoftCode', 1});
        
        sma = AddState(sma,'Name', 'WNoise', ...
            'Timer', 0,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'SoftCode', 2});     
        
        sma = AddState(sma,'Name', 'Neutral', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'SoftCode', neutralCode});
        
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',4,...   % should end with global timer 2 but in case global timer 2 misfires, exit trial via 4 second timer
            'StateChangeConditions',{'GlobalTimer2_End','exit', 'Tup', 'exit'},...
            'OutputActions',{});    
        
        
        %%
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
                try % this shouldn't fail, just assigning to a cell array
                    processPhotometryAcq(currentTrial);
                catch
                    disp('*** Problem with saving, this should not happen ***');
                end
                try % in case photometry hicupped
                %% online plotting
                    processPhotometryOnline(currentTrial);
                    updatePhotometryPlot('update', startX);  
                    xlabel('Time from cue (s)');
                catch
                    disp('*** Problem with online photometry processing ***');
                end
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)        
            
%             %TrialOutcome -> NaN: future trial or omission, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot)
%             if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.AnswerLick(1))
%                 lickAction = 'lick';
%                 ReinforcementOutcome = Outcome;               
%                 if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
%                     TrialOutcome = 1; % hit
%                 if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
%                      TrialOutcome = -1; % miss
%                 if S.Block.Table.CSValence(TrialType) == -1
%                      TrialOutcome = 2; % correct rejection
%                 elseif S.Block.Table.CSValence(TrialType) == -1
%                     TrialOutcome = 0; % false alarm
%                 else
%                     TrialOutcome = NaN; % uncued
%                 end
%                 end
%                 end
%             end
% % %             else
% % %                 lickAction = 'nolick';
% % %                 ReinforcementOutcome = Outcome;
% % %                 if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
% % %                     TrialOutcome = -1; % miss
% % %                 elseif S.Block.Table.CSValence(TrialType) == -1
% % %                     TrialOutcome = 2; % correct rejection
% % %                 else
% % %                     TrialOutcome = NaN; % uncued
% % %                 end                
% % %             end
            
            % computer number of answer licks
% % %             answerWindow = [...
% % %                 BpodSystem.Data.RawEvents.Trial{currentTrial}.States.AnswerStart(1)... % start of answer
% % %                 max(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Outcome(end), BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Outcome(end))... % end of answer
% % %                 ];            
% % %             
% % %             if isfield(BpodSystem.Data.RawEvents.Trial{currentTrial}.Events, 'Port1In')
% % %                 BpodSystem.Data.AnswerLicks.count(end + 1) = sum((answerWindow(1) <= BpodSystem.Data.RawEvents.Trial{currentTrial}.Events.Port1In) & (BpodSystem.Data.RawEvents.Trial{currentTrial}.Events.Port1In < answerWindow(2)));
% % %             else
% % %                 BpodSystem.Data.AnswerLicks.count(end + 1) = 0;
% % %             end
% % % 
% % %             BpodSystem.Data.AnswerLicks.duration(end + 1) = diff(answerWindow);
% % %             BpodSystem.Data.AnswerLicks.rate(end + 1) = BpodSystem.Data.AnswerLicks.count(end) / BpodSystem.Data.AnswerLicks.duration(end);
% % % 
% % %             BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
% % %             BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
% % %             BpodSystem.Data.OdorValve1(end + 1) =  OdorValve1;
% % %             BpodSystem.Data.OdorValve2(end + 1) =  OdorValve2;
% % %             BpodSystem.Data.OdorValveIndex(end + 1) = S.Block.Table.CS(TrialType);
% % %             BpodSystem.Data.CSValence(end + 1) = S.Block.Table.CSValence(TrialType);% 1 = CS+, 0 = CS-
% % %             BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
% % %             BpodSystem.Data.ReinforcementOutcome{end + 1} = ReinforcementOutcome; % i.e. 1: reward, 2: neutral, 3: punish
% % %             BpodSystem.Data.BlockNumber(end + 1) = S.GUI.Block;
% % %             BpodSystem.Data.LickAction{end + 1} = lickAction;

            %% update outcome plot to reflect upcoming trial
% % %             TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
% % %                 currentTrial, BpodSystem.Data.TrialTypes, BpodSystem.Data.TrialOutcome);            
% % %             if strcmpi(ReinforcementOutcome, 'reward')
% % %                 TotalRewardDisplay('add', S.GUI.Reward);
% % %             end
            
            %% adaptive block transitions
% %             if S.Block.LinkTo
% %                 switchFcn = str2func(S.Block.LinkToFcn);
% %                 [S.GUI.Block, switchParameter, switchParameterCriterion] = switchFcn(BpodSystem.Data.TrialOutcome, BpodSystem.Data.BlockNumber, S);
% %                 S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
% %             else
% %                 switchParameter = NaN;
% %                 switchParameterCriterion = NaN;
% %             end
% %             BpodSystem.Data.SwitchParameter(end + 1) = switchParameter(1);
% %             BpodSystem.Data.SwitchParameterCriterion = switchParameterCriterion;

% % %             % testing auROC plotting
% % %             set(BpodSystem.ProtocolFigures.auROC.sh, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.AnswerLicksROC.auROC, 'CData', BpodSystem.Data.AnswerLicksROC.pVal);
% % %             set(BpodSystem.ProtocolFigures.auROC.splh, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.SwitchParameter);
% % %             set(BpodSystem.ProtocolFigures.auROC.clh, 'XData', [1 currentTrial], 'YData', [switchParameterCriterion switchParameterCriterion]);
% % %             set(BpodSystem.ProtocolFigures.auROC.ax2, 'YLim', [0 1]);
            
            %% block transition lines
% % %             blockTransitions = find(diff(BpodSystem.Data.BlockNumber));
% % %             if any(blockTransitions)
% % %                 btx = repmat([startX; startX + S.nidaq.duration], 1, length(blockTransitions));
% % %                 btx2 = repmat([-S.nidaq.duration; S.nidaq.duration], 1, length(blockTransitions));
% % %                 bty = [blockTransitions; blockTransitions;];
% % %             end
% % %             %% update photometry rasters
% % %             try % in case photometry hicupped
% % %                 if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode    
% % %                     % Note that switchParameterCriterion not used for
% % %                     % LNL_pRasters_byOdor, but doesn't matter when
% % %                     % supplied via varargin
% % %                     prfh('Update', 'switchParameterCriterion', switchParameterCriterion, 'XLim', [-S.nidaq.duration, S.nidaq.duration]);
% % %                     if any(blockTransitions) % block transition lines
% % %                         if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch1)
% % %                             for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch1(2:end)
% % %                                 plot(btx2, bty, '-r', 'Parent', ah);
% % %                             end
% % %                         end
% % %                         if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch2)
% % %                             for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch2(2:end)
% % %                                 plot(btx2, bty, '-r', 'Parent', ah);
% % %                             end
% % %                         end
% % %                     end
% % %                 end
% % %             end
            
            %% lick rasters by odor   
%             bpLickRaster2(SessionData, filtArg, zeroField, figName, ax)
            bpLickRaster2({'OdorValveIndex', 1}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor1, 'session'); hold on;
            bpLickRaster2({'OdorValveIndex', 2}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor2, 'session'); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor
            bpLickRaster2({'OdorValveIndex', 3}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor3, 'session'); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor   
            bpLickRaster2({'OdorValveIndex', 4}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor4, 'session'); hold on;
% % %             if any(blockTransitions)
% % %                 plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxOdor1);
% % %                 plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxOdor2); % just make 
% % %                 drawnow;
% % %             end             
            set([BpodSystem.ProtocolFigures.lickRaster.AxOdor1 BpodSystem.ProtocolFigures.lickRaster.AxOdor2 BpodSystem.ProtocolFigures.lickRaster.AxOdor3 BpodSystem.ProtocolFigures.lickRaster.AxOdor4], 'XLim', [startX, startX + S.nidaq.duration]);
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor1, 'Time from cue (s)');
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor2, 'Time from cue (s)');
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor3, 'Time from cue (s)');
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor4, 'Time from cue (s)');
            
            
            
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
% % %             if ~BpodSystem.EmulatorMode
% % %                 fclose(valveSlave);
% % %                 delete(valveSlave);
% % %             end
            return
        end 
    end
            