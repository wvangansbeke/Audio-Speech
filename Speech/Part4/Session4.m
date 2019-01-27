% Session4
load('DDHMMwm','Model','lex','hmm_descriptions_of_words');

VQdir='../../session_3/test/';
FileList=textread('Test.list','%s');
WEP=-0.1;
beam=-50;
Ploop=0.9;

NbPdf=size(Model{1},1);
%An extra word for trailing silence is created
Lsil=strmatch('#',lex,'exact');
lex=[lex lex(Lsil)];
hmm_descriptions_of_words{end+1}=hmm_descriptions_of_words{Lsil};
Tsil=length(lex);
Digit=1:Tsil-1;Digit(Lsil)=[];
% create the states
word_lengths=cellfun('length',hmm_descriptions_of_words);
hmm_states=[hmm_descriptions_of_words{:}];
word_end=cumsum(word_lengths);
word_start=word_end-word_lengths+1;
nb_states=sum(word_lengths);
output=cell(1,nb_states);
for k=1:length(lex),output{word_end(k)}=lex{k};end

% build recognition grammar
% first the within-word state transitions
From=[1:nb_states 1:nb_states];
To=[2:nb_states+1 1:nb_states];
From(word_end)=[];
To(word_end)=[];
logP=[log(1-Ploop)*ones(1,nb_states) log(Ploop)*ones(1,nb_states)];
logP(word_end)=[];

% leading silence to any digit
OD=ones(1,length(Digit));
From=[From word_end(Lsil(OD))];
To=[To word_start(Digit)];
logP=[logP WEP(OD)];
% any digit to leading silence (loop)
From=[From word_end(Digit)];
To=[To word_start(Lsil(OD))];
logP=[logP WEP(OD)];
% any digit to trailing silence
From=[From word_end(Digit)];
To=[To word_start(Tsil(OD))];
logP=[logP WEP(OD)];
% any digit to any digit
%???
%???
%???
%???

Bigram=sparse(From,To,logP,nb_states,nb_states);
fiInit=-inf(1,nb_states);fiInit(word_start(Lsil))=1e-5;
end_states=word_end(Tsil);
for utt=1:length(FileList),
    % read the label data
    fid=fopen([VQdir FileList{utt}],'rb');lab=fread(fid,[2 inf],'uint8')+1;fclose(fid);
    T=size(lab,2);
    ortho=FileList{utt}(5:end-4); % the orthographic transcription is in the file name
    iortho=arrayfun(@(x) strmatch(x,lex),ortho);

    % emission probs in B
    B=ones(NbPdf,T);
    for k=1:2,
        B=B.*Model{k}(:,lab(k,:));
    end
    [cost,path,fi,nActive]=vit_gen2(log(B),Bigram,hmm_states,fiInit,beam,end_states);
    path=packul(path);
    fprintf('%s => %s\n',ortho,[output{path}]);

end % for utt

