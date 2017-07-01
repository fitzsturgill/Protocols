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