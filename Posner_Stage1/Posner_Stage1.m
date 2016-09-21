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
function Posner_Stage1
% This protocol introduces a naive mouse to water available in ports 1 and 3. 

global BpodSystem

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; %ul
    S.GUI.PortOutRegDelay = 2; % How long the mouse must remain out before poking back in
    S.GUI.BaselineIntensity = 2.5;
    S.GUI.LightIntensity = 255;
    S.GUI.SessionStartDelay =1;
    S.GUI.WaitForPoke1=2;
    S.GUI.eitherSide = 1; % allow mouse to be rewarded for right and left pokes rather than randomly for either right or left poke (requires exploration if set to 0)
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

MaxTrials = 1000;

%% generate randomized trial types
TrialTypes = randi(2, 1, 1000); % 

    
Outcomes = []; % The trial type of each trial completed (equivalent to the outcome) will be added here
ITIs = []; % time in between trials


%% Initialize plots

BpodNotebook('init');

%%
outcomeFig = ensureFigure('Outcome_plot', 1);
outcomeAxis = subplot(2,1,1);
outcomeSpan = 20;
ITIsAxis = subplot(2,1,2);
xlabel('trial #'); ylabel('ITI');



%% This code initializes the Total Reward Display plugin, and updates it on each trial. 
TotalRewardDisplay('init');

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
  
    ValveOutputandRewardLight1 = {'ValveState', 1, 'PWM1', S.GUI.BaselineIntensity + S.GUI.LightIntensity};   
    ValveOutputandRewardLight3 = {'ValveState', 4, 'PWM3', S.GUI.BaselineIntensity + S.GUI.LightIntensity};
    
    if S.GUI.eitherSide
        StateOnLeftPoke = 'LeftReward'; 
        StateOnRightPoke = 'RightReward';
    elseif TrialTypes(currentTrial) == 1
        StateOnLeftPoke = 'LeftReward'; 
        StateOnRightPoke = 'WaitForPoke';        
    else
        StateOnLeftPoke = 'WaitForPoke'; 
        StateOnRightPoke = 'RightReward';        
    end
            
    BaselineLight={'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity};            

    sma = NewStateMatrix(); % Assemble state matrix    
    sma = AddState(sma, 'Name', 'WaitForPoke', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', StateOnLeftPoke, 'Port3In', StateOnRightPoke},...
        'OutputActions', BaselineLight);
    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'DrinkingLeft'},...
        'OutputActions', ValveOutputandRewardLight1); 
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'DrinkingRight'},...
        'OutputActions', ValveOutputandRewardLight3); 
    sma = AddState(sma, 'Name', 'DrinkingLeft', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1Out', 'ConfirmPortOutLeft'},...
        'OutputActions', ValveOutputandRewardLight1);
    sma = AddState(sma, 'Name', 'ConfirmPortOutLeft', ... 
        'Timer', S.GUI.PortOutRegDelay,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1In', 'DrinkingLeft'},...
        'OutputActions', ValveOutputandRewardLight1);
    sma = AddState(sma, 'Name', 'DrinkingRight', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit', 'Port3Out', 'ConfirmPortOutRight'},...
        'OutputActions', ValveOutputandRewardLight3);
    sma = AddState(sma, 'Name', 'ConfirmPortOutRight', ... 
        'Timer', S.GUI.PortOutRegDelay,...
        'StateChangeConditions', {'Tup', 'exit', 'Port3In', 'Drinking'},...
        'OutputActions', ValveOutputandRewardLight3);
    
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.LeftReward(1))
            Outcomes(currentTrial) = 1; %Left
        else
            Outcomes(currentTrial) = 2; %Right
        end
        
        if currentTrial == 1
            ITIs(1) = NaN;
        else
            ITIs(currentTrial) = BpodSystem.Data.TrialStartTimestamp(currentTrial) - BpodSystem.Data.TrialStartTimestamp(currentTrial - 1);
        end
        
        % update outcome plot 
        plot(outcomeAxis, Outcomes, 'o');
        set(outcomeAxis, 'XLim', [max(0, currentTrial - outcomeSpan) min(MaxTrials, currentTrial)]);
        
        % update ITIs plot
        plot(ITIsAxis, ITIs, 'o');

        
        
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.Outcomes = Outcomes; % Adds the trial type of the current trial to data
        BpodSystem.Data.ITIs = ITIs;
        

        TotalRewardDisplay('add', RewardAmount); % you can't comlete a trial without achieving a reward (if you are a mouse!)
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
end






