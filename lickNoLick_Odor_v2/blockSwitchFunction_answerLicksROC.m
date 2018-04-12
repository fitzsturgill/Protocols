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
        'ROCwindow', 20;... 
        'reset', 1;... 
        'nBoot', 100;...
        'pCritical', 0.05;...
        'nTrialsAbove', 20;...  % for how many trials does the p value need to pass the criterion (at least by the fractionAboveNeeded)
        'fractionAboveNeeded', 0.9;...
        'minTrials', 50;...
        };
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

    theseData = BpodSystem.AnswerLicks.rate(trw(1):trw(2));
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
        end
    else
        fractionAbove = NaN;
    end
    
    switchParameter = fractionAbove; % convention: rename for consistency with with other blockswitchfunction output arguments
    criterion = bss.fractionAboveNeeded; % similar reasoning
    if fractionAbove >= criterion
        nextBlock = S.Block.LinkTo;
    else
        nextBlock = S.GUI.Block;
    end
    
    
    
end

function varargout = rocarea_CI(x,y,varargin)
% 
%  [D, P, CI] = rocarea(x,y,{'boot',n},{'transform'},{'PLOT'})
%
%  Computes discriminability index or area under ROC curve. 
% D : discriminability index or auROC
% Confidence Interval : bootstrapped confidence interval for D statistic 
%  x, y : data
%  'boot', n: number of bootstraps
%  transform: 'swap' -- always gives you results between 0.5 - 1
%             'scale' -- scales to give you results from -1 to 1
%
% 'PLOT' -- plots the ROC curve
%
% AK 2/2002
% AK 4/2005
% FS 4/2018

Nboot = 0;
TRANSFORM = 0;
if isempty(x) || isempty(y)
    if nargout > 0
        varargout{1} = NaN; % D
    end
    if nargout > 1
        varargout{2} = NaN; % P
    end
    if nargout > 2
        varargout{3} = [NaN NaN]; % CI
    end    
   return
end

if nargin > 2
    switch lower(varargin{1}) 
        case 'boot'
            Nboot = varargin{2};
        case 'swap'
              TRANSFORM = 1;
        case 'scale'
              TRANSFORM = 2;
        otherwise
              TRANSFORM = 0;
    end
    if nargin > 4
      switch lower(varargin{3}) 
        case 'swap'
              TRANSFORM = 1;
        case 'scale'
              TRANSFORM = 2;
      end
    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

x=x(:); y=y(:);


nbin = ceil(max(length(x)*1.2,length(y)*1.2)); % some automatic assignment for number of bins
MN = min([x;y]);    MX = max([x;y]);
bin_size = (MX-MN)/nbin;
bins = MN-bin_size:bin_size:MX+bin_size;
Lx = length(x); Ly = length(y);

%%%%%%%%%%%%%%%%%%%%
% ROC calculation
%%%%%%%%%%%%%%%%%%%%
D = auc(x,y,Lx,Ly,bins);


%%%%%%%%%%%%%%
% bootstrap- bootstrap P value and confidence interval for D statistic
%%%%%%%%%%%%%
if Nboot > 0

 z = [x; y]; % null hypothesis, x and y are drawn from same distribution
 DbootNull = NaN(Nboot, 1);
 Dboot = NaN(Nboot, 1);
 for i=1:Nboot    
   % can we reject null hypothesis?
   orderNull=round(rand(1,Lx+Ly)*(Lx+Ly-1))+1;  %resample null
   pxNull=z(orderNull(1:Lx));           %resort
   pyNull=z(orderNull(Lx+1:Lx+Ly));
   DbootNull(i)= auc(pxNull,pyNull,Lx,Ly,bins);     %recalculate D
   
   % confidence intervals for D
   orderx = round(rand(1,Lx)*(Lx-1))+1;  %resample x
   ordery = round(rand(1,Ly)*(Ly-1))+1;  %resample y
   px=x(orderx);           
   py=y(ordery);
   thisD = auc(px,py,Lx,Ly,bins);
   switch TRANSFORM
    case 1 
        thisD=abs(thisD-0.5)+0.5;       % 'swap'
    case 2
        thisD=2*(thisD-0.5);            % 'scale'
   end
   Dboot(i)= thisD;     % transformed
 end
    % P value for null hypothesis
    P = iprctile(DbootNull,D);
    if D > mean(DbootNull)
        P = 1 - P;
    end
    % compute confidence intervals from bootstrapped distributions
    CI = zeros(1,2);
    CI(1) = percentile(Dboot, .05);
    CI(2) = percentile(Dboot, .95);    
else
   P = 1;
   CI = [NaN NaN];
end


%%%%%%%%%%%%%%
% transform D
%%%%%%%%%%%%%
switch TRANSFORM
    case 1 
        D=abs(D-0.5)+0.5;       % 'swap'
    case 2
        D=2*(D-0.5);            % 'scale'
end

%%%%%%%%%%%%
%  P L O T
%%%%%%%%%%%
if nargin > 2 & strcmp(lower(varargin{end}), 'plot')
  p = histc(x,bins);  q = histc(y,bins);
  cdf1 = cumsum(p)/Lx;   cdf2 = cumsum(q)/Ly;
  hold on
  plot(cdf2,cdf1,'b','LineWidth',2);
  plot([0 1],[0 1],'k');
  xlabel('False alarm'); ylabel('Hit rate');
  title(num2str(D));
end
% set outputs
if nargout > 0
    varargout{1} = D;
end
if nargout > 1
    varargout{2} = P;
end
if nargout > 2
    varargout{3} = CI;
end
end
    

function D = auc(x,y,Lx,Ly,bins);

p = histc(x,bins);  q = histc(y,bins);

cdf1 = cumsum(p)/Lx;   cdf2 = cumsum(q)/Ly;

if isempty(cdf1) || isempty(cdf2)
    D = NaN;
else
    D=trapz(cdf1,cdf2);
end
end