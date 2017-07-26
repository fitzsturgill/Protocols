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
function PhotoStim_multi
% PhotoStim w/ multiple frequencies for optogenetic tagging

global BpodSystem
PulsePal('COM5');

%% Define parameters
S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

MaxTrials = 160;
% TrialTypes=repmat([1 2 3 4 5],1,ceil(MaxTrials/5));
TrialTypes = repmat([2], 1, MaxTrials); % kludge to just do 10 hz stimulation
BpodSystem.Data.TrialTypes = []; % The trial type of each trial completed will be added here.
BpodSystem.Data.PulsePalProgram = {}; % the pulse pal program used will be deposited here


%% Main trial loop
for currentTrial = 1:MaxTrials
    switch TrialTypes(currentTrial) % Determine trial-specific state matrix fields
        case 1
           load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'LightTrain_5hz_1ms.mat'));
           BpodSystem.Data.PulsePalProgram{currentTrial} = 'LightTrain_5hz_1ms';
        case 2
           load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'LightTrain_10hz_1ms.mat'));   
           BpodSystem.Data.PulsePalProgram{currentTrial} = 'LightTrain_10hz_1ms';           
        case 3
           load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'LightTrain_20hz_1ms.mat')); 
           BpodSystem.Data.PulsePalProgram{currentTrial} = 'LightTrain_20hz_1ms';           
        case 4
           load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'LightTrain_40hz_1ms.mat'));      
           BpodSystem.Data.PulsePalProgram{currentTrial} = 'LightTrain_40hz_1ms';           
        case 5
           load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'LightTrain_80hz_1ms.mat'));
           BpodSystem.Data.PulsePalProgram{currentTrial} = 'LightTrain_80hz_1ms';           
    end

%     load(fullfile(BpodSystem.BpodUserPath, 'Protocols', 'PhotoStim_multi', 'test.mat'));
    disp(['*** Trial # ' num2str(currentTrial) ' Program: ' BpodSystem.Data.PulsePalProgram{currentTrial} ' ***']);
%     disp(['*** Trial # ' num2str(currentTrial)]);
    ProgramPulsePal(ParameterMatrix);
    
   % S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    
    sma = NewStateMatrix(); % Assemble state matrix  
    sma = AddState(sma, 'Name', 'Start', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'DeliverStimulus'},...
        'OutputActions', {});
    sma = AddState(sma, 'Name', 'DeliverStimulus', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', BpodSystem.Data.PulsePalProgram{currentTrial}},...
        'OutputActions', {});
%     sma = AddState(sma, 'Name', 'DeliverStimulus', ...
%         'Timer', 0,...
%         'StateChangeConditions', {'Tup', 'test'},...
%         'OutputActions', {});
%     sma = AddState(sma, 'Name', 'test', ... % individual states for neurlynx syncing purposes (unique 
%         'Timer', 0,...
%         'StateChangeConditions', {'Tup', 'ITI'},...
%         'OutputActions', {'BNCState',2});
    sma = AddState(sma, 'Name', 'LightTrain_5hz_1ms', ... % individual states for neurlynx syncing purposes (unique 
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',2});
    sma = AddState(sma, 'Name', 'LightTrain_10hz_1ms', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',2});
    sma = AddState(sma, 'Name', 'LightTrain_20hz_1ms', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',2});
    sma = AddState(sma, 'Name', 'LightTrain_40hz_1ms', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',2});
    sma = AddState(sma, 'Name', 'LightTrain_80hz_1ms', ...
        'Timer', 0,...
        'StateChangeConditions', {'Tup', 'ITI'},...
        'OutputActions', {'BNCState',2});    
    sma = AddState(sma, 'Name', 'ITI', ...
        'Timer', 10,...
        'StateChangeConditions', {'Tup', 'exit'},...
        'OutputActions', {}); 
    
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;

    if ~isempty(fieldnames(RawEvents)) % If trial data was returned
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data
        % BpodSystem.Data = BpodNotebook(BpodSystem.Data); % Sync with Bpod notebook plugin
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        BpodSystem.Data.TrialTypes(currentTrial) = TrialTypes(currentTrial); % Adds the trial type of the current trial to data
        SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
    end
    
    if BpodSystem.BeingUsed == 0
        RunProtocol('Stop');
        return
    end
    
    % close the procotol
    if currentTrial == MaxTrials
        RunProtocol('Stop');
        return
    end
    
end
