function blocks = pavlovian_reversals_blocks

blocks = {};

%% block 1
S = struct(); ST = struct();
ST.BlockNumber = 1; % fluff
ST.P = 1;
ST.CS = 1; % will be used to select S.GUI.Odor1Valve
ST.CSValence = 1;
ST.US = {'Reward'};   % Reward
ST.Instrumental = 0;
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
        


%% block 2 (initial contingency, manual control)
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2]; % fluff
ST.P = [0.4; 0.1; 0.4; 0.1];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 3 (reversed, manual control)
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.4; 0.1; 0.4; 0.1];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 4 (initial contingency, adaptive control)
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4]; % fluff
ST.P = [0.4; 0.1; 0.4; 0.1];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 5;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

%% block 5 (reversed contingency, adaptive control)
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5]; % fluff
ST.P = [0.4; 0.1; 0.4; 0.1];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 4;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;