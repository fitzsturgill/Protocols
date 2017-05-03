function wheel_v1

    global BpodSystem
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    defaults = {...
        'GUI.Epoch', 1;...
        'GUI.Baseline', 2;...
        'GUI.AcqLength', 30;...
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 0;...
        'GUI.mu_IRI', 15;... % mean inter-reward interval
        'GUI.min_IRI', 2;...
        'GUI.max_IRI', 45;...
        'GUI.Reward', 8;...
        'GUI.PhotometryOn', 1;...
        'GUI.PhotometryDutyCycle', 1;... % fraction of trials with photometry
        'GUI.RewardValveCode', 1;...
        'GUI.maxReward', 1000;...
        };
    
    S = setBpodDefaultSettings(S, defaults);
    
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    

    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;

    S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.GUI.RewardValveCode);
    
    %% Initialize NIDAQ
    S.nidaq.duration = S.GUI.AcqLength;
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry(S);
    end
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        updatePhotometryPlot('init');
        BpodSystem.PluginObjects.Photometry.baselinePeriod = [0 S.GUI.Baseline]; % kludge, need to move baseline def. out of lickNoLick_Photometry_rasters
    end
    %% Initialize Sound Stimuli    
    if ~BpodSystem.EmulatorMode
        SF = 192000;

        % linear ramp of sound for 10ms at onset and offset
        neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, neutralTone);
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
    end
    
    
    
    
    
    % determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    if ~BpodSystem.EmulatorMode        
    % retrieve machine specific point grey camera settings
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        pgSettings = machineSpecific_pointGrey;
        rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict         
        switch pgSettings.triggerType
            case 'WireState'
                npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
            case 'BNCState'
                npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
        end
    end
    
    %% initialize trial types and outcomes
    MaxTrials = 1000;
    
    %% Main trial loop
    nextReward = 0; % first reward delivered immediately after baseline in first trial
    totalReward = 0;
    for currentTrial = 1:MaxTrials         
        disp([' *** Trial # ' num2str(currentTrial)]); 
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        
        rewardTimes = max(0, nextReward - S.GUI.Baseline);
        %% Deliver rewards with approximately flat hazard rate, ITI determined by reward timing        
        while 1
            thisTime = Inf;
            while thisTime > S.GUI.max_IRI   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                thisTime = exprnd(S.GUI.mu_IRI);
            end
            if sum(rewardTimes) + S.RewardValveTime * (length(rewardTimes) - 1) >= S.GUI.AcqLength
                break
            end
            rewardTimes(end + 1) = thisTime; %really you are collecting durations of inter reward intervals, refer to state matrix construction block
        end
        if length(rewardTimes) > 1 % reward occurs this trial (i.e. you didn't hit break in outer 'while' loop above)
            nextReward = sum(rewardTimes) + S.RewardValveTime * (length(rewardTimes) - 1) - S.GUI.AcqLength;
        else % no reward this trial, deduct trial length
            nextReward = rewardTimes - S.GUI.AcqLength;
        end
        rewardThisTrial = (length(rewardTimes) - 1) * S.GUI.Reward;
        totalReward = totalReward + rewardThisTrial;
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        %% state matrix construction        
        sma = NewStateMatrix(); 
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0.025,...
            'StateChangeConditions', {'Tup', 'Baseline'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'BNCState', npgBNCArg, 'WireState', npgWireArg});
        sma = AddState(sma, 'Name','Baseline',...
            'Timer',S.GUI.Baseline,...
            'StateChangeConditions',{'Tup','IRI1'},...
            'OutputActions',{});        
        % for loop skipped if no reward occurs this trial
        for counter = linspace(1,length(rewardTimes) - 1, length(rewardTimes) - 1) 
            sma = AddState(sma,'Name', ['IRI' num2str(counter)], ...
                'Timer', rewardTimes(counter),...
                'StateChangeConditions', {'Tup', ['Reward' num2str(counter)]},...
                'OutputActions', {});
            sma = AddState(sma,'Name', ['Reward' num2str(counter)], ... 
                'Timer', S.RewardValveTime,... %
                'StateChangeConditions', {'Tup', ['IRI' num2str(counter + 1)]},...
                'OutputActions', {'ValveState', S.GUI.RewardValveCode, 'SoftCode', 1});            
        end
        sma = AddState(sma,'Name', ['IRI' num2str(length(rewardTimes))], ...
            'Timer', rewardTimes(end),...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', {});
        
        %%
        SendStateMatrix(sma);

        %% prep data acquisition
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
            preparePhotometryAcq(S);
        end
        %% Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
        tic;
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
                updatePhotometryPlot('update', 0);  
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            TotalRewardDisplay('add', rewardThisTrial);        
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            if totalReward >= S.GUI.maxReward
                RunProtocol('Stop');
            end
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end         
    end