function [CodeBook,j]=cluster_inc(data,CodeBook,Mcdb)
% This method splits big clusters until the required number is reached
% inputs
% ------
% data: a matrix containing data-vectors in the columns
% Mcdb: the desired number of clusters is 2^Mcdb
% outputs
% -------
% Codebook: a matrix containing the cluster centers in its columns
% j: a vector containing for every input data vector the index of
%    closest cluster center

Scale=0.01*std(data,1,2);
D=size(CodeBook,1);
[CodeBook,cost,j] = kmeans(data,CodeBook,1);
while size(CodeBook,2)<2^Mcdb,
    % split each prototype randomly
    disp(size(CodeBook))
    [dummy,iSplit]=max(hist(j,size(CodeBook,2)));
    OS=ones(1,size(CodeBook,2));
    CodeBook=[CodeBook CodeBook(:,iSplit)+Scale.*randn(D,1)];
    % do kmeans iterations
    [CodeBook, cost, j] = kmeans(data,CodeBook,1);
end
[CodeBook, cost, j] = kmeans(data,CodeBook,2);

