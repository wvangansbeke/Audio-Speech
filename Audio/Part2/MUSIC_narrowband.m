clc
clear all
%% CREATE MIC SIGS
speechfilename{1} = 'speech1.wav';
speechfilename{2} = 'speech2.wav';
whitenoise{1} = 'White_noise1.wav';
record_len = 10;
load('Computed_RIRs.mat')
num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);
mic_dist = m_pos(2,2)-m_pos(1,2); 
[y,fs] = audioread(speechfilename{1});
[y1,fs1] = audioread(speechfilename{2});
[y2,fs2] = audioread(whitenoise{1});
y = resample(y, fs_RIR, fs);
y1 = resample(y1, fs_RIR, fs1);
speechfilename{2, 1} = fs;
speechfilename{2, 2} = fs1;
whitenoise{2, 1} = fs2;
speechfilename{3, 1} = y(1:min(fs_RIR*record_len,length(y)));
speechfilename{3, 2} = y1(1:min(fs_RIR*record_len,length(y1)));
whitenoise{3, 1} = y2(1:min(fs_RIR*record_len,length(y1)));
mic = zeros( length(speechfilename{3, 1}), num_mics);
RIR_sources = permute(RIR_sources,[1 3 2]);
RIR_noise = permute(RIR_noise,[1 3 2]);
for i = 1:num_mics
    mic(:,i) = sum(fftfilt(RIR_sources(:,:,i), [speechfilename{3, 1}]), 2);
    if num_noise ~= 0
        mic(:,i) = mic(:,i) + fftfilt(RIR_noise(:,:,i), whitenoise{3, 1});
    end
end

%% SPECTOGRAM & PSD
dftsize=1024; %Changes freqcuency bins spacing (resolution=fs/dftsize)  
%IF greater than window: time zeropadding=> interpolation occurs.
N=dftsize/2; %want 1 kant wordt maar geplot van spectrum
Len=1024;
%WINDOWING
%windowing(truncating) to reduce spectral leakage.
%window=hamming(Len); 
rect_win=rectwin(Len); %window has big influence on time resolution. The smaller the better in the time resolution.
%rectwin will give a good frequency resolution (less smear-effect), but a lot of leakage. Small
%main loop, but high side lobs.
win_hanning=hanning(Len);
win_kaiser = kaiser(Len,2.5);
noverlap=Len/2; %better time resolution, variance will go down in spectrum.

%spectrogram using stft
figure
for i = 1:num_mics
    subplot(num_mics,1,i)
    s_sig(:,:,i)=spectrogram(mic(:,i),win_hanning,noverlap,dftsize,fs_RIR); 
    
    spectrogram(mic(:,i),win_hanning,noverlap,dftsize,fs_RIR,'yaxis');
    title(['MIC',num2str(i)])
end

c_sig = size(s_sig,num_mics);
for i = 1:num_mics
    psd_sig(:,i) = (1/c_sig)*sum(abs(s_sig(:,:,i)), 2);
end
[~,indices] = max(psd_sig);
bin_max = round(mean(indices));
y = s_sig(bin_max,:,:);
y = permute(y,[3 2 1]);
a = mean(y,2);
a1 = y(:,309); 
%rho = zeros(361,c_sig);
%% PSEUDOSPECTRUM RHO
c = 340;
f_max = fs_RIR/dftsize*(bin_max-1);
k = 2*pi*f_max/c;
tic

dtheta = 0.5;
theta = 0:dtheta:180;
g = exp(-1j*(k*mic_dist*[0:num_mics-1]'*cos(theta*pi/180)));
%R = a*a.';
[~,R]=corrmtx(a,length(a)-1,'modified'); % TIP: for better performance
[E,D] = eig(R.');
[~,I] = sort(diag(D),'descend');
v = E(:,I);

rho = abs(1./(diag(g'*v(:,num_mics-num_sources-num_noise:end)*v(:,num_mics-num_sources-num_noise:end)'*g)));
toc

[vals,locs] = findpeaks(rho);
[vals,I] = sort(vals,'descend');
locs = locs(I);

locs = locs(1:num_sources);
vals = vals(1:num_sources);
pred = NaN(361,1);
pred(locs) = vals;

DOA_est = (locs-1)*dtheta
%DOA_est = [DOA_est DOA_est]
save('DOA_est','DOA_est')
%% with NOISE
%y = a*S + N
%R = E{y*y'} = E{aSS'a'}+E{N*N'}
%  = R1 + Sigma^2*I (uncorrelated noise with variance sigma)
%R1*q_i = lambda*q_i
%=> R*q = R1*q + Sigma^2I*q (eigevector of R1 is also eigvec of R)
%eigevalues = lambda_i+sigma^2
%thus: uncorrelated noise has no influence because eigvecs stay the same:great!
%% PLOTS
figure
plot(0:0.5:180,abs(rho))
hold on
stem(0:0.5:180,pred,'r','filled')
xlabel('Angle[°]')
ylabel('Pseudospectrum rho(theta)')
figure
plot(psd_sig)
legend('first source', 'second source')






