function blocks = instrumental_reversals_blocks2

blocks = {};

%% block 1
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
        
%% block 2
S = struct(); ST = struct();
ST.BlockNumber = [2; 2]; % fluff
ST.P = [0.8; 0.2];
ST.CS = [1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;




%% block 3
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 4, first reversal
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 5, continue first reversal
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 6, first re-reversal
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [0; 0; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 7, continue re-reversal, first contingency, adaptively link to block 8
S = struct(); ST = struct();
ST.BlockNumber = [7; 7; 7; 7]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 8;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

%% block 8, reversed contingency, adaptively link to block 7
S = struct(); ST = struct();
ST.BlockNumber = [8; 8; 8; 8]; % fluff
ST.P = [0.4; 0.1; 0.25; 0.25];
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'};   % Reward
ST.Instrumental = [1; 1; 1; 1];
S.Table = struct2table(ST);
S.LinkTo = 7;
S.LinkToFcn = 'blockSwitchFunction_responseRateDifference';

blocks{end + 1} = S;

