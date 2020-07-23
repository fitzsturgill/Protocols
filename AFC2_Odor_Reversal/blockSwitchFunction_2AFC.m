function [nextBlock, switchParameter, criterion] = blockSwitchFunction_2AFC(outcomes, blockNumbers, LinkTo, varargin)

% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)

% switchParameter-   this function outputs percent correct over last n
% trials

%% optional parameters, first set defaults
    defaults = {...
        'window', 20;... % 20 trials comprise the window for calculating performance
        'criterion', 0.85;... % percent correct over last n trials
        'minTrials', 30;... % 50 minimum trials to trigger reversal, should be >= window
        };
    [bss, ~] = parse_args(defaults, varargin{:}); % block switch settings    
    assert(bss.minTrials >= bss.window, 'minTrials must be >= window');
    criterion = bss.criterion;
    nextBlock = blockNumbers(end); % don't switch blocks by default
    
    lastReverse = find(diff(blockNumbers), 1, 'last');
    if isempty(lastReverse)
        lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
    else
        lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
    end

    % select last n=window trials, if too few trials calculate criterion
    % but don't switch blocks
    theseTrials = find(ismember(outcomes(lastReverse:end), [0 1]));
    totalTrials = length(theseTrials); % total number of trials with responses from last reversal;
    theseTrials = theseTrials(end - min(bss.window, length(theseTrials)) + 1:end);
    
    if isempty(theseTrials)
        switchParameter = NaN;
        return
    else
        % early withdrawal -1; incorrect 0; correct 1; miss 2
        nCorrect = sum(outcomes(lastReverse:end) == 1); % count hits only
        nIncorrect = sum(outcomes(lastReverse:end) == 0); % count hits only
        nTotal = nCorrect + nIncorrect;
        switchParameter = nCorrect / nTotal;
    end
   

    if totalTrials >= bss.minTrials
        nextBlock = LinkTo;
    end
   

    
    

