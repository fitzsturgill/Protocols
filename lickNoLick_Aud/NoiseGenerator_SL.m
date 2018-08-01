function noise=NoiseGenerator_SL(noise1, sampRate, Ramp, SignalMinFreq, SignalMaxFreq, NoiseAmplitude)
% function noise=NoiseGenerator_SL(sampRate, Ramp, SignalMinFreq, SignalMaxFreq, NoiseDuration, NoiseAmplitude)
%sound=SoundGenerator(sampRate, meanFreq, duration, amplitude).
%
%Generates a white noise.
%The frequencies are defined by "MinFreq" and "MaxFreq".
%sampRate is the sampling Rate of the sound card.
%function written by Shujing for lickNolick_Aud bpod protocol.

%% generate noise
%generate noise vector
%     samplenum=round(sampRate * NoiseDuration);
%     noise = 2 * rand(1, samplenum) - 1;%make white uniform noise -1 to 1


    SoundCal = load('C:\Users\Adam\BpodUser\Calibration Files\SoundCalibration.mat');
    
    toneAtt = [mean(polyval(SoundCal.SoundCal.Coefficient,linspace(SignalMinFreq,SignalMaxFreq)))]; %just take the mean over signal frequencies -
    diffSPL = NoiseAmplitude - [SoundCal.SoundCal.TargetSPL];
    attFactor = sqrt(10.^(diffSPL./10)); 
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    noise = noise1*att; 
        
%put an envelope to avoide clicking sounds at beginning and end
    omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(Ramp/pi*2); % This is for the envelope with Ramp duration duration
    t=0 : (1/sampRate) : pi/2/omega;
    t=t(1:(end-1));
    RaiseVec= (cos(omega*t)).^2;

    Envelope = ones(length(noise),1); % This is the envelope
    Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
    Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);

    noise = noise.*Envelope';

        
