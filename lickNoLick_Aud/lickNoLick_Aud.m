function lickNoLick_Aud

    global BpodSystem
    
    %% CS valence is important-   explain here!!!
    
    TotalRewardDisplay('init')
    %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S
    S.FPDistribList = {'EXP', 'UNIFORM', 'GAUSS', 'BIMODAL', 'UNIMODAL'}; % Foreperiod distribution before Cue
    blockFunctionList = {'gonogo_Aud_blocks'};
    PhotometryRasterFcnList = {'lickNoLick_Sound_PhotometryRasters', 'LNL_Sound_pRasters_3Sounds', 'LNL_pRasters_bySound'};
    defaults = {...
        'GUIPanels.Photometry', {'LED1_amp', 'LED2_amp', 'PhotometryOn'};...
        'GUI.LED1_amp', 1.5;...
        'GUI.LED2_amp', 0;...
        'GUI.PhotometryOn', 1;...
        
        'GUIPanels.Timing', {'Epoch', 'NoLick', 'FP', 'FPMean', 'FPMin', 'FPMax', 'FPSD', 'FPDistrib', 'AnswerDelay', 'Answer', 'OutcomeDelay','FeedbackDelayOn', 'FeedbackDelay'};...
        'GUI.Epoch', 1;...
        'GUI.NoLick', 1.5;... % mouse must stop licking for this period 
        'GUI.FP', 0;... % foreperiod
%         'GUI.mu_iti', 6;... % if > 0, determines random ITI
        'GUI.FPMean', 1.4;...
        'GUI.FPMin', 0.1;...
        'GUI.FPMax', 4;...
        'GUI.FPSD',0.25;...
        'GUI.FPDistrib', 'EXP';...
        'GUIMeta.FPDistrib.Style', 'popupmenutext';...
        'GUIMeta.FPDistrib.String',  S.FPDistribList;... 
        'GUI.AnswerDelay', 0.1;... % post-Sound, time until answer period, (in future may be updated trial-by-trial)
        % !!!! set OutcomeDelay = Answer for fixed timing (as in pavlovian
        % conditioning)!!!
        'GUI.Answer', 1;... % answer period duration
        'GUI.OutcomeDelay', 1;... % response (lick) to reinforcement delay, (in future may be updated trial-by-trial)
        'GUI.FeedbackDelayOn', 0;...        
        'GUIMeta.FeedbackDelayOn.Style', 'checkbox';... 
        'GUI.FeedbackDelay', [0.2 0.4 0.3 0.03];...       
        
        'GUIPanels.Stimuli', {'UsePulsePal', 'MeanSoundFreq1', 'MeanSoundFreq2', 'SoundAmplitude', 'Reward', 'PunishValveTime', 'PunishSoundOn', 'PunishSoundAmplitude', 'PunishSoundDuration', 'WhiteNoiseOn', 'WhiteNoiseAmplitude'};... %'neutralToneOn', 'TsToneOn'};...
        'GUI.UsePulsePal', 0;...         
        'GUI.MeanSoundFreq1', 8000;... % Hz; Go A --- easy trials
        'GUI.MeanSoundFreq2', 4000;... % Nogo A --- easy trials
        'GUI.SoundAmplitude', 60;...  % sound amplitude in db
        'GUI.Reward', 5;...
        'GUI.PunishValveTime', 0.2;... %s  
        'GUI.PunishSoundOn', 0;...
        'GUIMeta.PunishSoundOn.Style', 'checkbox';...
        'GUI.PunishSoundAmplitude', 1;... % punish sound amplitude in db
        'GUI.PunishSoundDuration', 0.25;...
        'GUI.WhiteNoiseOn', 0;...
        'GUIMeta.WhiteNoiseOn.Style', 'checkbox';... 
        'GUI.WhiteNoiseAmplitude', 1;... % whitenoise sound amplitude in db
%         'GUIMeta.neutralToneOn.Style', 'checkbox';...
%         'GUIMeta.TsToneOn.Style', 'checkbox';...      
        'GUIPanels.Blocks', {'BlockFcn', 'PhotometryRasterFcn', 'Block'};...
        'GUI.BlockFcn', 'gonogo_Aud_blocks';...
        'GUIMeta.BlockFcn.Style', 'popupmenutext';...
        'GUIMeta.BlockFcn.String',  blockFunctionList;...
        'GUI.PhotometryRasterFcn', 'lickNoLick_Sound_PhotometryRasters';...
        'GUIMeta.PhotometryRasterFcn.Style', 'popupmenutext';...
        'GUIMeta.PhotometryRasterFcn.String', PhotometryRasterFcnList;...
        'GUI.Block', 3;...
        
        'GUITabs.General', {'Photometry'};...
        'GUITabs.Timing', {'Timing'};...
        'GUITabs.Stimuli', {'Stimuli'};...
        'GUITabs.Blocks', {'Blocks'};...
%         'GUI.Hit_RewardFraction', 0.7;...
%         'GUI.FA_RewardFraction', 0.3;...
%         'GUI.Hit_PunishFraction', 0;...
%         'GUI.FA_PunishFraction', 0;...        
        
        % parameters for adaptive reversals 

        % common across LinkTo functions
%         'reversalCriterion', [];... % criterion for reversal, plotted online
%         
%         % number correct dictates reversal, LinkToFcn =
%         % blockSwitchFunction_nCorrect
%         'SwFcn_nC_MinCorrect', 10;... 
%         'SwFcn_nC_MeanAdditionalCorrect', 10;...
%         'SwFcn_nC_MaxAdditionalCorrect', 20;...
%         
%         % response rate difference dictates reversal, LinkToFcn =
%         % blockSwitchFunction_responseRateDifference
%         'SwFcn_BlockRRD_minDiff', 0.5;...
%         'SwFcn_BlockRRD_minTrials', 20;...     

%         'OdorTime', 1;...
        'SoundDuration', 0.5;...
        'SoundSamplingRate', 192000;...        
%         'TsTime', 1;...
        'PreCsRecording', 4;...
        'PostUsRecording', 4;...
        'currentValve', [];... % holds Sound valve # for current trial
        'RewardValveCode', 1;...
        'PunishValveCode', 2;...
        'RewardValveTime', [];...
        };
    
    S = setBpodDefaultSettings(S, defaults);
    
    %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin    
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;

%     S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);
    %% Load Tables
    bfh = str2func(S.GUI.BlockFcn);
    try
        S.Tables = bfh();
    catch
        error('** block function error ***');
    end
    
    %% init photometry raster function handle
    prfh = str2func(S.GUI.PhotometryRasterFcn);
    

    %% lick rasters for cs1 and cs2
    BpodSystem.ProtocolFigures.lickRaster.fig = ensureFigure('lick_raster', 1);        
    BpodSystem.ProtocolFigures.lickRaster.AxSound1 = subplot(1, 3, 1); title('Sound 1');
    BpodSystem.ProtocolFigures.lickRaster.AxSound2 = subplot(1, 3, 2); title('Sound 2');
    BpodSystem.ProtocolFigures.lickRaster.AxSound3 = subplot(1, 3, 3); title('Sound 3');
    %% Initialize Sound Stimuli
    if ~BpodSystem.EmulatorMode

%         % linear ramp of sound for 10ms at onset and offset
%         neutralTone = taperedSineWave(SF, 10000, 0.1, 0.01); % 10ms taper
%         PsychToolboxSoundServer('init')
%         PsychToolboxSoundServer('Load', 1, neutralTone);
%         
%         % TrialStart sound
%         TsTone = taperedSineWave(SF, 20000, 0.1, 0.01); % 10ms taper
%         PsychToolboxSoundServer('init')
%         PsychToolboxSoundServer('Load', 3, TsTone);

%         % PunishSound 
%         PunishSound = (rand(1, S.GUI.PunishSoundDuration * S.SoundSamplingRate) - 0.5) * S.GUI.PunishSoundAmplitude;
%         PsychToolboxSoundServer('Load', 4, PunishSound);
%         
%         % white noise 
%         wn_duration = 1;
%         WhiteNoise = (rand(1, wn_duration * S.SoundSamplingRate) - 0.5) * S.GUI.WhiteNoiseAmplitude;
%         PsychToolboxSoundServer('Load', 3, WhiteNoise);
%         BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';

    %% Generate feedback white noise
        

        load('PulsePalParamFeedback.mat');
        if S.GUI.UsePulsePal
            soundArg = bitset(0, 2); % kludge to get pulse pal to work on top rig but not disrupt bottom rig
            try
                ProgramPulsePal(PulsePalParamFeedback);        
            catch % if you're a dolt and forgot to start pulse pal
                PulsePal;
                ProgramPulsePal(PulsePalParamFeedback);        
            end
                maxLineLevel = 1; % e.g. +/- 1V command signal to an amplified speaker
                nPulses = 1000;
                SendCustomWaveform(1, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %
                SendCustomWaveform(2, 0.0001, (rand(1,nPulses)-.5)*maxLineLevel * 2); %        
        else
            soundArg = 0;
        end

    
        %% Initialize olfactometer and point grey camera
        % retrieve machine specific olfactometer settings
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        olfSettings = machineSpecific_Olfactometer;
        rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict

        % retrieve machine specific point grey camera settings
        addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
        pgSettings = machineSpecific_pointGrey;
        rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict    

        % initialize olfactometer slave arduino
        valveSlave = initValveSlave(olfSettings.portName);
        if isempty(valveSlave)
            BpodSystem.BeingUsed = 0;
            error('*** Failure to initialize valve slave ***');
        end
    end

    % determine nidaq/point grey and olfactometer triggering arguments
    npgWireArg = 0;
    npgBNCArg = 1; % BNC 1 source to trigger Nidaq is hard coded
    olfWireArg = 0;
    olfBNCArg = 0;
    if ~BpodSystem.EmulatorMode
        switch pgSettings.triggerType
            case 'WireState'
                npgWireArg = bitset(npgWireArg, pgSettings.triggerNumber); % its a wire trigger
            case 'BNCState'
                npgBNCArg = bitset(npgBNCArg, pgSettings.triggerNumber); % its a BNC trigger
        end
        olfWireArg = 0;
        olfBNCArg = 0;
        switch olfSettings.triggerType
            case 'WireState'
                olfWireArg = bitset(olfWireArg, olfSettings.triggerNumber);
            case 'BNCState'
                olfBNCArg = bitset(olfBNCArg, olfSettings.triggerNumber);
        end
    end
    %% initialize trial types and outcomes
    MaxTrials = 1000;

    % Outcomes -> NaN: future trial, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot) 
    ReinforcementOutcome = []; % local version of BposSystem.Data.ReinforcementOutcome
    
    BpodSystem.Data.TrialTypes = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.TrialOutcome = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.CSValence = []; % 1 = CS+, -1 = CS-, 0 = unCued or a 'control' Sound that doesn't affect outcomes or adaptive reversals
    BpodSystem.Data.ReinforcementOutcome = []; % i.e. Reward, Punish, WNoise, or Neutral
    BpodSystem.Data.WaterAmount = []; % i.e. WaterAmount
    BpodSystem.Data.LickAction = []; % 'lick' or 'noLick' 
    BpodSystem.Data.SoundValve = []; % e.g. 1st sound = sound1, or sound2
    BpodSystem.Data.SoundValveIndex = []; % 1st Sound, 2nd Sound
    BpodSystem.Data.Epoch = []; % onlineFilterTrials dependent on this variable
    BpodSystem.Data.BlockNumber = [];
    BpodSystem.Data.SwitchParameter = []; % e.g. nCorrect or response rate difference (hit rate - false alarm rate), dependent upon block switch LinkTo function 
    BpodSystem.Data.SwitchParameterCriterion = [];
    BpodSystem.Data.AnswerLicks = struct('count', [], 'rate', [], 'duration', []); % number of licks during answer period, nTrials x 1
%     BpodSystem.Data.AnswerLicksROC = struct('auROC', [], 'pVal', [], 'CI', []); 
    lickOutcome = '';
    noLickOutcome = '';
    lickAction = '';
    %% Outcome Plot
    trialsToShow = 50;
%     TrialTypes = [];
%     TrialOutcomes = [];
    BpodSystem.ProtocolFigures.OutcomePlotFig = figure('Position', [200 200 1000 200],'name','Outcome plot','numbertitle','off', 'MenuBar', 'none');
    BpodSystem.GUIHandles.OutcomePlot = axes;
    TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'init', BpodSystem.Data.TrialTypes);%, 'ntrials', trialsToShow);
    
%     %% testing auROC plotting
%     BpodSystem.ProtocolFigures.auROC.fig = ensureFigure('auROC_plot', 1); % still a kludge, assumes that I'm using correct block switch funtion currently... (4/2018)
%     BpodSystem.ProtocolFigures.auROC.ax = subplot(2,1,1, 'NextPlot', 'add');
%     BpodSystem.ProtocolFigures.auROC.sh = scatter([], [], 20, [], 'Parent', BpodSystem.ProtocolFigures.auROC.ax); 
%     ylabel('auROC');
%     BpodSystem.ProtocolFigures.auROC.ax2 = subplot(2,1,2, 'NextPlot', 'add'); % plot switchParameter
%     BpodSystem.ProtocolFigures.auROC.clh = line(0,0, 'Parent', BpodSystem.ProtocolFigures.auROC.ax2, 'Color', 'g');
%     BpodSystem.ProtocolFigures.auROC.splh = line(0,0, 'Parent', BpodSystem.ProtocolFigures.auROC.ax2, 'Color', 'k');
%     ylabel('Fraction significant'); xlabel('trial number');
%     
%     lickOutcome = '';
%     noLickOutcome = '';
%     lickAction = '';
    
    %% Main trial loop
    for currentTrial = 1:MaxTrials
        S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
        BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
        SaveBpodProtocolSettings;
        S.Block = S.Tables{S.GUI.Block};
        TrialType = pickRandomTrials_blocks(S.Block.Table); % trial type chosen on the fly based upon current Protocol Settings
        TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',... % update outcome plot to show trial type of current trial with outcome undefined (NaN)
            currentTrial, [BpodSystem.Data.TrialTypes TrialType], [BpodSystem.Data.TrialOutcome NaN]);            
        switch S.Block.Table.CS(TrialType)
            case 0
                SoundValve = 0; % uncued
            case 1
                SoundValve = 1;
            case 2
                SoundValve = 2;
        end
        
        S.Sound = S.Block.Table.CS(TrialType);
        %  test whether SoundAmplitude column exist in Block Table        
        if  ismember('SoundAmplitude', S.Block.Table.Properties.VariableNames)
            SoundAmplitude = S.Block.Table.SoundAmplitude{TrialType};      
            S.GUI.SoundAmplitude = SoundAmplitude;
        else
            SoundAmplitude = S.GUI.SoundAmplitude;
        end        
 
        Sound1 = SoundGenerator_SL(S.SoundSamplingRate, S.GUI.MeanSoundFreq1, S.SoundDuration, SoundAmplitude);
        Sound2 = SoundGenerator_SL(S.SoundSamplingRate, S.GUI.MeanSoundFreq2, S.SoundDuration, SoundAmplitude);
        PsychToolboxSoundServer('init')
        PsychToolboxSoundServer('Load', 1, Sound1);
        PsychToolboxSoundServer('Load', 2, Sound2); 
        
        lickOutcome = S.Block.Table.US{TrialType};
        if ~S.Block.Table.Instrumental(TrialType)
            noLickOutcome = S.Block.Table.US{TrialType};
        else
            noLickOutcome = 'Neutral';
        end
                     
       %test whether WaterAmount column exist in Block Table 
        if  ismember('WaterAmount', S.Block.Table.Properties.VariableNames)
            WaterAmount = S.Block.Table.WaterAmount{TrialType};      
            S.GUI.Reward = WaterAmount;
            S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);
        else
            WaterAmount = S.GUI.Reward;
            S.RewardValveTime = GetValveTimes(S.GUI.Reward, S.RewardValveCode);
        end
        
      
%         if S.GUI.neutralToneOn
%             neutralCode = 1;
%         else
%             neutralCode = 0;
%         end
%         
%         if S.GUI.TsToneOn
%             TsCode = 3;
%         else
%             TsCode = 0;
%         end
        
        if S.GUI.WhiteNoiseOn
            wnCode = 3;
        else
            wnCode = 0;
        end
        
        if S.GUI.PunishSoundOn
            PunishSoundCode = 4;
        else
            PunishSoundCode = 0;
        end
        
        %% update Sound valve number for current trial
        if ~BpodSystem.EmulatorMode
%             slaveResponse = updateValveSlave(valveSlave, OdorValve); 
            slaveResponse = updateValveSlave(valveSlave, SoundValve); 
            S.currentValve = slaveResponse;
            if isempty(slaveResponse)
                disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
                continue
            else
                disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
            end
        end
        disp(['*** Trial Type = ' num2str(TrialType) ' Block = ' num2str(S.GUI.Block) ' ***']);
        S.Block.Table % display current block (should have this be in a GUI window eventually)

%         %% Expotentially distributed ITIs
%         if S.GUI.mu_iti
%             S.GUI.ITI = inf;
%             while S.GUI.ITI > 3 * S.GUI.mu_iti   % cap exponential distribution at 3 * expected mean value (1/rate constant (lambda))
%                 S.GUI.ITI = exprnd(S.GUI.mu_iti);
%             end        
%         end    
        %% Prepare foreperiod
        switch S.GUI.FPDistrib
            case 1 % EXP
                mns = value(S.GUI.FPMean);
                FPMean2 = mns(1) - value(S.GUI.FPMin);
                FPMax2 = value(S.GUI.FPMax) - value(S.GUI.FPMin);
                temp = exprnd(FPMean2,NumTrials,1);
                while any(temp>FPMax2)
                    inx = temp > FPMax2;
                    temp(inx) = exprnd(FPMean2,sum(inx),1);
                end
                temp = temp + value(FPMin);
                S.GUI.FP = temp;
            case 2 % UNIFORM
                S.GUI.FP = unifrnd(value(S.GUI.FPMin),value(S.GUI.FPMax),NumTrials,1);
            case 3 % GAUSS
                mns = value(S.GUI.FPMean);
                FPMean2 = mns(1) - value(S.GUI.FPMin);
                FPMax2 = value(S.GUI.FPMax) - value(S.GUI.FPMin);
                temp = normrnd(FPMean2,value(FPSD),NumTrials,1);
                while any(temp>FPMax2) || any(temp<0)
                    inx = temp > FPMax2 | temp < 0;
                    temp(inx) = normrnd(FPMean2,value(FPSD),sum(inx),1);
                end
                temp = temp + value(S.GUI.FPMin);
                S.GUI.FP = temp;
            case 4 % BIMODEL
                FPmin = value(S.GUI.FPMin);  % FPMin = 0.1;
                FPmax = value(S.GUI.FPMax);  % FPMax = 3;
                mns = value(S.GUI.FPMean);
                mng1 = mns(1);   % mng1 = 0.3;   % parameters for the Gaussians
                mng2 = mns(end);   % mng2 = 2;
                sdg = value(S.GUI.FPSD);   % sdg = 0.15;
                pmx1 = 0.35;   % mixing probabilities
                pmx2 = 0.35;
                pmx3 = 1 - pmx1 - pmx2;
                
                FPs1 = random('Normal',mng1,sdg,1,NumTrials);
                while any(FPs1>FPmax) || any(FPs1<FPmin)
                    inx = FPs1 > FPmax  | FPs1 < FPmin;
                    FPs1(inx) = random('Normal',mng1,sdg,1,sum(inx));
                end
                FPs2 = random('Normal',mng2,sdg,1,NumTrials);
                while any(FPs2>FPmax) || any(FPs2<FPmin)
                    inx = FPs2 > FPmax  | FPs2 < FPmin;
                    FPs2(inx) = random('Normal',mng2,sdg,1,sum(inx));
                end
                FPs3 = random('Uniform',FPmin,FPmax,1,NumTrials);
                prr = rand(1,NumTrials);
                rr = zeros(3,NumTrials);
                rr(1,prr<pmx1) = 1;
                rr(2,prr>=pmx1&prr<(pmx1+pmx2)) = 1;
                rr(3,prr>=(pmx1+pmx2)) = 1;
                S.GUI.FP = rr(1,:) .* FPs1 + rr(2,:) .* FPs2 + rr(3,:) .* FPs3;
            case 5 % UNIMODEL  
                FPmin = value(S.GUI.FPMin);  % FPMin = 0.1;
                FPmax = value(S.GUI.FPMax);  % FPMax = 3;
                mns = value(S.GUI.FPMean);
                mng = mns(1);   % mng = 1.4;   % parameters for the Gaussians
                sdg = value(S.GUI.FPSD);   % sdg = 0.25;
                pmx1 = 0.65;   % mixing probabilities
                pmx2 = 1 - pmx1;
                
                FPs1 = random('Normal',mng,sdg,1,NumTrials);
                while any(FPs1>FPMax) | any(FPs1<FPMin)
                    inx = FPs1 > FPMax  | FPs1 < FPMin;
                    FPs1(inx) = random('Normal',mng,sdg,1,sum(inx));
                end
                FPs2 = random('Uniform',FPMin,FPMax,1,NumTrials);
                prr = rand(1,NumTrials);
                rr = zeros(2,NumTrials);
                rr(1,prr<pmx1) = 1;
                rr(2,prr>=pmx1) = 1;
                S.GUI.FP = rr(1,:) .* FPs1 + rr(2,:) .* FPs2;
        end
        
        %% define the duration of PreCsRecording

            S.PreCsRecording = 4 - S.GUI.FP % S.PreCsRecording + S.GUI.FP = 4
                               
         %% Feedback delay distribution (Gaussian)
         if S.GUI.FeedbackDelayOn
            allv = value(S.GUI.FeedbackDelay);
            FBmn = allv(1);   % minimum
            FBmx = allv(2);   % maximum
            FBmns = allv(3);  % mean
            FBsdg = allv(4);  % SD
            FBmn2 = FBmns - FBmn;
            FBmx2 = FBmx - FBmn;
            FBtemp = normrnd(FBmn2,FBsdg,NumTrials,1);
            while any(FBtemp>FBmx2) || any(FBtemp<0)
              inx = FBtemp > FBmx2 | FBtemp < 0;
              FBtemp(inx) = normrnd(FBmn2,FBsdg,sum(inx),1);
            end
            FBtemp = FBtemp + FBmn;
            S.OutcomeDelay = FBtemp;             
         else
            S.OutcomeDelay = S.GUI.OutcomeDelay 
         end
        
        %% TO DO
        % setup global counter to track number of licks during answer
        % period
        
        BpodSystem.Data.Settings = S; % SAVE SETTINGS, USED BY UPDATEPHOTOMETRYRASTERS SUBFUNCTION CURRENTLY, but redundant with trialSettings        
       
        %% Initialize NIDAQ
%     S.nidaq.duration = S.PreCsRecording + S.TsTime + S.SoundDuration + S.GUI.AnswerDelay + S.GUI.Answer + S.PostUsRecording;
%     startX = 0 - S.PreCsRecording - S.TsTime; % 0 defined as time from cue (because reward time can be variable depending upon outcomedelay)
    S.nidaq.duration = S.PreCsRecording + S.GUI.FP + S.SoundDuration + S.GUI.AnswerDelay + S.OutcomeDelay + S.PostUsRecording;
    startX = 0 - S.PreCsRecording - S.GUI.FP; % 0 defined as time from cue (because reward time can be variable depending upon outcomedelay)
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        S = initPhotometry(S);
    end
    %% photometry plots
    if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
        updatePhotometryPlot('init');
        prfh('init', 'baselinePeriod', [1 S.PreCsRecording])
    end
       %% Assemble state matrix
        sma = NewStateMatrix(); 
        sma = SetGlobalTimer(sma,1,S.SoundDuration + S.GUI.AnswerDelay); % Answer window   
        sma = SetGlobalTimer(sma,2,S.nidaq.duration); % photometry acq duration
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick'},...
            'OutputActions', {}); 
        sma = AddState(sma,'Name', 'NoLick', ...
            'Timer', S.GUI.NoLick,...
            'StateChangeConditions', {'Tup', 'StartRecording','Port1In','RestartNoLick'},...
            'OutputActions', {'WireState', bitset(0, 2), 'PWM1',100}); % Pulse Pal sound on
        sma = AddState(sma,'Name', 'RestartNoLick', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLick'},...
            'OutputActions', {'PWM1',100}); %
        sma = AddState(sma, 'Name', 'StartRecording',...
            'Timer',0.025,...
            'StateChangeConditions', {'Tup', 'PreCsRecording'},...
            'OutputActions', {'GlobalTimerTrig', 2, 'BNCState', npgBNCArg, 'WireState', npgWireArg, 'PWM1',100}); % trigger photometry acq global timer, nidaq trigger, point grey camera
        sma = AddState(sma, 'Name','PreCsRecording',...
            'Timer',S.PreCsRecording,...
            'StateChangeConditions',{'Tup','foreperiod'},...
            'OutputActions',{'PWM1',100});   
        sma = AddState(sma,'Name', 'foreperiod', ...
            'Timer', S.GUI.FP,...
            'StateChangeConditions', {'Tup', 'Cue'},...
            'OutputActions', {}); 
%         sma = AddState(sma, 'Name', 'TrialStart', ...  %add TrialStart tone
%             'Timer', S.TsTime,...
%             'StateChangeConditions', {'Tup','Cue'},...
%             'OutputActions',{'SoftCode', TsCode});         
        sma = AddState(sma, 'Name', 'Cue', ... 
            'Timer', S.SoundDuration,...
            'StateChangeConditions', {'Port1In', 'AnswerLick', 'Tup','AnswerDelay'},...
            'OutputActions', {'GlobalTimerTrig', 1, 'SoftCode', S.Sound});
        sma = AddState(sma, 'Name', 'AnswerDelay', ... 
            'Timer', S.GUI.AnswerDelay,...
            'StateChangeConditions', {'Port1In', 'AnswerLick', 'Tup', 'AnswerNoLick', 'GlobalTimer1_End', 'AnswerNoLick'},...
            'OutputActions', {'SoftCode', 255});        
%         sma = AddState(sma, 'Name', 'AnswerDelay', ... 
%             'Timer', S.GUI.AnswerDelay,...
%             'StateChangeConditions', {'Tup', 'AnswerStart'},...
%             'OutputActions', {});
%         sma = AddState(sma, 'Name', 'AnswerStart', ... 
%             'Timer', 0,...
%             'StateChangeConditions', {'Tup', 'AnswerNoLick'},...
%             'OutputActions', {'GlobalTimerTrig', 1});
        sma = AddState(sma, 'Name', 'AnswerNoLick', ... 
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'NoLickOutcome'},...
            'OutputActions', {});     
        sma = AddState(sma, 'Name', 'AnswerLick', ... 
            'Timer', S.OutcomeDelay,...
            'StateChangeConditions', {'Tup', 'LickOutcome'},...
            'OutputActions', {'SoftCode', 255});             
        sma = AddState(sma, 'Name', 'NoLickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', noLickOutcome},...
            'OutputActions', {});      
        sma = AddState(sma, 'Name', 'LickOutcome',... % dummy state for alignment
            'Timer', 0,...
            'StateChangeConditions', {'Tup', lickOutcome},...
            'OutputActions', {});      
        sma = AddState(sma,'Name', 'Reward', ... % 4 possible outcome states: Reward (H2O + tone), Punish (air puff + tone), WNoise (white noise), Neutral (tone)
            'Timer', S.RewardValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.RewardValveCode}); % previously 'SoftCode', 1
        sma = AddState(sma,'Name', 'Punish', ...
            'Timer', S.GUI.PunishValveTime,... %
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {'ValveState', S.PunishValveCode, 'SoftCode', PunishSoundCode});  % previously 'neutralCode'
%         sma = AddState(sma,'Name', 'WNoise', ...
%             'Timer', 0,... %
%             'StateChangeConditions', {'Tup', 'PostUsRecording'},...
%             'OutputActions', {'SoftCode', wnCode});        
        sma = AddState(sma,'Name', 'Neutral', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'PostUsRecording'},...
            'OutputActions', {}); % previously 'neutralCode'
        sma = AddState(sma, 'Name', 'PostUsRecording',...
            'Timer', S.PostUsRecording,...   % should end with global timer 2 but in case global timer 2 misfires, exit trial via 4 second timer
            'StateChangeConditions',{'GlobalTimer2_End','exit', 'Tup', 'exit'},...
            'OutputActions',{});    
        
        
        %%
        SendStateMatrix(sma);

        %% prep data acquisition
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
            preparePhotometryAcq(S);
        end
        %% Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!
        %% Stop Photometry session
        if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode
            stopPhotometryAcq;   
        end
        
        if ~isempty(fieldnames(RawEvents)) % If trial data was returned
            %% Process NIDAQ session
            if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode            
                try % in case photometry hicupped
                    processPhotometryAcq(currentTrial);
                %% online plotting
                    processPhotometryOnline(currentTrial);
                    updatePhotometryPlot('update', startX);  
                    xlabel('Time from cue (s)');
                catch
                    disp('*** Problem with online photometry processing ***');
                end
            end
            %% collect and save data
            BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents); % computes trial events from raw data
            BpodSystem.Data.TrialSettings(currentTrial) = S; % Adds the settings used for the current trial to the Data struct (to be saved after the trial ends)        
            
            %TrialOutcome -> NaN: future trial or omission, -1: miss, 0: false alarm, 1: hit, 2: correct rejection (see TrialTypeOutcomePlot)
            if ~isnan(BpodSystem.Data.RawEvents.Trial{end}.States.AnswerLick(1))
                lickAction = 'lick';
                ReinforcementOutcome = lickOutcome;               
                if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
                    TrialOutcome = 1; % hit
                elseif S.Block.Table.CSValence(TrialType) == -1
                    TrialOutcome = 0; % false alarm
                else
                    TrialOutcome = NaN; % uncued
                end
            else
                lickAction = 'nolick';
                ReinforcementOutcome = noLickOutcome;
                if S.Block.Table.CSValence(TrialType) == 1 % 1 = CS+, 0 = CS-
                    TrialOutcome = -1; % miss
                elseif S.Block.Table.CSValence(TrialType) == -1
                    TrialOutcome = 2; % correct rejection
                else
                    TrialOutcome = NaN; % uncued
                end                
            end
            
            % computer number of answer licks
            answerWindow = [...
                BpodSystem.Data.RawEvents.Trial{currentTrial}.States.Cue(1)... % start of answer
                max(BpodSystem.Data.RawEvents.Trial{currentTrial}.States.LickOutcome(end), BpodSystem.Data.RawEvents.Trial{currentTrial}.States.NoLickOutcome(end))... % end of answer
                ];            
            
            if isfield(BpodSystem.Data.RawEvents.Trial{currentTrial}.Events, 'Port1In')
                BpodSystem.Data.AnswerLicks.count(end + 1) = sum((answerWindow(1) <= BpodSystem.Data.RawEvents.Trial{currentTrial}.Events.Port1In) & (BpodSystem.Data.RawEvents.Trial{currentTrial}.Events.Port1In < answerWindow(2)));
            else
                BpodSystem.Data.AnswerLicks.count(end + 1) = 0;
            end

            BpodSystem.Data.AnswerLicks.duration(end + 1) = diff(answerWindow);
            BpodSystem.Data.AnswerLicks.rate(end + 1) = BpodSystem.Data.AnswerLicks.count(end) / BpodSystem.Data.AnswerLicks.duration(end);

            BpodSystem.Data.TrialTypes(end + 1) = TrialType; % Adds the trial type of the current trial to data
            BpodSystem.Data.TrialOutcome(end + 1) = TrialOutcome;            
            BpodSystem.Data.SoundValve(end + 1) =  SoundValve;
            BpodSystem.Data.SoundValveIndex(end + 1) = S.Block.Table.CS(TrialType);
            BpodSystem.Data.CSValence(end + 1) = S.Block.Table.CSValence(TrialType);% 1 = CS+, 0 = CS-
            BpodSystem.Data.Epoch(end + 1) = S.GUI.Epoch;            
            BpodSystem.Data.ReinforcementOutcome{end + 1} = ReinforcementOutcome; % i.e. 1: reward, 2: neutral, 3: punish
            BpodSystem.Data.BlockNumber(end + 1) = S.GUI.Block;
            BpodSystem.Data.LickAction{end + 1} = lickAction;

            %% update outcome plot to reflect upcoming trial
            TrialTypeOutcomePlot(BpodSystem.GUIHandles.OutcomePlot, 'update',...
                currentTrial, BpodSystem.Data.TrialTypes, BpodSystem.Data.TrialOutcome);            
            if strcmpi(ReinforcementOutcome, 'reward')
                TotalRewardDisplay('add', S.GUI.Reward);
            end
            
            %% adaptive block transitions
            if S.Block.LinkTo
                switchFcn = str2func(S.Block.LinkToFcn);
                [S.GUI.Block, switchParameter, switchParameterCriterion] = switchFcn(BpodSystem.Data.TrialOutcome, BpodSystem.Data.BlockNumber, S);
                S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
            else
                switchParameter = NaN;
                switchParameterCriterion = NaN;
            end
            BpodSystem.Data.SwitchParameter(end + 1) = switchParameter(1);
            BpodSystem.Data.SwitchParameterCriterion = switchParameterCriterion;

            

            % testing auROC plotting
%             set(BpodSystem.ProtocolFigures.auROC.sh, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.AnswerLicksROC.auROC, 'CData', BpodSystem.Data.AnswerLicksROC.pVal);
%             set(BpodSystem.ProtocolFigures.auROC.splh, 'XData', 1:currentTrial, 'YData', BpodSystem.Data.SwitchParameter);
%             set(BpodSystem.ProtocolFigures.auROC.clh, 'XData', [1 currentTrial], 'YData', [switchParameterCriterion switchParameterCriterion]);
%             set(BpodSystem.ProtocolFigures.auROC.ax2, 'YLim', [0 1]);
            
            %% block transition lines
            blockTransitions = find(diff(BpodSystem.Data.BlockNumber));
            if any(blockTransitions)
                btx = repmat([startX; startX + S.nidaq.duration], 1, length(blockTransitions));
                btx2 = repmat([-S.nidaq.duration; S.nidaq.duration], 1, length(blockTransitions));
                bty = [blockTransitions; blockTransitions;];
            end
            %% update photometry rasters
            try % in case photometry hicupped
                if S.GUI.PhotometryOn && ~BpodSystem.EmulatorMode    
                    % Note that switchParameterCriterion not used for
                    % LNL_pRasters_bySound, but doesn't matter when
                    % supplied via varargin
                    prfh('Update', 'switchParameterCriterion', switchParameterCriterion, 'XLim', [-S.nidaq.duration, S.nidaq.duration]);
                    if any(blockTransitions) % block transition lines
                        if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch1)
                            for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch1(2:end)
                                plot(btx2, bty, '-r', 'Parent', ah);
                            end
                        end
                        if ~isempty(BpodSystem.ProtocolFigures.phRaster.ax_ch2)
                            for ah = BpodSystem.ProtocolFigures.phRaster.ax_ch2(2:end)
                                plot(btx2, bty, '-r', 'Parent', ah);
                            end
                        end
                    end
                end
            end
            
            %% lick rasters by sound   
%             bpLickRaster2(SessionData, filtArg, zeroField, figName, ax)
            bpLickRaster2({'SoundValveIndex', 1}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxSound1, 'session'); hold on;
            bpLickRaster2({'SoundValveIndex', 2}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxSound2, 'session'); hold on; % make both rasters regardless of number of Sounds, it'll just be blank if you don't have that Sound
%             bpLickRaster2({'OdorValveIndex', 3}, 'Cue', 'lick_raster', BpodSystem.ProtocolFigures.lickRaster.AxOdor3, 'session'); hold on; % make both rasters regardless of number of odors, it'll just be blank if you don't have that odor            
            if any(blockTransitions)
                plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxSound1);
                plot(btx, bty, '-r', 'Parent', BpodSystem.ProtocolFigures.lickRaster.AxSound2); % just make 
                drawnow;
            end             
            set([BpodSystem.ProtocolFigures.lickRaster.AxSound1 BpodSystem.ProtocolFigures.lickRaster.AxSound2 BpodSystem.ProtocolFigures.lickRaster.AxSound3], 'XLim', [startX, startX + S.nidaq.duration]);
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxSound1, 'Time from cue (s)');
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxSound2, 'Time from cue (s)');
            xlabel(BpodSystem.ProtocolFigures.lickRaster.AxSound3, 'Time from cue (s)');
            
            
            
            %% save data
            SaveBpodSessionData; % Saves the field BpodSystem.Data to the current data file
        else
            disp([' *** Trial # ' num2str(currentTrial) ':  aborted, data not saved ***']); % happens when you abort early (I think), e.g. when you are halting session
        end
        
        HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
        if BpodSystem.BeingUsed == 0
            if ~BpodSystem.EmulatorMode
                fclose(valveSlave);
                delete(valveSlave);
            end
            return
        end 
    end
            