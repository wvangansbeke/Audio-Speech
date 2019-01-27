%create speechfilename
clear all; close all; clc;

%----------------SET PARAMETERS-------------------%
speechfilename{1} = 'speech1.wav';
speechfilename{2} = 'speech2.wav';
whitenoise{1} = 'White_noise1.wav';
record_len = 10; %maak inf om geen rekening mee te houden

%---------------CREATE MIC SIGS------------------%
disp('CREATING MIC SIGS')
load('Computed_RIRs.mat')
targets_len = length(speechfilename);
noise_len = length(whitenoise);
for i = 1:targets_len
    [y,fs] = audioread(speechfilename{1, i});
    y = resample(y, fs_RIR, fs);
    speechfilename{2, i} = fs;
    if record_len == inf
        speechfilename{3, i} = y;        
    else
        speechfilename{3, i} = y(1:min(fs_RIR*record_len,length(y)));
    end
end

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
%determine recorded signals
%RIR sources = (len, #mics, #audio sources)
%RIR noise = (len, #mics, #noise sources)
num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);

%DETERMINE INPUT FILE
%filename = 'speech1.wav';

%CREATE MIC MATRIX
mic = zeros(length(speechfilename{3, 1}), num_mics);
RIR_sources = permute(RIR_sources,[1 3 2]);
RIR_noise = permute(RIR_noise,[1 3 2]);
for i = 1:num_mics
    mic(:,i) = sum(fftfilt(RIR_sources(:,:,i), speechfilename{3, 1}), 2);
    if num_noise ~= 0
        mic(:,i) = mic(:,i) + fftfilt(RIR_noise(:,:,i), whitenoise{3, 1});
    end
end
save('mic.mat','mic','fs_RIR');
%%
%PLOTS

figure(1)
plot(mic)
legend('mic1','mic2','mic3')
figure(2)
plot(speechfilename{3,1})
%soundsc(mic(:,1),fs_RIR)
%soundsc(speechfilename{3,1},fs)
disp('DONE')
%figure for RIR for two mic array
figure(3)
subplot(3,1,1)
plot(RIR_sources(:,:,1))
title('RIR mic1')
subplot(3,1,2)
plot(RIR_sources(:,:,2))
title('RIR mic2')
subplot(3,1,3)
diff = RIR_sources(:,:,1) - RIR_sources(:,:,2);
plot(diff)
title('difference')
figure(4)
plot(mic(:,1)-mic(:,2))






