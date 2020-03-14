function odorTest

    global BpodSystem
    
    
        %% Define parameters
    S = BpodSystem.ProtocolSettings; % Load settings chosen in launch manager into current workspace as a struct called S


    defaults = {... % If settings file was an empty struct, populate struct with default settings
        'GUI.odor1On', 1;... % % which odors to cycle through
        'GUIMeta.odor1On.Style', 'checkbox';...      
        'GUI.odor2On', 1;... % % which odors to cycle through
        'GUIMeta.odor2On.Style', 'checkbox';...       
        'GUI.odor3On', 1;... % % which odors to cycle through
        'GUIMeta.odor3On.Style', 'checkbox';...  
        'GUI.odor4On', 1;... % % which odors to cycle through
        'GUIMeta.odor4On.Style', 'checkbox';...       
    };
    S = setBpodDefaultSettings(S, defaults);
        %% Pause and wait for user to edit parameter GUI 
    BpodParameterGUI('init', S);    
    BpodSystem.Pause = 1;
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    S = BpodParameterGUI('sync', S); % Sync parameters with BpodParameterGUI plugin
    BpodSystem.ProtocolSettings = S; % copy settings back prior to saving
    SaveBpodProtocolSettings;
    
    
    odorsOnIx = find(logical([S.GUI.odor1On S.GUI.odor2On S.GUI.odor3On S.GUI.odor4On]));
    odorValves = [5 6 7 8];
    odorsOn = odorValves(odorsOnIx);
    
    
    %% Initialize Sound Stimuli to signal odor valve actuation
%     SF = 192000; 
%     % linear ramp of sound for 10ms at onset and offset
%     oneBeep = makeBeeps(1);
%     twoBeep = makeBeeps(2);
%     threeBeep = makeBeeps(3);
%     fourBeep = makeBeeps(4);
%     PsychToolboxSoundServer('init')
%     PsychToolboxSoundServer('Load', 1, oneBeep);
%     PsychToolboxSoundServer('Load', 2, twoBeep);
%     PsychToolboxSoundServer('Load', 3, threeBeep);
%     PsychToolboxSoundServer('Load', 4, fourBeep);
%     BpodSystem.SoftCodeHandlerFunction = 'SoftCodeHandler_PlaySound';
%     
%     
    % retrieve machine specific olfactometer settings
    addpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % Settings path is assumed to be shielded by gitignore file
    olfSettings = machineSpecific_Olfactometer;
    rmpath(genpath(fullfile(BpodSystem.BpodUserPath, 'Settings Files'))); % remove it just in case there would somehow be a name conflict   
    
    
    olfWireArg = 0;
    olfBNCArg = 0;    
    
    switch olfSettings.triggerType
        case 'WireState'
            olfWireArg = bitset(olfWireArg, olfSettings.triggerNumber);
        case 'BNCState'
            olfBNCArg = bitset(olfBNCArg, olfSettings.triggerNumber);
    end    
            
    % initialize olfactometer slave arduino
    valveSlave = initValveSlave(olfSettings.portName);
    if isempty(valveSlave)
        BpodSystem.BeingUsed = 0;
        error('*** Failure to initialize valve slave ***');
    end        
    
    for currentTrial = 1:100
        
        switch rem(currentTrial, length(odorsOn))
            case 0
                OdorValve = odorsOn(1);
                softCode = odorsOnIx(1);
            case 1
                OdorValve = odorsOn(2);
                softCode = odorsOnIx(2);
            case 2
                OdorValve = odorsOn(3);
                softCode = odorsOnIx(3);
            case 3
                OdorValve = odorsOn(4);
                softCode = odorsOnIx(4);
        end
            
        slaveResponse = updateValveSlave(valveSlave, OdorValve); 
        if isempty(slaveResponse)
            disp(['*** Valve Code not succesfully updated, trial #' num2str(currentTrial) ' skipped ***']);
            continue
        else
            disp(['*** Valve #' num2str(slaveResponse) ' Trial #' num2str(currentTrial) ' ***']);
        end            
        
        
        sma = NewStateMatrix(); 
        sma = AddState(sma, 'Name', 'Start', ...
            'Timer', 0,...
            'StateChangeConditions', {'Tup', 'ITI'},...
            'OutputActions', {}); 
        sma = AddState(sma,'Name', 'ITI', ...
            'Timer', 4,...
            'StateChangeConditions', {'Tup', 'cueOdor'},...
            'OutputActions', {});         
%         sma = AddState(sma, 'Name', 'cueOdor', ... 
%             'Timer', 0.1,...
%             'StateChangeConditions', {'Tup', 'Delay'},...
%             'OutputActions', {'SoftCode', softCode}); 
        sma = AddState(sma, 'Name', 'cueOdor', ... 
            'Timer', 0.1,...
            'StateChangeConditions', {'Tup', 'Delay'},...
            'OutputActions', {}); 
        sma = AddState(sma,'Name', 'Delay', ...
            'Timer', 0.5,...
            'StateChangeConditions', {'Tup', 'Odor'},...
            'OutputActions', {});       
        sma = AddState(sma, 'Name', 'Odor', ... 
            'Timer', 1,...
            'StateChangeConditions', {'Tup','exit'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});        
%         sma = AddState(sma, 'Name', 'Odor', ... 
%             'Timer', 1,...
%             'StateChangeConditions', {'Tup','exit'},...
%             'OutputActions', {'WireState', olfWireArg, 'BNCState', 2});  
        
        %%
        SendStateMatrix(sma);        
                
        %% Run state matrix
        RawEvents = RunStateMatrix();  % Blocking!       
        
        if BpodSystem.BeingUsed == 0
            if ~BpodSystem.EmulatorMode
                fclose(valveSlave);
                delete(valveSlave);
            end
            return
        end     
    end
end

% function beeps =  makeBeeps(nBeeps)
% SF = 192000; 
% Duration = 0.1;
% Frequency = 2000;
%     dt = 1/SF;
%     t = 0:dt:Duration;
%     SineWave=sin(2*pi*Frequency*t)/100;
% 
%     beeps = repmat([SineWave SineWave .* 0], 1, nBeeps);
% end