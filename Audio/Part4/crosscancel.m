%Written by Wouter Van Gansbeke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; 
% close all; 
clc;

%% LOAD MAT FILES
load('Computed_RIRs.mat')
load('HRTF.mat')
RIR_sources=RIR_sources(1:400,:,:); % Truncate the transfer functions (for complexity reasons)

num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);

%% CREATE THE SOE PARAMETERS H AND X
X_desired1=[1 1];
X_desired2=[HRTF(1:800,1) HRTF(1:800,2)];

Lh=size(RIR_sources(:,1,1),1); 
Lg=max(ceil((2*(Lh-1))/(num_sources-2)),length(X_desired1(:,1))-Lh+1);

% Create the HRTF's
% original
xL1=[X_desired1(:,1); zeros(Lh+Lg-2,1)];
xR1=[X_desired1(:,2); zeros(Lh+Lg-2,1)];
% delay right signal 135°
xL2=[X_desired1(:,1); zeros(Lh+Lg-2,1)];
xR2=[zeros(3,1); X_desired1(:,2); zeros(Lh+Lg-2-3,1)];
% delay left signal 45°
xR3=[X_desired1(:,1); zeros(Lh+Lg-2,1)];
xL3=[zeros(3,1); X_desired1(:,2); zeros(Lh+Lg-2-3,1)];
% half volume right signal 135°
xL4=[X_desired1(:,1); zeros(Lh+Lg-2,1)];
xR4=0.5*[X_desired1(:,2); zeros(Lh+Lg-2,1)];
% half volume left signal 45°
xL5=0.5*[X_desired1(:,1); zeros(Lh+Lg-2,1)];
xR5=[X_desired1(:,2); zeros(Lh+Lg-2,1)];
% use HRTFS: reverberant + 135°
xL6 = X_desired2(:,1);
xR6 = X_desired2(:,2);

% set xL en xR
xL = xL3;
xR = xR3;

H_L=[];
H_R=[];
% H_L2=[];
% H_R2=[];
for i=1:num_sources
    H_L=[H_L toeplitz([RIR_sources(:,1,i); zeros(Lg-1,1)],[RIR_sources(1,1,i); zeros(Lg-1,1)])];
    H_R=[H_R toeplitz([RIR_sources(:,2,i); zeros(Lg-1,1)],[RIR_sources(1,2,i); zeros(Lg-1,1)])];
%     H_R=[H_R toeplitz([RIR_sources(:,4,i); zeros(Lg-1,1)],[RIR_sources(1,4,i); zeros(Lg-1,1)])];
%     H_L2=[H_L2 toeplitz([RIR_sources(:,2,i); zeros(Lg-1,1)],[RIR_sources(1,2,i); zeros(Lg-1,1)])];
%     H_R2=[H_R2 toeplitz([RIR_sources(:,5,i); zeros(Lg-1,1)],[RIR_sources(1,5,i); zeros(Lg-1,1)])];
end

H=[H_L; H_R];
% H2=[H_L2; H_R2];

% Add noise to H with std of 5% of the std of the first column of H
sigma=std(H(:,1));
noise=wgn(2*(Lh+Lg-1),num_sources*Lg,10*log10(0.05*sigma^2));

H_original=H;
H=H_original+noise;

Delta=ceil(sqrt(room_dim(1)^2+room_dim(2)^2)*fs_RIR/340);   % room_dim is the maximum possible distance between 
                                                            % the sources (mics) and the mics (ears) which makes 
                                                            % this delta the minimum possible delay that does 
                                                            % not cause problems
X_L=[zeros(Delta,1); xL(1:end-Delta)];
X_R=[zeros(Delta,1); xR(1:end-Delta)];

X=[X_L; X_R];

%% REMOVE ZERO-FILLED ROWS IN H AND x AND SOLVE THE SOE
rows=size(H,1);
columns=size(H,2);

H_shrunk=[];
%H_original_shrunk=[];
X_shrunk=[];
for i=1:rows
    if ~isequal(H(i,:),zeros(1,columns))
        H_shrunk=[H_shrunk; H(i,:)];
        %H_original_shrunk=[H_original_shrunk; H_original(i,:)];
        X_shrunk=[X_shrunk; X(i,:)];
    end
end

g_shrunk=H_shrunk\X_shrunk;

g=pinv(H)*X;
%% FIGURES
figure
subplot(2,1,1)
plot(H*g, 'blue')
hold on
plot(X, 'red')
ylim([0 1])
title('Full matrices')
subplot(2,1,2)
plot(H_shrunk*g_shrunk, 'blue')
hold on
plot(X_shrunk, 'red')
ylim([0 1])
title('Shrunk matrices')

synth_error=norm(H*g-X)

synth_error_shrunk=norm(H_shrunk*g_shrunk-X_shrunk)

%% READ OUT SPEECH FILE
speechfilename{1} = 'speech1.wav';
record_len = 10; 
targets_len = length(speechfilename);

[y,fs] = audioread(speechfilename{1, 1});
assert(fs_RIR==8000);
y = resample(y, fs_RIR, fs);
speechfilename{2, 1} = fs;
if record_len == inf
    speechfilename{3, 1} = y;
else
    speechfilename{3, 1} = y(1:min(fs_RIR*record_len,length(y)));
end
%% FILTER THE SPEECH SIGNAL WITH OPTIMAL g's
y_L=fftfilt(H_shrunk(1:Lh+Lg-1,:)*g_shrunk, speechfilename{3, 1});
y_R=fftfilt(H_shrunk(Lh+Lg-1:end,:)*g_shrunk, speechfilename{3, 1});
% y_L=fftfilt(H_original_shrunk(1:Lh+Lg-1,:)*g_shrunk, speechfilename{3, 1});
% y_R=fftfilt(H_original_shrunk(Lh+Lg-1:end,:)*g_shrunk, speechfilename{3, 1});
% y_L2=fftfilt(H2(1:Lh+Lg-1,:)*g_shrunk, speechfilename{3, 1});
% y_R2=fftfilt(H2(Lh+Lg-1:end,:)*g_shrunk, speechfilename{3, 1});

binaural_sig1=[y_L y_R];
% binaural_sig2=[y_L2 y_R2];
soundsc(binaural_sig1, fs_RIR);
% soundsc(binaural_sig2, fs_RIR);
