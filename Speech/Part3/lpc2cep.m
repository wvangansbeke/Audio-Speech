function cep=lpc2cep(lpc,Eres)

cep=lpc;
cep(1,:)=log(Eres)/2;
OT=ones(1,size(lpc,2));
for n=2:size(lpc,1),
    wght=(1:n-2)'/(n-1);
    cep(n,:)=-lpc(n,:)-sum(wght(:,OT).*cep(2:n-1,:).*lpc(n-1:-1:2,:),1);
end