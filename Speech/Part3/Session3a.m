% Session 3a
% Make codebook for DDHMM and quantize static and velocity features of
% training set and test set

Mcdb=7; % there will be 2^Mcdb entries
SamDir='/esat/spchdisk/scratch/hvanhamm/aurora2/speechdata_orig/train/clean/';
!if [[ ! -d "./train/" ]]; then mkdir "./train/"; fi
VQdir='./train/';

FileList=textread('Train.list','%s');
DeltaFilter=[2 1 0 -1 -2]/10;
FileList=FileList(randperm(length(FileList))); % scramble utterances and speakers

AllStatic=[];
AllVelocity=[];
for utt=1:1000,
    fid=fopen([SamDir FileList{utt}],'rb','b');sam=fread(fid,[1 inf],'short');fclose(fid);
    [cep,k,a,logE]=myFE(sam);
    Static=[cep;logE];
    AllStatic=[AllStatic Static(:,logE>10)];
    T=size(Static,2); % number of frames
    
    % delta features
    Velocity=filter(DeltaFilter,1,Static(:,[1 1 1:T T T]),[],2);
    Velocity=Velocity(:,5:end); 
    AllVelocity=[AllVelocity Velocity(:,logE>10)];
end
[StaticCdb,jS]=cluster(AllStatic,Mcdb);
[VelocityCdb,jV]=cluster(AllVelocity,Mcdb);
% does the codeboook cover the data reasonably ?
figure;subplot(211);hist(jS,2^Mcdb);subplot(212);hist(jV,2^Mcdb)

% try an equalizing step
[dummy,iV]=sort(hist(jV,2^Mcdb));
% remove smallest clusters
VelocityCdb(:,iV(1:15))=[];
% split largest clusters
[VelocityCdb,jV]=cluster_inc(AllVelocity,VelocityCdb,Mcdb);

figure;subplot(211);hist(jS,2^Mcdb);subplot(212);hist(jV,2^Mcdb)


% write VQ labels
h=waitbar(0,'writing labels for train set');
for utt=1:length(FileList),
    waitbar(utt/length(FileList),h);
    fid=fopen([SamDir FileList{utt}],'rb','b');sam=fread(fid,[1 inf],'short');fclose(fid);
    [cep,k,a,logE]=myFE(sam);
    Static=[cep;logE];
    T=size(Static,2); % number of frames

    z = eucl_dx(Static,StaticCdb);
    [m,StatLab] = min(z,[],1); % for every data point, the best prototype

    Velocity=filter(DeltaFilter,1,Static(:,[1 1 1:T T T]),[],2);
    Velocity=Velocity(:,5:end);
    z = eucl_dx(Velocity,VelocityCdb);
    [m,VelLab] = min(z,[],1); % for every data point, the best prototype
    
    fid=fopen([VQdir FileList{utt}],'wb');fwrite(fid,[StatLab;VelLab]-1,'uint8');fclose(fid);
    
end
delete(h)

SamDir='/esat/spchdisk/scratch/hvanhamm/aurora2/speechdata_orig/testa/clean1/';
!if [[ ! -d "./test/" ]]; then mkdir "./test/"; fi
VQdir='./test/';
FileList=textread('Test.list','%s');
h=waitbar(0,'writing labels for test set');
for utt=1:length(FileList),
    waitbar(utt/length(FileList),h);
    fid=fopen([SamDir FileList{utt}],'rb','b');sam=fread(fid,[1 inf],'short');fclose(fid);
    [cep,k,a,logE]=myFE(sam);
    Static=[cep;logE];
    T=size(Static,2); % number of frames

    z = eucl_dx(Static,StaticCdb);
    [m,StatLab] = min(z,[],1); % for every data point, the best prototype

    Velocity=filter(DeltaFilter,1,Static(:,[1 1 1:T T T]),[],2);
    Velocity=Velocity(:,5:end);
    z = eucl_dx(Velocity,VelocityCdb);
    [m,VelLab] = min(z,[],1); % for every data point, the best prototype
    
    fid=fopen([VQdir FileList{utt}],'wb');fwrite(fid,[StatLab;VelLab]-1,'uint8');fclose(fid);
    
end
delete(h)
