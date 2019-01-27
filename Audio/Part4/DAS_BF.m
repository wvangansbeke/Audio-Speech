%Written by Wouter Van Gansbeke 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; 
% close all; 
clc;

load('Computed_RIRs.mat');
num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);

%% RUN create_micsigs.m
create_micsigs

%% SPECTOGRAM & PSD
dftsize=1024; % Changes freqcuency bins spacing (resolution=fs/dftsize)  
% IF greater than window: time zeropadding=> interpolation occurs.
N=dftsize/2; % Only one side will be plotted
Len=1024;

% Windowing(truncating) to reduce spectral leakage.
% window=hamming(Len); 
rect_win=rectwin(Len);	% Window has big influence on time resolution. The smaller the better in the time resolution.
						% Rectwin will give a good frequency resolution (less smear-effect), but a lot of leakage. Small
						% Main lobe, but high side lobes.
win_hanning=hanning(Len);
win_kaiser = kaiser(Len,2.5);
noverlap=Len/2; % Better time resolution, variance will go down in spectrum.

% Spectrogram calculation using stft by matlab
% figure
for i = 1:num_mics
%     subplot(num_mics,1,i)
    s_sig(:,:,i)=spectrogram(mic(:,i),win_hanning,noverlap,dftsize,fs_RIR); 
    
%     spectrogram(mic(:,i),win_hanning,noverlap,dftsize,fs_RIR,'yaxis');
%     title(['MIC',num2str(i)])
end

% Calculate psd by using spectogram (windows)
c_sig = size(s_sig,2);
for i = 1:num_mics
    psd_sig(:,i) = (1/c_sig)*sum(abs(s_sig(:,:,i)), 2);
end

%% PSEUDOSPECTRUM RHO USING GEOMEAN
% More stable formula is used to calculate rho
mic_dist = m_pos(2,2)-m_pos(1,2); 
c = 340;
dtheta = 0.5;
theta = 0:dtheta:180;
rho = zeros(361,1);
% tic
rho_individual = zeros(361,N-1);
for i = 2:N
    f = fs_RIR/dftsize*(i-1);
    k = 2*pi*f/c;
    g = exp(-1j*(k*mic_dist*[0:num_mics-1]'*cos(theta*pi/180)));
    yy(:,:)=s_sig(i,:,:);
    Ryy=yy'*yy; % num_mics x num_mics matrix
    [E,D] = eig(Ryy);
    [~,I] = sort(diag(D),'descend');
    v = E(:,I);
    rho_individual(:,i) = abs(1./(diag(g'*v(:,num_mics-num_sources-num_noise:end)*v(:,num_mics-num_sources-num_noise:end)'*g)));
    rho = rho + log10(rho_individual(:,i));
end
rho = (10.^(rho)).^(1/(N-1));
% toc

% Show peaks in pseudospectrum
[vals,locs] = findpeaks(rho);
[vals,I] = sort(vals,'descend');
locs = locs(I);
locs = locs(1:num_sources+num_noise);
vals = vals(1:num_sources+num_noise);
pred = NaN(361,1);
pred(locs) = vals;
DOA_est = (locs-1)*dtheta;
save('DOA_est', 'DOA_est')

%% PLOTS
figure
plot(0:0.5:180,rho)
hold on
stem(0:0.5:180,pred,'r','filled')
xlabel('Angle[°]')
ylabel('Pseudospectrum rho(theta)')

%% CHECK DELAY BETWEEN MIC SIGNALS
% [cor,lag] = xcorr(mic(:,1),mic(:,2));
% [~,I] = max(abs(cor));
% lagDiff = lag(I)

%% CREATE DELAY-AND-SUM BEAMFORMER (DAS BF)
[~,index]=min(abs(90-DOA_est));
DOA_est=DOA_est(index); % Select peak closest to 90° (convention to put speech 
                        % source closer to 90° than noise source)
save('DOA_est');

% Use the DOA_est to estimate the time delay between the microphone signals
if DOA_est <= 90    % If angle is between [0°-90°], the mic signals should be delayed compared to mic signal 1
    diff_dist=cos(pi*DOA_est/180)*mic_dist;
    delay=ceil((diff_dist/340)*fs_RIR);
    for i=1:num_mics
        mic(:,i)=[zeros((i-1)*delay,1); mic(1:end-(i-1)*delay,i)];
        speech(:,i)=[zeros((i-1)*delay,1); speech(1:end-(i-1)*delay,i)];
        noise(:,i)=[zeros((i-1)*delay,1); noise(1:end-(i-1)*delay,i)];
    end
else    % If angle is between [90°-180°], the mic signals should be delayed compared to mic signal 5
    DOA_est=180-DOA_est;
    diff_dist=cos(pi*DOA_est/180)*mic_dist;
    delay=ceil((diff_dist/340)*fs_RIR);
    for i=1:num_mics
        mic(:,i)=[zeros((num_mics-i)*delay,1); mic(1:end-(num_mics-i)*delay,i)];
        speech(:,i)=[zeros((num_mics-i)*delay,1); speech(1:end-(num_mics-i)*delay,i)];
        noise(:,i)=[zeros((num_mics-i)*delay,1); noise(1:end-(num_mics-i)*delay,i)];
    end
end

% APPLY BEAMFORMER TO MIC
DAS_out=(1/num_mics)*sum(mic,2);

% APPLY BEAMFORMER TO MIC
speech_DAS=(1/num_mics)*sum(speech,2);

% APPLY BEAMFORMER TO MIC
noise_DAS=(1/num_mics)*sum(noise,2);

%% PLOTS
figure
plot(mic(:,1),'blue');
hold on
plot(DAS_out,'red');

SNR_out_DAS=10*log10(var(speech_DAS(VAD==1))/var(noise_DAS))    

save('DAS.mat', 'speech_DAS', 'noise_DAS', 'DAS_out', 'SNR_out_DAS');

% soundsc(mic(:,1),fs);
% soundsc(DAS_out,fs);
