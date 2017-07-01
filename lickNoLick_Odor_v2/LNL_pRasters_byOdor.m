function LNL_pRasters_byOdor(Op, varargin)
    global BpodSystem nidaq

        %% optional parameters, first set defaults
    defaults = {...
        'baselinePeriod', [1 4];... 
        'lookupFactor', 4;... % 1 - 3 second into recording
        'phRStamp', 6;... % # pixels to push high or low to indicate alternative reinforcement outcomes
        'decimationFactor', nidaq.online.decimationFactor;...
        'odorsToPlot', [1 2];...
        'XLim', 0;...
        };
    [ls, ~] = parse_args(defaults, varargin{:}); % combine default and passed (via varargin) parameter settings
    channelsOn = nidaq.channelsOn;
    Op = lower(Op);
    switch Op
        case 'init'
            BpodSystem.PluginObjects.Photometry.blF = []; %[nTrials, nDemodChannels]
            BpodSystem.PluginObjects.Photometry.baselinePeriod = ls.baselinePeriod;
            BpodSystem.PluginObjects.Photometry.trialDFF = {}; % 1 x nDemodChannels cell array, fill with nTrials x nSamples dFF matrix for now to make it easy to pull out raster data
            BpodSystem.ProtocolFigures.phRaster.decimationFactor = ls.decimationFactor;
            BpodSystem.ProtocolFigures.phRaster.lookupFactor = ls.lookupFactor;
            BpodSystem.ProtocolFigures.phRaster.phRStamp = ls.phRStamp;            
            BpodSystem.ProtocolFigures.phRaster.odorsToPlot = ls.odorsToPlot;
           if sum(channelsOn == 1)
                BpodSystem.ProtocolFigures.phRaster.fig_ch1 = ensureFigure('phRaster_ch1', 1);        
                nAxes = numel(ls.odorsToPlot);        
                % params.matpos defines position of axesmatrix [LEFT TOP WIDTH HEIGHT].    
                params.cellmargin = [0.02 0.02 0.02 0.02];   
                params.matpos = [0 0 1 1];        
                hAx = horzcat(hAx, axesmatrix(1, nAxes, 1:nAxes, params, gcf));      
                set(hAx, 'NextPlot', 'Add');
                BpodSystem.ProtocolFigures.phRaster.ax_ch1 = hAx;
                set(hAx, 'YDir', 'Reverse');
            else
                BpodSystem.ProtocolFigures.phRaster.fig_ch1 = [];
                BpodSystem.ProtocolFigures.phRaster.ax_ch1 = [];
            end
           if sum(channelsOn == 2)
                BpodSystem.ProtocolFigures.phRaster.fig_ch2 = ensureFigure('phRaster_ch2', 1);        
                nAxes = numel(ls.odorsToPlot);        
                % params.matpos defines position of axesmatrix [LEFT TOP WIDTH HEIGHT].    
                params.cellmargin = [0.02 0.02 0.02 0.02];   
                params.matpos = [0 0 1 1];        
                hAx = horzcat(hAx, axesmatrix(1, nAxes, 1:nAxes, params, gcf));      
                set(hAx, 'NextPlot', 'Add');
                BpodSystem.ProtocolFigures.phRaster.ax_ch1 = hAx;
                set(hAx, 'YDir', 'Reverse');
            else
                BpodSystem.ProtocolFigures.phRaster.fig_ch2 = [];
                BpodSystem.ProtocolFigures.phRaster.ax_ch2 = [];
           end         
        case 'update'
            %% update photometry rasters
            displaySampleRate = nidaq.sample_rate / BpodSystem.ProtocolFigures.phRaster.decimationFactor;
            x1 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(1), displaySampleRate, 0);
            x2 = bpX2pnt(BpodSystem.PluginObjects.Photometry.baselinePeriod(2), displaySampleRate, 0);        

               
            nTrials = length(BpodSystem.Data.TrialTypes);
            odorsToPlot = BpodSystem.ProtocolFigxdures.phRaster.odorsToPlot;
            phRStamp = BpodSystem.ProtocolFigures.phRaster.phRStamp;
            lookupFactor = BpodSystem.ProtocolFigures.phRaster.lookupFactor;
            for i = 1:length(odorsToPlot)
                thisOdorIndex = odorsToPlot(i);
                outcome_left = onlineFilterTrials_v2('OdorValveIndex', thisOdorIndex,'TrialOutcome', [-1, 0]); % miss or false alarm            
                outcome_right = onlineFilterTrials_v2('OdorValveIndex', thisOdorIndex,'TrialOutcome', [1, 2]); % hit or correct rejection
                rewardTrials = onlineFilterTrials_v2('ReinforcementOutcome', 'Reward');
                neutralTrials = onlineFilterTrials_v2('ReinforcementOutcome', 'Neutral');
                punishTrials = onlineFilterTrials_v2('ReinforcementOutcome', {'Punish', 'WNoise'});                
                if BpodSystem.Data.Settings.GUI.LED1_amp > 0
                    channelData = BpodSystem.PluginObjects.Photometry.trialDFF{1};
                    nSamples = size(channelData, 2);
                    if i == 1
                        set(BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch1, 'YData', 1:nTrials, 'XData', BpodSystem.Data.SwitchParameter);
                        set(BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch1, 'YData', 1:nTrials, 'XData', repmat(ls.switchParameterCriterion, 1, nTrials));            
                        if ~isnan(ls.switchParameterCriterion)
                            set(BpodSystem.ProtocolFigures.phRaster.ax_ch1(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.SwitchParameter(end) + 1, ls.switchParameterCriterion + 1)]);
                        else
                            if ~isnan(BpodSystem.Data.SwitchParameter(end))
                                set(BpodSystem.ProtocolFigures.phRaster.ax_ch1(1), 'YLim', [0 nTrials], 'XLim', [0 BpodSystem.Data.SwitchParameter(end) + 0.1]);
                            end
                        end
                    end
                    phMean = mean(nanmean(channelData(:,x1:x2)));
                    phStd = mean(nanstd(channelData(:,x1:x2)));    
                    ax = BpodSystem.ProtocolFigures.phRaster.ax_ch1(i + 1); % phRaster axes start at i + 1

                    CData = NaN(nTrials, nSamples * 2); % double width for split, mirrored, dual outcome raster
                    CData(outcome_left, (1:nSamples)) = fliplr(channelData(outcome_left, :));
                    CData(outcome_right, (nSamples+1):end) = channelData(outcome_right, :);
                    % add color tags marking trial reinforcment outcome
                    % high color = reward, 0 color = neutral, low color = punish
                    CData(rewardTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = 255; % 255 is arbitrary large value that will max out color table
                    CData(neutralTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = 0;            
                    CData(punishTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = -255;            
                    CData(rewardTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = 255; % 255 is arbitrary large value that will max out color table
                    CData(neutralTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = 0;            
                    CData(punishTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = -255;            
                    
                    image('YData', [1 size(CData, 1)], 'XData', ls.XLim,... % XData property is a 1 or 2 element vector
                        'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
                    set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd],...
                        'YTickLabel', {});
                    axis(ax, 'tight');
                end
                
                if BpodSystem.Data.Settings.GUI.LED2_amp > 0
                    channelData = BpodSystem.PluginObjects.Photometry.trialDFF{2};
                    nSamples = size(channelData, 2);
                    if i == 1
                        set(BpodSystem.ProtocolFigures.phRaster.nCorrectLine_ch2, 'YData', 1:nTrials, 'XData', BpodSystem.Data.SwitchParameter);
                        set(BpodSystem.ProtocolFigures.phRaster.nextReverseLine_ch2, 'YData', 1:nTrials, 'XData', repmat(ls.switchParameterCriterion, 1, nTrials));            
                        if ~isnan(ls.switchParameterCriterion)
                            set(BpodSystem.ProtocolFigures.phRaster.ax_ch2(1), 'YLim', [0 nTrials], 'XLim', [0 max(BpodSystem.Data.SwitchParameter(end) + 1, ls.switchParameterCriterion + 1)]);
                        else
                            if ~isnan(BpodSystem.Data.SwitchParameter(end))
                                set(BpodSystem.ProtocolFigures.phRaster.ax_ch2(1), 'YLim', [0 nTrials], 'XLim', [0 BpodSystem.Data.SwitchParameter(end) + 0.1]);
                            end
                        end
                    end
                    phMean = mean(mean(channelData(:,x1:x2)));
                    phStd = mean(std(channelData(:,x1:x2)));    
                    ax = BpodSystem.ProtocolFigures.phRaster.ax_ch2(i + 1); % phRaster axes start at i + 1

                    CData = NaN(nTrials, nSamples * 2); % double width for split, mirrored, dual outcome raster
                    CData(outcome_left, (1:nSamples)) = fliplr(channelData(outcome_left, :));
                    CData(outcome_right, (nSamples+1):end) = channelData(outcome_right, :);
                    % add color tags marking trial reinforcment outcome
                    % high color = reward, 0 color = neutral, low color = punish
                    CData(rewardTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = 255; % 255 is arbitrary large value that will max out color table
                    CData(neutralTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = 0;            
                    CData(punishTrials & outcome_left, (nSamples - phRStamp + 1):nSamples) = -255;            
                    CData(rewardTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = 255; % 255 is arbitrary large value that will max out color table
                    CData(neutralTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = 0;            
                    CData(punishTrials & outcome_right, (nSamples+1):(nSamples + phRStamp)) = -255;                   

                    image('YData', [1 size(CData, 1)], 'XData', ls.XLim,...
                        'CData', CData, 'CDataMapping', 'Scaled', 'Parent', ax);
                    set(ax, 'CLim', [phMean - lookupFactor * phStd, phMean + lookupFactor * phStd],...
                        'YTickLabel', {});
                    axis(ax, 'tight');
                end                
                

             
            end
        otherwise
            error('operator not correctly specified');
    end            