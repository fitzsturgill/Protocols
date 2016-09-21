function lickNoLick_Odor
% instrumental odor discrimination task with positive and negative
% reinforcement outcomes
% Photometry support

    global BpodSystem nidaq
    
    
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
        S.GUI.Epoch
        S.OdorTime = 1;
        S.PreCsRecording = 4;
        S.PostOutcomeRecording = 3;
        S.currentValve = []; % holds odor valve # for current trial
        S.RewardValveTime =  GetValveTimes(S.GUI.Reward, S.RewardValveCode);
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
        TrialTypesSimple = randi(2, 1, MaxTrials); % 1 = CS+, 2 = CS-
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


    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        TrialType = TrialTypes(currentTrial);
        
        % choose odor
        if ismember(TrialType, [1 3])
            OdorValve = S.GUI.Odor1Valve;
        else
            OdorValve = S.GUI.Odor1Valve;
        end
        
        %% determine odor cues and outcomes for current trial
        switch TrialType
            case 1
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';
            case 2
                OdorValve = S.GUI.Odor2Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';
            case 1
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';
            case 1
                OdorValve = S.GUI.Odor1Valve;
                lickOutcome = 'Reward';
                noLickOutcome = 'Neutral';                

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
            'StateChangeConditions', {'Tup', 'Answer'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'Outcome',... % dummy state for alignment, globalcounter determine3s next state
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 
        sma = AddState(sma,'Name', 'Us', ...
            'Timer',UsTime,... % time will be 0 for omission
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', UsAction);
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',S.PostUsRecording,...  
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{});        
        
        
       %% adaptive code or function to determine if a reversal is necessary 
%        if necessary, increment epoch and toggle isReversal for future
%        trials
    end
        
        
        
