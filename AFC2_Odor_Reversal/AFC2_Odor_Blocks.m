function blocks = AFC2_Odor_Blocks

blocks = {};

S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1; 1]; % fluff
ST.P = [0.5 * 0.7; 0.5 * 0.3; 0.5 * 0.7; 0.5 * 0.3];
ST.Odor = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CorrectResponse = {'Left'; 'Left'; 'Right'; 'Right'};
ST.OutcomeLeft = {'RewardLeft'; 'Neutral'; 'Neutral'; 'RewardLeft'};   % Reward
ST.OutcomeRight = {'Neutral'; 'RewardRight'; 'RewardRight'; 'Neutral';};
ST.RewardSizeLeft = [2; 2; 2; 2];   % uL
ST.RewardSizeRight = [2; 2; 2; 2];  % uL 
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;