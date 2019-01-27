function y=adjust_pitch(pNorm,XWin,Nwin)
% function y=adjust_pitch(pNorm,XWin,Nwin)
% adjust the normalized pitch estimate for Fourier resolution of largest harmonic
% XWin: fft spectrum, bins 2:Nfft/2
[N,T]=size(XWin);
Nfft=2*(N+1);
R=ceil(2*Nfft/Nwin); % Fourier resolution in bins
rng=(-R:R)';
y=pNorm;
for t=1:T,
   bin=pNorm(t)*Nfft:pNorm(t)*Nfft:N-R;
   n=round(bin/pNorm(t)); % harmonic number
   nMax=max(n);
   offs=rng*(n/nMax);
   sel=round(offs+bin(ones(2*R+1,1),:));
   a=zeros(size(sel));
   a(:)=abs(XWin(sel,t));
   [dummy,i]=max(sum(a,2));
   y(t)=y(t)+rng(i)/nMax;
end

      