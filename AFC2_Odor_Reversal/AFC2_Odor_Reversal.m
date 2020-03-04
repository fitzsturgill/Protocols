function AFC2_Odor_Reversal

global BpodSystem


TotalRewardDisplay('init')
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
%     defaults = {...
%         'GUIPanels.Photometry', {'LED1_amp', 'LED2_amp', 'PhotometryOn', 'LED1_f', 'LED2_f'};...
%         'GUI.LED1_amp', 1.5;...
%         'GUI.LED2_amp', 0;...    

defaults = {...
    'GUI.LeftPort', 1;...  % have this be in rig-specific settings?
    'GUI.CenterPort', 2;... % have this be in rig-specific settings?
    'GUI.RightPort', 3;... % have this be in rig-specific settings?
    'GUI.GracePeriod', 0.05;...
    'GUI.ResponseWindow', 8;...
    'GUI.CenterPokeTime', 0.05;... % what value to use?
    'GUI.Cue', 1;...
    'GUI.CueGrace', 0.2;...
    'GUI.DrinkingGrace', 0.2;...
    'GUI.ITI', 2;... % do I need an ITI?
    'GUI.ResposeWindow', 8;...
    'GUI.DrinkingGrace', 0.2;...
    };
    

S = setBpodDefaultSettings(S, defaults);

%% Pause and wait for user to edit parameter GUI 
BpodParameterGUI('init', S);    
BpodSystem.Pause = 1;
HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin    
BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
SaveBpodProtocolSettings;    

LeftPortIn = sprintf('Port%uIn', S.GUI.LeftPort);
LeftPortOut = sprintf('Port%uOut', S.GUI.LeftPort);
CenterPortIn = sprintf('Port%uIn', S.GUI.CenterPort);
CenterPortOut = sprintf('Port%uOut', S.GUI.CenterPort);
RightPortIn = sprintf('Port%uIn', S.GUI.RightPort);
RightPortOut = sprintf('Port%uOut', S.GUI.RightPort);
CenterLight = sprintf('PWM%u', S.GUI.CenterPort);
LeftLight = sprintf('PWM%u', S.GUI.LeftPort);
RightLight = sprintf('PWM%u', S.GUI.RightPort);
CenterLightOn = {CenterLight, 255};
SideLightOn = {LeftLight, 255, RightLight, 255};

%% Initialize Stimuli
if ~BpodSystem.EmulatorMode    
    
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

%% Initialize Photometry
% place holder for now

%% Initialize data structures    
%{
I need: Choice (Left or right), Outcome  (Reward or Neutral), Reward
amount, what else
%}
BpodSystem.Data.TrialTypes= []; % The type of each trial completed will be deposited here
BpodSystem.Data.TrialOutcomes = []; % ditto for outcomes
BpodSystem.Data.ITIs = [];

%% Main trial loop
RunSession = true;
currentTrial = 1;


% S = struct(); ST = struct();
% ST.BlockNumber = [4; 4; 4; 4]; % fluff
% ST.P = [0.5 * 0.7; 0.5 * 0.3; 0.5 * 0.7; 0.5 * 0.3];
% ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
% ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'RewardLeft'; 'Neutral'};   % Reward
% ST.OutcomeRight = ['Neutral'; 'RewardRight'; 'Neutral'; 'RewardRight';];
% ST.RewardSizeLeft = [2; 2; 2; 2];   % uL
% ST.RewardSizeRight = [2; 2; 2; 2];  % uL 
% S.Table = struct2table(ST);
% S.LinkTo = 5;
% S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';
% RewardActionLeft = {'ValveState', S.GUI.LeftPort};
% RewardActionRight = {'ValveState', S.GUI.RightPort};      

while RunSession
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;
    
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table); % trial type chosen on the fly based upon current Protocol Settings
        
        switch S.Block.Table.CS(TrialType)
            case 0
                OdorValve = 0; % uncued
            case 1
                OdorValve = S.GUI.Odor1Valve;
            case 2
                OdorValve = S.GUI.Odor2Valve;
            case 3
                OdorValve = S.GUI.Odor3Valve;
        end
        
        OutcomeLeft = S.Block.Table.OutcomeLeft{TrialType};
        RewardLeft = S.Block.Table.RewardLeft{TrialType}; % only relevant if OutcomeLeft = 'Reward'        
        ConditionLeft = {LeftPortIn, OutcomeLeft};
        
        OutcomeRight = S.Block.Table.OutcomeRight{TrialType};
        RewardRight = S.Block.Table.RewardRight{TrialType};
        ConditionRight = {RightPortIn, OutcomeRight};    

        LeftValveTime = GetValveTimes(RewardLeft, S.GUI.LeftPort); 
        RightValveTime = GetValveTimes(RewardRight, S.GUI.RightPort);
        
                       
        sma = NewStateMatrix(); % Assemble state matrix
        sma = SetGlobalTimer(sma,1,S.GUI.Cue); % pre cue  
        sma = SetGlobalTimer(sma,2,S.GUI.CueGrace); % pre cue  
        sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
            'Timer', 0,...
            'StateChangeConditions', {CenterPortIn, 'CenterPokeDetected'},...
            'OutputActions', CenterLightOn); 
        sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
            'Timer', S.CenterPokeTime,...
            'StateChangeConditions', {'Tup', 'trigCue', CenterPortOut, 'WaitForPoke'},...
            'OutputActions', CenterLightOn);
        
        % Do I require mouse to poke and hold for entire cue? part of cue?
        % how to implement?
        %% cue block with grace period for maintaining center poke
        % trigger global timer defining cue
        sma = AddState(sma, 'Name', 'trigCue', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 1});
        % cue1: poke outs trigger grace period, poke ins skip to cue2 to cancel grace period
        sma = AddState(sma, 'Name', 'Cue1',...
            'Timer', 0,...
            'StateChangeCondtions', {'GlobalTimer1_End', 'WaitForResponse', 'GlobalTimer4_End', 'ITI', CenterPortIn, 'Cue2', CenterPortOut, 'trigGrace_Cue'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'trigGrace_Cue',...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 2});
        % cue2 is for when animal pokes back in, grace period timer is ignored here 
        sma = AddState(sma, 'Name', 'Cue2',...
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer1_End', 'WaitForResponse', 'Port2Out', 'trigGrace_Cue'},... 
            'OutputActions', {});
        %% end cue block
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', S.GUI.ResponseWindow, ...
            'StateChangeConditions', [{'Tup', 'ITI'}, ConditionLeft, ConditionRight], ...
            'OutputActions', SideLightOn);
        % dummy state for choose left?
        % dummy state for choose right?
        sma = AddState(sma, 'Name', 'RewardLeft', ...
            'Timer', LeftValveTime,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [{'ValveState', S.GUI.LeftPort}, SideLightOn]);    

        sma = AddState(sma, 'Name', 'Drinking', ... % let the mouse drink before continuing to next trial
            'Timer', 0,...
            'StateChangeConditions', {LeftPortOut, 'DrinkingGrace', RightPortOut, 'DrinkingGrace', CenterPortOut, 'DrinkingGrace'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'DrinkingGrace',... % let the mouse drink before continuing to next trial
            'Timer', S.DrinkingGrace,...
            'StateChangeConditions', {LeftPortIn, 'Drinking', RightPortIn, 'Drinking', CenterPortIn, 'Drinking', 'Tup', 'ITI'},...
            'OutputActions', {});      
        sma = AddState(sma, 'Name', 'Neutral', ... % let the mouse try to drink before continuing to next trial
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', {});
        % what if mouse pokes into side port during ITI? do I require mouse
        % to wait until center light turns on signalling trial initiation
        % availability? I could go to "drinking" upon a center poke in....
        % to retrigger the ITI....
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {LeftPortIn, 'Drinking', RightPortIn, 'Drinking', CenterPortIn, 'Drinking', 'Tup', 'exit'},...
            'OutputActions', {});        
        
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix; % RawEvents = the data from the trial        
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end
end 