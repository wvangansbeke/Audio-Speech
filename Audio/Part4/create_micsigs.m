%Written by Wouter Van Gansbeke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%create speechfilename
clear all; 
% close all; 
clc;

%----------------SET PARAMETERS-------------------%
speechfilename{1} = 'speech1.wav';
speechfilename{2} = 'speech2.wav';
babblenoise{1} = 'Babble_noise1.wav';
whitenoise{1} = 'White_noise1.wav';
record_len = 10; %maak inf om geen rekening mee te houden

%---------------CREATE SPEECH SIGS------------------%
disp('CREATING MIC SIGS')
load('Computed_RIRs.mat')
targets_len = length(speechfilename);
noise_len = length(babblenoise);
for i = 1:targets_len
    [y,fs] = audioread(speechfilename{1, i});
    assert(fs_RIR==44100);
    y = resample(y, fs_RIR, fs);
    speechfilename{2, i} = fs;
    if record_len == inf
        speechfilename{3, i} = y;        
    else
        speechfilename{3, i} = y(1:min(fs_RIR*record_len,length(y)));
    end
end

%---------------CREATE WHITE NOISE SIGS--------------%
for i = 1:noise_len
    [y,fs] = audioread(whitenoise{1, i});
    y = resample(y, fs_RIR, fs);
    whitenoise{2, i} = fs;
    if record_len == inf
        whitenoise{3, i} = y;
    else
        whitenoise{3, i} = y(1:min(fs_RIR*record_len,length(y)));
    end     
end

%---------------CREATE BABBLE NOISE SIGS--------------%
for i = 1:noise_len
    [y,fs] = audioread(babblenoise{1, i});
    y = resample(y, fs_RIR, fs);
    babblenoise{2, i} = fs;
    if record_len == inf
        babblenoise{3, i} = y;
    else
        babblenoise{3, i} = y(1:min(fs_RIR*record_len,length(y)));
    end     
end

%---------------CREATE SPEECH NOISE SIGS--------------%
[y,fs] = audioread(speechfilename{1, 2});
y = resample(y, fs_RIR, fs);
speechnoise{2, 1} = fs;
if record_len == inf
    speechnoise{3, 1} = y;
else
    speechnoise{3, 1} = y(1:min(fs_RIR*record_len,length(y)));
end

%determine recorded signals
%RIR sources = (len, #mics, #audio sources)
%RIR noise = (len, #mics, #noise sources)
num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);

speech = zeros(length(speechfilename{3, 1}), num_mics);
mic = zeros(length(speechfilename{3, 1}), num_mics);
RIR_sources = permute(RIR_sources,[1 3 2]);
RIR_noise = permute(RIR_noise,[1 3 2]);

% CREATE MICROPHONE SIGNALS (SPEECH + NOISE)
for i = 1:num_mics
    % CREATE SPEECH SIGNAL AND CALCULATE POWER
    speech(:,i) = sum(fftfilt(RIR_sources(:,:,i), speechfilename{3, 1}), 2);
    VAD=abs(speech(:,i))>std(speech(:,i))*1e-3; % Check where signal is active
    power=var(speech(VAD==1,i));    % Calculate power only where signal is active

    % CREATE AWGN
    noise(:,i)=wgn(length(speech),1,10*log10(0.1*power));    % Create WGN with 10% of signal power
    
    % ADD NOISE FROM NOISE SOURCE
    if num_noise ~= 0
        noise(:,i) = noise(:,i) + fftfilt(RIR_noise(:,:,i), babblenoise{3, 1});
    end
    
    % ADD MICROPHONE NOISE
    mic(:,i) = speech(:,i) + noise(:,i);
end

% CALCULATE SNR
signal_power=var(speech(VAD==1,1));
noise_power=var(noise(:,1));
SNR_in=10*log10(signal_power/noise_power)

save('mic.mat','speech','noise','mic','SNR_in');

% soundsc(mic(:,1),fs);
