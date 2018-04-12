function [nextBlock, switchParameter, criterion] = blockSwitchFunction_answerLicksROC(outcomes, blockNumbers, S, varargin)

% LOGICAL? IS USE OF VARARGIN CORRECT HERE, WILL I EVER USE IT CONSIDERING
% HOW i REFERENCE THE BLOCK SWITCH FUNCTIONS WITHIN THE BLOCKS???

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
        'ROCwindow', 20;... 
        'reset', 1;... 
        'nBoot', 100;...
        'pCritical', 0.05;...
        'nTrialsAbove', 20;...  % for how many trials does the p value need to pass the criterion (at least by the fractionAboveNeeded)
        'fractionAboveNeeded', 0.9;...
        'minTrials', 50;...
        };
% %% testing kludge
%     defaults = {...
%         'ROCwindow', 20;... 
%         'reset', 1;... 
%         'nBoot', 100;...
%         'pCritical', 0.05;...
%         'nTrialsAbove', 3;...  % for how many trials does the p value need to pass the criterion (at least by the fractionAboveNeeded)
%         'fractionAboveNeeded', 0.6;...
%         'minTrials', 20;...
%         };

% %% end kludge
    [bss, ~] = parse_args(defaults, varargin{:}); % block switch settings
    auROC = NaN;
    
    
    lastReverse = find(diff(blockNumbers), 1, 'last');
    if isempty(lastReverse)
        lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
    else
        lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
    end
    
    currentTrial = length(outcomes);
    trw = [max(max(1, currentTrial - bss.ROCwindow + 1), lastReverse), currentTrial]; % trw = thisROCwindow
    tfw = [max(max(1, currentTrial - bss.nTrialsAbove + 1), lastReverse), currentTrial]; % tfw = this nTrialsAbove window

    theseData = BpodSystem.Data.AnswerLicks.rate(trw(1):trw(2));
    thesePlusTrials = BpodSystem.Data.CSValence(trw(1):trw(2)) == 1;
    theseMinusTrials = BpodSystem.Data.CSValence(trw(1):trw(2)) == -1;
    nTrialsCurrent = currentTrial - lastReverse + 1; % don't count uncued (for which outcome = NaN)    
    
    if any(thesePlusTrials) && any(theseMinusTrials) % needs to be at least 1 trial of each trial type (CS+ and CS-)
        [D, P, CI] = rocarea_CI(theseData(thesePlusTrials), theseData(theseMinusTrials), 'boot', bss.nBoot, 'scale');
        BpodSystem.Data.AnswerLicksROC.auROC(currentTrial, 1) = D;
        BpodSystem.Data.AnswerLicksROC.pVal(currentTrial ,1) = P;
        BpodSystem.Data.AnswerLicksROC.CI(currentTrial, :) = CI;
        % compute fraction significant trials(the switch parameter)
        if nTrialsCurrent >= bss.nTrialsAbove
            % keeper trials have positive auROC and are significant
            validTrials = (BpodSystem.Data.AnswerLicksROC.pVal(tfw(1):tfw(2)) <= bss.pCritical) &...
                (BpodSystem.Data.AnswerLicksROC.auROC(tfw(1):tfw(2)) > 0);
            fractionAbove = sum(validTrials) / bss.nTrialsAbove;
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
    
    
    

