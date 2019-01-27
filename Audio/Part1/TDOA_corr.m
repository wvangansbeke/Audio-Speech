clc
clear all

%RIR sources = (len, #mics, #audio sources)
%RIR noise = (len, #mics, #noise sources)
load('Computed_RIRs.mat')
h1 = RIR_sources(:,1);
h2 = RIR_sources(:,2);
figure;
plot(h1)
hold on
plot(h2)
legend('h mic1', 'h mic2')

[~, index_mic1] = max(h1);
[~, index_mic2] = max(h2);
sample_delay = index_mic1 - index_mic2;
time_diff = sample_delay/fs_RIR;
[cor,lag] = xcorr(h1,h2);
[~,I] = max(abs(cor));
sample_delay = lag(I);

%whitenoise{1} = 'White_noise1.wav';
%[y,fs] = audioread(whitenoise{1});
speechfile{1} = 'speech1.wav';
[y,fs] = audioread(speechfile{1});
y = resample(y, fs_RIR, fs);
num_mics = size(m_pos, 1);
mic = zeros(length(y), num_mics);
for i = 1:num_mics
    mic(:,i) = fftfilt(RIR_sources(:,i), y);
end
mic_rec1 = mic(:,1);
mic_rec2 = mic(:,2);
[cor,lag] = xcorr(mic_rec1,mic_rec2);
[~,I] = max(abs(cor));
lagDiff = lag(I);
err = sample_delay - lagDiff;
X = sprintf('Diff between estimated & ground truth = %d', err);
disp(X)
%PLOT
expected = NaN(length(cor),1);
expected(I) = max(abs(cor));
figure;
plot(cor,'blue')
hold on
stem(expected,'filled', 'red')
legend('crosscorrelation','expected peak')

