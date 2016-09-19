%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

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
function SO_Training
% Cued outcome task
% Written by Tom Sikkens 5/2015.

global BpodSystem

%% Define parameters

S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    
    S.GUI.NumTrialTypes = 2;
    S.GUI.SinWaveFreq1 = 20000; %Hz
    S.GUI.SinWaveFreq2 = 4000;  %Hz
    
    S.NoLick = 1.5; %s
    S.ITI = 1; %ITI duration is set to be exponentially distributed later
    S.SoundDuration = 1; %s
    S.RewardValveCode = 2;
    S.RewardAmount = 5; %ul
    S.PunishValveCode = 4;
    S.PunishValveTime = 0.2; %s
    S.Delay = 0.5; %s
    S.RewardValveTime =  GetValveTimes(S.RewardAmount, S.RewardValveCode);
    S.DirectDelivery = 1; % 0 = 'no' 1 = 'yes'
end

% Initialize parameter GUI plugin
BpodParameterGUI('init', S);

%% Define trials

MaxTrials = 5000;
rng('shuffle')
TrialTypes = randi(S.GUI.NumTrialTypes,1,MaxTrials);
p = rand(1,MaxTrials);

UsOutcome = ones(size(TrialTypes));
UsOutcome(p <= 0.55 & TrialTypes == 2) = 0;
UsOutcome( p >= 0.9 & TrialTypes == 1) = 0;


BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.

%% Initialize plots

BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [400 400 1000 200],'Name','Outcome plot','numbertitle','off', 'MenuBar', 'none', 'Resize', 'off');
BpodSystem.GUIHandles.OutcomePlot = axes('Position', [.075 .3 .89 .6]);
OutcomePlot_Pavlov(BpodSystem.GUIHandles.OutcomePlot,'init',1-TrialTypes, UsOutcome);

%% Define stimuli and send to sound server

SF = 192000; % Sound card sampling rate
Sound1 = GenerateSineWave(SF, S.GUI.SinWaveFreq1, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)
Sound2 = GenerateSineWave(SF, S.GUI.SinWaveFreq2, S.SoundDuration); % Sampling freq (hz), Sine frequency (hz), duration (s)


PsychToolboxSoundServer('init')
PsychToolboxSoundServer('Load', 1, Sound1);
PsychToolboxSoundServer('Load', 2, Sound2);

BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

%% Main trial loop

for currentTrial = 1:MaxTrials
    
    switch UsOutcome(currentTrial)
        case 1
                StateChangeArgument1 = 'Reward';
                 
                if S.DirectDelivery == 1;
                    StateChangeArgument2 = 'Reward';
                else
                	StateChangeArgument2 = 'PostUS';
                end
                
        case 2
                StateChangeArgument1 = 'Punish';
                StateChangeArgument2 = 'Punish';
        case 0
                StateChangeArgument1 = 'PostUS';
                StateChangeArgument2 = 'PostUS';
    end
       
    S.ITI = 10;
    while S.ITI > 4
    S.ITI = exprnd(1)+1;
    end
    
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    sma = NewStateMatrix(); % Assemble state matrix
    sma = SetGlobalTimer(sma, 1, S.SoundDuration + S.Delay);
    sma = AddState(sma,'Name', 'NoLick', ...
        'Timer', S.NoLick,...
        'StateChangeConditions', {'Tup', 'ITI','Port2In','RestartNoLick'},...
        'OutputActions', {'PWM1', 255}); %Light On
    sma = AddState(sma,'Name', 'RestartNoLick', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'NoLick',},...
        'OutputActions', {'PWM1', 255}); %Light On
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer',S.ITI,...
        'StateChangeConditions', {'Tup', 'StartStimulus'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'StartStimulus', ...
        'Timer', 0.025,...
        'StateChangeConditions', {'Tup','DeliverStimulus'},...
        'OutputActions', {'SoftCode',TrialTypes(currentTrial)});
     sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', S.SoundDuration,...
        'StateChangeConditions', {'Port2In','WaitForUS','Tup','Delay'},...
        'OutputActions', {'GlobalTimerTrig',1});
    sma = AddState(sma, 'Name','Delay', ...
        'Timer', S.Delay,...
        'StateChangeConditions', {'Port2In','WaitForUS','Tup',StateChangeArgument2},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'WaitForUS', ...
        'Timer',3,...
        'StateChangeConditions', {'GlobalTimer1_End', StateChangeArgument1},...
        'OutputActions', {});
    sma = AddState(sma,'Name', 'Reward', ...
        'Timer',S.RewardValveTime,...
        'StateChangeConditions', {'Tup', 'PostUS'},...
        'OutputActions', {'ValveState', S.RewardValveCode});
    sma = AddState(sma, 'Name', 'Punish', ...
        'Timer',S.PunishValveTime, ...
        'StateChangeConditions', {'Tup', 'PostUS'}, ...
        'OutputActions', {'ValveState', S.PunishValveCode});
    sma = AddState(sma,'Name','PostUS',...
        'Timer',1,...
        'StateChangeConditions',{'Port2In','ResetDrinkingTimer','Tup','exit'},...
        'OutputActions',{});
    sma = AddState(sma,'Name','ResetDrinkingTimer',...
        'Timer',0,...
        'StateChangeConditions',{'Tup','PostUS'},...
        'OutputActions',{});
    SendStateMatrix(sma);
   
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        Outcomes = UpdateOutcomePlot(TrialTypes, BpodSystem.Data, UsOutcome);
        BpodSystem.Data.TrialOutcome(currentTrial) = Outcomes(currentTrial);
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    if BpodSystem.BeingUsed == 0
        return
        
    end 
   
end
end

%% sub-functions
function Outcomes = UpdateOutcomePlot(TrialTypes, Data, UsOutcome)
global BpodSystem
Outcomes = zeros(1,Data.nTrials);

for x = 1:Data.nTrials
    Lick = ~isnan(Data.RawEvents.Trial{x}.States.WaitForUS(1)) ;
    if ~isnan(Data.RawEvents.Trial{x}.States.Reward(1)) && Lick ==1
        Outcomes(x) = 1;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.Punish(1))&& Lick == 1
        Outcomes(x) = 0;
    elseif Lick ~= 1 && UsOutcome(x) == 1
        Outcomes(x) = 2;
    elseif ~isnan(Data.RawEvents.Trial{x}.States.Punish(1))
        Outcomes(x) = 4;
    elseif Lick == 1
        Outcomes(x) = 5;
    else 
        Outcomes(x) = 3;
    end
end
OutcomePlot_Pavlov(BpodSystem.GUIHandles.OutcomePlot,'update',Data.nTrials+1,1-TrialTypes,Outcomes, UsOutcome)
end


