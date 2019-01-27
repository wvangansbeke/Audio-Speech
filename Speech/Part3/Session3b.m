% Session3b
% Define HMM structures
lex={'#','1','2','3','4','5','6','7','8','9','Z','O'};
nb_iter=10; % number of EM iterations
gamma_thr=1e-4;
Mcdb=7; % there are 2^Mcdb codebook entries
VQdir='./train/';
file_list=textread('Train.list','%s');
nb_states_per_word=16;

hmm_descriptions_of_words=cell(1,length(lex));
hmm_descriptions_of_words{1}=(1:3); % 3 states for '#'
nb_hmm_states=3;
for k=2:length(lex),
    % <nb_states_per_word> states for the rest
    hmm_descriptions_of_words{k}=nb_hmm_states+(1:nb_states_per_word);
    nb_hmm_states=nb_hmm_states+nb_states_per_word;
end
word_lengths=cellfun('length',hmm_descriptions_of_words);

for k=1:2,
    Model{k}=rand(nb_hmm_states,2^Mcdb)+0.1;
    Model{k}=spdiag(1./sum(Model{k},2))*Model{k}; % normalize
    Cnt{k}=zeros(nb_hmm_states,2^Mcdb);
end

silence=strmatch('#',lex,'exact');
for iter=1:nb_iter,
    log_likelihood=0;
    for utt=1:length(file_list),
        % read the label data
        fid=fopen([VQdir file_list{utt}],'rb');lab=fread(fid,[2 inf],'uint8')+1;fclose(fid);
        T=size(lab,2);
        ortho=file_list{utt}(5:end-4);
    	iortho=arrayfun(@(x) strmatch(x,lex),ortho);

        iortho=[iortho;silence(ones(1,length(iortho)))];iortho=[silence;iortho(:)]';
        word_end=cumsum(word_lengths(iortho));
        word_start=word_end-word_lengths(iortho)+1;
        N=word_end(end); % number of states in this utterance
        From=[1:N 1:N-1]; % self-loop and next state in strict left-to-right
        To=[1:N 2:N];
        Cost=ones(1,2*N-1);
        % make interword silence optional: skip from last state of non-silence 
        % words to first state of the next non-silence word
        From=[From word_end(2:2:end-3)];
        To=[To word_start(4:2:end-1)];
        Cost=[Cost ones(1,length(ortho)-1)];
        A=sparse(From,To,Cost);
        B=ones(nb_hmm_states,T);
        for k=1:2,
            B=B.*Model{k}(:,lab(k,:));
        end
        p0=[1;zeros(N-1,1)];p9=flipud(p0);
        hmm_states=[hmm_descriptions_of_words{iortho}];
    	[alpha,beta,logA,logB]=forwardbackward_basic_end(B,A,p0,p9,hmm_states);
        log_likelihood=log_likelihood+sum(logA);

        gamma=alpha.*beta;
        gamma=gamma*spdiag(1./(sum(gamma,1)+1e-300));
    	% figure; subplot(311); imagesc(gamma); title('gamma'); subplot(312); imagesc(log(gamma)); title('log(gamma)');

        gamma(gamma<gamma_thr)=0;
    	% subplot(313); imagesc(log(gamma)); title('thresholded log(gamma)'); 
        [state,time,gam]=find(gamma);

        % accumulate emission counts
        for k=1:2,
           Cnt{k}=Cnt{k}+accumarray([hmm_states(state)' lab(k,time)'],gam,size(Cnt{k}));
        end
    end % for utt
    disp(log_likelihood)
    for k=1:2,
        Model{k}=spdiag(1./(sum(Cnt{k},2)+1e-2))*Cnt{k};
    end
end
save('DDHMMwm','Model','lex','hmm_descriptions_of_words','log_likelihood');
