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
        'GUI.ITI', 0;... 
        'GUI.mu_IRI', 6;... % mean inter-reward interval
        'GUI.Reward', 8;...
        'GUI.PhotometryOn', 1;...
        'GUI.RewardValveCode', 1;...
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
    
    %% Initialize Sound Stimuli    
    if ~BpodSystem.EmulatorMode
        SF = 192000;

        % linear ramp of sound for 10ms at onset and offset
        neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, neutralTone);
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
    rewardTimes = 0; % first reward delivered immediately after baseline in first trial
    for currentTrial = 1:MaxTrials               
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        
        %% Deliver rewards with approximately flat hazard rate, ITI determined by reward timing        
        while sum(rewardTimes) + S.RewardValveTime * min(1, length(rewardTimes) - 1) < S.GUI.AcqLength
            thisTime = Inf;
            while thisTime > 3 * S.GUI.mu_IRI   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                thisTime = exprnd(S.GUI.mu_IRI);
            end
            rewardTimes(end + 1) = thisTime;
        end
        
        S.GUI.ITI = min(0, sum(rewardTimes) + S.RewardValveTime * rewardTimes(1:min(1, length(rewardTimes) - 1)) - S.GUI.AcqLength - S.GUI.Baseline);
        rewardTimes(end) = S.GUI.AcqLength - sum(rewardTimes(1:end-1) + S.RewardValveTime);
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        
        sma = NewStateMatrix(); 
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0.025,...
            'StateChangeConditions', {'Tup', 'IRI1'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'BNCState', npgBNCArg, 'WireState', npgWireArg});
        for counter = 1:length(rewardTimes) - 1
            sma = AddState(sma,'Name', ['IRI' num2str(counter)], ...
                'Timer', rewardTimes(counter),...
                'StateChangeConditions', {'Tup', ['Reward' num2str(counter)]},...
                'OutputActions', {});
            sma = AddState(sma,'Name', ['Reward' num2str(counter)], ... 
                'Timer', S.RewardValveTime,... %
                'StateChangeConditions', {'Tup', ['IRI' num2str(counter + 1)]},...
                'OutputActions', {'ValveState', S.RewardValveCode, 'SoftCode', 1});            
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
                updatePhotometryPlot('update', startX);  
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)                
            TotalRewardDisplay('add', S.GUI.Reward * (length(rewardTimes) - 1));        
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end         
    end