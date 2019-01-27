function y=fdiff(x)
% fdiff:    y=(1-z^-1)*x
T=size(x,2);
y=x(:,2:T)-x(:,1:T-1);
