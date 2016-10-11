function Posner_Stage2
    %note during training, there is no distinction between invalid/valid trials
    %because the "cue light" is a pre-emptive, bidirectional flash (i.e. dim
    %flash appears on both the right and left side prior to the appearance of
    %the target light)

    global BpodSystem
    
    S = BpodSystem.ProtocolSettings;
    
    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.RewardAmount = 5; %ul
        S.GUI.Punish = 6; % How long the mouse must wait in the goal port for reward to be delivered

        S.GUI.BaselineIntensity = 2.5;    
        S.GUI.CueLightIntensity = 2.5; % value added to baseline intensity to determine cue light intensity
        S.GUI.TargetLightIntensity = 255; %Set target light intensity

        S.GUI.Foreperiod = 0.4; %0.02
        S.GUI.Trace = 0.4; % 0.02 How long the mouse must poke in the center to activate the goal port
        S.GUI.Cue = 0.4; % 0.02
        S.GUI.Graceperiod = 0.3; %0.05

        S.GUI.ITI = 2;
        S.GUI.windowIncrement = 3;

        S.DrinkingGrace = 0.25; 
        S.TargetLightOn = 100;
        S.maxForeperiod = 100;
        S.maxTrace = 100;
        S.maxCue = 100;
        S.CenterPokeTime = 0.05; % WHAT VALUE TO USE HERE????????????
    end    

    % Initialize parameter GUI plugin
    BpodParameterGUI('init', S);

    %% initialize trial types and outcomes
    
    MaxTrials = 1000;    
    % generate randomized trial types
    TrialTypes = randi(2, 1, 1000); 
    Outcomes = NaN(1, MaxTrials); % NaN: future trial, -1: early withdrawal, 1: correct withdrawal
    ITIs = []; % time in between trials
    
    BpodSystem.Data.TrialTypes= []; % The type of each trial completed will be deposited here
    BpodSystem.Data.TrialOutcomes = []; % ditto for outcomes
    BpodSystem.Data.ITIs = [];
    

    %% Initialize plots
    trialsToShow = 50;
    BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
    BpodSystem.GUIHandles.OutcomePlot = subplot(2,1,1);
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',TrialTypes, 'ntrials', trialsToShow);
    BpodSystem.GUIHandles.ITIPlot = subplot(2,1,2);
    BpodNotebook('init');



    %% This code initializes the Total Reward Display plugin, 
    TotalRewardDisplay('init');


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
%         S.GUI.foreperiod = S.foreperiod;    
%         S.GUI.CueDelay = S.CueDelay;
%         S.GUI.LightOn = S.LightOn;
        S = BpodParameterGUI('sync', S); % BpodParemeterGUI can sync in either direction (apparently from the documentation)

        R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts

    %     %% Suelynn: generate exponentially distributed reward delay but bounded by min and max specified values    
    %     RewardDelayMin = 0;
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

        %% 

        switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
            case 1 %cuetarget match left
                TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                RewardTime = LeftValveTime;
                RewardAction = {'ValveState', 1};

            case 2 %cuetarget match right
                TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', min(S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity, 255)}; 
                RewardTime = RightValveTime;
                RewardAction = {'ValveState', 4};
        end
        CueLight = {'PWM1', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255), 'PWM3', min(S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 255)};    
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
            'StateChangeCondtions', {'GlobalTimer3_End', 'Reward', 'GlobalTimer4_End', 'Punish', 'Port2In', 'Trace2', 'Port2Out', 'trigGrace_Trace'},...
            'OutputActions', BaselineLight);
        sma = AddState(sma, 'Name', 'trigGrace_Trace',...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'Trace1'},...
            'OutputActions', {'GlobalTimerTrig', 4});
        % Trace2 is for when animal pokes back in, grace period timer is ignored here 
        sma = AddState(sma, 'Name', 'Trace2',...
            'Timer', 0,...
            'StateChangeConditions', {'GlobalTimer3_End', 'Reward', 'Port2Out', 'trigGrace_Trace'},...
            'OutputActions', BaselineLight);
        %% reward delivered noncontingently, target light remains on until reward is collected
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
                Outcomes(currentTrial) = 1; % correct withdrawal
            else
                Outcomes(currentTrial) = -1; % early withdrawal
            end
            % calculate total ITI
            if currentTrial == 1
                ITIs(1) = NaN;                
            else
                ITIs(currentTrial) = BpodSystem.Data.TrialStartTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial - 1);
            end
            BpodSystem.Data.TrialOutcomes(currentTrial) = Outcomes(currentTrial);
            BpodSystem.Data.ITIs(currentTrial) = ITIs(currentTrial);

            % update plots
            TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial, TrialTypes, Outcomes);
            % update ITIs plot
            plot(BpodSystem.GUIHandles.ITIPlot, ITIs, 'o'); xlabel(BpodSystem.GUIHandles.ITIPlot,'trial #'); ylabel(BpodSystem.GUIHandles.ITIPlot,'ITI');            
            TotalRewardDisplay('add', S.GUI.RewardAmount); % and updates it on each trial. 
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            
            % still need code to update waiting times, right now this is
            % done manually
        end
        
%         %% Code to increase waiting times in center port: Every x trials mouse gets correct, 
%         %the foreperiods increase by 1 ms. Incorrect trials result in a 0.5 ms decrease. 
% 
%         for x = 1:BpodSystem.Data.nTrials
%             if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Drinking(1))
%                 DrinkingState(x) = 1;
%             else
%                 DrinkingState(x) = 0;
%             end
%         end
% 
%         %%
%         if numel(DrinkingState) == 1 % initialize on trial # 1
%             cR = 0; % cR = number of consecutive responses correct (i.e. no early withdrawals)
%         end
%         windowIncrement = S.GUI.windowIncrement;
%         if DrinkingState(end) == 1
%             cR = cR + 1;
%         else DrinkingState(end)
%             cR = 0;
%             S.foreperiod = min(S.foreperiod - 0.0005, S.maxForeperiod);
%             S.CueDelay = min(S.CueDelay - 0.0005, S.maxCueDelay);
%             S.LightOn = min(S.LightOn - 0.0005, S.maxLightOn);
%         end
%         if cR == windowIncrement
%             cR = 0;
%             S.foreperiod = min(S.foreperiod + 0.001, S.maxForeperiod);
%             S.CueDelay = min(S.CueDelay + 0.001, S.maxCueDelay);
%             S.LightOn = min(S.LightOn + 0.001, S.maxLightOn);
%         end
%     %     end
%         disp(['*** Trial ' num2str(x) ' cuedelay is ' num2str(S.CueDelay)]);            
%     %%
%         HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
%         if BpodSystem.BeingUsed == 0
%             return
%         end
    end
