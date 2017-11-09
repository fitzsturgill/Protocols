function blocks = pavlovian_reversals_blocks

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
        


%% block 2 (initial contingency, manual control)
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2]; % fluff
ST.P = [0.45; 0.05; 0.25; 0.25];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 3 (reversed, manual control)
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.45; 0.05; 0.25; 0.25];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 4 (initial contingency, adaptive control)
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 5;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

%% block 5 (reversed contingency, adaptive control)
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 4;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

%% block 6 (initial contingency, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6; 6; 6]; % fluff
ST.P = [0.45 * 0.9; 0.05 * 0.9; 0.25 * 0.9; 0.25 * 0.9; 0.05; 0.05];
ST.CS = [1; 1; 2; 2; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 7 (reversed, manual control, with occasional uncued outcomes)
S = struct(); ST = struct();
ST.BlockNumber = [7; 7; 7; 7; 7; 7]; % fluff
ST.P = [0.45 * 0.9; 0.05 * 0.9; 0.25 * 0.9; 0.25 * 0.9; 0.05; 0.05];
ST.CS = [2; 2; 1; 1; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;


%% block 8 (initial contingency, manual control, plus novel CS+)
S = struct(); ST = struct();
ST.BlockNumber = [8; 8; 8; 8; 8; 8]; % fluff
ST.P = [1/3 * 0.8; 1/3 * 0.2; 1/3 * 0.5; 1/3 * 0.5; 1/3 * 0.8; 1/3 * 0.2];
ST.CS = [1; 1; 2; 2; 3; 3]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 1; 1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 9 (reversed, manual control, plus novel CS+)
S = struct(); ST = struct();
ST.BlockNumber = [9; 9; 9; 9; 9; 9]; % fluff
ST.P = [1/3 * 0.8; 1/3 * 0.2; 1/3 * 0.5; 1/3 * 0.5; 1/3 * 0.8; 1/3 * 0.2];
ST.CS = [2; 2; 1; 1; 3; 3]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1; 1; 1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
