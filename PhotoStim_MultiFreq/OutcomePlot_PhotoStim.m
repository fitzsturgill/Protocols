function OutcomePlot_PhotoStim(AxesHandles,Action)
global BpodSystem
global TaskParameters
switch Action
    case 'init'
        axes(AxesHandles.HandleOutcome);
        set(AxesHandles.HandleOutcome,'TickDir', 'out','XLim',[0, 10],'YLim', [0, 6], 'YTick', [1, 2,3,4,5],'YTickLabel', {'5Hz','10Hz','20Hz','40Hz','80Hz'}, 'FontSize', 13);
        xlabel(AxesHandles.HandleOutcome, 'Trial#', 'FontSize', 14);
        hold(AxesHandles.HandleOutcome, 'on');
            
        BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle = line(1,0, 'LineStyle','none','Marker','o','MarkerEdge','k','MarkerFace',[1 1 1], 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.Correct = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','g','MarkerFace','g', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.Incorrect = line(-1,1, 'LineStyle','none','Marker','o','MarkerEdge','r','MarkerFace','r', 'MarkerSize',6);
        BpodSystem.GUIHandles.OutcomePlot.Time =  text(0.5,5.5,[' min and ' ' sec remaining.']);
    case 'update'
        
        Xdata = find(BpodSystem.Data.Outcomes==1);
        Ydata = BpodSystem.Data.StimFreqIdx;
        set(BpodSystem.GUIHandles.OutcomePlot.Correct, 'xdata', Xdata, 'ydata', Ydata);
        
        Xdata = find(BpodSystem.Data.Outcomes==0);
        Ydata = BpodSystem.Data.StimFreqIdx;
        set(BpodSystem.GUIHandles.OutcomePlot.Incorrect, 'xdata', Xdata, 'ydata', Ydata);
        
        set(BpodSystem.GUIHandles.OutcomePlot.CurrentTrialCircle, 'xdata', BpodSystem.Data.iTrial(end)+1, 'ydata', 0);
        set(AxesHandles.HandleOutcome, 'XLim', [0, max([TaskParameters.GUI.NTrials,BpodSystem.Data.iTrial(end)+1])])
        
        %time left?
        TrialsLeft = TaskParameters.GUI.NTrials - BpodSystem.Data.iTrial(end);
        Freqs = TaskParameters.GUI.StimFreq.Freq(logical(TaskParameters.GUI.StimFreq.Active));
        FreqTr = round(TrialsLeft/length(Freqs));
        TimeLeft = sum(1./Freqs.*TaskParameters.GUI.NPulses*FreqTr) + TrialsLeft*TaskParameters.GUI.ITI;
        sec = mod(TimeLeft,60);
        min = floor(TimeLeft/60);
        BpodSystem.GUIHandles.OutcomePlot.Time.String =[ num2str(min),' min and ',num2str(sec), ' sec remaining.'];
end

end

