function noise=GenerateNoise(StimulusSettings)
global BpodSystem %we need this for volume adjustment

%% abbreviate variable names and clip impossible values for better handling
SamplingRate=StimulusSettings.SamplingRate;
Ramp=StimulusSettings.Ramp;
NoiseColor=StimulusSettings.NoiseColor;
NoiseDuration=StimulusSettings.NoiseDuration;
NoiseVolume=StimulusSettings.NoiseVolume;
SignalMinFreq=StimulusSettings.SignalMinFreq;
SignalMaxFreq=StimulusSettings.SignalMaxFreq;

%% generate noise
%generate noise vector
samplenum=round(SamplingRate * NoiseDuration);
switch NoiseColor
    case 'WhiteUniform'
        noise = 2 * rand(1, samplenum) - 1;%make white uniform noise -1 to 1
    case 'WhiteGaussian' %gaussian noise from mean 0 std .25
        noise = .25 * randn(1, samplenum);%make white gausian noise and clip to [-1 1]
        noise(noise<-1)=-1;
        noise(noise>1)=1;
    case 'PinkGaussian'
        noise = f_alpha_gaussian (samplenum,.2^2,1)';%make colored gaussian noise with std .2 and 1/f^alpha
        %     case 'naturalistic' %https://www.ncbi.nlm.nih.gov/pubmed/18301738 "Efficient coding of naturalistic stimuli"
        %         noise = randn(1, samplenum);%
        %         noise1 = f_alpha_gaussian ( samplenum,1, 0.1)';%make colored noise  1/f^alpha
        %         noise2 = f_alpha_gaussian ( samplenum,1, 0.1)';%make colored noise 1/f^alpha
        %         noisemodulator=(noise1.^2+noise2.^2).^.1;%make colored noise modulator with amplitude modulation spectrume Raleigh
end

%clip noise to [-1 1]
noise(noise<-1)=-1;
noise(noise>1)=1;

%put in double speaker
noise = [noise;noise];

%adjust noise volume
SoundCal = BpodSystem.CalibrationTables.SoundCal;
if(isempty(SoundCal))
    disp('Error: no sound calibration file specified');
    return
end
if size(SoundCal,2)<2
   disp('Error: no two speaker sound calibration file specified');
   return
end
for s=1:2 %loop over two speakers
    toneAtt = [mean(polyval(SoundCal(1,s).Coefficient,linspace(SignalMinFreq,SignalMaxFreq)))]; %just take the mean over signal frequencies -
    %toneAtt = [polyval(SoundCal(1,1).Coefficient,toneFreq)' polyval(SoundCal(1,2).Coefficient,toneFreq)']; in Torben's script
    diffSPL = NoiseVolume - [SoundCal(1,s).TargetSPL];
    attFactor = sqrt(10.^(diffSPL./10)); %sqrt(10.^(diffSPL./10)) in Torben's script WHY sqrt?
    att = toneAtt.*attFactor;%this is the value for multiplying signal scaled/clipped to [-1 to 1]
    noise(s,:)=noise(s,:).*att; %should the two speakers dB be added?
end

%put an envelope to avoide clicking sounds at beginning and end
omega=(acos(sqrt(0.1))-acos(sqrt(0.9)))/(Ramp/pi*2); % This is for the envelope with Ramp duration duration
t=0 : (1/SamplingRate) : pi/2/omega;
t=t(1:(end-1));
RaiseVec= (cos(omega*t)).^2;

Envelope = ones(length(noise),1); % This is the envelope
Envelope(1:length(RaiseVec)) = fliplr(RaiseVec);
Envelope(end-length(RaiseVec)+1:end) = (RaiseVec);

noise = noise.*Envelope';