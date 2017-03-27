function [nextBlock, nCorrect, criterion] = blockSwitchFunction_nCorrect(outcomes, blockNumbers, S)
% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)
% S- settings for 
%% adaptive code or function to determine if a reversal is necessary 
        % common across LinkTo functions
%         'performanceTally', [];... % tally of parameter controlling reversals
%         'reversalCriterion', [];... % criterion for reversal
%         
%         % number correct dictates reversal, LinkToFcn =
%         % blockSwitchFunction_nCorrect
%         'SwFcn_nC_MinCorrect', 10;... 
%         'SwFcn_nC_MeanAdditionalCorrect', 10;...
%         'SwFcn_nC_MaxAdditionalCorrect', 20;...
            
        nextBlock = 0;
        lastReverse = find(diff(blockNumbers), 1, 'last');
        if isempty(lastReverse)
            lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
        else
            lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
        end

        nCorrect = length(find(outcomes(lastReverse:end) == 1)); % count hits only

    %                 Determine nCorrectNeeded for this trial (doesn't really matter
    %                 that I calculate this for every trial, regardless of
    %                 whether a reversal is to occur)
        p = 1/(S.SwFcn_nC_meanAdditionalCorrect + 1); % for geometric distribution, mean = (1-p) / p
        additionalCorrectNeeded = Inf;
        while additionalCorrectNeeded > S.SwFcn_nC_MaxAdditionalCorrect
            additionalCorrectNeeded = geornd(p); % geometric distribution with probability = p of success on each trial
        end
        nCorrectNeeded = S.SwFcn_nC_MinCorrect + additionalCorrectNeeded;

        if nCorrect == nCorrectNeeded
            nextBlock = S.block.LinkTo;
        end
        
        criterion = nCorrectNeeded;

                
                
            
            
%         function y = movsum(x, N)
%             x = double(x);
%             y = conv(x,ones(N,1), 'same');
%         end