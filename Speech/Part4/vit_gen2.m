function [cost,path,fi,nActive,start]=vit_gen2(logB,logA,PdfNr,fiInit,beam,endStates)
% function [cost,path,fi,nActive]=vit_gen2(logB,logA,PdfNr,fiInit,beam,endStates)
% logB = local scores for all Pdfs; size(logB,2)=T
% logA (N-by-N) = transition matrix with log-probs (sparse)
%   logA(from,to)
% PdfNr (1-by-N): for every state, the index into logB to obtain state scores
% fiInit (1-by-N) = initial state cost, full. Inactive entries should be set to -inf
% beam = scalar, normally negative
% endStates: list of states (index in fiInit) in which paths can end
% cost: total cost (scalar)
% path: stateNr (1-by-T)
% fi: state costs, 1-by-N
% nActive: nnr active states
% start: vit_gen makes a transition on the 1st frame. What is in path(1) is
% the state after transition. What is in start is where we came from in
% fiInit, i.e. the state at frame 0

fi=full(fiInit);
N=length(logA);
[from,to,logAval]=find(logA);

T=size(logB,2);
Best=zeros(T,N);
nActive=N*ones(1,T);
for t=1:T,
   [fi,Best(t,:)]=spmax2(from,to,fi(from),logB(PdfNr(to),t)+logAval,N);
   sel=fi>=max(fi)+beam;
   nActive(t)=sum(sel);
   fi(~sel)=-inf;
end

% backtrace
[cost,path(1,T)]=max(fi(endStates));
path(1,T)=endStates(path(1,T));
cost=full(cost);
for t=T-1:-1:1,
   path(t)=Best(t+1,path(t+1));
end
start=Best(1,path(1));
return