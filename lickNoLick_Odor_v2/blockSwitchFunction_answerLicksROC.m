function [nextBlock, auROC, criterion] = blockSwitchFunction_answerLicksROC(outcomes, blockNumbers, S, varargin)
% This function is modeled after previous blockSwFcns that derive
% switchParameter from trial outcomes (discrete, of set [-1 0 1 2])
% HOWEVER- this function derives switchParameter from the anticipatory 
% lick rate during the answer period (auROC CS+ vs CS-)
% For consistency, I'm going to access the BpodSystem global variable to get the
% answer lick rate
%INPUTS
% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)
% S- settings structure
% OUTPUTS
% nextBlock- block of next trial
% auROC, scaled auROC comparing CS+ vs CS- anticipatory lick rate computed
% across a moving window of trials from each block trial segment
% criterion- target auROC for triggering a block switch (e.g. reversal)

    global BpodSystem

%% optional parameters, first set defaults
    defaults = {...
        'window', 20;... 
        'reset', 1;... % # pixels to push high or low to indicate alternative reinforcement outcomes
        'nBoot', 100;...
        };
    [ls, ~] = parse_args(defaults, varargin{:}); % combine default and passed (via varargin) parameter settings

    lastReverse = find(diff(blockNumbers), 1, 'last');
    if isempty(lastReverse)
        lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
    else
        lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
    end

    trialsCurrentBlock = length(find(~isnan(outcomes(lastReverse:end)))); % don't count uncued (for which outcome = NaN)
    if any(ismember(outcomes(lastReverse:end), [1 -1])) && any(ismember(outcomes(lastReverse:end), [0 2])) % needs to be at least 1 trial of each trial type (CS+ and CS-)
        HitRate = length(find(outcomes(lastReverse:end) == 1)) / length(find(ismember(outcomes(lastReverse:end), [1 -1]))); % 
        FARate = length(find(outcomes(lastReverse:end) == 0)) / length(find(ismember(outcomes(lastReverse:end), [0 2]))); % 
        rateDiff = HitRate - FARate;
    else
        rateDiff = NaN;
    end