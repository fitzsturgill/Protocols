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
        

