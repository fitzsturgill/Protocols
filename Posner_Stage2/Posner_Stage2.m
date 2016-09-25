function Posner_Stage2

    global BpodSystem
    
    S = BpodSystem.ProtocolSettings;
    
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; %ul
    S.GUI.Punish = 6; % How long the mouse must wait in the goal port for reward to be delivered
    
    S.GUI.CueLightIntensity = 2.5; %Set Cue light intensity
    S.GUI.TargetLightIntensity = 255; %Set target light intensity
    
    S.GUI.BaselineIntensity=2.5;
    S.GUI.Foreperiod = 1;
    S.GUI.Trace = 1; % How long the mouse must poke in the center to activate the goal port
    S.GUI.Cue=1;
    
    S.GUI.RealITI = 2;
    S.GUI.windowIncrement = 3;
    
  

%     S.DrinkingGrace = 0.25; 
    S.TargetLightOn = 100;
    S.maxForeperiod = 100;
    S.maxTrace = 100;
    S.maxCue = 100;
    S.CenterPokeTime = 0.05; % WHAT VALUE TO USE HERE????????????
%     S.foreperiod = S.GUI.foreperiod;    
%     S.CueDelay = S.GUI.CueDelay;
%     S.LightOn = S.GUI.LightOn;    
end    

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%% Define trials-Trial types tranformed via iterative process  
%note during training, there is no distinction between invalid/valid trials
%because the "cue light" is a pre-emptive, bidirectional flash (i.e. dim
%flash appears on both the right and left side prior to the appearance of
%the target light)

MaxTrials = 1000;

%% generate randomized trial types
ra = rand(1,MaxTrials);
TrialTypes(ra < 0.5) = 1; %  50% of trials are type 1
TrialTypes(ra >= 0.5) = 2; % 50% of trials are type 2

    
BpodSystem.Data.TrialTypes= []; % The trial type of each trial completed will be added here


%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes);
BpodNotebook('init');



%% This code initializes the Total Reward Display plugin, 
TotalRewardDisplay('init');
RewardAmount = S.GUI.RewardAmount;

%%Generate white noise
SF = 192000; % Sound card sampling rate
PunishSound = (rand(1,SF*.5)*2) - 1;
PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 1, PunishSound);
% Set soft code handler to trigger sounds
BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
%% Main trial loop
for currentTrial = 1:MaxTrials
    %% Foreperiod, sync GUI to reflect updated values (see adjustment at end of each trial)
    S.GUI.foreperiod = S.foreperiod;    
    S.GUI.CueDelay = S.CueDelay;
    S.GUI.LightOn = S.LightOn;
    S = BpodParameterGUI('sync', S); % BpodParemeterGUI can sync in either direction (apparently from the documentation)
    
    R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
    
    %% Suelynn: generate exponentially distributed reward delay but bounded by min and max specified values    
    RewardDelayMin = 0;
    RewardDelayMean = 0.015; 
    RewardDelayMax = 0.1;
    S.RewardDelay = -1;
    while 1
        if RewardDelayMin <= S.RewardDelay <= RewardDelayMax;
            break
        else
            S.RewardDelay = exprnd(RewardDelayMean);
        end
    end

    %% 
    
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1 %cuetarget match left
            CueLight = {'PWM3', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 'PWM1', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity};
            TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            RewardState = 'LeftReward';
            DrinkingReward = 'Port1Out'; 
        case 2 %cuetarget match right
            CueLight = {'PWM1', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 'PWM3', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity}; 
            TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            RewardState= 'RightReward';
            DrinkingReward = 'Port3Out';
    end
   
    BaselineLight={'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity};
    
    
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetGlobalTimer(sma,1,S.GUI.Foreperiod); % pre cue  
    sma = SetGlobalTimer(sma,2,S.GUI.Foreperiod); % pre cue  
    
    sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'CenterPokeDetected'},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
        'Timer', S.CenterPokeTime,...
        'StateChangeConditions', {'Tup', 'WaitForCue', 'Port2Out', 'WaitForPoke'},...
        'OutputActions', BaselineLight);

    %% variable foreperiod betwen center poke and cue light

    sma = AddState(sma, 'Name', 'WaitForCue', ... %wait for the cue
        'Timer', S.Foreperiod,...
        'StateChangeConditions', {'Port2Out', 'GracePeriodCue', 'Tup','CueAndWait'},... %early response to cue light results in punishment 
        'OutputActions', BaselineLight);

    sma = AddState(sma, 'Name', 'GracePeriodCue', ... %wait for the cue
        'Timer', S.GUI.GracePeriod,...
        'StateChangeConditions', {'Port2In', 'WaitForCue', 'Tup','PunishWithdrawal'},... %early response to cue light results in punishment 
        'OutputActions', BaselineLight);
    sma = AddState(sma, 'Name', 'trigForeperiod', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'Foreperiod1'},...
        'OutputActions', {'GlobalTimerTrig', 1});
    sma = AddState(sma, 'Name', 'Foreperiod1',...
        'Timer', 0,...
        'StateChangeCondtions', {'GlobalTimer1_end', 'trigCue', 'Port2Out', 'Foreperiod2'},...
        'OutputActions', BaselineLight);
    % TRIG GLOBAL TIMER
    sma = AddState(sma, 'Name', 'Foreperiod2',...
        'Timer', 0,...
        'StateChangeConditions', {'GlobalTimer1_end', 'trigCue', 'GlobalTimer4_end', 'Punish', 'Port2In', 'Foreperiod3'},...
        'OutputActions', [{'GlobalTimerTrig', 4}, BaselineLight]);
    sma = AddState(sma, 'Name', 'Foreperiod3',...
        'Timer', 0,...
        'StateChangeConditions', {'GlobalTimer1_end', 'trigCue', 'GlobalTimer4_end', 'Punish', '
        'OutputActions', [{'GlobalTimerTrig', 4}, BaselineLight]);
    