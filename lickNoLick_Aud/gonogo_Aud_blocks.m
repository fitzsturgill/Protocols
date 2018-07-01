function blocks = gonogo_Aud_blocks

blocks = {};

%% block 1 easy task without airpuff
S = struct(); ST = struct();
ST.BlockNumber = [1; 1]; % fluff
ST.P = [0.8; 0.2];
ST.CS = [1; 2]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {60; 60};
ST.CSValence = [1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [0; 0];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 2 full task with highest sound intensity
S = struct(); ST = struct();
ST.BlockNumber = [2; 2]; % fluff
ST.P = [0.5; 0.5];
ST.CS = [1; 2]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {60; 60};
ST.CSValence = [1; 1];
% ST.US = {'Reward'; 'Punish'};   
ST.Instrumental = [0; 0];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 3 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3; 3; 3; 3; 3; 3]; % fluff
ST.P = [0.125; 0.125; 0.125; 0.125; 0.125; 0.125; 0.125; 0.125];
ST.CS = [1; 1; 1; 1; 2; 2; 2; 2]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {60; 50; 40; 30; 60; 50; 40; 30};
ST.CSValence = [1; 1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1; 1; 1; 1];
% ST.WaterAmount = {5; 0};
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'; 'Punish'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
