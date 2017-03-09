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
        'GUI.outcomeDelay', 0;... % response (lick) to reinforcement delay, may be updated trial-by-trial
        'GUI.Answer', 1;... % answer period duration
        'GUI.PunishValveTime', 0.2;... %s        
        'GUI.Reward', 8;...
        
        %% variables to be incoporated in or connected to block tables:
        % do I need all these (except for block?)
        'GUI.Block', 1;...
        'GUI.Pavlovian', 1;... % pavlovian option for training
        'GUI.Odor1Valve', 5;...
        'GUI.Odor2Valve', 6;...
        'GUI.Hit_RewardFraction', 0.7;...
        'GUI.FA_RewardFraction', 0.3;...
        'GUI.Hit_PunishFraction', 0;...
        'GUI.FA_PunishFraction', 0;...
        
        
        % parameters controling reversals
        'BlockFirstReverseCorrect', 30;...% % number of correct responses necessary prior to initial reversal
        'IsFirstReverse', 1;... % are we evaluating initial reversal? % this will be saved across sessions
        'BlockCountCorrect', 0;... % tally of correct responses prior to a reversal
        'BlockMinCorrect', 10;... 
        'BlockMeanAdditionalCorrect', 10;...
        'BlockMaxAdditionalCorrect', BlockMeanAdditionalCorrect * 2;...
        'BlockAdditionalCorrect', [];... % determined adaptively
%         'GUI.Reverse', 0;... % determined adaptively, do I need this?


        'OdorTime', 1;...
        'PreCsRecording', 4;...
        'PostUsRecording', 4;...
        'currentValve', [];... % holds odor valve # for current trial
        'RewardValveCode', 1;...
        'PunishValveCode', 2;...
        'RewardValveTime', GetValveTimes(GUI.Reward, RewardValveCode);...
        };
    
    S = setBpodDefaultSettings(S, defaults);
    
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    

    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;

    %% Load Tables
    S.Tables = lickNoLick_Odor_v2_blocks;
% Block #1
%     P    CS       US       Instrumental
%     _    __    ________    ____________
% 
%     1    1     'reward'    0           
% 
% 
% Block #2
% 
%     P    CS       US       Instrumental
%     _    __    ________    ____________
% 
%     1    1     'reward'    1           
% 
% 
% Block #3
% 
%      P     CS       US       Instrumental
%     ___    __    ________    ____________
% 
%     0.5    1     'reward'    1           
%     0.5    2     'wnoise'    1           
% 
% 
% Block #4
% 
%      P     CS       US       Instrumental
%     ___    __    ________    ____________
% 
%     0.5    2     'reward'    0           
%     0.5    1     'wnoise'    1           
% 
% 
% Block #5
% 
%      P     CS       US       Instrumental
%     ___    __    ________    ____________
% 
%     0.5    2     'reward'    1           
%     0.5    1     'wnoise'    1           
% 
% 
% Block #6
% 
%      P     CS       US       Instrumental
%     ___    __    ________    ____________
% 
%     0.5    1     'reward'    0           
%     0.5    2     'wnoise'    1           
% 
% 
% Block #7
% 
%      P     CS       US       Instrumental
%     ___    __    ________    ____________
% 
%     0.5    1     'reward'    1           
%     0.5    2     'wnoise'    1               
    
    
    

    
    %% Initialize NIDAQ
    S.nidaq.duration = S.PreCsRecording + S.OdorTime + S.AnswerMaxDelay + S.GUI.Answer + S.PostUsRecording;
    startX = 0 - S.PreCsRecording - S.OdorTime - S.AnswerMaxDelay - S.GUI.Answer; % 0 defined as time from reinforcement
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
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        S.Block = S.Tables{S.GUI.Block};
        TrialType = defineRandomizedTrials(chooseHitOutcome, 1);
        

       %% Assemble state matrix
        sma = NewStateMatrix(); 
        sma = SetGlobalTimer(sma,1,S.GUI.Answer); % post cue   
        sma = SetGlobalTimer(sma,2,S.nidaq.duration); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {'GlobalTimerTrig', 2}); % trigger photometry acq global timer
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
        sma = AddState(sma,'Name', 'Reward', ...
            'Timer', S.RewardValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.RewardValveCode, 'SoftCode', 1});
        sma = AddState(sma,'Name', 'Punish', ...
            'Timer', S.GUI.PunishValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.PunishValveCode, 'SoftCode', 1});
        sma = AddState(sma,'Name', 'Neutral', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'SoftCode', 1});
        sma = AddState(sma, 'Name','PostUsRecording',...
            'Timer',0,...  
            'StateChangeConditions',{'GlobalTimer2_End','exit'},...
            'OutputActions',{});    