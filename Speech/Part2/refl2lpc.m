function a=refl2lpc(k)
% function a=refl2lpc(k)
% a = predicition polynomial coefficients, including the leading 1 (a0)
% Beware for sign: use polynomial coefficients as-is: freqz(1,a(:,frame))
% is transfer function
% k = reflection coefficients

[N,T]=size(k);
a=zeros(N+1,T);a(1,:)=1;

for m=1:N,
    a(2:m+1,:)=a(2:m+1,:)-k(m*ones(m,1),:).*a(m:-1:1,:);
end
