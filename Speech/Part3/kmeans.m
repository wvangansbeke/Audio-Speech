function [x,esq,j] = kmeans(d,x0,maxiter)
%KMEANS Vector quantisation using K-means algorithm [X,ESQ,J]=(D,X0)
%Inputs:
% D contains data vectors (one per col)
% X0 are the initial centres
%
%Outputs:
% X is output row vectors (K cols)
% ESQ is mean square error
% J indicates which centre each data vector belongs to

%  Based on a routine by Chuck Anderson, anderson@cs.colostate.edu, 1996


%      Copyright (C) Mike Brookes 1998
%
%      Last modified Mon Jul 27 15:48:23 1998
%
%   VOICEBOX home page: http://www.ee.ic.ac.uk/hp/staff/dmb/voicebox/voicebox.html
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   This program is free software; you can redistribute it and/or modify
%   it under the terms of the GNU General Public License as published by
%   the Free Software Foundation; either version 2 of the License, or
%   (at your option) any later version.
%
%   This program is distributed in the hope that it will be useful,
%   but WITHOUT ANY WARRANTY; without even the implied warranty of
%   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%   GNU General Public License for more details.
%
%   You can obtain a copy of the GNU General Public License from
%   ftp://prep.ai.mit.edu/pub/gnu/COPYING-2.0 or by writing to
%   Free Software Foundation, Inc.,675 Mass Ave, Cambridge, MA 02139, USA.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

BlkSz=1e5;
if nargin<3,
    maxiter=inf;
end

[p,n] = size(d);
x=x0;
k=size(x,2);
y = x+1;

ItNr=0;
while any(x(:) ~= y(:))
   ItNr=ItNr+1;
   fprintf('iteration %d ',ItNr);
   m=zeros(n,1);j=m;
   kk=0;
   while kk<n,
       sel=kk+1:min(kk+BlkSz,n);
       z = eucl_dx(x,d(:,sel)); % BlkSz-by-k
       [m(sel),j(sel)] = min(z,[],2); % for every data point, the best prototype
       kk=kk+BlkSz;
   end
   y = x;
   ToBeRemoved=logical(zeros(1,k));
   for i=1:k
      s = j==i; % select the data points for which i is the best prototype
      if any(s)
         x(:,i) = mean(d(:,s),2);
      else
         ToBeRemoved(i)=1;
      end
   end
   if any(ToBeRemoved),
       x(:,ToBeRemoved)=[];
       y=x+1;
   end
   fprintf('dx %16.9f\n',mean(m));
   if ItNr>maxiter,
       break
   end
end
esq=mean(m);
