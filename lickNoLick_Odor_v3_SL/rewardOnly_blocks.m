function blocks = rewardOnly_blocks
blocks = {};

%% block 1 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = [1; 1]; % fluff
ST.P = [0.5; 0.5];
ST.CS = [1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1];
ST.US = {'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;