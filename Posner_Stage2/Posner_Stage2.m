function Posner_Stage2

    global BpodSystem
    
    S = BpodSystem.ProtocolSettings;
    
if isempty(fieldnames(S))  % If settings file was an empty struct, populate struct with default settings
    S.GUI.RewardAmount = 5; %ul
    S.GUI.Punish = 6; % How long the mouse must wait in the goal port for reward to be delivered
    
    S.GUI.CueLightIntensity = 2.5; %Set Cue light intensity
    S.GUI.TargetLightIntensity = 255; %Set target light intensity
    
    S.GUI.BaselineIntensity=2.5;
    S.GUI.foreperiod = 1;
    S.GUI.CueDelay = 1; % How long the mouse must poke in the center to activate the goal port
    S.GUI.LightOn=1;
    
    S.GUI.RealITI = 2;
    S.GUI.windowIncrement = 3;
    
  
     
%% Suelynn: Note you Can define variables in settings without linking them to the GUI:
%% Useful for variables you want to save in the settings but aren't likely to change on the fly (keeps GUI uncluttered)
    S.DrinkingGrace = 0.25; 
    S.TargetLightOn = 100;
    S.maxForeperiod = 100;
    S.maxCueDelay = 100;
    S.maxLightOn = 100;
    S.foreperiod = S.GUI.foreperiod;    
    S.CueDelay = S.GUI.CueDelay;
    S.LightOn = S.GUI.LightOn;    
end    