function sound=SoundGenerator(sampRate, meanFreq, duration, amplitude)
%sound=SoundGenerator(sampRate, meanFreq, duration, amplitude).
%
%Generates a pure tone.
%The frequencies are defined by "meanFreq".
%SamplingRate is the sampling Rate of the sound card.
%
%function written by Shujing for lickNolick_Aud bpod protocol.

    if nargin ~=4
        disp('*** please enter correct arguments for the SoundGenerator function ***');
        return;
    end
    
    TimeVec = (0:1/sampRate:duration)';
    sound = sin(2*pi*meanFreq*TimeVec);
    
    %adjust signal volume
    SpeakerCalibrationFile = 'C:\Users\Adam\BpodUser\Calibration Files\SoundCalibration.mat';
    SoundCal = load(SpeakerCalibrationFile);
%     SoundCal = BpodSystem.CalibrationTables.SoundCal;
    if(isempty(SoundCal))
        disp('Error: no sound calibration file specified');
        return
    end
    
    toneAtt = polyval(SoundCal(1,1).Coefficient,meanFreq);
    diffSPL = amplitude - [SoundCal(1,1).TargetSPL];
    attFactor = sqrt(10.^(diffSPL./10)); 
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    sound =sound*att; 
    

        


        
