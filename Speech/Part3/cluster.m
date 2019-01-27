function [CodeBook,j]=cluster(data,Mcdb)
% This method doubles the codebook size Mcdb times
% inputs
% ------
% data: a matrix containing data-vectors in the columns
% Mcdb: the number of times the number of clusters is doubled
%	the final number of clusters will be 2^Mcdb
% outputs
% -------
% Codebook: a matrix containing the cluster centers in its columns
% j: a vector containing for every input data vector the index of
%    closest cluster center

CodeBook=mean(data,2);
Scale=0.01*std(data,1,2);
D=size(CodeBook,1);
while size(CodeBook,2)<2^Mcdb,
    % split each prototype randomly
    disp(size(CodeBook))
    OS=ones(1,size(CodeBook,2));
    CodeBook=[CodeBook+Scale(:,OS).*randn(size(CodeBook)) CodeBook+Scale(:,OS).*randn(size(CodeBook))];
    % do kmeans iterations
    CodeBook = kmeans(data,CodeBook,5);
end
[CodeBook,cost,j] = kmeans(data,CodeBook,10);

