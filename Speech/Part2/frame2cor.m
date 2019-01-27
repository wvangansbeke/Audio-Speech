function r=frame2cor(x,p)
%function r=frame2cor(x,p)
% x = (N-by-T) framing matrix, one column per frame of length N
% p = number of lags
% r = (p+1)-by-T of unnormalized autocorrelations, r(0,:) on top, r(p,:)
%      at the bottom
r=zeros(p+1,size(x,2));
for k=1:p+1,
    r(k,:)=sum(x(k:end,:).*x(1:end-k+1,:),1);
end