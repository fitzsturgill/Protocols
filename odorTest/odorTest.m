function odorTest

    global BpodSystem
    
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
        
        switch rem(currentTrial, 3)
            case 1
                OdorValve = 5;
            case 2
                OdorValve = 6;
            case 4
                OdorValve = 7;
        end
            
        slaveResponse = updateValveSlave(valveSlave, OdorValve); 
        if isempty(slaveResponse);
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
            'StateChangeConditions', {'Tup', 'DummyClick'},...
            'OutputActions', {});         
        sma = AddState(sma, 'Name', 'DummyClick', ... 
            'Timer', 0.1,...
            'StateChangeConditions', {'Tup', 'Delay'},...
            'OutputActions', {'ValveState', 1}); 
        sma = AddState(sma,'Name', 'Delay', ...
            'Timer', 0.4,...
            'StateChangeConditions', {'Tup', 'Odor'},...
            'OutputActions', {});       
        sma = AddState(sma, 'Name', 'Odor', ... 
            'Timer', 1,...
            'StateChangeConditions', {'Tup','exit'},...
            'OutputActions', {'WireState', olfWireArg, 'BNCState', olfBNCArg});        
        
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