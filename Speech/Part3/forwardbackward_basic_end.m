function [alpha,beta,logA,logB]=forwardbackward_basic_end(B,A,p0,p9,map)
% Forward-backward algoritme
  
% INPUT:    B                  (MxT)-matrix met observatieprobs voor elk tijdstip
%           A                  (NxN)-matrix met transitieprobs
%           p0                 (Nx1)-vector met initiele probs
%           p9                 (Nx1)-vector met eind probs
%           map                (1xN)-vector met mapping van dim N
%                                naar dim M
% OUTPUT:   alpha              (NxT)-matrix met gescaleerde forward probs
%           beta               (NxT)-matrix met gescaleerde backward probs
%           logA:              (1xT): the log of the scaling factors. 
%           logB:              (1xT): the log of the scaling factors.
%             logB(T)=sum(beta(:,1).*B(:,1).*p0)
%               sum(logA)=sum(logB)=P(O|HMM)
  
% author: Veronique Stouten  
% date: 06/03/2003.
% -------------------------- 
  
tijd=size(B,2);
nbstates=size(A,1);

% initialisatie
logA=zeros(1,tijd);
alpha=[p0.*B(map,1) zeros(nbstates,tijd-1)];
  scaleA1=sum(alpha(:,1))+1E-300;
  alpha(:,1)=alpha(:,1)/scaleA1;
logA(1)=log(scaleA1);
beta=[zeros(nbstates,tijd-1) p9];

% inductie
for t=2:tijd,
%   alpha(:,t)=A'*alpha(:,t-1);
%   scaleA1=sum(alpha(:,t))+1E-300;
%   alpha(:,t)=alpha(:,t)/scaleA1;
%   alpha(:,t)=(alpha(:,t)).*B(map,t);
%   scaleA2=sum(alpha(:,t))+1E-300;
%   alpha(:,t)=alpha(:,t)/scaleA2;   
  alpha(:,t)=(A'*alpha(:,t-1)).*B(map,t);
  if t==tijd, alpha(:,t)=alpha(:,t).*p9; end
  scaleA1=sum(alpha(:,t))+1E-300;
  logA(t)=log(scaleA1);
  alpha(:,t)=alpha(:,t)/scaleA1;
end
logB=zeros(1,tijd);
beta=[zeros(nbstates,tijd-1) p9];
for t=tijd-1:-1:1,
  beta(:,t)=A*(beta(:,t+1).*B(map,t+1));
  scaleB2=sum(beta(:,t))+1E-300;
  beta(:,t)=beta(:,t)/scaleB2;
  logB(t)=log(scaleB2);
end
logB(tijd)=log(sum(beta(:,1).*B(map,1).*p0));
