%{
----------------------------------------------------------------------------
This file is part of the Sanworks Bpod repository
Copyright (C) 2016 Sanworks LLC, Sound Beach, New York, USA
----------------------------------------------------------------------------
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.
This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}



function PosnerTraining_pokeAndHold
% Posner_V8 modified for training. CueLight appears on both the right and
% left port. Target light gives directionality and noncontingent reward. 
global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings;
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; %ul
    S.GUI.Punish = 6; % How long the mouse must wait in the goal port for reward to be delivered
    
    S.GUI.CueLightIntensity = 2.5; %Set Cue light intensity;
    S.GUI.TargetLightIntensity = 255; %Set target light intensity
    
    S.GUI.BaselineIntensity=2.5;
    S.GUI.foreperiod = 0.08;
    S.GUI.CueDelay = 0.05; % How long the mouse must poke in the center to activate the goal port
    S.GUI.CueDelayMin=0.005; 
    S.GUI.LightOn=0.05;
    
    S.GUI.RealITI = 3;
    
  
     
%% Suelynn: Note you Can define variables in settings without linking them to the GUI:
%% Useful for variables you want to save in the settings but aren't likely to change on the fly (keeps GUI uncluttered)
    S.DrinkingGrace = 0.25; 
    S.TargetLightOn = 100;
    S.maxForeperiod = 100;
    S.maxCueDelay = 100;
    S.maxLightOn = 100;
    S.foreperiod = S.GUI.foreperiod;    
    S.CueDelay = S.GUI.CueDelay;
    S.LightOn=S.GUI.LightOn;    
end

%takes settings from previous session, if field does not exist in previous
%session, keeps default values defined above
% prompt='Load Session Settings (Y=1/N=2)? ';
% x=input(prompt);
% if x==1
%     session = bpLoadSession;
%     GUIparameters=sort(fieldnames(S.GUI));
%     SessionParameters=sort(fieldnames(session.SessionData.TrialSettings(end).GUI));
%    
%     
%     %if the field exists, replace the default settings with session speciic settings, 
%     %otherwise, it's a new field that's been added to the main protocol
%     DoesThisFieldExist= ismember(GUIparameters, SessionParameters);
%     for i=1:numel(fieldnames(S.GUI))
%         if DoesThisFieldExist(i) == 1 
%                 S.GUI.(GUIparameters{i})=session.SessionData.TrialSettings(end).GUI.(SessionParameters{i});
%         end
%     end
% end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%% Define trials-Trial types tranformed via iterative process  
%note during training, there is no distinction between invalid/valid trials
%because the "cue light" is a pre-emptive, bidirectional flash (i.e. dim
%flash appears on both the right and left side prior to the appearance of
%the target light)

MaxTrials = 1000;

TrialTypes=rand(1,1000);
Transf=zeros(size(TrialTypes));
for ii = 1:length(TrialTypes)
    if TrialTypes(ii) < 0.35; %t/rial type 1 occurs 35%
        Transf(ii)= 1;
    elseif TrialTypes(ii) <0.7; %trial type 2 occurs 35%
        Transf(ii)=2;
    elseif TrialTypes (ii) <0.85; %trial type 15%
        Transf(ii)=3;
    else %trial type 4 15%
        Transf(ii)=4;
    end
end
    
BpodSystem.Data.Transf= []; % The trial type of each trial completed will be added here


%% Initialize plots
BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'init',Transf);
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
    
    %% Suelynn: generate exponentialy distributed reward delay but bounded by min and max specified values    
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
    
    CueDelayMean = S.GUI.CueDelay; %exponential intertrial interval (foreperiod)
    
    CueDelayMax = CueDelayMean*3; % Cue delay mean, 50ms, range 5-150ms
    S.CueDelay = CueDelayMax;

    while S.CueDelay >= CueDelayMax;

        S.CueDelay = exprnd(CueDelayMean)+S.GUI.CueDelayMin;
    end
    
    ForeperiodMean = S.GUI.foreperiod; %exponential intertrial interval (foreperiod)
    
    ForeperiodMax = ForeperiodMean*3;

    S.foreperiod = ForeperiodMax;

    if S.foreperiod >= ForeperiodMax;
        S.foreperiod = min(exprnd(ForeperiodMean) + 0.05, ForeperiodMax); %min foreperiod, 50ms, range 50-160

    end
   
%%        
   switch Transf(currentTrial) % Determine trial-specific state matrix fields
        case 1 %cuetarget match left
            CueLight = {'PWM3', S.GUI.BaselineIntensity, 'PWM1', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity};
            TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            DrinkingReward = 'Port1Out'; 
            LeftPokeAction = 'LeftRewardDelay';
            RightPokeAction = 'Punish';  
        case 2 %cuetarget match right
            CueLight = {'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity}; 
            TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            DrinkingReward = 'Port3Out';
            LeftPokeAction = 'Punish';
            RightPokeAction = 'RightRewardDelay'; 
       case 3
            CueLight = {'PWM3', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 'PWM1', S.GUI.BaselineIntensity};
            TargetLight = {'PWM3', S.GUI.BaselineIntensity,'PWM1', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            DrinkingReward = 'Port1Out'; 
            LeftPokeAction = 'LeftRewardDelay';
            RightPokeAction = 'Punish';  
       case 4
            CueLight = {'PWM1', S.GUI.BaselineIntensity+S.GUI.CueLightIntensity, 'PWM3', S.GUI.BaselineIntensity}; 
            TargetLight = {'PWM1', S.GUI.BaselineIntensity,'PWM3', S.GUI.BaselineIntensity+S.GUI.TargetLightIntensity}; 
            DrinkingReward = 'Port3Out';
            LeftPokeAction = 'Punish';
            RightPokeAction = 'RightRewardDelay'; 
   end
   
   BaselineLight={'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity};
    
    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = SetGlobalTimer(sma,1,S.CueDelay); % pre cue  
    sma = SetGlobalTimer(sma,2,S.LightOn); % cue period
    sma = SetGlobalTimer(sma,3,S.foreperiod); % post cue
    
    sma = AddState(sma, 'Name', 'WaitForPoke', ... %Wait for initiation
        'Timer', 0,...
        'StateChangeConditions', {'Port2In', 'CenterPokeDetected'},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'CenterPokeDetected', ... %purposeful center poke
        'Timer', 0.015,...
        'StateChangeConditions', {'Tup', 'WaitForCue', 'Port2Out', 'WaitForPoke'},...
        'OutputActions', BaselineLight);
    
    %% variable foreperiod betwen center poke and cue light
    sma = AddState(sma, 'Name', 'WaitForCue', ... %wait for the cue
        'Timer', S.CueDelay,...
        'StateChangeConditions', {'Port2Out', 'Grace', 'Tup','CueAndWait'},... %early response to cue light results in punishment 
        'OutputActions', BaselineLight);    
    

    %% Cue light comes on
    sma = AddState(sma, 'Name', 'CueAndWait', ... % don't need global timer here (because you don't have to confirm animal pokes back into port)
        'Timer', S.LightOn,... 
        'StateChangeConditions', {'Port2Out', 'PunishWithdrawal', 'Tup', 'Foreperiod'},... % punish without grace period for withdrawal since cue is short
        'OutputActions', CueLight);
    sma = AddState(sma, 'Name', 'Foreperiod', ... 
        'Timer', S.foreperiod,... 
        'StateChangeConditions', {'Port2Out', 'PunishWithdrawal', 'Tup', 'TargetLightOn'},... %early response to cue light results in punishment 
        'OutputActions', BaselineLight);
    sma = AddState(sma, 'Name', 'TargetLightOn', ... %Target light comes on 
        'Timer', S.LightOn,...
        'StateChangeConditions', {'Tup', 'WaitForResponse'},... % Non contingent reward
        'OutputActions', TargetLight);
    sma = AddState(sma, 'Name', 'WaitForResponse', ... %response time is set to after the target light comes on
        'Timer', 5,...
        'StateChangeConditions', {'Port1In', LeftPokeAction, 'Port3In', RightPokeAction, 'Tup', 'RealITI'},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'LeftRewardDelay', ...
        'Timer', S.RewardDelay,...
        'StateChangeConditions', {'Tup', 'LeftReward', 'Port1Out', 'CorrectEarlyWithdrawal'},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'RightRewardDelay', ...
        'Timer', S.RewardDelay,...
        'StateChangeConditions', {'Tup', 'RightReward', 'Port3Out', 'CorrectEarlyWithdrawal'},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', [BaselineLight, {'ValveState', 1}]); 
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', [BaselineLight, {'ValveState', 4}]); 
    %% good thinking below Suelynn!!!!
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 0,...
        'StateChangeConditions', {DrinkingReward, 'DrinkingGrace'},... %mouse cannot move onto a new trial without finding water in the correct port (i.e. H2O cant accumulate between trials)
        'OutputActions', BaselineLight);
    %%
    sma = AddState(sma, 'Name', 'DrinkingGrace', ...
        'Timer', S.DrinkingGrace,...
        'StateChangeConditions', {'Tup', 'RealITI', 'Port1In', 'Drinking', 'Port3In', 'Drinking'},...
        'OutputActions', BaselineLight);
        sma = AddState(sma, 'Name', 'Punish', ...
        'Timer', S.GUI.Punish,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', [{'SoftCode', 1}, {'PWM2', 255}]);
    sma = AddState(sma, 'Name', 'PunishWithdrawal', ...
        'Timer', S.GUI.Punish,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', [{'SoftCode', 1}, {'PWM2', 255}]);
    sma = AddState(sma, 'Name', 'RealITI', ...
        'Timer', S.GUI.RealITI,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions',  {'PWM2', 255});
    sma = AddState(sma, 'Name', 'CorrectEarlyWithdrawal', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup','RealITI'},...
        'OutputActions', {});
   
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;

        
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.Transf(currentTrial) = Transf(currentTrial); % Adds the trial type of the current trial to data        
        UpdateSideOutcomePlot(Transf, BpodSystem.Data);
        UpdateTotalRewardDisplay(S.GUI.RewardAmount, currentTrial); % and updates it on each trial. 
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        
        
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end

%     %% Code to increase waiting times in center port: Every x trials mouse gets correct, 
%     %the foreperiods increase by 1 ms. Incorrect trials result in a 0.5 ms decrease. 
%     
%     for x = 1:BpodSystem.Data.nTrials
%         if ~isnan(BpodSystem.Data.RawEvents.Trial{x}.States.Drinking(1))
%             DrinkingState(x) = 1;
%         else
%             DrinkingState(x) = 0;
%         end
%     end
%     
%     windowIncrement = S.GUI.windowIncrement;
%     if x == 1
%         window = 0;
%     end
%     if numel(DrinkingState)>=window
% %         if x == 3
% %             disp('wtf');
% %         end
%         DrinkingState(1:min(numel(DrinkingState), window)) = 0;
%         if sum(DrinkingState(max(numel(DrinkingState) - windowIncrement + 1, 1):end)) >= windowIncrement
%              S.foreperiod = min(S.foreperiod + 0.001, S.maxForeperiod);
%              S.CueDelay = min(S.CueDelay + 0.001, S.maxCueDelay);
%              S.LightOn = min(S.LightOn + 0.001, S.maxLightOn);
%              window=window+windowIncrement;
%         elseif DrinkingState(end)==0
%              S.foreperiod = min(S.foreperiod - 0.0005, S.maxForeperiod);
%              S.CueDelay = min(S.CueDelay - 0.0005, S.maxCueDelay);
%              S.LightOn = min(S.LightOn - 0.0005, S.maxLightOn);
%         end
%     end
%     disp(['*** Trial ' num2str(x) ' cuedelay is' num2str(S.CueDelay)]);
%     
% %     window=2;
% %     if numel(DrinkingState)>=window
% %         if sum(DrinkingState((end-(window - 1)):end)) >= window
% %              S.foreperiod = min(S.foreperiod + 0.001, S.maxForeperiod);
% %              S.CueDelay = min(S.CueDelay + 0.001, S.maxCueDelay);
% %              S.LightOn = min(S.LightOn + 0.001, S.maxLightOn);
% %              window=window+2;
% %         else
% %              S.foreperiod = min(S.foreperiod - 0.0005, S.maxForeperiod);
% %              S.CueDelay = min(S.CueDelay - 0.0005, S.maxCueDelay);
% %              S.LightOn = min(S.LightOn - 0.00, S.maxLightOn);
% %             
% %         end
% %     end    
%         
% %     if ~isnan(BpodSystem.Data.RawEvents.Trial{1,currentTrial}.States.Drinking(1))
% %          S.foreperiod = min(S.foreperiod + 0.001, S.maxForeperiod);
% %          S.CueDelay = min(S.CueDelay + 0.001, S.maxCueDelay);
% %          S.LightOn = min(S.LightOn + 0.001, S.maxLightOn);
% %     end
% 
%    
end
%%
function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
    global BpodSystem
    if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking(1))
        TotalRewardDisplay('add', RewardAmount);
    end

function UpdateSideOutcomePlot(Transf, Data)
    global BpodSystem
    Outcomes = zeros(1,BpodSystem.Data.nTrials); % earlywithdrawal = 0, set to zeros by default
    for x = 1:BpodSystem.Data.nTrials
        if ~isnan(Data.RawEvents.Trial{x}.States.Drinking(1))
            Outcomes(x) = 1;
        else
            Outcomes(x) = 0;
        end
    end
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,Transf,Outcomes)
    

