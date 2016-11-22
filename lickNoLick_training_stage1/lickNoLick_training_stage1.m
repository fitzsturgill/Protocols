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
function lickNoLick_training_stage1
    % simple operant protocol in which mouse gets rewarded for licking when
    % "house light" tone is off

    global BpodSystem 
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S

    if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
        S.GUI.Reward = 5;
        S.GUI.RewardValveCode = 1;
        S.GUI.NoLick = 1.5;
        S.GUI.PostReward = 2;
        S.GUI.maxTrials = round(1000/S.GUI.Reward);
        S.RewardValveTime = [];
    end
    
    %% Initialize parameter GUI plugin
    BpodParameterGUI('init', S);
    

    BpodSystem.Data.Settings = S;

    
    %% Initialize Sound Stimuli
    SF = 192000; 
    
    % linear ramp of sound for 10ms at onset and offset
    neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 1, neutralTone);
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
    
    %% Generate white noise (I want to make this brown noise eventually)
    HouseLightSound = (rand(1,SF*.5)*2) - 1; %  2s punish sound
    PsychToolboxSoundServer('init')
    PsychToolboxSoundServer('Load', 2, HouseLightSound);
    % Set soft code handler to trigger sounds
    BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

%% init lick raster plot

    performance.fig = ensureFigure('performance', 1);
    performance.Timeout_ax = subplot(2,1,1);
    ylabel('timeout (s)');
    performance.Timeout_lh = plot(NaN);

    performance.ResponseTime_ax = subplot(2,1,2);
    ylabel('response latency (s)');
    performance.ResponseTime_lh = plot(NaN);
    
%% initialize ITIs and RTs to measure how efficiently mouse is obtaining reward
    BpodSystem.Data.Timeout = []; % time during which "house light" tone is turned on
    BpodSystem.Data.ResponseTime = []; % time from when "house light" tone is turned off to operant response (lick)




    %% Main trial loop
    for currentTrial = 1:S.GUI.maxTrials
        S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.GUI.RewardValveCode);

       
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin

        sma = NewStateMatrix(); % Assemble state matrix
        sma = AddState(sma,'Name', 'NoLick', ...
            'Timer', S.GUI.NoLick,...
            'StateChangeConditions', {'Tup', 'WaitForLick','Port1In','RestartNoLick'},...
            'OutputActions', {'SoftCode', 2}); % Sound on
        sma = AddState(sma,'Name', 'RestartNoLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick',},...
            'OutputActions', {}); % Sound on, to do    
        sma = AddState(sma, 'Name', 'WaitForLick', ... 
            'Timer', 0,...
            'StateChangeConditions', {'Port1In', 'Reward'},...
            'OutputActions', {});
        sma = AddState(sma,'Name', 'Reward', ...
            'Timer',S.RewardValveTime,... % time will be 0 for omission
            'StateChangeConditions', {'Tup', 'PostReward'},...
            'OutputActions', {'ValveState', S.GUI.RewardValveCode, 'SoftCode', 1}); % trigger neutral tone
        sma = AddState(sma, 'Name','PostReward',...
            'Timer', S.GUI.PostReward,... %
            'StateChangeConditions',{'Tup','exit'},...
            'OutputActions',{});


        %%
        BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)
        SendStateMatrix(sma);



        % Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!



        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % Computes trial events from raw data            
            TotalRewardDisplay('add', S.GUI.Reward);
            % calculate timeout and response time
            BpodSystem.Data.ResponseTime(end + 1) = diff(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForLick); 
            BpodSystem.Data.Timeout(end + 1) =...
            BpodSystem.Data.RawEvents.Trial{currentTrial}.States.WaitForLick(1)...        
                - BpodSystem.Data.TrialStartTimestamp(currentTrial);
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
            % update figures
            performance.Timeout_lh.YData = smooth(BpodSystem.Data.Timeout);
            performance.ResponseTime_lh.YData = smooth(BpodSystem.Data.ResponseTime);            
        end
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            return
        end 
    end
end

