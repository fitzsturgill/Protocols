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
        S.GUI.ITI = 0; % reserved for future use
        S.GUI.mu_iti = 6; % if > 0, determines random ITI
        S.GUI.NoLick = 0; % mouse must stop licking for this period to advance to the next trial
        S.GUI.AnswerDelay = 1; % post-odor, time until answer period
        S.GUI.Answer = 1; % answer period duration
        S.GUI.PunishValveTime = 0.2; %s        
        S.GUI.Reward = 8;
        S.GUI.Pavlovian = 1; % pavlovian option for training

        S.GUI.Odor1Valve = 5;
        S.GUI.Odor2Valve = 6;
        S.GUI.Hit_RewardFraction = 0.7;
        S.GUI.FA_RewardFraction = 0.3;
        S.GUI.Hit_PunishFraction = 0;
        S.GUI.FA_PunishFraction = 0;
        % parameters controling reversals
        S.BlockFirstReverseCorrect = 30;% % number of correct responses necessary prior to initial reversal
        S.IsFirstReverse = 1; % are we evaluating initial reversal? % this will be saved across sessions
        S.BlockCountCorrect = 0; % tally of correct responses prior to a reversal
        S.BlockMinCorrect = 10; 
        S.BlockMeanAdditionalCorrect = 10;
        S.BlockMaxAdditionalCorrect = S.BlockMeanAdditionalCorrect * 2;
        S.BlockAdditionalCorrect = []; % determined adaptively
%         S.GUI.Reverse = 0; % determined adaptively, do I need this?


        S.OdorTime = 1;
        S.PreCsRecording = 4;
        S.PostUsRecording = 4;
        S.currentValve = []; % holds odor valve # for current trial
        S.RewardValveCode = 1;
        S.PunishValveCode = 2;
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);        
    end
        S.PostUsRecording = 4;
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    

    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;


    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.OdorTime + S.GUI.AnswerDelay + S.GUI.Answer + S.PostUsRecording;
    startX = 0 - S.PreCsRecording - S.OdorTime - S.GUI.AnswerDelay - S.GUI.Answer; % 0 defined as time from reinforcement
    S = initPhotometry(S);

    %% Initialize Sound Stimuli
    SF = 192000; 
    
    % linear ramp of sound for 10ms at onset and offset
    neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, neutralTone);
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
    
    %% Generate white noise (I want to make this brown noise eventually)
    if ~BpodSystem.EmulatorMode
        load('PulsePalParamFeedback.mat');
        ProgramPulsePal(PulsePalParamFeedback);        
        maxLineLevel = 1; % e.g. +/- 1V command signal to an amplified speaker
        nPulses = 1000;
        SendCustomWaveform(1, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %
        SendCustomWaveform(2, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %        
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

    TrialTypesSimple = randi(2, 1, MaxTrials); % 1 = Odor1, 2 = Odor2
    isReverse = zeros(1, MaxTrials); % 0 = no reverse, 1 = reversed contingencies
    TrialTypes = TrialTypesSimple; % 1=0dor1, CS+ 2=Odor2, CS-, 3=Odor1, CS-, 4=Odor2, CS+, this array (extended for plotting) will be updated dynamically
    Outcomes = NaN(1, MaxTrials); % NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 
    ReinforcementOutcome = []; % local version of BposSystem.Data.ReinforcementOutcome
    
    BpodSystem.Data.TrialTypes = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.TrialOutcome = [];% onlineFilterTrials dependent on this variable
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. reward, punish or neutral
    BpodSystem.Data.TrialTypesSimple = [];    
    BpodSystem.Data.OdorValve = [];
    BpodSystem.Data.Epoch = [];% onlineFilterTrials dependent on this variable
    BpodSystem.Data.isReverse = [];
    BpodSystem.Data.nCorrect = []; % computed for each trial, cumulative tally of correct responses within the reversal block to which the trial belongs
    
    lickOutcome = '';
    noLickOutcome = '';
    
%% Init nidaq trial data plot: UPDATE THIS TO USE PLUGINOBJECTS???
    scrsz = get(groot,'ScreenSize'); 
    
    BpodSystem.ProtocolFigures.NIDAQFig       = figure(...
        'Position', [25 scrsz(4)*2/3-100 scrsz(3)/2-50  scrsz(4)/3],'Name','NIDAQ plot','numbertitle','off');
    BpodSystem.ProtocolFigures.NIDAQPanel1     = subplot(2,1,1);
    BpodSystem.ProtocolFigures.NIDAQPanel2     = subplot(2,1,2); 
    
%% Outcome Plot
    trialsToShow = 50;
    BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
    BpodSystem.GUIHandles.OutcomePlot = axes;
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', TrialTypes, 'ntrials', trialsToShow);
    
%%  Initialize photometry session analysis plots    
    BpodSystem.PluginObjects.Photometry.blF = []; %[nTrials, nDemodChannels]
    BpodSystem.PluginObjects.Photometry.baselinePeriod = [1 S.PreCsRecording];
    BpodSystem.PluginObjects.Photometry.trialDFF = {}; % 1 x nDemodChannels cell array, fill with nTrials x nSamples dFF matrix for now to make it easy to pull out raster data


    BpodSystem.ProtocolFigures.phRaster.TypesOutcomes = {1, [-1 1]; ... % type, outcomes associated with a split photometry raster plot
                                                        2, [0 2]; ...
                                                        3, [0 2]; ...
                                                        4, [-1 1]};

    
%% lick raster plots (by odor)
    BpodSystem.ProtocolFigures.lickRaster.fig = ensureFigure('lick_raster', 1);        
    BpodSystem.ProtocolFigures.lickRaster.AxOdor1 = subplot(1, 2, 1);
    BpodSystem.ProtocolFigures.lickRaster.AxOdor2 = subplot(1, 2, 2);


%% Define the axes matrix positions on the figure
  
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
        BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch1 = line('XData', NaN, 'YData', NaN, 'Parent', hAx(1));
        BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch1 = line('XData', NaN, 'YData', NaN, 'Parent', hAx(1), 'Color', 'm');
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
        BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch2 = line('XData', NaN, 'YData', NaN, 'Parent', hAx(1));
        BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch2 = line('XData', NaN, 'YData', NaN, 'Parent', hAx(1), 'Color', 'm');        
    end    
    


    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        TrialType = TrialTypes(currentTrial);


        %% determine odor cues lick outcomes and reinforcement outcomes for current trial
        chooseHitOutcome = [...
            % high value odor (no punish)
            1, S.GUI.Hit_RewardFraction;... %  reward
            2, 1 - S.GUI.Hit_RewardFraction - S.GUI.Hit_PunishFraction;... % neutral
            3, S.GUI.Hit_PunishFraction;...  % punish
            ];
        HitOutcome = defineRandomizedTrials(chooseHitOutcome, 1);
        chooseFAOutcome = [...
            % high value odor (no punish)
            1, S.GUI.FA_RewardFraction;... %  reward
            2, 1 - S.GUI.FA_RewardFraction - S.GUI.FA_PunishFraction;... % neutral
            3, S.GUI.FA_PunishFraction;...  % punish
            ];        
        FAOutcome = defineRandomizedTrials(chooseFAOutcome, 1);        
        ReinforcementOutcomes = {'Reward', 'Neutral', 'Punish'};

        switch TrialType
            case 1
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = ReinforcementOutcomes{HitOutcome};          
                if S.GUI.Pavlovian
                    noLickOutcome = lickOutcome; % animal's response doesn't affect reinforcement outcome
                else                
                    noLickOutcome = 'Neutral';
                end
            case 2
                OdorValve = S.GUI.Odor2Valve;
                lickOutcome = ReinforcementOutcomes{FAOutcome};          
                if S.GUI.Pavlovian
                    noLickOutcome = lickOutcome; % animal's response doesn't affect reinforcement outcome
                else                
                    noLickOutcome = 'Neutral';
                end
            case 3
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = ReinforcementOutcomes{FAOutcome};          
                if S.GUI.Pavlovian
                    noLickOutcome = lickOutcome; % animal's response doesn't affect reinforcement outcome
                else                
                    noLickOutcome = 'Neutral';
                end                                               
            case 4
                OdorValve = S.GUI.Odor2Valve;
                lickOutcome = ReinforcementOutcomes{HitOutcome};          
                if S.GUI.Pavlovian
                    noLickOutcome = lickOutcome; % animal's response doesn't affect reinforcement outcome
                else                
                    noLickOutcome = 'Neutral';
                end                
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
        disp(['*** Trial Type = ' num2str(TrialType) ' ***']);
        
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
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer1_End', lickOutcome},...
            'OutputActions', {});             
        sma = AddState(sma, 'Name', 'NoLickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', noLickOutcome},...
            'OutputActions', {});      
        sma = AddState(sma, 'Name', 'LickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', lickOutcome},...
            'OutputActions', {});      
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
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            

            % determine outcome,   -1 = miss, 0 = f.a., 1 = hit, 2 = c.r.

            lickOutcomes = [1 0 0 1];
            noLickOutcomes = [-1 2 2 -1];
            if S.GUI.Pavlovian % kludge for Pavlovian- TrialOutcome doesn't matter but set here for phRasters
                if ismember(TrialType, [1 4]);
                    TrialOutcome = lickOutcomes(TrialType);
                    ReinforcementOutcome = strmatch(lickOutcome, ReinforcementOutcomes);
                else
                    TrialOutcome = noLickOutcomes(TrialType);
                    ReinforcementOutcome = strmatch(noLickOutcome, ReinforcementOutcomes);                                  
                end            
            else
                if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.AnswerLick(1))
                    TrialOutcome = lickOutcomes(TrialType);
                    ReinforcementOutcome = strmatch(lickOutcome, ReinforcementOutcomes);
                else
                    TrialOutcome = noLickOutcomes(TrialType);
                    ReinforcementOutcome = strmatch(noLickOutcome, ReinforcementOutcomes);                                  
                end
            end

            disp(['*** Trial Outcome = ' num2str(TrialOutcome) ' ***']);
            Outcomes(currentTrial) = TrialOutcome;
            if ReinforcementOutcome == 1
                TotalRewardDisplay('add', S.GUI.Reward);
            end

            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialTypesSimple(end + 1) = TrialTypesSimple(currentTrial);                
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.OdorValve(end + 1) =  OdorValve;
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            BpodSystem.Data.isReverse(end + 1) = isReverse(currentTrial);
            BpodSystem.Data.ReinforcementOutcome(end + 1) = ReinforcementOutcome; % i.e. 1: reward, 2: neutral, 3: punish
            
            % lick rasters by odor                
            bpLickRaster(BpodSystem.Data, [1 3], [], 'Cue', [], BpodSystem.ProtocolFigures.lickRaster.AxOdor1);
            bpLickRaster(BpodSystem.Data, [2 4], [], 'Cue', [], BpodSystem.ProtocolFigures.lickRaster.AxOdor2);            
            set([BpodSystem.ProtocolFigures.lickRaster.AxOdor1 BpodSystem.ProtocolFigures.lickRaster.AxOdor2], 'XLim', [startX, startX + S.nidaq.duration]);            

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
            

            lastReverse = find(diff(BpodSystem.Data.Epoch), 1, 'last');
            if isempty(lastReverse)
                lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
            else
                lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
            end
            if ~S.GUI.Pavlovian && lastReverse == 1;
                nCorrectNeeded = S.BlockFirstReverseCorrect; % assert fixed number of correct responses for first reversal
            elseif S.GUI.Pavlovian
                nCorrectNeeded = 0;
            end
            nCorrect = length(find(BpodSystem.Data.TrialOutcome(lastReverse:end) == 1)); % count hits only
            if ~S.GUI.Pavlovian && nCorrect == nCorrectNeeded % reverse next trial
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
            elseif S.GUI.Pavlovian
                nCorrect = 0; % irrelevent for Pavlovian
%                 % correct computed for hit trials across last 20 trials
%                 % in kludgy fashion nCorrect means fraction correct when punish = off currently
%                 nCorrect = length(find(BpodSystem.Data.TrialOutcome(max(end - 20, 1):end) == 1))...
%                     / length(find(ismember(BpodSystem.Data.TrialTypes(max(end - 20, 1):end), [1 4]))); 
            end                

            BpodSystem.Data.nCorrect(end + 1) = nCorrect;
            %% update photometry raster plots, see subfunction
            updatePhotometryRasters(nCorrectNeeded);
            % update outcome plot to reflect upcoming trial
            TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial + 1, TrialTypes, Outcomes);

        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            fclose(valveSlave);
            delete(valveSlave);
            return
        end 

    end
end

function updatePhotometryRasters(nCorrectNeeded)
    global BpodSystem nidaq
    
    
    %% update photometry rasters
    displaySampleRate = nidaq.sample_rate / nidaq.online.decimationFactor;
    x1 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(1), displaySampleRate, 0);
    x2 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(2), displaySampleRate, 0);        
    TypesOutcomes = BpodSystem.ProtocolFigures.phRaster.TypesOutcomes;
%             lookupFactor = S.GUI.phRasterScaling;
    lookupFactor = 4;
    phRStamp = 6; % # pixels to push high or low to indicate alternative reinforcement outcomes
    for i = 1:size(TypesOutcomes, 1)
        if BpodSystem.Data.Settings.GUI.LED1_amp > 0
            channelData = BpodSystem.PluginObjects.Photometry.trialDFF{1};
            nTrials = size(channelData, 1);
            nSamples = size(channelData, 2);
            set(BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch1, 'YData', 1:nTrials, 'XData', BpodSystem.Data.nCorrect);
            set(BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch1, 'YData', 1:nTrials, 'XData', repmat(nCorrectNeeded, 1, nTrials));            
            if nCorrectNeeded
                set(BpodSystem.ProtocolFigures.phRaster.ax_ch1(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.nCorrect(end) + 1, nCorrectNeeded + 1)]);
            else
                set(BpodSystem.ProtocolFigures.phRaster.ax_ch1(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.nCorrect(end)) + 0.1]);
            end
            phMean = mean(mean(channelData(:,x1:x2)));
            phStd = mean(std(channelData(:,x1:x2)));    
            ax = BpodSystem.ProtocolFigures.phRaster.ax_ch1(i + 1); % phRaster axes start at i + 1
            outcome_left = onlineFilterTrials(TypesOutcomes{i,1},TypesOutcomes{i,2}(1),[]);            
            outcome_right = onlineFilterTrials(TypesOutcomes{i,1},TypesOutcomes{i,2}(2),[]);
            rewardTrials = find(BpodSystem.Data.ReinforcementOutcome == 1);
            neutralTrials = find(BpodSystem.Data.ReinforcementOutcome == 2);
            punishTrials = find(BpodSystem.Data.ReinforcementOutcome == 3);
            CData = NaN(nTrials, nSamples * 2); % double width for split, mirrored, dual outcome raster
            CData(outcome_left, (1:nSamples)) = fliplr(channelData(outcome_left, :));
            CData(outcome_right, (nSamples+1):end) = channelData(outcome_right, :);
            % add color tags marking trial reinforcment outcome
            % high color = reward, 0 color = neutral, low color = punish
            CData(intersect(outcome_left, find(BpodSystem.Data.ReinforcementOutcome == 1)), (nSamples - phRStamp + 1):nSamples) = 255; % 255 is arbitrary large value that will max out color table
            CData(intersect(outcome_left, find(BpodSystem.Data.ReinforcementOutcome == 2)), (nSamples - phRStamp + 1):nSamples) = 0;            
            CData(intersect(outcome_left, find(BpodSystem.Data.ReinforcementOutcome == 3)), (nSamples - phRStamp + 1):nSamples) = -255;            
            CData(intersect(outcome_right, find(BpodSystem.Data.ReinforcementOutcome == 1)), (nSamples+1):(nSamples + phRStamp)) = 255; % 255 is arbitrary large value that will max out color table
            CData(intersect(outcome_right, find(BpodSystem.Data.ReinforcementOutcome == 2)), (nSamples+1):(nSamples + phRStamp)) = 0;            
            CData(intersect(outcome_right, find(BpodSystem.Data.ReinforcementOutcome == 3)), (nSamples+1):(nSamples + phRStamp)) = -255;            
            
            image('YData', [1 size(CData, 1)],...
                'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
            set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd],...
                'YTickLabel', {});
        end
        if BpodSystem.Data.Settings.GUI.LED2_amp > 0
            channelData = BpodSystem.PluginObjects.Photometry.trialDFF{2};
            nTrials = size(channelData, 1);
            nSamples = size(channelData, 2);
            set(BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch2, 'YData', 1:nTrials, 'XData', BpodSystem.Data.nCorrect);
            set(BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch2, 'YData', 1:nTrials, 'XData', repmat(nCorrectNeeded, 1, nTrials));    
            if nCorrectNeeded
                set(BpodSystem.ProtocolFigures.phRaster.ax_ch2(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.nCorrect(end) + 1, nCorrectNeeded + 1)]);
            else
                set(BpodSystem.ProtocolFigures.phRaster.ax_ch2(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.nCorrect(end)) + 0.1]);
            end            
            phMean = mean(mean(channelData(:,x1:x2)));
            phStd = mean(std(channelData(:,x1:x2)));    
            ax = BpodSystem.ProtocolFigures.phRaster.ax_ch2(i + 1); % phRaster axes start at i + 1
            outcome_left = onlineFilterTrials(TypesOutcomes{i,1},TypesOutcomes{i,2}(1),[]);
            outcome_right = onlineFilterTrials(TypesOutcomes{i,1},TypesOutcomes{i,2}(2),[]);                 
            CData = NaN(nTrials, nSamples * 2); % double width for split, mirrored, dual outcome raster
            CData(outcome_left, (1:nSamples)) = fliplr(channelData(outcome_left, :));
            CData(outcome_right, (nSamples+1):end) = channelData(outcome_right, :);            
            image('YData', [1 size(CData, 1)],...
                'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
            set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd],...
                'YTickLabel', {});
        end        
    end
end

        
        
        
