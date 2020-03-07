function AFC2_Odor_Reversal

global BpodSystem


TotalRewardDisplay('init');
%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    
%     defaults = {...
%         'GUIPanels.Photometry', {'LED1_amp', 'LED2_amp', 'PhotometryOn', 'LED1_f', 'LED2_f'};...
%         'GUI.LED1_amp', 1.5;...
%         'GUI.LED2_amp', 0;...    

blockFunctionList = {'AFC2_Odor_Blocks'};
defaults = {...
    'GUI.BlockFcn', 'AFC2_Odor_Blocks';...
    'GUIMeta.BlockFcn.Style', 'popupmenutext';...
    'GUIMeta.BlockFcn.String',  blockFunctionList;...      
    'GUI.LeftPort', 1;...  % have this be in rig-specific settings?
    'GUI.CenterPort', 2;... % have this be in rig-specific settings?
    'GUI.RightPort', 3;... % have this be in rig-specific settings?
    'GUI.GracePeriod', 0.05;...
    'GUI.ResponseWindow', 8;...
    'GUI.CenterPokeTime', 0.05;... % what value to use?
    'GUI.Cue', 1;...
    'GUI.CueAdjust', 0;... % make check box
    'GUI.CueAdjust_target', 0;...  % desired cue duration
    'GUI.CueAdjust_increment', 0.01;...  % cue duration increment
    'GUI.CueGrace', 0.2;...
    'GUI.DrinkingGrace', 0.2;...
    'GUI.ITI', 2;... % do I need an ITI?
    'GUI.DrinkingGrace', 0.2;...
    'GUI.Block', 1;...  
    'GUI.Odor1Valve', 4;...
    'GUI.Odor2Valve', 5;...
    'GUI.Odor3Valve', 6;...
    'GUI.Odor4Valve', 7;...    
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
bfh = str2func(S.GUI.BlockFcn);
try
    S.Tables = bfh();
catch
    error('** block function error ***');
end

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
% NaN: future trial (blue), -1: early withdrawal (red circle), 0: favored
% choice (red dot), 1: disfavored choice (green dot), 2: did not choose (green circle)
%{
I need: Choice (Left or right), Outcome  (Reward or Neutral), Reward
amount, what else
%}

BpodSystem.Data.TrialTypes= []; % The type of each trial completed will be deposited here
BpodSystem.Data.TrialOutcomes = []; % ditto for outcomes
BpodSystem.Data.Choice = {}; % left or right
BpodSystem.Data.RewardLeft = []; % in uL
BpodSystem.Data.RewardRight = []; % in uL
BpodSystem.Data.RewardCenter = []; % in uL
BpodSystem.Data.CorrectResponse = {} % left or right
BpodSystem.Data.BlockNumber = [];
BpodSystem.Data.EW = []; % early withdrawal, redundant to trial outcomes
BpodSystem.Data.ITIs = [];
BpodSystem.Data.OdorValve = []; % e.g. 1st odor = V5, or V6
BpodSystem.Data.OdorValveIndex = []; % 1st odor, 2nd odor
BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
BpodSystem.Data.SwitchParameterCriterion = [];    

%% Main trial loop
RunSession = true;
currentTrial = 1;    

% NEED TO ADD CENTER REWARD!!!!!!!!!!
while RunSession
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;
    
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table); % trial type chosen on the fly based upon current Protocol Settings
        
        switch S.Block.Table.Odor(TrialType)
            case 0
                OdorValve = 0; % uncued
            case 1
                OdorValve = S.GUI.Odor1Valve;
            case 2
                OdorValve = S.GUI.Odor2Valve;
            case 3
                OdorValve = S.GUI.Odor3Valve;
            case 4
                OdorValve = S.GUI.Odor4Valve;                
        end
        
        OutcomeLeft = S.Block.Table.OutcomeLeft{TrialType};
        RewardSizeLeft = S.Block.Table.RewardSizeLeft(TrialType); % only relevant if OutcomeLeft = 'Reward'        
        ConditionLeft = {LeftPortIn, OutcomeLeft};
        
        OutcomeRight = S.Block.Table.OutcomeRight{TrialType};
        RewardSizeRight = S.Block.Table.RewardSizeRight(TrialType);
        ConditionRight = {RightPortIn, OutcomeRight};    

        LeftValveTime = GetValveTimes(RewardSizeLeft, S.GUI.LeftPort); 
        RightValveTime = GetValveTimes(RewardSizeRight, S.GUI.RightPort);
        
        CorrectResponse = S.Block.Table.CorrectResponse{TrialType};
                               
        sma = NewStateMatrix(); % Assemble state matrix
        sma = SetGlobalTimer(sma,1,S.GUI.Cue); % pre cue  
        sma = SetGlobalTimer(sma,2,S.GUI.CueGrace); % pre cue  
        sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
            'Timer', 0,...
            'StateChangeConditions', {CenterPortIn, 'CenterPokeDetected'},...
            'OutputActions', CenterLightOn); 
        sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
            'Timer', S.GUI.CenterPokeTime,...
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
        %  end cue block
        %%
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', S.GUI.ResponseWindow, ...
            'StateChangeConditions', {'Tup', 'ITI', LeftPortIn, 'LeftChoice', RightPortIn, 'RightChoice'}, ...
            'OutputActions', SideLightOn);
        sma = AddState(sma, 'Name', 'LeftChoice', ...
            'Timer', 0, ...
            'StateChangeConditions', ConditionLeft, ...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'RightChoice', ...
            'Timer', 0, ...
            'StateChangeConditions', ConditionRight, ...
            'OutputActions', {});       
        sma = AddState(sma, 'Name', 'RewardLeft', ...
            'Timer', LeftValveTime,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [{'ValveState', S.GUI.LeftPort}, SideLightOn]);    
        sma = AddState(sma, 'Name', 'RewardRight', ...
            'Timer', RightValveTime,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [{'ValveState', S.GUI.RightPort}, SideLightOn]);            
        sma = AddState(sma, 'Name', 'Drinking', ... % let the mouse drink before continuing to next trial
            'Timer', 0,...
            'StateChangeConditions', {LeftPortOut, 'DrinkingGrace', RightPortOut, 'DrinkingGrace', CenterPortOut, 'DrinkingGrace'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'DrinkingGrace',... % let the mouse drink before continuing to next trial
            'Timer', S.GUI.DrinkingGrace,...
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

% BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
% BpodSystem.Data.SwitchParameterCriterion = [];    

% NaN: future trial (blue), -1: early withdrawal (red circle), 0: disfavored
% choice (red dot), 1: favored choice (green dot), 2: did not choose (green circle)
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)   
            BpodSystem.Data.TrialType(currentTrial) = TrialType(currentTrial); % Adds the trial type of the current trial to data
            BpodSystem.Data.BlockNumber(currentTrial) = S.GUI.BlockNumber;
            BpodSystem.Data.Block(currentTrial) = S.Block; % save the table, linkto fcn, and linkto block #
            BpodSystem.Data.OdorValveIndex(currentTrial) = S.Block.Table.Odor(TrialType);
            BpodSystem.Data.OdorValve(currentTrial) = OdorValve;
            BpodSystem.Data.CorrectResponse{currentTrial} = CorrectResponse; % left or right
            
            EW = isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForResponse);
            BpodSystem.Data.EW(currentTrial) = EW;
            if EW
                choice = '';
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.LeftChoice)
                choice = 'Left';
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.LeftChoice)
                choice = 'Right';
            else
                choice = '';
            end
            BpodSystem.Data.Choice{currentTrial} = choice;
            if EW
                BpodSystem.Data.TrialOutcome(currentTrial) = -1; % early withdrawal
            elseif strcmp(choice, CorrectResponse)
                BpodSystem.Data.TrialOutcome(currentTrial) = 1; % correct
            elseif ~EW && isempty(choice)
                BpodSystem.Data.TrialOutcome(currentTrial) = 2; % miss
            else
                BpodSystem.Data.TrialOutcome(currentTrial) = 0; % incorrect
            end
                
            % calculate total ITI
            if currentTrial == 1
                ITI = NaN;                
            else
                ITI = BpodSystem.Data.TrialStartTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial - 1);
            end
            BpodSystem.Data.ITI(currentTrial) = ITI;
            

            
            %% adaptive cue increment
            criterion = 0.8; % fraction correctly initiated trials (not early withdrawal)
            history = 50; % n trials to consider
            minTrials = 50;
            if S.GUI.CueAdjust
                if currentTrial > 10
                   considerTrials =  max(minTrials, currentTrial - history):1:currentTrial;
                   % if not EW on previous trial and performance over
                   % previous n history trials above criterion, increment
                   % cue duration
                   if ((sum(BpodSystem.Data.EW(considerTrials)) / length(considerTrials)) > criterion) && ~EW
                       S.GUI.Cue = min(S.GUI.CueAdjust_target, S.GUI.Cue + S.GUI.CueAdjust_increment);
                       sprintf('*** Trial %i, Cue time increased to %.3f ***');
                   end
                end
            end
%                 winsize = 20; % 20 trial sum
%     h = ensureFigure('Posner_stage3_Performance', 1);
%     subplot(3,1,1);
%     plot(movsum(correctLeft, winsize) ./ movsum(totalLeft, winsize), 'g'); hold on;
%     plot(movsum(correctRight, winsize) ./ movsum(totalRight, winsize), 'r');
%     plot(movsum(correctBoth, winsize) ./ movsum(totalBoth, winsize), 'b');
%     legend({'Left', 'Right'}, 'Box', 'off');
            
            winsize = 20; % 20 trial sum
            %% calculate performance
            performance_total = movsum(BpodSystem.Data.TrialOutcome == 1, [winsize, 0], 'Endpoints', 'fill') ./ movsum(BpodSystem.Data.TrialOutcome ~= -1, [winsize, 0], 'Endpoints', 'fill'); % winsize trials back
            performance_left = movsum(BpodSystem.Data.TrialOutcome == 1 & strcmp(BpodSystem.Data.CorrectResponse, 'Left') , [winsize, 0], 'Endpoints', 'fill')...
                ./ movsum(BpodSystem.Data.TrialOutcome ~= -1 & strcmp(BpodSystem.Data.CorrectResponse, 'Left'), [winsize, 0], 'Endpoints', 'fill'); % winsize trials back
            performance_right = movsum(BpodSystem.Data.TrialOutcome == 1 & strcmp(BpodSystem.Data.CorrectResponse, 'Right') , [winsize, 0], 'Endpoints', 'fill')...
                ./ movsum(BpodSystem.Data.TrialOutcome ~= -1 & strcmp(BpodSystem.Data.CorrectResponse, 'Right'), [winsize, 0], 'Endpoints', 'fill'); % winsize trials back            
            
            
            %% adaptive bias correction, let's try a 150 trial window over previous trials
            
            
            
            
            %% Save protocol settings to reflect updated values
            BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
            SaveBpodProtocolSettings;        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end
end 