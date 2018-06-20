function blocks = expected_uncertainty_v3_SL

blocks = {};

% %% block 1 odor 1- pReward = 1, odor 2- pReward = 0.5, odor 3- pReward = 0
% S = struct(); ST = struct();
% ST.BlockNumber = [1; 1; 1; 1; 1; 1; 1]; % fluff
% ST.P = [1 * 0.3; 0 * 0.3; 0.5 * 0.3; 0.5 * 0.3; 0 * 0.3; 1 * 0.3; 0.1];
% ST.CS = [1; 1; 2; 2; 3; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; 1; 1; 1; 1; 0];
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;

%% block 1 RewardAmount = 10, odor 1- pReward = 0.8, odor 2- pReward = 0.5, odor 3- pReward = 0.2
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1; 1; 1; 1]; % fluff
ST.P = [0.8 * 0.3; 0.2 * 0.3; 0.5 * 0.4; 0.5 * 0.4; 0.2 * 0.3; 0.8 * 0.3];
ST.CS = [1; 1; 2; 2; 3; 3]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 1; 1; 1; 1];
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 2 odor 1- pPunish = 1, odor 2- pPunish = 0.5, odor 3- pPunish = 0
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2; 2; 2; 2]; % fluff
ST.P = [1 * 0.3; 0 * 0.3; 0.5 * 0.3; 0.5 * 0.3; 0 * 0.3; 1 * 0.3; 0.1];
ST.CS = [1; 1; 2; 2; 3; 3; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 1; 1; 1; 1; 0];
ST.US = {'Punish'; 'Neutral'; 'Punish'; 'Neutral'; 'Punish'; 'Neutral'; 'Punish'};   % Punish
ST.Instrumental = [0; 0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
%% block 3 odor 4- RewardAmount = 8, odor 5- RewardAmount = 5, odor 6- RewardAmount = 2
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.3; 0.3; 0.3; 0.1];
ST.CS = [1; 2; 3; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 1; 1];
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Reward'};   % Reward
ST.WaterAmount = {8; 5; 2; 8};
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;