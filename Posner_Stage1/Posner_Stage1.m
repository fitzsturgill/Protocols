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
    
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

MaxTrials = 1000;

%% generate randomized trial types
ra = rand(1,MaxTrials);
TrialTypes(ra < 0.5) = 1; %  50% of trials are type 1
TrialTypes(ra >= 0.5) = 2; % 50% of trials are type 2

    
BpodSystem.Data.TrialTypes= []; % The trial type of each trial completed will be added here


%% Initialize plots
% BpodSystem.ProtocolFigures.SideOutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
% BpodSystem.GUIHandles.SideOutcomePlot = axes('Position', [.075 .3 .89 .6]);
% SideOutcomePlot(BpodSystem.GUIHandles.SideOutcomePlot,'init');
BpodNotebook('init');

%%
outcomeFig = ensureFigure('Outcome_plot', 1);
scrsz = get(groot,'ScreenSize'); 
set(outcomeFig, 'Position', [25 scrsz(4)/2-150 scrsz(3)-50  scrsz(4)/6],'numbertitle','off', 'MenuBar', 'none'); %, 'Resize', 'off');    
outcomeAxes = axes('Parent', outcomeFig);
placeHolder = line([1 1], [0 2], 'Color', [0.8 0.8 0.8], 'LineWidth', 4, 'Parent', outcomeAxes);    
hold on;
outcomes = zeros(1, MaxTrials);
outcomesHandle = scatter(1:MaxTrials, outcomes);
outcomeSpan = 20;
set(outcomeAxes, 'XLim', [0 outcomeSpan]);
%% initialize trial outcome array


%% This code initializes the Total Reward Display plugin, and updates it on each trial. 
TotalRewardDisplay('init');
RewardAmount = S.GUI.RewardAmount;

%% Main trial loop
for currentTrial = 1:MaxTrials
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    R = GetValveTimes(S.GUI.RewardAmount, [1 3]); LeftValveTime = R(1); RightValveTime = R(2); % Update reward amounts
  
    ValveOutputandRewardLight1 = {'ValveState', 1, 'PWM1', S.GUI.BaselineIntensity + S.GUI.LightIntensity};   
    ValveOutputandRewardLight3 = {'ValveState', 4, 'PWM3', S.GUI.BaselineIntensity + S.GUI.LightIntensity};
    StateOnLeftPoke = 'LeftReward'; 
    StateOnRightPoke = 'RightReward';
            
    BaselineLight={'PWM1', S.GUI.BaselineIntensity, 'PWM3', S.GUI.BaselineIntensity};            

    sma = NewStateMatrix(); % Assemble state matrix
    
    sma = AddState(sma, 'Name', 'WaitForPoke1', ...
        'Timer', 0,...
        'StateChangeConditions', {'Port1In', StateOnLeftPoke, 'Port3In', StateOnRightPoke},...
        'OutputActions', BaselineLight); 
    sma = AddState(sma, 'Name', 'LeftReward', ...
        'Timer', LeftValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', ValveOutputandRewardLight1); 
    sma = AddState(sma, 'Name', 'RightReward', ...
        'Timer', RightValveTime,...
        'StateChangeConditions', {'Tup', 'Drinking'},...
        'OutputActions', ValveOutputandRewardLight3); 
    sma = AddState(sma, 'Name', 'Drinking', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1Out', 'ConfirmPortOut', 'Port3Out', 'ConfirmPortOut'},...
        'OutputActions', BaselineLight);
    sma = AddState(sma, 'Name', 'ConfirmPortOut', ... 
        'Timer', S.GUI.PortOutRegDelay,...
        'StateChangeConditions', {'Tup', 'exit', 'Port1In', 'Drinking', 'Port3In', 'Drinking'},...
        'OutputActions', BaselineLight);
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        if isfield(BpodSystem.Data.RawEvents.Trial{currentTrial}, 'Events')
            if isfield(BpodSystem.Data.RawEvents.Trial{end}.Events, 'Port1In')
                outcomes(currentTrial) = 1; %Left
            else
                outcomes(currentTrial) = 2; %Right
            end
        end
        
                % update outcome plot to reflect currently executed trial
        set(outcomeAxes, 'XLim', [max(0, currentTrial - round(outcomeSpan/2)) min(MaxTrials, currentTrial + round(outcomeSpan/2))]);
        set(placeHolder, 'XData', [currentTrial currentTrial]);
        set(outcomesHandle, 'YData', outcomes);
        
        
        BpodSystem.Data = BpodNotebook('sync', BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        %UpdateSideOutcomePlot(TrialTypes, BpodSystem.Data);
        UpdateTotalRewardDisplay(S.GUI.RewardAmount, currentTrial);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
end

function UpdateTotalRewardDisplay(RewardAmount, currentTrial)
global BpodSystem
if ~isnan(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Drinking(1))
    TotalRewardDisplay('add', RewardAmount);
end

function UpdateSideOutcomePlot(TrialTypes, Data)
global BpodSystem
Outcomes = zeros(1,BpodSystem.Data.nTrials);
for x = 1:BpodSystem.Data.nTrials
    if ~isnan(Data.RawEvents.Trial{x}.States.Drinking(1))
        Outcomes(x) = 1;
    else
        Outcomes(x) = 3;
    end

%TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot,'update',BpodSystem.Data.nTrials+1,TrialTypes,Outcomes)
end



