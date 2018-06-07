function blocks = reward_only_reverse

blocks = {};

%% block 1, pavlovian
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1; 1]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 2, pavlovian reversed
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 3, mixed pavlovian/instrumental
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;




%% block 4, mixed pavlovian/instrumental, reversed
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

%% block 5, instrumental
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 6, instrumental reversed
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 7, instrumental, adaptive
S = struct(); ST = struct();
ST.BlockNumber = [7; 7; 7; 7]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 8;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

%% block 8, instrumental, adaptive, reversed
S = struct(); ST = struct();
ST.BlockNumber = [8; 8; 8; 8]; % fluff
ST.P = [0.4; 0.1; 0.1; 0.4];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 7;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;