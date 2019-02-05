function blocks = rewardPunishBlocks

blocks = {};



%% block 1, tone accompanies 
S = struct(); ST = struct();
ST.BlockNumber = repmat(1, 7, 1); % fluff
ST.P = [...
    1/3*0.8;...
    1/3*0.2;...
    1/3*0.8;...
    1/3*0.2;...
    1/3*0.45;...
    1/3*0.45;...
    1/3 * 0.1;...
    ];
ST.CS1 = [0; 0; 0; 0; 0; 0; 0;]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [1; 1; 2; 2; 0; 0; 0;]; % will be used to select S.GUI.Odor2Valve
ST.CS1_tone = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_tone = [1; 1; 0; 0; 0; 0; 0;];
ST.CS1_light = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_light = [0; 0; 10; 10; 0; 0; 0;];
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'; 'Neutral'};   % is it Rewarded ?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 2, no tone or light, reward only (first stage of training)
S = struct(); ST = struct();
ST.BlockNumber = repmat(2, 7, 1); % fluff
ST.P = [...
    0.7*0.8;...
    0.7*0.2;...
    0;...
    0;...
    0.2;...
    0;...
    0.1;...
    ];
ST.CS1 = [0; 0; 0; 0; 0; 0; 0;]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [1; 1; 2; 2; 0; 0; 0;]; % will be used to select S.GUI.Odor2Valve
ST.CS1_tone = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_tone = [0; 0; 0; 0; 0; 0; 0;];
ST.CS1_light = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_light = [0; 0; 0; 0; 0; 0; 0;];
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'; 'Neutral'};   % is it Rewarded ?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 3, no tone or light, reward and punish (second stage of training)
S = struct(); ST = struct();
ST.BlockNumber = repmat(3, 7, 1); % fluff
ST.P = [...
    1/3*0.8;...
    1/3*0.2;...
    1/3*0.8;...
    1/3*0.2;...
    1/3*0.45;...
    1/3*0.45;...
    1/3 * 0.1;...
    ];
ST.CS1 = [0; 0; 0; 0; 0; 0; 0;]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [1; 1; 2; 2; 0; 0; 0;]; % will be used to select S.GUI.Odor2Valve
ST.CS1_tone = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_tone = [0; 0; 0; 0; 0; 0; 0;];
ST.CS1_light = [0; 0; 0; 0; 0; 0; 0;];
ST.CS2_light = [0; 0; 0; 0; 0; 0; 0;];
ST.US = {'Reward'; 'Neutral'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'; 'Neutral'};   % is it Rewarded ?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;