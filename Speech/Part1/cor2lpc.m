function [a,k,Eres]=cor2lpc(r)
% function [a,k,Eres]=cor2lpc(r)
% a = predicition polynomial coefficients, including the leading 1 (a0)
% Beware for sign: use polynomial coefficients as-is: freqz(1,a(:,frame))
% is transfer function
% k = reflection coefficients
% Eres: variance of the residual

[N,T]=size(r);
a=zeros(N,T);a(1,:)=1;
k=zeros(N-1,T);

for m=1:N-1,
    k(m,:)=sum(r(m+1:-1:2,:).*a(1:m,:),1) ./ sum(r.*a,1);
    a(2:m+1,:)=a(2:m+1,:)-k(m*ones(m,1),:).*a(m:-1:1,:);
end
Eres=sum(r.*a,1);