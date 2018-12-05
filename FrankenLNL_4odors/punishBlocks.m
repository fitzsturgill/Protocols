function blocks = punishBlocks

blocks = {};

%% block 1 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1]; % fluff
ST.P = [0.8 * 0.8; 0.8 * 0.2; 0.2];
ST.CS1 = [0; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [1; 1; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Punish'; 'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;



%% block 2 (TinyPuff)
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2]; % fluff
ST.P = [0.8 * 0.8; 0.8 * 0.2; 0.2];
ST.CS1 = [0; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [-1; -1; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Punish'; 'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;


%% block 3 (TinyPuff baseline avoidance with Punish)
S = struct(); ST = struct();
ST.BlockNumber = [3; 3]; % fluff
ST.P = [0.5; 0.5];
ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [-1; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
        
%% block 4 (TinyTone baseline avoidance with Punish)
S = struct(); ST = struct();
ST.BlockNumber = [4; 4]; % fluff
ST.P = [0.5; 0.5];
ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [1; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
%% block 5 (TinyTone instead of TinyPuff)
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5]; % fluff
ST.P = [0.8 * 0.8; 0.8 * 0.2; 0.2];
ST.CS1 = [0; 0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [5; 5; 0]; % CS 5 indicates tone instead of TinyPuff
ST.US = {'Punish'; 'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 6 (what do)
S = struct(); ST = struct();
ST.BlockNumber = [6; 6]; % fluff
ST.P = [0.8; 0.2];
ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [5; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Neutral'; 'Punish'}; % is it rewarded?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
        



