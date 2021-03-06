%{
----------------------------------------------------------------------------

This file is part of the Bpod Project
Copyright (C) 2014 Joshua I. Sanders, Cold Spring Harbor Laboratory, NY, USA

----------------------------------------------------------------------------

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, version 3.

This program is distributed  WITHOUT ANY WARRANTY and without even the 
implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  
See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
%}
% function OutcomePlot(AxesHandle,TrialTypeSides, OutcomeRecord, CurrentTrial)
function OutcomePlot_Pavlov(AxesHandle, Action, varargin)
%% 
% Plug in to Plot reward side and trial outcome.
% AxesHandle = handle of axes to plot on
% Action = specific action for plot, "init" - initialize OR "update" -  update plot

%Example usage:
% OutcomePlot(AxesHandle,'init',TrialTypeSides)
% OutcomePlot(AxesHandle,'init',TrialTypeSides,'ntrials',90)
% OutcomePlot(AxesHandle,'update',CurrentTrial,TrialTypeSides,OutcomeRecord)

% varargins:
% TrialTypeSides: Vector of 0's (right) or 1's (left) to indicate reward side (0,1), or 'None' to plot trial types individually
% OutcomeRecord:  Vector of trial outcomes
%                 Simplest case: 
%                               1: correct trial (green)
%                               0: incorrect trial (red)
%                 Advanced case: 
%                               NaN: future trial (blue)
%                                -1: withdrawal (red circle)
%                                 0: incorrect choice (red dot)
%                                 1: correct choice (green dot)
%                                 2: did not choose (green circle)
% OutcomeRecord can also be empty
% Current trial: the current trial number

% Adapted from BControl (SidesPlotSection.m) 
% Kachi O. 2014.Mar.17

%% Code Starts Here
global nTrialsToShow %this is for convenience
% global BpodSystem

switch Action
    case 'init'
        %initialize pokes plot
        SideList = varargin{1};
        %SideList = SideList+.5;
        ColorList = varargin{2};
        
               
        nTrialsToShow = 90; %default number of trials to display
        
        if nargin > 4 %custom number of trials
            nTrialsToShow =varargin{4};
        end
        
        %plot in specified axes
        scatter(AxesHandle,  find(ColorList(1:nTrialsToShow) == 0), SideList(ColorList(1:nTrialsToShow) == 0),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [0 0 1]);
        hold(AxesHandle, 'on');
        scatter(AxesHandle,  find(ColorList(1:nTrialsToShow) == 1), SideList(ColorList(1:nTrialsToShow) == 1),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [0 1 0]);
        scatter(AxesHandle,  find(ColorList(1:nTrialsToShow) == 2), SideList(ColorList(1:nTrialsToShow) == 2),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [1 0 0]);
        set(AxesHandle,'TickDir', 'out','YLim', [-2, 1], 'YTick', [-1 0],'YTickLabel', { 'Type 2','Type 1'}, 'FontSize', 16);
        xlabel(AxesHandle, 'Trial#', 'FontSize', 18);
        
        
    case 'update'
        CurrentTrial = varargin{1};
        SideList = varargin{2};
        OutcomeRecord = varargin{3};
        ColorList = varargin{4};
       
        
        if CurrentTrial<1
            CurrentTrial = 1;
        end
        
        % recompute xlim
        [mn, mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow);
        
        %plot future trials
        FutureTrialsIndx = CurrentTrial:mx;
        scatter(AxesHandle,  FutureTrialsIndx(ColorList(FutureTrialsIndx) == 0), SideList(FutureTrialsIndx(ColorList(FutureTrialsIndx) == 0)),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [0 0 1]);
        hold(AxesHandle, 'on');
        scatter(AxesHandle,  FutureTrialsIndx(ColorList(FutureTrialsIndx) == 1), SideList(FutureTrialsIndx(ColorList(FutureTrialsIndx) == 1)),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [0 1 0]);
        scatter(AxesHandle,  FutureTrialsIndx(ColorList(FutureTrialsIndx) == 2), SideList(FutureTrialsIndx(ColorList(FutureTrialsIndx) == 2)),'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', [1 0 0]);
        
        %Plot current trial
        scatter(AxesHandle,CurrentTrial,SideList(CurrentTrial), 'o', 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', 'k')
        scatter(AxesHandle,CurrentTrial,SideList(CurrentTrial), '+', 'MarkerFaceColor',[1 1 1],'MarkerEdgeColor', 'k')
        
        %Plot past trials
        if ~isempty(OutcomeRecord)
            indxToPlot = mn:CurrentTrial-1;
            %Plot NoLick, punished
            EarlyWithdrawalTrialsIndx =(OutcomeRecord(indxToPlot) == 4);
            scatter(AxesHandle,  indxToPlot(EarlyWithdrawalTrialsIndx), SideList(indxToPlot(EarlyWithdrawalTrialsIndx)),'ro','MarkerFaceColor',[1 1 1]);
            %Plot Lick, punished
            InCorrectTrialsIndx = (OutcomeRecord(indxToPlot) == 0);
            scatter(AxesHandle,  indxToPlot(InCorrectTrialsIndx), SideList(indxToPlot(InCorrectTrialsIndx)),'MarkerFaceColor','r','MarkerEdgeColor', 'r');
            %Plot Lick, rewarded
            CorrectTrialsIndx = (OutcomeRecord(indxToPlot) == 1);
            scatter(AxesHandle,  indxToPlot(CorrectTrialsIndx), SideList(indxToPlot(CorrectTrialsIndx)),'MarkerFaceColor','g','MarkerEdgeColor', 'g');
            %Plot NoLick, unrewarded
            DidNotChooseTrialsIndx = (OutcomeRecord(indxToPlot) == 2);
            scatter(AxesHandle,  indxToPlot(DidNotChooseTrialsIndx), SideList(indxToPlot(DidNotChooseTrialsIndx)),'go','MarkerFaceColor',[1 1 1]);
            %Plot Lick, omission
            DidNotChooseTrialsIndx = (OutcomeRecord(indxToPlot) == 5);
            scatter(AxesHandle,  indxToPlot(DidNotChooseTrialsIndx), SideList(indxToPlot(DidNotChooseTrialsIndx)),'MarkerEdgeColor','b','MarkerFaceColor','b');
            %Plot NoLick, omission
            DidNotChooseTrialsIndx = (OutcomeRecord(indxToPlot) == 3);
            scatter(AxesHandle,  indxToPlot(DidNotChooseTrialsIndx), SideList(indxToPlot(DidNotChooseTrialsIndx)),'bo','MarkerFaceColor',[1 1 1]);
            xlabel(AxesHandle, 'Trial#', 'FontSize', 18);
            drawnow;
        end

end

end

function [mn,mx] = rescaleX(AxesHandle,CurrentTrial,nTrialsToShow)
FractionWindowStickpoint = .75; % After this fraction of visible trials, the trial position in the window "sticks" and the window begins to slide through trials.
mn = max(round(CurrentTrial - FractionWindowStickpoint*nTrialsToShow),1);
mx = mn + nTrialsToShow - 1;
set(AxesHandle,'XLim',[mn-1 mx+1]);
end


