function [cost,path,fi,nActive]=vit_gen(logB,logA,PdfNr,fiInit,beam)
% function [cost,path,fi,nActive]=vit_gen(logB,logA,PdfNr,fiInit,beam)
% logB = local scores for all Pdfs; size(logB,2)=T
% logA = transition matrix with log-probs (sparse)
%   logA(from,to)
% PdfNr: for every state, the index into logB to obtain state scores
% fiInit = initial state cost, sparse
% beam = (optional) normally negative
% cost: total cost (scalar)
% path: stateNr (1-by-T)
% fi: state costs
% nActive: nnr active states

fi=sparse(fiInit);
N=length(logA);
[from,to,logAval]=find(logA);

T=size(logB,2);
Best=zeros(T,N);
nActive=N*ones(1,T);
for t=1:T,
   [fi,Best(t,:)]=spmax2(from,to,fi(from),logB(PdfNr(to),t)+logAval,N);
   if nargin>=5,
      sel=fi>max(fi)+beam;
      nActive(t)=sum(sel);
      fi(~sel)=-inf;
   end
end

% backtrace
[cost,path(1,T)]=max(fi);
cost=full(cost);
for t=T-1:-1:1,
   path(t)=Best(t+1,path(t+1));
end
