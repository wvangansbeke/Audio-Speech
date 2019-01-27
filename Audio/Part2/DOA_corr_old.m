clc
load('Computed_RIRs.mat')
num_sources = size(s_pos, 1);
mic_dist = m_pos(2,2)-m_pos(1,2);
DOA_est = zeros(num_sources,1);
for i = 1:num_sources
    h1 = RIR_sources(:,1,i);
    h2 = RIR_sources(:,2,i);
    [cor,lag] = xcorr(h1,h2);
    [~,I] = max(abs(cor));
    sample_delay = lag(I);
    time_diff = sample_delay/fs_RIR;
    diff_dist = 340*time_diff;
    DOA_est(i) = acos(diff_dist/mic_dist)*180/pi;
end
DOA_est
save('DOA_est.mat','DOA_est')