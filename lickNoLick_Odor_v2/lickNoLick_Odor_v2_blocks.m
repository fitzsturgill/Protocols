function blocks = lickNoLick_Odor_v2_blocks

blocks = {};

%% block 1
S = struct();
S.P = 1;
S.CS = 1; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'};   % reward
S.Instrumental = 0;

blocks{end + 1} = struct2table(S);
        
%% block 2
S = struct();
S.P = 1;
S.CS = 1; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'};   % reward
S.Instrumental = 1;

blocks{end + 1} = struct2table(S);


%% block 3
S = struct();
S.P = [0.5; 0.5];
S.CS = [1; 2]; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'; 'wnoise'};   % reward
S.Instrumental = [1; 1];


blocks{end + 1} = struct2table(S);

%% block 4, first reversal
S = struct();
S.P = [0.5; 0.5];
S.CS = [2; 1]; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'; 'wnoise'};   % reward
S.Instrumental = [0; 1];


blocks{end + 1} = struct2table(S);

%% block 5, continue first reversal
S = struct();
S.P = [0.5; 0.5];
S.CS = [2; 1]; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'; 'wnoise'};   % reward
S.Instrumental = [1; 1];


blocks{end + 1} = struct2table(S);

%% block 6, first re-reversal
S = struct();
S.P = [0.5; 0.5];
S.CS = [1; 2]; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'; 'wnoise'};   % reward
S.Instrumental = [0; 1];


blocks{end + 1} = struct2table(S);

%% block 7, continue re-reversal, from now on cycle back to 5
S = struct();
S.P = [0.5; 0.5];
S.CS = [1; 2]; % will be used to select S.GUI.Odor1Valve
S.US = {'reward'; 'wnoise'};   % reward
S.Instrumental = [1; 1];


blocks{end + 1} = struct2table(S);

