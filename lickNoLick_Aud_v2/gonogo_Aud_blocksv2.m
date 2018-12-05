function blocks = gonogo_Aud_blocksv2

blocks = {};

%% block 1-Pavlovian
S = struct(); ST = struct();
ST.BlockNumber = [1; 1; 1]; % fluff
ST.P = [0.8; 0.1; 0.1];
ST.CS = [1; 2; 3]; % GoTone A and NoGoTone B and NeutralTone C
ST.SoundAmplitude = {50; 50; 50};
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'};  
ST.Instrumental = [0; 0; 0];
% ST.WaterAmount = {8; 0; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 2-gonogo without airpuff
S = struct(); ST = struct();
ST.BlockNumber = [2; 2; 2]; % fluff
ST.P = [0.8; 0.1; 0.1];
ST.CS = [1; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {50; 50; 50};
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Neutral'; 'Neutral'};   
ST.Instrumental = [1; 1; 1];
% ST.WaterAmount = {8; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 3-gonogo with airpuff
S = struct(); ST = struct();
ST.BlockNumber = [3; 3; 3]; % fluff
ST.P = [0.7; 0.2; 0.1];
ST.CS = [1; 2; 3]; % GoTone A and NoGoTone B and NeutralTone C
ST.SoundAmplitude = {50; 50; 50};
ST.CSValence = [1; 1; 1];
ST.US = {'Reward'; 'Punish'; 'Neutral'};   
ST.Instrumental = [1; 1; 1];
% ST.WaterAmount = {8; 0; 0};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;

%% block 4 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [4; 4; 4; 4; 4]; % fluff
ST.P = [0.225; 0.225; 0.225; 0.225; 0.1];
ST.CS = [1; 1; 2; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {50; 40; 50; 40; 50};
ST.CSValence = [1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1];
% ST.WaterAmount = {8; 8; 0; 0; 0};
ST.US = {'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Neutral'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 5 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [5; 5; 5; 5; 5; 5; 5]; % fluff
ST.P = [0.15; 0.15; 0.15; 0.15; 0.15; 0.15; 0.1];
ST.CS = [1; 1; 1; 2; 2; 2; 3]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {50; 40; 30; 50; 40; 30; 50};
ST.CSValence = [1; 1; 1; 1; 1; 1; 1];
% ST.US = {'Reward'; 'Neutral'};  
ST.Instrumental = [1; 1; 1; 1; 1; 1; 1];
% ST.WaterAmount = {5; 0};
ST.US = {'Reward'; 'Reward'; 'Reward'; 'Punish'; 'Punish'; 'Punish'; 'Neutral'};
% noLickOutcome = {'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'; 'Neutral'};
S.Table = struct2table(ST);
S.LinkTo = 0;
S.LinkToFcn = '';
blocks{end + 1} = S;
%% block 6 full task with different sound intensities
S = struct(); ST = struct();
ST.BlockNumber = [6; 6; 6; 6; 6; 6; 6; 6; 6]; % fluff
ST.P = [0.12; 0.12; 0.12; 0.12; 0.12; 0.12; 0.12; 0.12; 0.04];
ST.CS = [1; 1; 1; 1; 2; 2; 2; 2]; % GoTone A and NoGoTone B
ST.SoundAmplitude = {50; 40; 30; 20; 50; 40; 30; 20; 50};
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