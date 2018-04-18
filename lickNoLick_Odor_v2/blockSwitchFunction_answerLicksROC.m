function [nextBlock, switchParameter, criterion] = blockSwitchFunction_answerLicksROC(outcomes, blockNumbers, S, varargin)


% This function is modeled after previous blockSwFcns that derive
% switchParameter from trial outcomes (discrete, of set [-1 0 1 2])
% HOWEVER- this function derives switchParameter from the anticipatory 
% lick rate during the answer period (auROC CS+ vs CS-)
% For consistency and use as function handle, I'm going to access and write to the BpodSystem global variable to get the
% answer lick rate and output auROC values for plotting (seperate from the
% 'switchParameter')

%INPUTS
% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)
% S- settings structure
% OUTPUTS
% nextBlock- block of next trial
% switchParameter-  fraction of recent trials from last reversal/block (across
% nTrialsAbove window) bearing a significantly positive auROC value
% criterion- target fraction of significant recent trials (aross nTrialsAbove window) for triggering a block switch (e.g. reversal)

% Adds onto BpodSystem.Data.AnswerLicksROC:
% auROC: scaled auROC comparing CS+ vs CS- anticipatory lick rate computed
% across sliding window of trials since reversal/block start
% pVal: associated p value for auROC 
% CI: lower and upper bounds of confidence interval for auROC


    global BpodSystem

%% optional parameters, first set defaults
    defaults = {...
        'ROCwindow', 10;...
        'windowMode', 'local';... % [LOCAL | GLOBAL] Local: separate CS+ and CS- windows, number of elements = ROC window. Global: Windows include subset of last n = ROCwindow trials that are either CS+ or CS- trials
        'reset', 1;...  % always 1 for now, means that auROC values are reset following each block change
        'nBoot', 100;...
        'minROCPoints', 5;... % mininum sample size for auROC calculation
        'pCritical', 0.05;...
        'nTrialsAbove', 20;...  % denominator for determing what fraction of trials exceed the criterion p value
        'fractionAboveNeeded', 0.9;...
        'minTrials', 50;...
        'minHitRate', 0.7;...
        };

    [bss, ~] = parse_args(defaults, varargin{:}); % block switch settings
    
    lastReverse = find(diff(blockNumbers), 1, 'last');
    if isempty(lastReverse)
        lastReverse = 1; % session start
    else
        lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
    end
    currentTrial = length(outcomes);
    nTrialsCurrent = currentTrial - lastReverse + 1; 
    tfw = [max(max(1, currentTrial - bss.nTrialsAbove + 1), lastReverse), currentTrial]; % tfw = this nTrialsAbove window    

    
    %% for local and global modes, dataPlus and dataMinus are of length <= bss.nTrialsAbove
    switch bss.windowMode
        case 'local'
            thesePlusTrials = find(BpodSystem.Data.CSValence == 1 & ((1:currentTrial) > lastReverse));
            if ~isempty(thesePlusTrials)
                thesePlusTrials = thesePlusTrials(end - min(bss.ROCwindow, length(thesePlusTrials)) + 1:end);
                dataPlus = BpodSystem.Data.AnswerLicks.rate(thesePlusTrials);
%                 dataPlus = randn(size(dataPlus)) + 1.5;
            else
                dataPlus = [];
            end
            theseMinusTrials = find(BpodSystem.Data.CSValence == -1 & ((1:currentTrial) > lastReverse));
            if ~isempty(theseMinusTrials)
                theseMinusTrials = theseMinusTrials(end - min(bss.ROCwindow, length(theseMinusTrials)) + 1:end);
                dataMinus = BpodSystem.Data.AnswerLicks.rate(theseMinusTrials);
%                 dataMinus = randn(size(dataMinus)); % for testing
            else
                dataMinus = [];
            end
            beginHitRate = min(min(thesePlusTrials), min(theseMinusTrials)); % first trial to compute hit rate
        case 'global'
            trw = [max(max(1, currentTrial - bss.ROCwindow + 1), lastReverse), currentTrial]; % trw = thisROCwindow
            theseData = BpodSystem.Data.AnswerLicks.rate(trw(1):trw(2));
            thesePlusTrials = BpodSystem.Data.CSValence(trw(1):trw(2)) == 1;
            theseMinusTrials = BpodSystem.Data.CSValence(trw(1):trw(2)) == -1;
            dataPlus = theseData(thesePlusTrials);
            dataMinus = theseData(theseMinusTrials);
            beginHitRate = trw(1); % first trial to compute hit rate
    end

    if (length(dataPlus) >= bss.minROCPoints) && (length(dataMinus) >= bss.minROCPoints) % needs to be at least n data points to spit out auROC value
        [D, P, CI] = rocarea_CI(dataPlus, dataMinus, 'boot', bss.nBoot, 'scale');
        BpodSystem.Data.AnswerLicksROC.auROC(currentTrial, 1) = D;
        BpodSystem.Data.AnswerLicksROC.pVal(currentTrial ,1) = P;
        BpodSystem.Data.AnswerLicksROC.CI(currentTrial, :) = CI;
        
        % compute hit rate
        HitRate = length(find(outcomes(beginHitRate:end) == 1)) / length(find(ismember(outcomes(beginHitRate:end), [1 -1]))); % 
%         disp(['Hit rate is ' num2str(HitRate)]);
        % compute fraction significant trials(the switch parameter)
        if (nTrialsCurrent >= bss.minTrials) && (HitRate >= bss.minHitRate)
            % keeper trials have positive auROC and are significant
            validTrials = (BpodSystem.Data.AnswerLicksROC.pVal(tfw(1):tfw(2)) <= bss.pCritical) &...
                (BpodSystem.Data.AnswerLicksROC.auROC(tfw(1):tfw(2)) > 0);
            fractionAbove = sum(validTrials) / bss.nTrialsAbove; % if you don't have enough trials to have nTrialsAbove auROC data points, still divide by nTrialsAbove to penalize not having enough data points
        else
            fractionAbove = NaN;
        end
    else
        BpodSystem.Data.AnswerLicksROC.auROC(currentTrial, 1) = NaN;
        BpodSystem.Data.AnswerLicksROC.pVal(currentTrial ,1) = NaN;
        BpodSystem.Data.AnswerLicksROC.CI(currentTrial, :) = [NaN NaN];        
        fractionAbove = NaN;
    end
    
    switchParameter = fractionAbove; % convention: rename for consistency with with other blockswitchfunction output arguments
    criterion = bss.fractionAboveNeeded; % similar reasoning
    if fractionAbove >= criterion
        nextBlock = S.Block.LinkTo;
    else
        nextBlock = S.GUI.Block;
    end
    
    
    

