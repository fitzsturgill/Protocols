function [nextBlock, rateDiff, criterion] = blockSwitchFunction_responseRateDifference(outcomes, blockNumbers, S)
% outcomes-  vector of outcomes (1xnTrials)
% blockNubers-  vector of blockNumbers (1xnTrials)
% S- settings structure

          
%         % response rate difference dictates reversal, LinkToFcn =
%         % blockSwitchFunction_responseRateDifference
%         'SwFcn_BlockRRD_minDiff', 0.5;...
%         'SwFcn_BlockRRD_minTrials', 20;...
            
        nextBlock = 0;
        lastReverse = find(diff(blockNumbers), 1, 'last');

        if isempty(lastReverse)
            lastReverse = 1; % you can't have reversed on first trial but 1 as an index is useful
            elseg
            lastReverse = lastReverse + 1; % diff gives you trial BEFORE something happens so we add + 1
        end
%         trialsCurrentBlock = numel(blockNumbers) - lastReverse; % already added 1 to lastReverse
        trialsCurrentBlock = length(find(~isnan(outcomes(lastReverse:end)))); % don't count uncued (for which outcome = NaN)
        if any(ismember(outcomes(lastReverse:end), [1 -1])) && any(ismember(outcomes(lastReverse:end), [0 2])) % needs to be at least 1 trial of each trial type (CS+ and CS-)
            HitRate = length(find(outcomes(lastReverse:end) == 1)) / length(find(ismember(outcomes(lastReverse:end), [1 -1]))); % 
            FARate = length(find(outcomes(lastReverse:end) == 0)) / length(find(ismember(outcomes(lastReverse:end), [0 2]))); % 
            rateDiff = HitRate - FARate;
        else
            rateDiff = NaN;
        end

    %   

        if rateDiff >= S.SwFcn_BlockRRD_minDiff && trialsCurrentBlock >= S.SwFcn_BlockRRD_minTrials
            nextBlock = S.block.LinkTo;
        else
            nextBlock = S.GUI.Block;
        end
        
        criterion = S.SwFcn_BlockRRD_minDiff;

                
                
            
            
%         function y = movsum(x, N)
%             x = double(x);
%             y = conv(x,ones(N,1), 'same');
%         end