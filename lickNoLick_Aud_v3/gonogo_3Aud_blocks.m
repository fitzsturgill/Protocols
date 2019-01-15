function blocks = gonogo_3Aud_blocks

blocks = {};

%% block 1 initial training
S = struct(); ST = struct();
ST.BlockNumber = [1; 1]; % fluff
ST.P = [0.8; 0.2];
ST.CS = [1; 3]; % GoTone A and NeutralTone C
ST.SoundAmplitude = [50; 50];
ST.CSValence = [1; 1];
ST.US = {'Reward'; 'Neutral'};   
ST.Instrumental = [0; 0];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 2 pavlovian
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2]; % fluff
ST.P = [0.7; 0.2; 0.1];
ST.CS = [1; 2; 3]; % reward cue A, punish cue B and neutral tone
ST.SoundAmplitude = [50; 50; 50];
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'};  
ST.Instrumental = [0; 0; 0];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 3 gonogo with airpuff
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3]; % fluff
ST.P = [0.7; 0.2; 0.1];
ST.CS = [1; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 50; 50];
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'};   
ST.Instrumental = [1; 1; 1];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 4 gonogo with airpuff
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4]; % fluff
ST.P = [0.45; 0.45; 0.1];
ST.CS = [1; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 50; 50];
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'};   
ST.Instrumental = [1; 1; 1];
% ST.WaterAmount = {5; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 5 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5; 5; 5; 5]; % fluff
ST.P = [0.225; 0.2; 0.225; 0.2; 0.05; 0.05; 0.05];
ST.CS = [1; 1; 2; 2; 3; 0; 0]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 50; 40; 50; 0; 0];
ST.CSValence = [1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1; 0; 0];
% ST.WaterAmount = {5; 0};
ST.US = {'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Reward'; 'Punish'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 6 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6; 6; 6; 6; 6; 6]; % fluff
ST.P = [0.145; 0.14; 0.14; 0.145; 0.14; 0.14; 0.05; 0.05; 0.05];
ST.CS = [1; 1; 1; 2; 2; 2; 3; 0; 0]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 30; 50; 40; 30; 50; 0; 0];
ST.CSValence = [1; 1; 1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1; 1; 1; 0; 0];
% ST.WaterAmount = {5; 0};
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'; 'Neutral'; 'Reward'; 'Punish'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Reward'; 'Punish'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 7 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [7; 7; 7; 7; 7; 7; 7; 7; 7]; % fluff
ST.P = [0.1125; 0.1125; 0.1125; 0.1125; 0.1125; 0.1125; 0.1125; 0.1125; 0.1];
ST.CS = [1; 1; 1; 1; 2; 2; 2; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = [50; 40; 30; 20; 50; 40; 30; 20; 50];
ST.CSValence = [1; 1; 1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1; 1; 1; 1; 1];
% ST.WaterAmount = {5; 0};
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'; 'Punish'; 'Neutral'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;