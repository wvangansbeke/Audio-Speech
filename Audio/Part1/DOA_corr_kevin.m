clc
clear all
load('Computed_RIRs.mat')

speechfilename{1} = 'speech1.wav';
speechfilename{2} = 'speech2.wav';
record_len = 10; %make sure speech is active!
simultaneous = false;
%---------------CREATE MIC SIGS------------------%
disp('CREATING MIC SIGS')
load('Computed_RIRs.mat')
targets_len = length(speechfilename);
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

num_sources = size(s_pos, 1);
mic_dist = m_pos(2,2)-m_pos(1,2);
ground_truth = zeros(num_sources,1);
DOA_est = zeros(num_sources,1);
y1 = zeros(fs_RIR*record_len,1);
y2 = zeros(fs_RIR*record_len,1);
for j = 1:num_sources
    % Ground truth
    h1 = RIR_sources(:,1,j);
    h2 = RIR_sources(:,2,j);
    [cor,lag] = xcorr(h1,h2);
    [~,I] = max(abs(cor));
    sample_delay = lag(I);
    time_diff = sample_delay/fs_RIR;
    diff_dist = 340*time_diff;
    ground_truth(j) = acos(diff_dist/mic_dist)*180/pi;

    % Real signals
    if ~ simultaneous
        y1 = 0;
        y2 = 0;
    end
    y1 = y1 + fftfilt(RIR_sources(:,1,j), speechfilename{3, 1});
    y2 = y2 + fftfilt(RIR_sources(:,2,j), speechfilename{3, 1});
    
    if ~ simultaneous || j==num_sources
        
        [cor,lag] = xcorr(y1,y2);
        [~,I] = max(abs(cor));
        sample_delay = lag(I);
        time_diff = sample_delay/fs_RIR;
        diff_dist = 340*time_diff;
        DOA_est(j) = acos(diff_dist/mic_dist)*180/pi;
    end
end

ground_truth
DOA_est
save('DOA_est.mat','DOA_est')






