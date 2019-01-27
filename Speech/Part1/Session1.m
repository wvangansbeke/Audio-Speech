% commands
close all;
FrameLen=240; % in samples
FrameShift=80; % in samples
LPCorder=10;
Fsam=8000;
nr_bins=512;

% read input signal
% is a flat 16-bit short with big-endian byte ordering
% sampling rate is 8kHz
fid=fopen('MHS_54164A.08','rb','b');sam=fread(fid,[1 inf],'short');fclose(fid);

x=sam2frame(filter([1 -0.95],1,sam),FrameLen,FrameShift);
xWin=sparse(1:FrameLen,1:FrameLen,hamming(FrameLen))*x;
% equivalent: xWin=(hamming(FrameLen)*ones(1,size(x,2))).*x;

% display spectrogram
figure(1);imagesc(log(abs(fft(xWin,nr_bins))));axis xy
len=size(xWin,2)*FrameShift/Fsam;
set(gca, 'xtick', (0:0.5:len)*Fsam/FrameShift, 'xticklabel', (0:0.5:len));
set(gca, 'ytick', (0:200:Fsam)/Fsam*nr_bins, 'yticklabel', (0:200:Fsam));
xlabel('Time (in sec)');ylabel('Frequency (in Hz)');

r=frame2cor(xWin,LPCorder);
%autocorrelation method
[lpc,Eres,k]=levinson(r);

% Examine frame Tlook=100
Tlook=100; % look at this frame
magnitudes = abs(roots(lpc(Tlook,:)))
angles = angle(roots(lpc(Tlook,:)))
formant_frequencies = angles * Fsam / (2 * pi)
% Frequency response of the vocal tract filter for this frame
figure(2);freqz(sqrt(Eres(Tlook)),lpc(Tlook,:),512);axis xy

% make a spectrogram
for t=1:size(lpc,1),H(:,t)=freqz(sqrt(Eres(t)),lpc(t,:),512);end
figure(3);imagesc(log(abs(H)));axis xy

% compute the cepstra using the recursion
cep=lpc2cep(lpc',Eres);
M=cos(pi*(0:0.001:1)'*(0:LPCorder));
figure(4);imagesc(M*cep);axis xy

% check the effect of the number of cepstral coefficients
f=(0:1/1000:0.5)'*(0:LPCorder);
z=exp(j*2*pi*f);
A=abs(sqrt(Eres(Tlook))./(z*lpc(Tlook,:)'));
figure(5); h1=plot(20*log10(A)); hold on;
C=real(z*cep(:,Tlook));
h2=plot(20*C/log(10),'g');
ncep=50;
f=(0:1/1000:0.5)'*(0:ncep);
z=exp(j*2*pi*f);
cep=lpc2cep([lpc(Tlook,:)'; zeros(ncep-LPCorder,1)],Eres(Tlook));
D=real(z*cep);
h3=plot(20*D/log(10),'r--');

legend([h1;h2;h3],{'Spectral shape'; ['Cepstral approximation with ' num2str(LPCorder) ' coefficients']; ['Cepstral approximation with ' num2str(ncep) ' coefficients']});
