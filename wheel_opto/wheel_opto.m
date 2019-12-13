function wheel_opto
 % replaces reward with a trigger for pulse pal
    global BpodSystem
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
    defaults = {...
        'GUI.Epoch', 1;...
        'GUI.Baseline', 2;...
        'GUI.AcqLength', 30;...
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 1.5;...
        'GUI.ch1', 1;...
        'GUIMeta.ch1.Style', 'checkbox';...    
        'GUI.ch2', 1;...
        'GUIMeta.ch2.Style', 'checkbox';...  
        'GUI.alternateLEDs', 0;... % alternate which LEDs are turned on (both on, 1 on, 2 on, both on, etc.);
        'GUIMeta.alternateLEDs.Style', 'checkbox';...
        'GUI.LED1_f', 531;...
        'GUI.LED2_f', 211;...  
        'GUI.alternateReward', 0;...
        'GUIMeta.alternateReward.Style', 'checkbox';...
        'GUI.alternateMod', 0;... % alternate using and not using frequency modulation of the LEDs
        'GUIMeta.alternateMod.Style', 'checkbox';... 
        'GUI.Reward', 8;...        
        'GUI.mu_IRI', 30;... % mean inter-reward interval
        'GUI.min_IRI', 2;...
        'GUI.max_IRI', 90;...
        'GUI.PhotometryOn', 1;....
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
    S.LaserTime = 0.05; % just 50ms to trigger pulse pal now
    
    %% Initialize NIDAQ
    S.nidaq.duration = S.GUI.AcqLength;
    S.nidaq.IsContinuous = false;
    S.nidaq.updateInterval = 0.1; % save new data every n seconds
    
    
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
        neutralTone = neutralTone / 100;
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, neutralTone);
        BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
    end
    
     try
         load('wheel_opto_pulse.mat');
         ProgramPulsePal(wheel_opto_pulse);        
     catch
         PulsePal;
         load('wheel_opto_pulse.mat');
         ProgramPulsePal(wheel_opto_pulse);                 
     end  
    
    
    
    % determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    if ~BpodSystem.EmulatorMode        
    % retrieve machine specific point grey camera settings
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        pgSettings = machineSpecific_pointGrey;    
        switch pgSettings.triggerType
            case 'WireState'
                npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
            case 'BNCState'
                npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
        end       
    end
    
    %% alternate LED mode
    if S.GUI.alternateLEDs
        if ~all([S.GUI.ch1 S.GUI.ch2])
            error('Both acquisition channels must be turned on for alternate LED mode');
        end
        % store initial LED settings
        storedLED1_amp = S.GUI.LED1_amp;
        storedLED2_amp = S.GUI.LED2_amp;
    end
    
    %% alternate LED modulation mode
    if S.GUI.alternateMod
        % store initial LED settings
        storedLED1_f = S.GUI.LED1_f;
        storedLED2_f = S.GUI.LED2_f;
    end    
    
    %% initialize trial types and outcomes
    MaxTrials = 1000;
    
    %% Main trial loop
    nextReward = 0; % first reward delivered immediately after baseline in first trial
    totalReward = 0;
    for currentTrial = 1:MaxTrials 
% %       for currentTrial = 1:22
    nRewardThisTrial = 0;
        if S.GUI.alternateLEDs
            LEDmode = rem(currentTrial, 3);
            switch LEDmode
                case 1
                    S.GUI.LED1_amp = storedLED1_amp;
                    S.GUI.LED2_amp = storedLED2_amp;
                case 2
                    S.GUI.LED1_amp = storedLED1_amp;
                    S.GUI.LED2_amp = 0;
                case 0
                    S.GUI.LED1_amp = 0;
                    S.GUI.LED2_amp = storedLED2_amp;
            end
% %             if ~rem(currentTrial, 2)
% %                 hackFactor = currentTrial - 1;
% %             else
% %                 hackFactor = currentTrial;
% %             end
% % 
% %             if ismember(currentTrial, 21:22)
% %                 hackFactor = 0;
% %             end
% %             S.GUI.LED1_amp = hackFactor/20 * storedLED1_amp;
% %             S.GUI.LED2_amp = hackFactor/20 * storedLED2_amp;
        end
        
        if S.GUI.alternateMod
            if rem(currentTrial, 2)
                S.GUI.LED1_f = storedLED1_f;
                S.GUI.LED2_f = storedLED2_f;
            else
                S.GUI.LED1_f = 0;
                S.GUI.LED2_f = 0;         
            end
        end
            
        disp([' *** Trial # ' num2str(currentTrial)]); 
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
%         SaveBpodProtocolSettings; % don't want to save with alternateLED
%         mode
        
        rewardTimes = max(0, nextReward - S.GUI.Baseline); % delay reward if necessary so it doesn't occur during baseline period
%         if S.GUI.Reward % only if you are giving some reward at all (i.e. reward amount not set to 0)
            %% Deliver rewards with approximately flat hazard rate, ITI determined by reward timing        
            while 1
                thisTime = Inf;
                while (thisTime > S.GUI.max_IRI) || (thisTime < S.GUI.min_IRI)   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                    thisTime = exprnd(S.GUI.mu_IRI);
                end
                if S.GUI.Baseline + sum(rewardTimes) + S.RewardValveTime * (length(rewardTimes) - 1) >= S.GUI.AcqLength
                    break
                end
                rewardTimes(end + 1) = thisTime; %really you are collecting durations of inter reward intervals, refer to state matrix construction block
            end
        nextReward = S.GUI.Baseline + sum(rewardTimes) + S.RewardValveTime * (length(rewardTimes) - 1) - S.GUI.AcqLength;            
%         end

        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        
        %% state matrix construction                
        sma = NewStateMatrix(); 
        sma = SetGlobalTimer(sma,1,S.GUI.AcqLength + 0.025); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0.025,...
            'StateChangeConditions', {'Tup', 'Baseline'},...
            'OutputActions', {'BNCState', npgBNCArg, 'WireState', npgWireArg, 'GlobalTimerTrig', 1});
        sma = AddState(sma, 'Name','Baseline',...
            'Timer',S.GUI.Baseline,...
            'StateChangeConditions',{'Tup','IRI1'},...
            'OutputActions',{});        
        % for loop skipped if no reward occurs this trial

        for counter = linspace(1,length(rewardTimes) - 1, length(rewardTimes) - 1) 
            if S.GUI.alternateReward
               if rand < 0.5
                   useReward = true;
               else
                   useReward = false;
               end
            else
                useReward = false;
            end
            if useReward
                nextState = ['Reward' num2str(counter)];
            else
                nextState = ['Laser' num2str(counter)];
            end
            sma = AddState(sma,'Name', ['IRI' num2str(counter)], ...
                'Timer', rewardTimes(counter),...
                'StateChangeConditions', {'Tup', nextState},...
                'OutputActions', {});

            if ~useReward
                nRewardThisTrial = nRewardThisTrial + 1;
                sma = AddState(sma,'Name', ['Laser' num2str(counter)], ... 
                    'Timer', S.LaserTime,... %
                    'StateChangeConditions', {'Tup', ['IRI' num2str(counter + 1)]},...
                    'OutputActions', {'WireState',  bitset(0, 3)});        % removed neutral tone 12/12/19 , 'SoftCode', 1      
            else
                sma = AddState(sma,'Name', ['Reward' num2str(counter)], ... 
                    'Timer', S.RewardValveTime,... %
                    'StateChangeConditions', {'Tup', ['IRI' num2str(counter + 1)]},...
                    'OutputActions', {'ValveState', S.GUI.RewardValveCode});    % removed neutral tone 12/12/19 , 'SoftCode', 1          
            end
        end
        sma = AddState(sma,'Name', ['IRI' num2str(length(rewardTimes))], ... % use global timer
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer1_End','exit'},...
            'OutputActions', {});
        
        %%
        SendStateMatrix(sma);

        %% prep data acquisition
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
            preparePhotometryAcq(S);
        end
        %% Run state matrix
        tic;
        RawEvents = RunStateMatrix();  % Blocking!
        toc
        disp('*** trial ended ***');
        rewardThisTrial = nRewardThisTrial * S.GUI.Reward;
        totalReward = totalReward + rewardThisTrial;
        %% Stop Photometry session
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
            stopPhotometryAcq;   
        end
        global nidaq
        nidaq.LED1_amp
        nidaq.LED2_amp
        
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
%             BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
%             TotalRewardDisplay('add', rewardThisTrial);        
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
%             if totalReward >= S.GUI.maxReward
%                 RunProtocol('Stop');
%             end
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            stopPhotometryAcq;   
            return
        end
        
    end