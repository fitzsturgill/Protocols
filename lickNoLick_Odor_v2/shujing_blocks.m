function blocks = shujing_blocks
blocks = {};


%% block 1 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1]; % fluff
ST.P = [0.9 * 0.9; 0.9 * 0.1; 0.1];
ST.CS = [1; 1; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0];
ST.US = {'Reward'; 'Neutral'; 'Reward'};   % Reward
ST.Instrumental = [0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;



%% block 2 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2; 2; 2]; % fluff
ST.P = [0.9 * 0.9 * 0.5; 0.9 * 0.1 * 0.5; 0.1 * 0.5; 0.9 * 0.9 * 0.5; 0.9 * 0.1 * 0.5; 0.1 * 0.5;];
ST.CS = [1; 1; 0; 2; 2; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0; -1; -1; 0;];
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Punish'; 'Neutral'; 'Punish'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;