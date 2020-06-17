function blocks = AFC2_Odor_Blocks

blocks = {};

% block 1, stage 1, early training block, now deterministic initially
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1; 1]; % fluff
ST.P = [0.5 * 1; 0.5 * 0; 0.5 * 1; 0.5 * 0];
ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
ST.RewardSizeLeft = [10; 10; 10; 10];   % uL
ST.RewardSizeRight = [10; 10; 10; 10];  % uL 
ST.RewardSizeCenter = [5; 5; 5; 5];  % uL 
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;


% block 2, stage 2, intermediate training block, now deterministic
% initially
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2; 2]; % fluff
ST.P = [0.5 * 1; 0.5 * 0; 0.5 * 1; 0.5 * 0];
ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
ST.RewardSizeLeft = [5; 5; 5; 5];   % uL
ST.RewardSizeRight = [5; 5; 5; 5];  % uL 
ST.RewardSizeCenter = [1; 1; 1; 1];  % uL 
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;
% block 3, stage 2, quick and dirty bias right (to correct left bias)
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3]; % fluff
ST.P = [0.25; 0; 0.75; 0];
ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odr1Valve
ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
ST.RewardSizeLeft = [5; 5; 5; 5];   % uL
ST.RewardSizeRight = [5; 5; 5; 5];  % uL 
ST.RewardSizeCenter = [1; 1; 1; 1];  % uL 
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;



blocks{end + 1} = S;
% block 4, stage 2, quick and dirty bias left (to correct right bias)
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4]; % fluff
ST.P = [0.75; 0; 0.25; 0];
ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odr1Valve
ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
ST.RewardSizeLeft = [5; 5; 5; 5];   % uL
ST.RewardSizeRight = [5; 5; 5; 5];  % uL 
ST.RewardSizeCenter = [1; 1; 1; 1];  % uL 
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;


%%
% % block 1, stage 1, early training block
% S = struct(); ST = struct();
% ST.BlockNumber = [1; 1; 1; 1]; % fluff
% ST.P = [0.5 * 0.7; 0.5 * 0.3; 0.5 * 0.7; 0.5 * 0.3];
% ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
% ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
% ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
% ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
% ST.RewardSizeLeft = [10; 10; 10; 10];   % uL
% ST.RewardSizeRight = [10; 10; 10; 10];  % uL 
% ST.RewardSizeCenter = [5; 5; 5; 5];  % uL 
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% 
% % block 2, stage 2, intermediate training block
% S = struct(); ST = struct();
% ST.BlockNumber = [2; 2; 2; 2]; % fluff
% ST.P = [0.5 * 0.7; 0.5 * 0.3; 0.5 * 0.7; 0.5 * 0.3];
% ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
% ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
% ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
% ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
% ST.RewardSizeLeft = [5; 5; 5; 5];   % uL
% ST.RewardSizeRight = [5; 5; 5; 5];  % uL 
% ST.RewardSizeCenter = [1; 1; 1; 1];  % uL 
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
