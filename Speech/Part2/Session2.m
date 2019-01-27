% Session 2: speech coding
% Source filter model

FrameLen=240;
FrameShift=80;
LPCorder=10;
LAR_NbBits=[6 6 5 5 4 4 3 3 3 3]'; % number of bits to which to quantize

% limits for quantization of C0; depends on signal scaling !
cmin=1; 
cmax=10;

% limits for LAR
LARmax=5;

% read input signal
% is a flat 16-bit short with big-endian byte ordering
% sampling rate is 8kHz
fid=fopen('MHS_54164A.08','rb','b');sam=fread(fid,[1 inf],'short');fclose(fid);

% encoder
preemph=filter([1 -0.95],1,sam);
x=sam2frame(preemph,FrameLen,FrameShift);
xWin=sparse(1:FrameLen,1:FrameLen,hamming(FrameLen))*x;
r=frame2cor(xWin,LPCorder);
[a,Eres,k]=levinson(r); a=a'; Eres=Eres'; k=-k;
LAR = log((1-k)./(1+k));

% pitch estimate
T=size(x,2); % number of frames
[p1,dummy1,dummy2,dummy3,vuv]=subharmonic(xWin);
p1=max(10,min(256,round(8000./p1)));
Voiced=vuv>0.3;

% quantize all LARS
% represent as number between -1 and +1
OT=ones(1,T);
rng=2.^(LAR_NbBits-1);rng=rng(:,OT);
[dummy,i]=sort(abs(LAR),1,'descend');
for t=1:T,rng(i(:,t),t)=rng(:,t);end
LARq=round(rng.*LAR/LARmax)./rng;
LARq=max(-1,min(0.99999,LARq));
% quantize residual energy
c_bits=round(256*(log(Eres)/2-cmin)/(cmax-cmin))/256;
c_bits=max(0,min(0.99999,c_bits));

% decoder
% reconstruct lpc parameters from LAR
ARr=exp(LARmax*LARq);
kr=(1-ARr)./(1+ARr); % reflection coefficients
ar=refl2lpc(kr);

Ares=exp((cmax-cmin)*(c_bits)+cmin); % reconstructed amplitude scaling of residual

% compare lpc filters spectrally
for t=1:T,H(:,t)=freqz(sqrt(Eres(t)),a(:,t),512);end
for t=1:T,Hr(:,t)=freqz(Ares(t),ar(:,t),512);end
figure(1);
subplot(211);imagesc(log(abs(H)));axis xy;title('original')
subplot(212);imagesc(log(abs(Hr)));axis xy;title('receiver')

% resynthesize: excitation is periodic or random, depending on voicing
OF=ones(FrameShift,1);
Periodic=zeros(FrameShift,T);
t=1;
while t<T*FrameShift,
    tFr=ceil(t/FrameShift);
    Periodic(t)=Ares(tFr)*sqrt(p1(tFr));
    t=t+p1(tFr);
end
rnd=Ares(OF,:).*randn(FrameShift,T);
UnVoiced=1-Voiced;
excit=Voiced(OF,:).*Periodic+UnVoiced(OF,:).*rnd; % hard switching

% inverse filter
ar=ar(2:end,:); % don't need the ones in the first row
state=zeros(1,LPCorder);
y=zeros(FrameShift,T);
for t=1:T, % filter one frame with fixed lpc filter
    for u=1:FrameShift,
        y(u,t)=excit(u,t)-state*ar(:,t); % Q: why the minus sign ?
        state=[y(u,t) state(1:end-1)];
    end
end
soundsc(filter(1,[1 -0.95],y(:)),8000)
