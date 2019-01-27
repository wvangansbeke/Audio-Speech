function [cep,k,a,logE]=myFE(sam)

FrameLen=240;
FrameShift=80;
LPCorder=10;

x=sam2frame(filter([1 -0.95],1,sam),FrameLen,FrameShift);
xWin=sparse(1:FrameLen,1:FrameLen,hamming(FrameLen))*x;
r=frame2cor(xWin,LPCorder);
logE=log(r(1,:));
[a,Eres,k]=levinson(r); a=a'; Eres=Eres'; k=-k;
cep=lpc2cep(a,Eres);
