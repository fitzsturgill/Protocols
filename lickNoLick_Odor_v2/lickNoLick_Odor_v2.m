function lickNoLick_Odor_v2

    global BpodSystem
    
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    defaults = {...
        'GUI.Epoch', 1;...
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 0;...
        'GUI.ITI', 0;... % reserved for future use
        'GUI.mu_iti', 6;... % if > 0, determines random ITI
        'GUI.NoLick', 0;... % mouse must stop licking for this period to advance to the next trial
        'GUI.AnswerDelay', 1;... % post-odor, time until answer period, may be updated trial-by-trial
        'AnswerMaxDelay', 1;... % maximum delay to answer, defines NIDAQ acquisition duration
        % set outcomeDelay = answer for fixed timing (as in pavlovian
        % conditioning)
        'GUI.outcomeDelay', 1;... % response (lick) to reinforcement delay
        'GUI.Answer', 1;... % answer period duration
        'GUI.PunishValveTime', 0.2;... %s        
        'GUI.Reward', 8;...
        'GUI.PhotometryOn', 1;...
        
        'GUI.BlockFcn', 'pavlovian_reversals_blocks';...
        'GUIMeta.BlockFcn.Style', 'editText'
        'GUI.Block', 1;...
        'GUI.Odor1Valve', 5;...
        'GUI.Odor2Valve', 6;...
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
    
    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.OdorTime + S.AnswerMaxDelay + S.GUI.Answer + S.PostUsRecording;
    startX = 0 - S.PreCsRecording; % 0 defined as time from cue (because reward time can be variable depending upon outcomedelay)
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry(S);
    end
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        updatePhotometryPlot('init');
        xlabel('Time from cue (s)');
        lickNoLick_Odor_PhotometryRasters('init', 'baselinePeriod', [1 S.PreCsRecording])
    end
    %% lick rasters for cs1 and cs2
    BpodSystem.ProtocolFigures.lickRaster.fig = ensureFigure('lick_raster', 1);        
    BpodSystem.ProtocolFigures.lickRaster.AxOdor1 = subplot(1, 2, 1);
    BpodSystem.ProtocolFigures.lickRaster.AxOdor2 = subplot(1, 2, 2);
    %% Initialize Sound Stimuli
    if ~BpodSystem.EmulatorMode
        SF = 192000;

        % linear ramp of sound for 10ms at onset and offset
        neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
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



    Outcomes = []; % NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 
    ReinforcementOutcome = []; % local version of BposSystem.Data.ReinforcementOutcome
    
    BpodSystem.Data.TrialTypes = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.TrialOutcome = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.CSValence = []; % 1 = CS+, 0 = CS-
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. Reward, Punish, WNoise, or Neutral
    BpodSystem.Data.LickAction = []; % 'lick' or 'noLick' 
    BpodSystem.Data.OdorValve = []; % e.g. 1st odor = V5, or V6
    BpodSystem.Data.OdorValveIndex = []; % 1st odor, 2nd odor
    BpodSystem.Data.Epoch = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.BlockNumber = [];
    BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
    BpodSystem.Data.SwitchParameterCriterion = [];
    
    lickOutcome = '';
    noLickOutcome = '';
    lickAction = '';
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table);
        switch S.Block.Table.CS(TrialType)
            case 0
                OdorValve = 0; % ommission
            case 1
                OdorValve = S.GUI.Odor1Valve;
            case 2
                OdorValve = S.GUI.Odor2Valve;
            case 3
                OdorValve = S.GUI.Odor3Valve;
        end
        
        lickOutcome = S.Block.Table.US{TrialType};
        if ~S.Block.Table.Instrumental(TrialType)
            noLickOutcome = S.Block.Table.US{TrialType};
        else
            noLickOutcome = 'Neutral';
        end
        
        %% update odor valve number for current trial
        if ~BpodSystem.EmulatorMode
            slaveResponse = updateValveSlave(valveSlave, OdorValve); 
            S.currentValve = slaveResponse;
            if isempty(slaveResponse);
                disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
                continue
            else
                disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
            end
        end
        disp(['*** Trial Type = ' num2str(TrialType) ' Block = ' num2str(S.GUI.Block) ' ***']);
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
            'OutputActions', {'WireState', bitset(0, 2)}); % Sound on
        sma = AddState(sma,'Name', 'RestartNoLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick'},...
            'OutputActions', {}); % Sound on, to do
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'BNCState', npgBNCArg, 'WireState', npgWireArg}); % trigger photometry acq global timer, nidaq trigger, point grey camera
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','Cue'},...
            'OutputActions',{});
        sma = AddState(sma, 'Name', 'Cue', ... 
            'Timer', S.OdorTime,...
            'StateChangeConditions', {'Tup','AnswerDelay'},...
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
            'Timer', S.GUI.outcomeDelay,...
            'StateChangeConditions', {'Tup', lickOutcome, 'GlobalTimer1_End', lickOutcome},... % whichever comes first
            'OutputActions', {});             
        sma = AddState(sma, 'Name', 'NoLickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', noLickOutcome},...
            'OutputActions', {});      
        sma = AddState(sma, 'Name', 'LickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', lickOutcome},...
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
            'OutputActions', {'SoftCode', 1});
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',0,...  
            'StateChangeConditions',{'GlobalTimer2_End','exit'},...
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
                processPhotometryAcq(currentTrial);
            %% online plotting
                processPhotometryOnline(currentTrial);
                updatePhotometryPlot('update', startX);         
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)        
            
            %TrialOutcome -> NaN: future trial or omission, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot)
            if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.AnswerLick(1))
                lickAction = 'lick';
                ReinforcementOutcome = lickOutcome;               
                if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
                    TrialOutcome = 1; % hit
                elseif S.Block.Table.CSValence(TrialType) == -1
                    TrialOutcome = 0; % false alarm
                else
                    TrialOutcome = NaN; % uncued
                end
            else
                lickAction = 'nolick';
                ReinforcementOutcome = noLickOutcome;
                if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
                    TrialOutcome = -1; % miss
                elseif S.Block.Table.CSValence(TrialType) == -1
                    TrialOutcome = 2; % correct rejection
                else
                    TrialOutcome = NaN; % uncued
                end                
            end

            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.OdorValve(end + 1) =  OdorValve;
            BpodSystem.Data.OdorValveIndex(end + 1) = S.Block.Table.CS(TrialType);
            BpodSystem.Data.CSValence(end + 1) = S.Block.Table.CSValence(TrialType);% 1 = CS+, 0 = CS-
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            BpodSystem.Data.ReinforcementOutcome{end + 1} = ReinforcementOutcome; % i.e. 1: reward, 2: neutral, 3: punish
            BpodSystem.Data.BlockNumber(end + 1) = S.GUI.Block;
            BpodSystem.Data.LickAction{end + 1} = lickAction;
            
            if strcmpi(ReinforcementOutcome, 'reward')
                TotalRewardDisplay('add', S.GUI.Reward);
            end
            
            %% adaptive block transitions
            if S.Block.LinkTo
                switchFcn = str2func(S.Block.LinkToFcn);
                [S.GUI.Block, switchParameter, switchParameterCriterion] = switchFcn(BpodSystem.Data.TrialOutcome, BpodSystem.Data.BlockNumber, S);
                S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            else
                switchParameter = NaN;
                switchParameterCriterion = NaN;
            end
            BpodSystem.Data.SwitchParameter(end + 1) = switchParameter;
            BpodSystem.Data.SwitchParameterCriterion = switchParameterCriterion;
            
            %% block transition lines
            blockTransitions = find(diff(BpodSystem.Data.BlockNumber));
            if any(blockTransitions)
                btx = repmat([startX, startX + S.nidaq.duration], length(blockTransitions), 1);
                btx2 = repmat([-S.nidaq.duration, S.nidaq.duration], length(blockTransitions), 1);
                bty = [blockTransitions', blockTransitions'];
            end
            %% update photometry rasters
            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode    
                lickNoLick_Odor_PhotometryRasters('Update', 'switchParameterCriterion', switchParameterCriterion, 'XLim', [-S.nidaq.duration, S.nidaq.duration]);
                if any(blockTransitions) % block transition lines
                    if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch1)
                        for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch1(2:end)
                            plot(btx2, bty, '-r', 'Parent', ah);
                        end
                    end
                    if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch2)
                        for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch2(2:end)
                            plot(btx2, bty, '-r', 'Parent', ah);
                        end
                    end
                end
            end
            
            %% lick rasters by odor   
%             bpLickRaster2(SessionData, filtArg, zeroField, figName, ax)
            bpLickRaster2({'OdorValveIndex', 1}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor1); hold on;
            bpLickRaster2({'OdorValveIndex', 2}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor2); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor
            if any(blockTransitions)
                plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxOdor1);
                plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxOdor2); % just make 
                drawnow;
            end             
            set([BpodSystem.ProtocolFigures.lickRaster.AxOdor1 BpodSystem.ProtocolFigures.lickRaster.AxOdor2], 'XLim', [startX, startX + S.nidaq.duration]);
            xlabel([BpodSystem.ProtocolFigures.lickRaster.AxOdor1 BpodSystem.ProtocolFigures.lickRaster.AxOdor2], 'Time from cue (s)');
            
            
            
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
            