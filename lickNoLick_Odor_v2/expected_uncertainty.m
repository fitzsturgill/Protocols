function blocks = expected_uncertainty

blocks = {};

%% block 1 odor 1- pReward = 0.75, odor 2- pReward = 0.5, odor 3- pReward = 0.25
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1; 1; 1; 1; 1]; % fluff
ST.P = [0.75 * 0.3; 0.25 * 0.3; 0.5 * 0.3; 0.5 * 0.3; 0.25 * 0.3; 0.75 * 0.3; 0.1];
ST.CS = [1; 1; 2; 2; 3; 3; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 1; 1; 1; 1; 0];
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;