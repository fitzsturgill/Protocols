function sound=SoundGenerator_SL(sampRate, meanFreq, duration, amplitude)
%sound=SoundGenerator(sampRate, meanFreq, duration, amplitude).
%
%Generates a pure tone.
%The frequencies are defined by "meanFreq".
%sampRate is the sampling Rate of the sound card.
%function written by Shujing for lickNolick_Aud bpod protocol.

%     if nargin ~=4
%         disp('*** please enter correct arguments for the SoundGenerator function ***');
%         return;
%     end

   
    TimeVec = (0:1/sampRate:duration);
    sound = sin(2*pi*meanFreq*TimeVec);
    
    %adjust signal volume
%     SoundCal = BpodSystem.CalibrationTables.SoundCal;
%     if(isempty(SoundCal))
%         disp('Error: no sound calibration file specified');
%         return
%     end
%     SpeakerCalibrationFile = 'C:\Users\Adam\BpodUser\Calibration Files\SoundCalibration.mat';
%     SoundCal = load(SpeakerCalibrationFile);

    SoundCal = load('C:\Users\Adam\BpodUser\Calibration Files\SoundCalibration.mat');

%     for s=1:2 %loop over two speakers
%         toneAtt = polyval(SoundCal.SoundCal(1,s).Coefficient, meanFreq);
%         diffSPL = amplitude - [SoundCal.SoundCal(1,s).TargetSPL];
%         attFactor = sqrt(10.^(diffSPL./10)); 
%         att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
%         sound = sound.*att; 
%     end
    

    toneAtt = polyval(SoundCal.SoundCal.Coefficient,meanFreq);
    diffSPL = amplitude - [SoundCal.SoundCal.TargetSPL];
    attFactor = sqrt(10.^(diffSPL./10)); 
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    sound =sound*att;

    

        


        
