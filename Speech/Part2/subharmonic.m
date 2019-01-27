function [pMicro,p,praw,score,vuv]=subharmonic(x,fs,dpWidth)
% x: windowed and framed signal. One frame per column. 
% fs: sampling frequency
% dpWidth: number of subharmonic bins (48 per octave) the pitch can change
%   per frame
% pMicro = pitch in Hz after micro adjustment and dp smoothing
% p = pitch after dp smoothing
% praw = subharmonic argmax; contains doubling/halving errors
% score = local score along optimal path in dp
% vuv = voiced/unvoiced measure. Beware: omitting this return value saves
%   time

Nfft=1024;
if nargin<2,
  fs = 8000;
end
if nargin<3,
   dpWidth=4;
end

[FrameLen,T]=size(x);
interval = fs/Nfft;

XWin = fft(x,Nfft);
% keep only lower part of xfft
Nbw=floor(1250/fs*Nfft);
xfft = abs(XWin(1:Nbw,:));
flin=0:interval:interval*(Nbw-1); % frequency axis of xfft

% Find Relative Maximum
xAug=[zeros(1,T);xfft;zeros(1,T)];
maxpos = find( (xAug(2:end-1,:) > xAug(1:end-2,:)) & (xAug(2:end-1,:) > xAug(3:end,:)) );

% Set max positions and points around to zero
maxBar = xfft;
maxBar(maxpos)=0;
i=maxpos;i(rem(maxpos-1,Nbw)==0)=[];
maxBar(i-1)=0;
i=maxpos;i(rem(maxpos-1,Nbw)==Nbw-1)=[];
maxBar(i+1)=0;
    
% Subtract maxBar from x128 to get relative maxima and surounding points
relmax = xfft - maxBar;

% Low Pass Filter yeilding smoothed spectrum
smoothed = filter([1/4 1/2 1/4],1,[relmax zeros(Nbw,1)],[],2);
smoothed = smoothed(:,2:end);

% Spline Interpolation 48 points per octave
fsub = logspace(log10(2 * interval),log10(interval*Nfft),9*48+1);
fsub = fsub(fsub<=flin(Nbw) & fsub>=30);
subhar=zeros(length(fsub),T);

% linear interpolation
iL=floor(fsub/interval)+1; % the lower index
wH=(fsub-flin(iL))'/interval;
wH=wH(:,ones(1,T));
subhar=(1-wH).*smoothed(iL,:)+wH.*smoothed(iL+1,:);

% Harmonic Summation
offset=round(48*log(1:15)/log(2)); % distance between harmonics
h=(0.84 .^ (0:14))';
[dummy,Nmax]=min(abs(fsub-350)); % max pitch is 350 Hz
H=zeros(Nmax,T);
for s = 1:Nmax
    i = s + offset;
    i(i>size(subhar,1))=[];
    H(s,:)=sum(h(1:length(i),ones(1,T)).*subhar(i,:),1);
end
[dummy,s_pitch]=max(H,[],1);
praw = fsub(s_pitch);

A=sparse(0.1*diag(ones(Nmax,1),0));
for k=-dpWidth:dpWidth,
    A=A+sparse(0.1*diag(ones(Nmax-abs(k),1),k));
end;
logA=spfun('log',A);
wght=2000;
[cost,s_pitch,fi,nActive]=vit_gen(wght*H/max(max(H)),logA,1:Nmax,-1e-6*ones(Nmax,1),-wght/2);
score=H(sub2ind(size(H),s_pitch,1:T));
p = fsub(s_pitch);

% refine pitch estimate
pMicro=adjust_pitch(p/fs,XWin(2:Nfft/2,:),FrameLen)*fs;

if nargout>=5,
    Nover=2;
    rfft = real(ifft(xfft.^2,Nover*Nfft));
    Tsamples = 1./p .* fs;
    i = sub2ind(size(rfft),round(Nover*Tsamples)+1,1:T);
    vuv = rfft(i)./rfft(1,:);
end
