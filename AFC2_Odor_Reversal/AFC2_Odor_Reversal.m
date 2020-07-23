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
    'GUI.ResponseWindow', 20;... % start with 20s, then down to plot movement time, 3-5 seconds, even during training
    'GUI.CenterPokeTime', 0.1;... % what value to use?
    'GUI.Cue', 0.2;...
    'GUIMeta.CueAdjust.Style', 'checkbox';...
    'GUI.CueAdjust', true;... % make check box
    'GUI.CueAdjust_target', 1;...  % desired cue duration
    'GUI.CueAdjust_increment', 0.01;...  % cue duration increment
    'GUI.CueGrace', 0.1;...
    'GUI.FeedbackDelay', 0.1;...
    'GUI.DrinkingGrace', 0.1;... % not yet implemented
    'GUI.ITI', 0;... % now refers to mean of exponentially disributed ITI distribution
    'GUI.Block', 1;...  
    'GUI.Odor1Valve', 5;...
    'GUI.Odor2Valve', 6;...
    'GUI.Odor3Valve', 7;...
    'GUI.Odor4Valve', 8;...    
    };
    

S = setBpodDefaultSettings(S, defaults);
            
%% adaptive cue increment
S.EW_criterion = 0.8;
S.EW_history = 50;
S.EW_minTrials = 5;
%% Pause and wait for user to edit parameter GUI 
BpodParameterGUI('init', S);    
BpodSystem.Pause = 1;
HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
if BpodSystem.BeingUsed == 0
    return
end
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
olfWireArg = 0;
olfBNCArg = 0;    
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
    

    
    switch olfSettings.triggerType
        case 'WireState'
            olfWireArg = bitset(olfWireArg, olfSettings.triggerNumber);
        case 'BNCState'
            olfBNCArg = bitset(olfBNCArg, olfSettings.triggerNumber);
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

BpodSystem.Data.TrialType = []; % The type of each trial completed will be deposited here
BpodSystem.Data.TrialOutcome = []; % ditto for outcomes
BpodSystem.Data.Choice = {}; % left or right
BpodSystem.Data.RewardLeft = []; % in uL
BpodSystem.Data.RewardRight = []; % in uL
BpodSystem.Data.RewardCenter = []; % in uL
BpodSystem.Data.CorrectResponse = {}; % left or right
BpodSystem.Data.BlockNumber = [];
BpodSystem.Data.EW = []; % early withdrawal, redundant to trial outcomes
BpodSystem.Data.ITIs = [];
BpodSystem.Data.OdorValve = []; % e.g. 1st odor = V5, or V6
BpodSystem.Data.OdorValveIndex = []; % 1st odor, 2nd odor
BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
BpodSystem.Data.SwitchParameterCriterion = [];    
BpodSystem.Data.pf_EW = [];
BpodSystem.Data.pf_total = [];
BpodSystem.Data.pf_left = [];
BpodSystem.Data.pf_right = [];



%% Initialize Figures
trialsToShow = 100;
pf.figh= ensureFigure('performance', 1); % performance figure
pf.ax_outcome = subplot(4,1,1);
TrialTypeOutcomePlot(pf.ax_outcome,'init',[], 'ntrials', trialsToShow);
set(pf.ax_outcome, 'FontSize', 8);
pf.ax_ITI = subplot(4,1,2);
pf.lh_ITI = plot(NaN,NaN, 'o'); hold on; ylabel('ITI (s)');
pf.ax_ew = subplot(4,1,3);
pf.lh_ew = plot(NaN,NaN, '-k'); hold on; ylabel('EW');
% plot([S.EW_minTrials; S.EW_minTrials], [0; 1], '--r');
pf.ax_pf = subplot(4,1,4);
pf.lh_pf = plot(NaN,NaN, '-'); hold on; ylabel('performance'); xlabel('Trial #');
pf.lh_pf_left = plot(NaN,NaN, '-r');  % left, port = red
pf.lh_pf_right = plot(NaN,NaN, '-g');% right, starboard = green
legend({'total', 'left', 'right'});



cr.figh = ensureFigure('criterion', 1); 
% cr.ax = subplot(2,1,1, 'NextPlot', 'add');
% cr.sh = scatter([], [], 20, [], 'Parent', cr.ax); 
% ylabel('auROC');
cr.ax = subplot(1,1,1, 'NextPlot', 'add'); % plot switchParameter
cr.clh = line(0,0, 'Parent', cr.ax, 'Color', 'g');
cr.splh = line(0,0, 'Parent', cr.ax, 'Color', 'k');
ylabel('perc. Corr.'); xlabel('trial number');


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
        BpodSystem.Data.TrialType(currentTrial) = TrialType; % Adds the trial type of the current trial to data
        BpodSystem.Data.TrialOutcome(currentTrial) = NaN; % NaN for now to show current trial type while trial is in progress
        TrialTypeOutcomePlot(pf.ax_outcome, 'update',...
            currentTrial, BpodSystem.Data.TrialType, BpodSystem.Data.TrialOutcome);
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
        
        if ~BpodSystem.EmulatorMode 
            slaveResponse = updateValveSlave(valveSlave, OdorValve); 
            if isempty(slaveResponse)
                disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
                continue
            else
                disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
            end 
        end
        
                
        OutcomeLeft = S.Block.Table.OutcomeLeft{TrialType};
        RewardSizeLeft = S.Block.Table.RewardSizeLeft(TrialType); % only relevant if OutcomeLeft = 'Reward'        
%         ConditionLeft = {LeftPortIn, OutcomeLeft};
        
        OutcomeRight = S.Block.Table.OutcomeRight{TrialType};
        RewardSizeRight = S.Block.Table.RewardSizeRight(TrialType);
%         ConditionRight = {RightPortIn, OutcomeRight};    
        
        RewardSizeCenter = S.Block.Table.RewardSizeCenter(TrialType);
        
        if ~BpodSystem.EmulatorMode        
            LeftValveTime = GetValveTimes(RewardSizeLeft, S.GUI.LeftPort); 
            RightValveTime = GetValveTimes(RewardSizeRight, S.GUI.RightPort);
            CenterValveTime = GetValveTimes(RewardSizeCenter, S.GUI.CenterPort);
        else
            LeftValveTime = 0.01;
            RightValveTime = 0.01;
            CenterValveTime = 0.01;
        end
        
        CorrectResponse = S.Block.Table.CorrectResponse{TrialType};
        
        % kludge for debugging, indicate correct choice
        if BpodSystem.EmulatorMode
            switch CorrectResponse
                case 'Left'
                    SideLightOn = {LeftLight, 255};
                case 'Right'
                    SideLightOn = {RightLight, 255};
            end
        end
        
        
        if S.GUI.ITI
            ITI = inf;
            while ITI > 3 * S.GUI.ITI   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                ITI = exprnd(S.GUI.ITI);
            end        
        else
            ITI = 0;
        end
                               
        sma = NewStateMatrix(); % Assemble state matrix
        sma = SetGlobalTimer(sma,1,S.GUI.Cue); % cue
        sma = SetGlobalTimer(sma,2,S.GUI.CueGrace); % cue grace
        sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
            'Timer', 0.0002,...
            'StateChangeConditions', {CenterPortIn, 'CenterPokeDetected'},...
            'OutputActions', CenterLightOn); 
        sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
            'Timer', max(S.GUI.CenterPokeTime, 0.0002),...
            'StateChangeConditions', {'Tup', 'trigCue', CenterPortOut, 'WaitForPoke'},...
            'OutputActions', CenterLightOn);
        
        % Do I require mouse to poke and hold for entire cue? part of cue?
        % how to implement?
        %% cue block with grace period for maintaining center poke
        % trigger global timer defining cue
        sma = AddState(sma, 'Name', 'trigCue', ...
            'Timer', 0.0002,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 1});
        % cue1: poke outs trigger grace period, poke ins skip to cue2 to cancel grace period
        sma = AddState(sma, 'Name', 'Cue1',...
            'Timer', 0.0002,...
            'StateChangeCondtions', {'GlobalTimer1_End', 'RewardCenter', 'GlobalTimer2_End', 'ITI', CenterPortIn, 'Cue2', CenterPortOut, 'trigGrace_Cue'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});
        sma = AddState(sma, 'Name', 'trigGrace_Cue',...
            'Timer', 0.0002,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'WireState', olfWireArg, 'BNCState', olfBNCArg});
        % cue2: cancel grace period
        sma = AddState(sma, 'Name', 'Cue2',...
            'Timer', 0.0002,...
            'StateChangeConditions', {'GlobalTimer1_End', 'RewardCenter', CenterPortOut, 'trigGrace_Cue'},... 
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});
        %  end cue block
        %%
        sma = AddState(sma, 'Name', 'RewardCenter',...
            'Timer', max(CenterValveTime, 0.0002),...
            'StateChangeConditions', {CenterPortOut,'WaitForResponse','Tup','WaitForResponse'},...
            'OutputActions', {'ValveState', bitset(0, S.GUI.CenterPort)});
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', max(S.GUI.ResponseWindow, 0.0002), ...
            'StateChangeConditions', {'Tup', 'ITI', LeftPortIn, 'LeftChoice', RightPortIn, 'RightChoice'}, ...
            'OutputActions', SideLightOn);
        sma = AddState(sma, 'Name', 'LeftChoice', ...
            'Timer', max(0.0002, S.GUI.FeedbackDelay), ...
            'StateChangeConditions', {'Tup', OutcomeLeft}, ...
            'OutputActions', SideLightOn);
        sma = AddState(sma, 'Name', 'RightChoice', ...
            'Timer', max(0.0002, S.GUI.FeedbackDelay), ...
            'StateChangeConditions', {'Tup', OutcomeRight}, ...
            'OutputActions', SideLightOn);       
        sma = AddState(sma, 'Name', 'RewardLeft', ...
            'Timer', max(LeftValveTime, 0.0002),...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [{'ValveState', bitset(0, S.GUI.LeftPort)}, SideLightOn]);    
        sma = AddState(sma, 'Name', 'RewardRight', ...
            'Timer', max(RightValveTime, 0.0002),...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [{'ValveState', bitset(0, S.GUI.RightPort)}, SideLightOn]);            
        sma = AddState(sma, 'Name', 'Drinking', ... % let the mouse drink before continuing to next trial
            'Timer', 0.0002,...
            'StateChangeConditions', {LeftPortOut, 'DrinkingGrace', RightPortOut, 'DrinkingGrace', CenterPortOut, 'DrinkingGrace'},...
            'OutputActions', {});
        sma = AddState(sma, 'Name', 'DrinkingGrace',... % let the mouse drink before continuing to next trial
            'Timer', max(S.GUI.DrinkingGrace, 0.0002),...
            'StateChangeConditions', {LeftPortIn, 'Drinking', RightPortIn, 'Drinking', CenterPortIn, 'Drinking', 'Tup', 'ITI'},...
            'OutputActions', {});      
        sma = AddState(sma, 'Name', 'Neutral', ... % let the mouse try to drink before continuing to next trial
            'Timer', 0.0002,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', {});
        % what if mouse pokes into side port during ITI? do I require mouse
        % to wait until center light turns on signalling trial initiation
        % availability? I could go to "drinking" upon a center poke in....
        % to retrigger the ITI....
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', max(ITI, 0.0002),...
            'StateChangeConditions', {LeftPortIn, 'Drinking', RightPortIn, 'Drinking', CenterPortIn, 'Drinking', 'Tup', 'exit'},...
            'OutputActions', {});        
        
        SendStateMatrix(sma);
        RawEvents = RunStateMatrix; % RawEvents = the data from the trial     

% BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
% BpodSystem.Data.SwitchParameterCriterion = [];    

%%
% NaN: future trial (blue), -1: early withdrawal (red circle), 0: disfavored
% choice (red dot), 1: favored choice (green dot), 2: did not choose (green circle)
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)   

            BpodSystem.Data.BlockNumber(currentTrial) = S.GUI.Block;
            BpodSystem.Data.Block(currentTrial) = S.Block; % save the table, linkto fcn, and linkto block #
            BpodSystem.Data.OdorValveIndex(currentTrial) = S.Block.Table.Odor(TrialType);
            BpodSystem.Data.OdorValve(currentTrial) = OdorValve;
            BpodSystem.Data.CorrectResponse{currentTrial} = CorrectResponse; % left or right
            
            EW = isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForResponse(1));

            BpodSystem.Data.EW(currentTrial) = EW;
            if EW
                choice = '';
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.LeftChoice)
                choice = 'Left';
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RightChoice)
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
            
            if ~EW
                if strcmpi(choice, 'Left')
                    TotalRewardDisplay('add', RewardSizeLeft + RewardSizeCenter);
                else
                    TotalRewardDisplay('add', RewardSizeRight + RewardSizeCenter);
                end
            end
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardLeft)
                BpodSystem.Data.RewardLeft(currentTrial) = RewardSizeLeft;
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardRight)
                BpodSystem.Data.RewardRight(currentTrial) = RewardSizeRight;
            end
            
            if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.RewardCenter)
                BpodSystem.Data.RewardCenter(currentTrial) = RewardSizeCenter;
            end
                
            
            
            % calculate total ITI
            if currentTrial == 1
                ITI = NaN;                
            else
                ITI = BpodSystem.Data.TrialStartTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial - 1);
            end
            BpodSystem.Data.ITIs(currentTrial) = ITI;
            

            
            %% adaptive cue increment
            if S.GUI.CueAdjust
                if currentTrial > S.EW_minTrials
                   considerTrials =  max(S.EW_minTrials, currentTrial - S.EW_history):1:currentTrial;
                   % if not EW on previous trial and performance over
                   % previous n history trials above criterion, increment
                   % cue duration
                   if ((sum(~BpodSystem.Data.EW(considerTrials)) / length(considerTrials)) > S.EW_criterion) && ~EW
                       S.GUI.Cue = min(S.GUI.CueAdjust_target, S.GUI.Cue + S.GUI.CueAdjust_increment);
                       sprintf('*** Trial %i, Cue time increased to %.3f ***', currentTrial, S.GUI.Cue)
                   elseif ((sum(~BpodSystem.Data.EW(considerTrials)) / length(considerTrials)) < S.EW_criterion/2) && EW
                       S.GUI.Cue = min(S.GUI.CueAdjust_target, S.GUI.Cue - S.GUI.CueAdjust_increment);
                       sprintf('*** Trial %i, Cue time decreased to %.3f ***', currentTrial, S.GUI.Cue)
                   end
                end
            end
            BpodSystem.Data.pf_EW = movmean(~BpodSystem.Data.EW, [S.EW_history, 0], 'Endpoints', 'shrink'); % logical inconsistency, doesn't reflect minTrials


            

            %% calculate performance
            winsize = 20; % 20 trial sum
            if currentTrial >= winsize
                performance_total = movsum(BpodSystem.Data.TrialOutcome == 1, [winsize, 0], 'Endpoints', 'shrink') ./ movsum(BpodSystem.Data.TrialOutcome ~= -1, [winsize, 0], 'Endpoints', 'shrink'); % winsize trials back
                performance_left = movsum(BpodSystem.Data.TrialOutcome == 1 & strcmp(BpodSystem.Data.CorrectResponse, 'Left') , [winsize, 0], 'Endpoints', 'shrink')...
                    ./ movsum(BpodSystem.Data.TrialOutcome ~= -1 & strcmp(BpodSystem.Data.CorrectResponse, 'Left'), [winsize, 0], 'Endpoints', 'shrink'); % winsize trials back
                performance_right = movsum(BpodSystem.Data.TrialOutcome == 1 & strcmp(BpodSystem.Data.CorrectResponse, 'Right') , [winsize, 0], 'Endpoints', 'shrink')...
                    ./ movsum(BpodSystem.Data.TrialOutcome ~= -1 & strcmp(BpodSystem.Data.CorrectResponse, 'Right'), [winsize, 0], 'Endpoints', 'shrink'); % winsize trials back
            else
                performance_total = NaN;
                performance_left = NaN;
                performance_right = NaN;
            end
            BpodSystem.Data.pf_total = performance_total;
            BpodSystem.Data.pf_left = performance_left;
            BpodSystem.Data.pf_right = performance_right;
            
%             pf.figh= ensureFigure('performance', 1); % performance figure
% pf.ax_outcome = subplot(3,1,1);
% TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',[], 'ntrials', trialsToShow);
% pf.ax_ITI = subplot(3,1,2);
% pf.ax_pf = subplot(3,1,3);
            %% update plots
            if currentTrial > 1
                disp('wtf');
            end
            TrialTypeOutcomePlot(pf.ax_outcome, 'update',...
                currentTrial, BpodSystem.Data.TrialType, BpodSystem.Data.TrialOutcome);
            % update ITIs plot
            set(pf.lh_ITI, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.ITIs);
            % update EW plot
            set(pf.lh_ew, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.pf_EW);
            % update performance plot
            set(pf.lh_pf, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.pf_total);
            set(pf.lh_pf_left, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.pf_left);
            set(pf.lh_pf_right, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.pf_right);
            %% adaptive bias correction, let's try a 150 trial window over previous trials
            
            
            %% adaptive block switches
            S.Block.Table.OutcomeLeft{TrialType};
            if S.Block.LinkTo
                switchFcn = str2func(S.Block.LinkToFcn);
                [S.GUI.Block, switchParameter, switchParameterCriterion] = switchFcn(BpodSystem.Data.TrialOutcome, BpodSystem.Data.BlockNumber, S.Block.LinkTo);
                S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            else
                switchParameter = NaN;
                switchParameterCriterion = NaN;
            end
            BpodSystem.Data.SwitchParameter(end + 1) = switchParameter(1);
            BpodSystem.Data.SwitchParameterCriterion = switchParameterCriterion;
            
            
            % plot performance criterion that determines automated
            % reversals                        
            set(cr.splh, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.SwitchParameter);
            set(cr.clh, 'XData', [1 currentTrial], 'YData', [switchParameterCriterion switchParameterCriterion]);
            set(cr.ax, 'YLim', [0 1]);

            %% Save protocol settings to reflect updated values
            BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
            SaveBpodProtocolSettings;  
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
        currentTrial = currentTrial + 1;
end