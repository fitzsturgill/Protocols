function Posner_Stage3
% Posner Task
% Currently, trace, cue and target durations are NOT jittered
% AJ's version

    global BpodSystem
    
    S = BpodSystem.ProtocolSettings;
    
%     GUIdefaults = {...
%         'RewardAmount', 5,...
%         'biasMode', 0};
%     
%     for counter = 1:size(GUIdefaults, 1)
%         if ~isfield(S, GUIdefaults{counter, 1})
%             S.(GUIdefaults{counter, 1}) = GUIdefaults{counter, 2};
%         end
%     end
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.RewardAmount = 5; %ul
        S.GUI.Punish = 6; % How long the mouse must wait in the goal port for reward to be delivered

        S.GUI.BaselineIntensity = 2.5;    
        S.GUI.CueLightIntensity = 2.5; % value added to baseline intensity to determine cue light intensity
        S.GUI.TargetLightIntensity = 255; %Set target light intensity

        S.GUI.Foreperiod = 0.2; 
        S.GUI.Trace = 0.2; 
        S.GUI.Cue = 0.1; 
        S.GUI.Target = 0.1;
        S.GUI.Graceperiod = 0.05;
        
        S.GUI.varyTargetIntensity = 0;
        S.GUI.minTargetIntensity = 10;
        S.GUI.maxTargetIntensity = 200;

        S.GUI.ITI = 2;
        S.GUI.LeftBiasFraction = 0.5; % 0.5 for even
        

        S.GUI.delayAdjust_trialWindow = 10;
        % *********** !!!!!!!!!!!!!!!!!
%         Inf for step fractions disables adjustment of delay periods
%         during Posner_Stage3      
        S.GUI.delayAdjust_stepUpFraction = Inf; % if P% of trials are correct over T trials, then increase the delay periods by delayAdjust_Increment
        S.GUI.delayAdjust_stepDownFraction = Inf; % if P% of trials are incorrect over T trials, then decrease the delays
        S.GUI.delayAdjust_increment = 0.01;
        
        S.GUI.validFraction = 0.8;
        S.GUI.biasMode = 0; % 0 = off, 1 = repeat left trials, 2 = repeat right trials
        

        S.ResponseWindow = 8; % window in which mouse can make a response
        
        S.DrinkingGrace = 0.2;
        
        S.maxForeperiod = 0.45;
        S.maxTrace = 0.45;
        S.maxCue = 0.100;  % this should match the target light on time in the final task
        S.minForeperiod = 0.02;
        S.minTrace = 0.02;
        S.minCue = 0.02;  % 
        
        S.CenterPokeTime = 0.05; % WHAT VALUE TO USE HERE????????????
    elseif ~isfield(S.GUI, 'biasMode')
        S.GUI.biasMode = 0; % 0.5 for even
    end

    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);
    
    %% Pause and wait for user to edit parameter GUI 
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;

    %% initialize trial types and outcomes
    
    MaxTrials = 1000;    
    % generate randomized trial types
    typeMatrix = [...
        % valid cue
        1, S.GUI.validFraction * S.GUI.LeftBiasFraction;... %  target left, cue left
        2, S.GUI.validFraction * (1 - S.GUI.LeftBiasFraction);...  % target right, cue right
        % invalid cue
        3, (1 - S.GUI.validFraction) * S.GUI.LeftBiasFraction;...  % target left, cue right
        4, (1 - S.GUI.validFraction) * (1 - S.GUI.LeftBiasFraction);...  % target right, cue left
        ];
    TrialTypes = defineRandomizedTrials(typeMatrix, MaxTrials);
% NaN: future trial (blue), -1: early withdrawal (red circle), 0: incorrect choice (red dot), 1: correct
% choice (green dot), 2: did not choose (green circle)
    Outcomes = NaN(1, MaxTrials); 
    ITIs = []; % time in between trials
    Foreperiods = []; % to track adjustment of foreperiod delay
    
    BpodSystem.Data.TrialTypes= []; % The type of each trial completed will be deposited here
    BpodSystem.Data.TrialOutcomes = []; % ditto for outcomes
    BpodSystem.Data.ITIs = [];
    

    %% Initialize plots
    trialsToShow = 50;
    BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
    BpodSystem.GUIHandles.OutcomePlot = subplot(3,1,1);
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes, 'ntrials', trialsToShow);
    BpodSystem.GUIHandles.ITIPlot = subplot(3,1,2);
    BpodSystem.GUIHandles.ForeperiodPlot = subplot(3,1,3);
    BpodNotebook('init');



    %% This code initializes the Total Reward Display plugin, 
    TotalRewardDisplay('init');


    %% Generate white noise
    SF = 192000; % Sound card sampling rate
    PunishSound = (rand(1,SF*.5)*2) - 1; %  2s punish sound
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, PunishSound);
    % Set soft code handler to trigger sounds
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    %     %% exponentially distributed foreperiod duration bounded by min
    %     and max values
        FP_expOn = 1;
        if FP_expOn
            FP_bound = [0.05 0.35];
            FP_mean = 0.15;
            fp = inf;
            while fp < FP_bound(1) || fp > FP_bound(2)    % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                fp = exprnd(FP_mean);
            end            
            S.GUI.Foreperiod = fp;
            BpodParameterGUI('sync', S);
            disp(['*** Foreperiod: ' num2str(S.GUI.Foreperiod)]);
        end
        
    %% AJ - exponentially distributed trace period duration bounded by min and max values
        TP_expOn = 1;
        if TP_expOn
            TP_bound = [0.1 0.4];
            TP_mean = 0.2;
            tp = inf;
            while tp < TP_bound(1) || tp > TP_bound(2)    % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
                tp = exprnd(TP_mean);
            end            
            S.GUI.Trace = tp;
            BpodParameterGUI('sync', S);
            disp(['*** Trace period: ' num2str(S.GUI.Trace)]);
        end
        
    %% AJ - randomly selecting a target intensity
        if S.GUI.varyTargetIntensity == 1
            S.GUI.TargetLightIntensity = randi([S.GUI.minTargetIntensity, S.GUI.maxTargetIntensity]);
            disp(num2str(S.GUI.TargetLightIntensity));
        end
    %%
    %     RewardDelayMean = 0.015; 
    %     RewardDelayMax = 0.1;
    %     S.RewardDelay = -1;
    %     while 1
    %         if RewardDelayMin <= S.RewardDelay <= RewardDelayMax;
    %             break
    %         else
    %             S.RewardDelay = exprnd(RewardDelayMean);
    %         end
    %     end
    
    

        %% AJ - Bias Correction
        if S.GUI.biasMode && currentTrial > 1 && Outcomes(currentTrial - 1) == 0
            if (ismember(TrialTypes(currentTrial - 1), [1 3]) && S.GUI.biasMode == 1) || ...
                    (ismember(TrialTypes(currentTrial - 1), [2 4]) && S.GUI.biasMode == 2)
                TrialTypes(currentTrial) = TrialTypes(currentTrial - 1);
                TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial, TrialTypes, Outcomes);
            end  
        end
        %%
        switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
            % valid cue
            case 1 %target left, cue left
                TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                CueLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255)}; 
                CorrectCondition = {'Port1In', 'Reward'};
                IncorrectCondition = {'Port3In', 'PunishResponse'}; 
                RewardTime = LeftValveTime;
                RewardAction = {'ValveState', 1};
            case 2 % target right, cue right
                TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                CueLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255)}; 
                CorrectCondition = {'Port3In', 'Reward'};
                IncorrectCondition = {'Port1In', 'PunishResponse'}; 
                RewardTime = RightValveTime;
                RewardAction = {'ValveState', 4};
            % invalid cue                
            case 3 %target left, cue right
                TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                CueLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255)}; 
                CorrectCondition = {'Port1In', 'Reward'};
                IncorrectCondition = {'Port3In', 'PunishResponse'}; 
                RewardTime = LeftValveTime;
                RewardAction = {'ValveState', 1};
            case 4 % target right, cue left
                TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                CueLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255)}; 
                CorrectCondition = {'Port3In', 'Reward'};
                IncorrectCondition = {'Port1In', 'PunishResponse'}; 
                RewardTime = RightValveTime;
                RewardAction = {'ValveState', 4};                
        end 
        BaselineLight={'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity};


        sma = NewStateMatrix(); % Assemble state matrix
        sma = SetGlobalTimer(sma,1,S.GUI.Foreperiod); % pre cue  
        sma = SetGlobalTimer(sma,2,S.GUI.Cue); % pre cue  
        sma = SetGlobalTimer(sma,3,S.GUI.Trace); % pre cue  
        sma = SetGlobalTimer(sma,4,S.GUI.Graceperiod); % pre cue

        sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
            'Timer', 0,...
            'StateChangeConditions', {'Port2In', 'CenterPokeDetected'},...
            'OutputActions', BaselineLight); 
        sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
            'Timer', S.CenterPokeTime,...
            'StateChangeConditions', {'Tup', 'trigForeperiod', 'Port2Out', 'WaitForPoke'},...
            'OutputActions', BaselineLight);

        % add variable foreperiod betwen center poke and cue light in future????

        %% foreperiod block: each block implements a grace period for center poke and hold
        % trigger global timer defining foreperiod
        sma = AddState(sma, 'Name', 'trigForeperiod', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Foreperiod1'},...
            'OutputActions', {'GlobalTimerTrig', 1});
        % Foreperiod1: if poke out occurs trigger grace period, if poke in
        % occurs, skip to foreperiod2 to cancel grace period
        sma = AddState(sma, 'Name', 'Foreperiod1',...
            'Timer', 0,...
            'StateChangeCondtions', {'GlobalTimer1_End', 'trigCue', 'GlobalTimer4_End', 'Punish', 'Port2In', 'Foreperiod2', 'Port2Out', 'trigGrace_FP'},...
            'OutputActions', BaselineLight);
        sma = AddState(sma, 'Name', 'trigGrace_FP',...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Foreperiod1'},...
            'OutputActions', {'GlobalTimerTrig', 4});
        % Foreperiod2 is for when animal pokes back in, grace period timer is ignored here 
        sma = AddState(sma, 'Name', 'Foreperiod2',...
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer1_End', 'trigCue', 'Port2Out', 'trigGrace_FP'},...
            'OutputActions', BaselineLight);

        %% cue block
        % trigger global timer defining cue
        sma = AddState(sma, 'Name', 'trigCue', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 2});
        % cue1: poke outs trigger grace period, poke ins skip to cue2 to cancel grace period
        sma = AddState(sma, 'Name', 'Cue1',...
            'Timer', 0,...
            'StateChangeCondtions', {'GlobalTimer2_End', 'trigTrace', 'GlobalTimer4_End', 'Punish', 'Port2In', 'Cue2', 'Port2Out', 'trigGrace_Cue'},...
            'OutputActions', CueLight);
        sma = AddState(sma, 'Name', 'trigGrace_Cue',...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Cue1'},...
            'OutputActions', {'GlobalTimerTrig', 4});
        % cue2 is for when animal pokes back in, grace period timer is ignored here 
        sma = AddState(sma, 'Name', 'Cue2',...
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer2_End', 'trigTrace', 'Port2Out', 'trigGrace_Cue'},...
            'OutputActions', CueLight);
        %% trace block
        % trigger global timer defining trace
        sma = AddState(sma, 'Name', 'trigTrace', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Trace1'},...
            'OutputActions', {'GlobalTimerTrig', 3});
        % Trace1: poke outs trigger grace period, poke ins skip to Trace2 to cancel grace period
        sma = AddState(sma, 'Name', 'Trace1',...
            'Timer', 0,...
            'StateChangeCondtions', {'GlobalTimer3_End', 'Target', 'GlobalTimer4_End', 'Punish', 'Port2In', 'Trace2', 'Port2Out', 'trigGrace_Trace'},...
            'OutputActions', BaselineLight);
        sma = AddState(sma, 'Name', 'trigGrace_Trace',...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Trace1'},...
            'OutputActions', {'GlobalTimerTrig', 4});
        % Trace2 is for when animal pokes back in, grace period timer is ignored here 
        sma = AddState(sma, 'Name', 'Trace2',...
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer3_End', 'Target', 'Port2Out', 'trigGrace_Trace'},...
            'OutputActions', BaselineLight);
        %% Present Target and wait for response
        % target state assumed to be too short to enable the mouse to
        % respond (by moving from center to left or right port)
        sma = AddState(sma, 'Name', 'Target', ...
            'Timer', S.GUI.Target,...
            'StateChangeConditions', {'Tup', 'WaitForResponse'},...
            'OutputActions', TargetLight);    
        sma = AddState(sma, 'Name', 'WaitForResponse', ...
            'Timer', S.ResponseWindow, ...
            'StateChangeConditions', [{'Tup', 'ITI'}, CorrectCondition, IncorrectCondition], ...
            'OutputActions', BaselineLight);
        sma = AddState(sma, 'Name', 'Reward', ...
            'Timer', RewardTime,...
            'StateChangeConditions', {'Tup', 'Drinking'},...
            'OutputActions', [TargetLight RewardAction]);    
        sma = AddState(sma, 'Name', 'Drinking', ...
            'Timer', 0,...
            'StateChangeConditions', {'Port1Out', 'DrinkingGrace', 'Port3Out', 'DrinkingGrace'},...
            'OutputActions', TargetLight);
        sma = AddState(sma, 'Name', 'DrinkingGrace',...
            'Timer', S.DrinkingGrace,...
            'StateChangeConditions', {'Port1In', 'Drinking', 'Port3In', 'Drinking', 'Tup', 'exit'},...
            'OutputActions', TargetLight);
        sma = AddState(sma, 'Name', 'Punish', ...
            'Timer', S.GUI.Punish,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', [{'SoftCode', 1}, {'PWM2', 255}, BaselineLight]);        
% Extra time out but no white noise punish sound for incorrect responses
        sma = AddState(sma, 'Name', 'PunishResponse', ...
            'Timer', S.GUI.Punish,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', [{'PWM2', 255}, BaselineLight]);
        sma = AddState(sma, 'Name', 'ITI', ...
            'Timer', S.GUI.ITI,...
            'StateChangeConditions', {'Tup', 'exit'},...
            'OutputActions', [{'PWM2', 255}, BaselineLight]);

        SendStateMatrix(sma);
        RawEvents = RunStateMatrix; % RawEvents = the data from the trial
        
        
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
            BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
            BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
            % determine outcome
            if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Reward(1))
                Outcomes(currentTrial) = 1; % correct response
                TotalRewardDisplay('add', S.GUI.RewardAmount); % and updates it on each trial. 
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.PunishResponse(1))
                Outcomes(currentTrial) = 0; % incorrect response
            elseif ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.Punish(1))
                Outcomes(currentTrial) = -1; % early withdrawal
            else
                Outcomes(currentTrial) = 2; % did not choose              
            end
            % calculate total ITI
            if currentTrial == 1
                ITIs(1) = NaN;                
            else
                ITIs(currentTrial) = BpodSystem.Data.TrialStartTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial - 1);
            end
            BpodSystem.Data.TrialOutcomes(currentTrial) = Outcomes(currentTrial);
            BpodSystem.Data.ITIs(currentTrial) = ITIs(currentTrial);

            % update plots, update to reflect upcoming trial
            TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial + 1, TrialTypes, Outcomes);
            % update ITIs plot
            plot(BpodSystem.GUIHandles.ITIPlot, ITIs, 'o'); xlabel(BpodSystem.GUIHandles.ITIPlot,'trial #'); ylabel(BpodSystem.GUIHandles.ITIPlot,'ITI');            

            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            

        
            %% Code to increase waiting times in center port:
            if ~rem(currentTrial, S.GUI.delayAdjust_trialWindow)
                % if at least stepUpFraction trials are correct, increase
                % waiting times
                if sum(Outcomes(max(1, currentTrial - S.GUI.delayAdjust_trialWindow + 1):currentTrial) == 1)...
                        /S.GUI.delayAdjust_trialWindow >= S.GUI.delayAdjust_stepUpFraction
                    S.GUI.Foreperiod = min(S.GUI.Foreperiod + S.GUI.delayAdjust_increment, S.maxForeperiod);
                    S.GUI.Trace = min(S.GUI.Trace + S.GUI.delayAdjust_increment, S.maxTrace);
                    S.GUI.Cue = min(S.GUI.Cue + S.GUI.delayAdjust_increment, S.maxCue);
                % or else, if at least stepUpFraction trials are incorrect, decrease
                % waiting times                    
                elseif sum(Outcomes(max(1, currentTrial - S.GUI.delayAdjust_trialWindow + 1):currentTrial) == -1)...
                        /S.GUI.delayAdjust_trialWindow >= S.GUI.delayAdjust_stepDownFraction
                    S.GUI.Foreperiod = max(S.GUI.Foreperiod - S.GUI.delayAdjust_increment, S.minForeperiod);
                    S.GUI.Trace = max(S.GUI.Trace - S.GUI.delayAdjust_increment, S.minTrace);
                    S.GUI.Cue = max(S.GUI.Cue - S.GUI.delayAdjust_increment, S.minCue);                
                end
                sprintf('*** Trial %i, foreperiod = %.3f, cue = %.3f, trace = %.3f ***',...
                    currentTrial, S.GUI.Foreperiod, S.GUI.Cue, S.GUI.Trace)
            end
            % update foreperiod plot
            Foreperiods(currentTrial) = S.GUI.Foreperiod;
            plot(BpodSystem.GUIHandles.ForeperiodPlot, Foreperiods, 'o');
            xlabel(BpodSystem.GUIHandles.ForeperiodPlot,'trial #'); ylabel(BpodSystem.GUIHandles.ForeperiodPlot,'Foreperiod (s)');               
            %% Save protocol settings to reflect updated delay values
            BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
            SaveBpodProtocolSettings;
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end
    end
