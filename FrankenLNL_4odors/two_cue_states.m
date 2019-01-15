function blocks = two_cue_states

blocks = {};



%% block 1 (A&C preceeds B&D, rewarded 100%, 10% uncued rewards)
S = struct(); ST = struct();
ST.BlockNumber = repmat(1, 3, 1); % fluff
ST.P = [...
    0.90*0.5;...
    0.90*0.5;...
    0.10];
ST.CS1 = [1; 3; 0]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [2; 4; 0]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Reward';'Reward';'Reward'};   % is it Rewarded ?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;

%% block 2 (A&C preceeds B&D 80%, crossover 20%, NO uncued reward)
S = struct(); ST = struct();
ST.BlockNumber = repmat(2, 4, 1); % fluff
ST.P = [...
    0.5*0.8;...
    0.5*0.8;...
    0.5*0.2;...
    0.5*0.2];
ST.CS1 = [1; 3; 1; 3]; % will be used to select S.GUI.Odor1Valve
ST.CS2 = [2; 4; 4; 2]; % will be used to select S.GUI.Odor2Valve
ST.US = {'Reward';'Reward';'Reward';'Reward'};   % is it Rewarded ?
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';

blocks{end + 1} = S;







%% older crap:
% 
% % %% block 111 (same pavlovian vs. instrumental)
% % S = struct(); ST = struct();
% % ST.BlockNumber = repmat(1, 2, 1); % fluff
% % ST.P = [...
% %     0.9;...
% %     0.1];
% % ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
% % ST.CS2 = [1; 0]; % will be used to select S.GUI.Odor2Valve
% % ST.US = {'Reward'; 'Reward'}; % is it rewarded?
% % ST.Instrumental = [0; 0];
% % S.Table = struct2table(ST);
% % S.LinkTo = 0;
% % S.LinkToFcn = '';
% % 
% % blocks{end + 1} = S;
%         
% 
% 
% %%%%%%%%%%%%%%%%%  Blocks 2 & 3: CS+ pReward = 0.8,   CS- pReward = 0.3 
% 
% %% block 1 (Odor B rewarded 100% of the time, also 10% of trials uncued reward)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(1, 2, 1); % fluff
% ST.P = [...
%     0.9;...
%     0.1];
% ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CS2 = [1; 0]; % will be used to select S.GUI.Odor2Valve
% ST.US = {'Reward'; 'Reward'}; % is it rewarded?
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 2 (only cue D, rewarded 100%, 10% uncued rewards)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(2, 2, 1); % fluff
% ST.P = [...
%     0.9;...
%     0.1];
% ST.CS1 = [0; 0]; % will be used to select S.GUI.Odor1Valve
% ST.CS2 = [3; 0]; % will be used to select S.GUI.Odor2Valve
% ST.US = {'Reward'; 'Reward'}; % is it rewarded?
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 3 (B and D, both rewarded 100%, 10% uncued rewards)
% 
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(3, 3, 1);  %fluff
% ST.P = [...
%     0.90 * 0.50;...
%     0.90 * 0.50;...
%     0.10];
% ST.CS1 = [0; 0; 0];
% ST.CS2 = [1; 3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.US = {'Reward';'Reward';'Reward'};   % is it Rewarded ?
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 4 (A preceeds B, rewarded 100%, 10% uncued rewards)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(4, 2, 1); % fluff4
% ST.P = [...
%     0.90;...
%     0.10];
% ST.CS1 = [2; 0];
% ST.CS2 = [1; 0]; % will be used to select S.GUI.Odor1Valve
% ST.US = {'Reward';'Reward'};   % is it Rewarded ?
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;
% 
% %% block 5 (C preceeds D, rewarded 100%, 10% uncued rewards)
% S = struct(); ST = struct();
% ST.BlockNumber = repmat(5, 2, 1); % fluff
% ST.P = [...
%     0.90;...
%     0.10];
% ST.CS1 = [4; 0];
% ST.CS2 = [3; 0]; % will be used to select S.GUI.Odor1Valve
% ST.US = {'Reward';'Reward'};   % is it Rewarded ?
% S.Table = struct2table(ST);
% S.LinkTo = 0;
% S.LinkToFcn = '';
% 
% blocks{end + 1} = S;