function [nextBlock, nCorrect] = blockSwitchFunction_nCorrect(outcomes, blockNumbers, S)
% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)
% S- settings for 
%% adaptive code or function to determine if a reversal is necessary 
%         % parameters controling reversals
%         S.BlockFirstReverseCorrect = 30; % number of correct responses necessary prior to initial reversal
%         S.BlockCountCorrect = 0; % tally of correct responses prior to a reversal
%         S.BlockMinCorrect = 10;
%         S.BlockMeanAdditionalCorrect = 10;
%         S.BlockMaxAdditionalCorrect = S.BlockMeanAdditionalCorrect * 2;
%         S.BlockAdditionalCorrect = []; % determined adaptively
%         S.GUI.Reverse = 0; % determined adaptively, do I need this?   
            
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
        p = 1/(S.BlockMeanAdditionalCorrect + 1); % for geometric distribution, mean = (1-p) / p
        additionalCorrectNeeded = Inf;
        while additionalCorrectNeeded > S.BlockMaxAdditionalCorrect
            additionalCorrectNeeded = geornd(p); % geometric distribution with probability = p of success on each trial
        end
        nCorrectNeeded = S.BlockMinCorrect + additionalCorrectNeeded;

        if nCorrect == nCorrectNeeded
            nextBlock = S.block.LinkTo;
        end

                
                
            
            
%         function y = movsum(x, N)
%             x = double(x);
%             y = conv(x,ones(N,1), 'same');
%         end