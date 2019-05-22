function FrankenLNL_4odors
    % Protocol for pavlovian and odor conditioning
    % Written by Aubrey Siebels and Fitz Sturgill 2018
    global BpodSystem
    
    
    TotalRewardDisplay('init');
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    
    blockFunctionList = {'two_cue_states', 'punishBlocks', 'rewardPunishBlocks'};
    PhotometryRasterFcnList = {'FrankenLNL_4odors_pRasters'};
    defaults = {...
        'GUIPanels.Photometry', {'LED1_amp', 'LED2_amp', 'LED1_f', 'LED2_f', 'PhotometryOn'};...
        'GUI.LED1_amp', 2.5;...
        'GUI.LED2_amp', 4;...
        'GUI.LED1_f', 0;...
        'GUI.LED2_f', 0;...        
        'GUI.PhotometryOn', 1;...
        
        'GUIPanels.Aux', {'Aux'};...
        'GUI.Aux.channelsOn', [true; false; false; false];...
        'GUI.Aux.channelNumbers', [2; 3; 4; 5];...
        'GUI.Aux.downsample', [20; 20; 20; 20];...
        'GUIMeta.Aux.Style', 'table';...
        'GUIMeta.Aux.String', '';...
        
        'GUIPanels.Timing', {'ITI', 'mu_iti', 'Trace1Delay', 'Trace2Delay', 'Cue1Time', 'Cue2Time'};...
        'GUI.ITI', 0;... % reserved for future use
        'GUI.Trace1Delay',0; ...
        'GUI.Trace2Delay',0; ...
        'GUI.Cue1Time', 1; ...
        'GUI.Cue2Time', 1; ...             
        'GUI.mu_iti', 6;... % if > 0, determines random ITI
%         'GUI.NoLick', 0;... % mouse must stop licking for this period to advance to the next trial
%         'GUI.AnswerDelay', 0;... % post-odor, time until answer period, (in future may be updated trial-by-trial)
        % !!!! set OutcomeDelay = Answer for fixed timing (as in pavlovian
        % conditioning)!!!
%         'GUI.OutcomeDelay', 1;... % response (lick) to reinforcement delay, (in future may be updated trial-by-trial)
%         'GUI.Answer', 1;... % answer period duration

        'GUIPanels.Stimuli', {'PunishValveTime', 'Reward', 'UsePulsePal', 'Odor1Valve', 'Odor2Valve', 'Odor3Valve', 'Odor4Valve',...
        'neutralToneOn', 'outcomeToneOn', 'ShockTime'};...
        'GUI.PunishValveTime', 0.2;... %s    
        'GUI.Reward', 8;...
        'GUI.UsePulsePal', 0;...
        'GUI.Odor1Valve', 5;...
        'GUI.Odor2Valve', 6;...
        'GUI.Odor3Valve', 7;...
        'GUI.Odor4Valve', 8;...
        'GUI.neutralToneOn', 0;...
        'GUIMeta.neutralToneOn.Style', 'checkbox';...
        'GUI.outcomeToneOn', 0;...
        'GUIMeta.outcomeToneOn.Style', 'checkbox';...
        'GUI.ShockTime', 0.2;...
        'GUIPanels.Blocks', {'BlockFcn', 'PhotometryRasterFcn', 'Block'};...
        'GUI.BlockFcn', 'rewardPunishBlocks';...
        'GUIMeta.BlockFcn.Style', 'popupmenutext';...
        'GUIMeta.BlockFcn.String',  blockFunctionList;...
        'GUI.PhotometryRasterFcn', 'FrankenLNL_4odors_pRasters';...
        'GUIMeta.PhotometryRasterFcn.Style', 'popupmenutext';...
        'GUIMeta.PhotometryRasterFcn.String', PhotometryRasterFcnList;...
        'GUI.Block', 1;...
        
        'GUITabs.General', {'Photometry'};...
        
        'GUITabs.Timing', {'Timing'};...
        'GUITabs.Stimuli', {'Stimuli'};...
        'GUITabs.Blocks', {'Blocks'};...
        'GUITabs.Aux', {'Aux'};...
        'PreCsRecording', 4;... %AAS changed to 8 for 405/407 session 4/29/19
        'PostUsRecording', 4;... 
        'currentValve', [];... % holds odor valve # for current trial
        'RewardValveCode', 1;...
        'PunishValveCode', 2;...
        'RewardValveTime', [];...
        'ShockResistor', 10e3;... %10KOhm resistor
        'ShockUnits', 1e-6;...  % microAmperes
        };
    
    S = setBpodDefaultSettings(S, defaults);
     
    S.ShockResistor = 1e3; % kludge to overwrite shock resistor value from 5/4/19 and on to 1kOhm so that I don't exceed voltage limit on Nidaq board
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin    
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;


    %% Load Tables
    bfh = str2func(S.GUI.BlockFcn);
%     try
        S.Tables = bfh();
%     catch
%         error('** block function error ***');
%     end
    
    %% init photometry raster function handle
    prfh = str2func(S.GUI.PhotometryRasterFcn);
    
    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.GUI.Cue1Time + S.GUI.Trace1Delay + S.GUI.Cue2Time + S.GUI.Trace2Delay + S.PostUsRecording;
    startX = 0 - S.PreCsRecording; % 0 defined as time from cue (because reward time can be variable depending upon outcomedelay)
    S.nidaq.IsContinuous = false;
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry(S);
    end
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        updatePhotometryPlot('init');
        prfh('init', 'baselinePeriod', [1 S.PreCsRecording], 'odorsToPlot', [1 2 3 4 5 -1])
    end
    
    %% monitor shock current, assumes aux channel 2 is activated and downsampled to 20Hz
    if ~BpodSystem.EmulatorMode
        shockFig.h = ensureFigure('ShockCurrent', 1);
        shockFig.trialAxis = subplot(2,1,1); hold on; xlabel('time (s)'); ylabel('input voltage');
        shockFig.trialLine = scatter([],[],'MarkerFaceColor', 'flat'); colormap jet;
        shockFig.sessionAxis = subplot(2,1,2); xlabel('trial #'); ylabel('Ishock uAmps'); hold on;
        shockFig.sessionLine = scatter([],[],'MarkerFaceColor', 'flat'); colormap jet;
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
        attenuation = 20;

        % linear ramp of sound for 10ms at onset and offset
        neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01)/ attenuation; % 10ms taper
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, neutralTone);
           
        
        % white noise for punishment
        wn_duration = 1;
        wn_amplitude = 2;
        whiteNoise = (rand(1, wn_duration * SF) - 0.5) * wn_amplitude;
        PsychToolboxSoundServer('Load', 2, whiteNoise);


        % cue 1 and 2 tones, (same frequency)
        c1t = taperedSineWave(SF, 10000, S.GUI.Cue1Time, 0.01)/attenuation ; % 10ms taper 
        PsychToolboxSoundServer('Load', 3, c1t);
        c2t = taperedSineWave(SF, 10000, S.GUI.Cue2Time, 0.01)/attenuation ; % 10ms taper
        PsychToolboxSoundServer('Load', 4, c2t);   
        
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
    BpodSystem.Data.CSValence = []; % 1 = CS+, -1 = CS-, 0 = unCued or a 'control' odorant that doesn't affect outcomes or adaptive reversals
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. Reward, Punish, WNoise, or Neutral
    BpodSystem.Data.LickAction = []; % 'lick' or 'noLick' 
    BpodSystem.Data.Odor1Valve = []; % e.g. 1st odor = V5, or V6,
    BpodSystem.Data.Odor2Valve = []; % 
    BpodSystem.Data.Odor1ValveIndex = []; 
    BpodSystem.Data.Odor2ValveIndex = [];
    BpodSystem.Data.CS1_tone = []; 
    BpodSystem.Data.CS2_tone = [];   
    BpodSystem.Data.CS1_light = []; 
    BpodSystem.Data.CS2_light = [];       
    BpodSystem.Data.Epoch = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.BlockNumber = [];
    BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
    BpodSystem.Data.SwitchParameterCriterion = [];
    BpodSystem.Data.AnswerLicks = struct('count', [], 'rate', [], 'duration', []); % number of licks during answer period, nTrials x 1
    BpodSystem.Data.AnswerLicksROC = struct('auROC', [], 'pVal', [], 'CI', []); 
    BpodSystem.Data.ShockCurrent = [];

    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table); % trial type chosen on the fly based upon current Protocol Settings
% % %         TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',... % update outcome plot to show trial type of current trial with outcome undefined (NaN)
% % %             currentTrial, [BpodSystem.Data.TrialTypes TrialType], [BpodSystem.Data.TrialOutcome NaN]);            
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);

        TinyPuffCode1 = 0;
        switch S.Block.Table.CS1(TrialType)
            case 0
                Odor1Valve = 0; % uncued
            case 1
                Odor1Valve = S.GUI.Odor1Valve;
            case 2
                Odor1Valve = S.GUI.Odor2Valve;
            case 3
                Odor1Valve = S.GUI.Odor3Valve;
            case 4
                Odor1Valve = S.GUI.Odor4Valve;
            case 5
                Odor1Valve = 13; %tinytone
            case -1
                Odor1Valve = 0;
                TinyPuffCode1 = 1;
            
                
        end
        
        TinyPuffCode2 = 0;
        switch S.Block.Table.CS2(TrialType)
            case 0
                Odor2Valve = 0; % uncued
            case 1
                Odor2Valve = S.GUI.Odor1Valve;
            case 2
                Odor2Valve = S.GUI.Odor2Valve;
            case 3
                Odor2Valve = S.GUI.Odor3Valve;
            case 4
                Odor2Valve = S.GUI.Odor4Valve;
            case 5
                Odor2Valve = 0; %tinytone
            case -1
                Odor2Valve = 0;
                TinyPuffCode2 = 1;
        end
        

        if ismember('CS1_tone', S.Block.Table.Properties.VariableNames) && S.Block.Table.CS1_tone(TrialType);
            CS1_tone = true;
        else
            CS1_tone = false;
        end
        
        if ismember('CS2_tone', S.Block.Table.Properties.VariableNames) && S.Block.Table.CS2_tone(TrialType);
            CS2_tone = true;
        else
            CS2_tone = false;
        end
        
        if ismember('CS1_light', S.Block.Table.Properties.VariableNames) && S.Block.Table.CS1_light(TrialType)
            CS1_light = S.Block.Table.CS1_light(TrialType);
        else
            CS1_light = 0;
        end
        
        if ismember('CS2_light', S.Block.Table.Properties.VariableNames) && S.Block.Table.CS2_light(TrialType)
            CS2_light = S.Block.Table.CS2_light(TrialType);
        else
            CS2_light = 0;
        end
            
        
        Outcome = S.Block.Table.US{TrialType};
        
        if ismember('RewardSize', S.Block.Table.Properties.VariableNames) && strcmp(Outcome, 'Reward')
            S.GUI.Reward = S.Block.Table.RewardSize(TrialType);                       
        end
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);

        
        if S.GUI.neutralToneOn
            neutralCode = 1;
        else
            neutralCode = 0;
        end
        
        if S.GUI.outcomeToneOn
            outcomeToneCode = 1;
        else
            outcomeToneCode = 0;
        end
        
        
        
        
        %% update odor valve number for current trial
        if ~BpodSystem.EmulatorMode
            slaveResponse = updateValveSlave(valveSlave, [Odor1Valve Odor2Valve]); 
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
        sma = SetGlobalTimer(sma,1,S.nidaq.duration); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {}); 
        
        sma = AddState(sma,'Name', 'ITI', ...
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'StartRecording'},...
            'OutputActions', {}); 

        
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'GlobalTimerTrig', 1, 'BNCState', npgBNCArg, 'WireState', npgWireArg}); % trigger photometry acq global timer, nidaq trigger, point grey camera
       
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','Cue1'},...
            'OutputActions',{});
        
        sma = AddState(sma, 'Name', 'Cue1', ... 
            'Timer', S.GUI.Cue1Time,...
            'StateChangeConditions', {'Tup','Trace1'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg, 'ValveState', TinyPuffCode1 * S.PunishValveCode,...
            'SoftCode', 3 * CS1_tone, 'PWM1', CS1_light});
        
        sma = AddState(sma, 'Name','Trace1',...
            'Timer',S.GUI.Trace1Delay,...
            'StateChangeConditions',{'Tup','Cue2'},...
            'OutputActions',{});

        sma = AddState(sma, 'Name', 'Cue2', ... 
            'Timer', S.GUI.Cue2Time,...
            'StateChangeConditions', {'Tup','Trace2'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg, 'ValveState', TinyPuffCode2 * S.PunishValveCode,...
            'SoftCode', 4 * CS2_tone, 'PWM1', CS2_light});  
        
        sma = AddState(sma, 'Name','Trace2',...
            'Timer',S.GUI.Trace2Delay,...
            'StateChangeConditions',{'Tup','Outcome'},...
            'OutputActions',{});        
        
        sma = AddState(sma, 'Name', 'Outcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', Outcome},...
            'OutputActions', {});  
        
        sma = AddState(sma,'Name', 'Reward', ... % 4 possible outcome states: Reward (H2O + tone), Punish (air puff + tone), WNoise (white noise), Neutral (tone)
            'Timer', S.RewardValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.RewardValveCode, 'SoftCode', outcomeToneCode});
        
        sma = AddState(sma,'Name', 'Punish', ...
            'Timer', S.GUI.PunishValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.PunishValveCode, 'SoftCode', outcomeToneCode});
        
        sma = AddState(sma,'Name', 'Shock', ...
            'Timer', S.GUI.ShockTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'WireState', 2, 'SoftCode', outcomeToneCode});
        
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
            'StateChangeConditions',{'GlobalTimer1_End','exit', 'Tup', 'exit'},...
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
                    warning('*** Problem with saving, this should not happen ***');
                end
                try % in case photometry hicupped
                %% online plotting
                    processPhotometryOnline(currentTrial);
                    updatePhotometryPlot('update', startX);  
%                     xlabel('Time from cue (s)');
                catch
                    disp('*** Problem with online photometry processing ***');
                end
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)        
            

            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
% % %             BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.Odor1Valve(end + 1) =  Odor1Valve;
            BpodSystem.Data.Odor2Valve(end + 1) =  Odor2Valve;
            BpodSystem.Data.Odor1ValveIndex(end + 1) = S.Block.Table.CS1(TrialType);
            BpodSystem.Data.Odor2ValveIndex(end + 1) = S.Block.Table.CS2(TrialType);
            BpodSystem.Data.CS1_tone(end + 1) = CS1_tone;
            BpodSystem.Data.CS2_tone(end + 1) = CS2_tone;
            BpodSystem.Data.CS1_light(end + 1) = CS1_light;
            BpodSystem.Data.CS2_light(end + 1) = CS2_light;                     
            BpodSystem.Data.ReinforcementOutcome{end + 1} = Outcome; % i.e. 1: reward, 2: neutral, 3: punish
            BpodSystem.Data.BlockNumber(end + 1) = S.GUI.Block;


            %% update outcome plot to reflect upcoming trial
% % %             TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
% % %                 currentTrial, BpodSystem.Data.TrialTypes, BpodSystem.Data.TrialOutcome);            
            if strcmpi(Outcome, 'Reward')
                TotalRewardDisplay('add', S.GUI.Reward);
            end
            

            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode    
                % Note that switchParameterCriterion not used for
                % LNL_pRasters_byOdor, but doesn't matter when
                % supplied via varargin
                prfh('Update', 'odorsToPlot', [1 2 3 4 5 -1], 'XLim', [-S.nidaq.duration, S.nidaq.duration]);
            end

            
            %% lick rasters by odor and shock graph
%             bpLickRaster2(SessionData, filtArg, zeroField, figName, ax)
            if ~BpodSystem.EmulatorMode  
                bpLickRaster2({'Odor2ValveIndex', 1}, 'Cue2', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor1, 'session'); hold on;
                bpLickRaster2({'Odor2ValveIndex', 2}, 'Cue2', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor2, 'session'); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor
                bpLickRaster2({'Odor2ValveIndex', 3}, 'Cue2', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor3, 'session'); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor   
                bpLickRaster2({'Odor2ValveIndex', 4}, 'Cue2', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor4, 'session'); hold on;

                set([BpodSystem.ProtocolFigures.lickRaster.AxOdor1 BpodSystem.ProtocolFigures.lickRaster.AxOdor2 BpodSystem.ProtocolFigures.lickRaster.AxOdor3 BpodSystem.ProtocolFigures.lickRaster.AxOdor4], 'XLim', [startX, startX + S.nidaq.duration]);
                xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor1, 'Time from cue (s)');
                xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor2, 'Time from cue (s)');
                xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor3, 'Time from cue (s)');
                xlabel(BpodSystem.ProtocolFigures.lickRaster.AxOdor4, 'Time from cue (s)');
                
                shockWindow = BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Shock - BpodSystem.Data.RawEvents.Trial{currentTrial}.States.StartRecording(1);
                if all(isfinite(shockWindow))
                    shockWindowIx = [bpX2pnt(shockWindow(1),20,0) bpX2pnt(shockWindow(2),20,0)];
                    BpodSystem.Data.ShockCurrent(end + 1) = median(BpodSystem.Data.AuxData{currentTrial, 2}(shockWindowIx(1):shockWindowIx(2))) / S.ShockResistor /S.ShockUnits;
                    nPoints = numel(BpodSystem.Data.AuxData{currentTrial, 2});
                    shockXData = (0:nPoints-1) ./ 20;
                    shockYData = BpodSystem.Data.AuxData{currentTrial, 2};
                    shockCData = zeros(size(shockXData));
                    shockCData(shockWindowIx(1):shockWindowIx(2)) = 1;
                else
                    BpodSystem.Data.ShockCurrent(end + 1) = NaN;
                    shockXData = [];
                    shockYData = [];
                    shockCData = [];
                end
                set(shockFig.sessionLine, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.ShockCurrent);
                set(shockFig.trialLine, 'XData', shockXData, 'YData', shockYData, 'CData', shockCData, 'SizeData', 10);
            end
            
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
            