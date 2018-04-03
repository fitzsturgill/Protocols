function blocks = pav_rev_blocks_noPunish

blocks = {};

%% block 1 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = repmat(1, 3, 1); % fluff
ST.P = [0.9 * 0.9; 0.9 * 0.1; 0.1];
ST.CS = [1; 1; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0];
ST.US = {'Reward'; 'Neutral'; 'Reward'};   % Reward
ST.Instrumental = [0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
        


%% Blocks 2 & 3: CS+ pReward = 0.8,   CS- pReward = 0.3 

%% block 2 (initial contingency, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = repmat(2, 6, 1); % fluff
ST.P = [0.80 * 0.5 * 0.9; 0.20 * 0.5 * 0.9; 0.30 * 0.5 * 0.9; 0.70 * 0.5 * 0.9; 0.05; 0.05];
ST.CS = [1; 1; 2; 2; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 3 (reversed, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = repmat(3, 6, 1); % fluff
ST.P = [0.80 * 0.5 * 0.9; 0.20 * 0.5 * 0.9; 0.30 * 0.5 * 0.9; 0.70 * 0.5 * 0.9; 0.05; 0.05];
ST.CS = [2; 2; 1; 1; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% Blocks 4 & 5: CS+ pReward = 0.8,   CS- pReward = 0.15 

%% block 4 (initial contingency, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = repmat(4, 6, 1); % fluff
ST.P = [0.8 * 0.5 * 0.9; 0.20 * 0.5 * 0.9; 0.15 * 0.5 * 0.9; 0.85 * 0.5 * 0.9; 0.05; 0.05];
ST.CS = [1; 1; 2; 2; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 5 (reversed, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = repmat(5, 6, 1); % fluff
ST.P = [0.80 * 0.5 * 0.9; 0.20 * 0.5 * 0.9; 0.30 * 0.5 * 0.9; 0.70 * 0.5 * 0.9; 0.05; 0.05];
ST.CS = [2; 2; 1; 1; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

