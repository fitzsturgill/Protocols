function blocks = pav_rev_blocks_noPunish

blocks = {};

%% block 1 (same pavlovian vs. instrumental)
S = struct(); ST = struct();
ST.BlockNumber = repmat(1, 2, 1); % fluff
ST.P = [...
    0.9;...
    0.1];
ST.CS = [1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 0]; 
ST.US = {'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0];
ST.Instrumental = [0; 0];
S.Table = struct2table(ST);
S.LinkTo = 1;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;
        


%%%%%%%%%%%%%%%%%  Blocks 2 & 3: CS+ pReward = 0.8,   CS- pReward = 0.3 

%% block 2 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
S = struct(); ST = struct();
ST.BlockNumber = repmat(2, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 2;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;


%% block 3 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% A extinction is lasered
S = struct(); ST = struct();
ST.BlockNumber = repmat(3, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 1; 1];
ST.Instrumental = [0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 3;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 4 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
S = struct(); ST = struct();
ST.BlockNumber = repmat(4, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 4;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 5 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% A Acquisition is lasered
S = struct(); ST = struct();
ST.BlockNumber = repmat(5, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [1; 1; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 5;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;
%

%% block 6 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% same as block 2
S = struct(); ST = struct();
ST.BlockNumber = repmat(6, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 6;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 7 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% B acquisition is lasered
S = struct(); ST = struct();
ST.BlockNumber = repmat(7, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [1; 1; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 7;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 8 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% same as block 4
S = struct(); ST = struct();
ST.BlockNumber = repmat(8, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [2; 2; 1; 1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 0; 0];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 8;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 9 (initial contingency, manual control, with occasional uncued outcomes) + TriggerPulsePal for Laser pew pew
% B extinction is lasered
S = struct(); ST = struct();
ST.BlockNumber = repmat(9, 4, 1); % fluff
ST.P = [...
    0.80 * 0.5;...
    0.20 * 0.5;...
    0.05 * 0.5;...
    0.95 * 0.5];
    
ST.CS = [1; 1; 2; 2]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 1; -1; -1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 1; 1];
ST.Instrumental = [0; 0; 0; 0;];
S.Table = struct2table(ST);
S.LinkTo = 9;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 10 
%Prob DA sensor task !!!

S = struct(); ST = struct();
ST.BlockNumber = repmat(10, 5, 1); % fluff
ST.P = [...
    0.70 * 0.5;... 
    0.70 * 0.5;...
    0.20 * 0.5;...
    0.20 * 0.5;...
    0.10;...
    ];
    
ST.CS = [1; 1; 1; 1; 0]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1; 0; 1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Neutral'};   % Reward
ST.TriggerPulsePal = [0; 0; 2; 2; 2];
ST.Instrumental = [0; 0; 0; 0; 0];
S.Table = struct2table(ST);
S.LinkTo = 10;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;

%% block 11
%trouble shooting

S = struct(); ST = struct();
ST.BlockNumber = repmat(11, 1, 1); % fluff
ST.P = [1];
    
ST.CS = [1]; % will be used to select S.GUI.Odor1Valve
ST.CSValence = [1]; % whether CS is considered CS+ and licks are counted as "hits"
ST.US = {'Neutral'};   % Reward
ST.TriggerPulsePal = [2];
ST.Instrumental = [0];
S.Table = struct2table(ST);
S.LinkTo = 11;
S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';

blocks{end + 1} = S;
% 
% 
% %% block 3 (reversed, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(3, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.9;...
%     0.20 * 0.5 * 0.9;...
%     0.30 * 0.5 * 0.9;...
%     0.70 * 0.5 * 0.9;...
%     0.05;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 0; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% b_b
% blocks{end + 1} = S;
% 
% %%%%%%%%%%%%%%%%%%%% Blocks 4 & 5: CS+ pReward = 0.8,   CS- pReward = 0.15 
% 
% %% block 4 (initial contingency, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(4, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.9;...
%     0.20 * 0.5 * 0.9;...
%     0.15 * 0.5 * 0.9;...
%     0.85 * 0.5 * 0.9;...
%     0.05;...
%     0.05];
% ST.CS = [1; 1; 2; 2; 0; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 5 (reversed, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(5, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.9;...
%     0.20 * 0.5 * 0.9;...
%     0.15 * 0.5 * 0.9;...
%     0.85 * 0.5 * 0.9;...
%     0.05;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 0; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Neutral'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %%%%%%%%%%%%%%%%%%%% Blocks 6 & 7: CS+ pReward = 0.8,   CS- pReward = 0.05 
% 
% %% block 6 (initial contingency, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(6, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [1; 1; 2; 2; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 7 (reversed, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(7, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Rewardb
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%% Blocks 8 & 9: CS+ pReward = 0.8,   CS- pReward = 0.05,
% %%%%%%%%%%%%%%%%%%%% manual reversals but plots switchParameter and reversalCriteron 
% %% block 8 (initial contingency, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(8, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [1; 1; 2; 2; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 8; % stay on block 8
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;
% 
% %% block 9 (reversed, manual control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(9, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 9; % stay on block 9
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;
% 
% 
% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%% Blocks 10 & 11: CS+ pReward = 0.8,   CS- pReward = 0.05,
% %%%%%%%%%%%%%%%%%%%% automated reversals!!!!!!
% 
% %% block 10 (initial contingency, auto control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(10, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [1; 1; 2; 2; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 11;
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;
% 
% %% block 11 (reversed, auto control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(11, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [0; 0; 0; 0; 0; 0];
% S.Table = struct2table(ST);
% S.LinkTo = 10;
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;
% 
% 
% 
% 
% %%
% %% block 12 (initial contingency, auto control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(12, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [1; 1; 2; 2; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [1; 1; 1; 1; 1; 1];
% S.Table = struct2table(ST);
% S.LinkTo = 11;
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;
% 
% %% block 13 (reversed, auto control, with occasional uncued outcomes)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(13, 6, 1); % fluff
% ST.P = [...
%     0.80 * 0.5 * 0.85;...
%     0.20 * 0.5 * 0.85;...
%     0.05 * 0.5 * 0.85;...
%     0.95 * 0.5 * 0.85;...
%     0.10;...
%     0.05];
% ST.CS = [2; 2; 1; 1; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CSValence = [1; 1; -1; -1; 0; 0]; % whether CS is considered CS+ and licks are counted as "hits"
% ST.US = {'Reward'; 'Neutral'; 'Reward'; 'Neutral'; 'Reward'; 'Reward'};   % Reward
% ST.Instrumental = [1; 1; 1; 1; 1; 1];
% S.Table = struct2table(ST);
% S.LinkTo = 10;
% S.LinkToFcn = 'blockSwitchFunction_answerLicksROC';
% 
% blocks{end + 1} = S;