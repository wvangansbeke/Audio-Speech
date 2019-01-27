%Written by Wouter Van Gansbeke 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clear all; 
% close all; 
clc;

load('Computed_RIRs.mat');
num_sources = size(s_pos, 1);
num_noise = size(v_pos, 1);
num_mics = size(m_pos, 1);

%% RUN DAS_BF.m (AND create_micsigs.m)
DAS_BF

%% MULTIPLY MIC SIGNALS WITH GRIFFITHS_JIM BLOCKING MATRIX
Ca=[ones(1,num_mics-1); diag(-ones(1,num_mics-1))];
X=mic*Ca;

%% APPLY LMS FILTER
mu=0.1;
%mu=1;   % Causes even more echo, the whole signal looks like noise on the plot
L=1024;

DAS_out=[zeros(L/2,1);DAS_out];

W=zeros(L,num_mics-1);
z=zeros(length(DAS_out),1);
for i=L:length(X(:,1))
    frob_norm=norm(X(i-L+1:i,:), 'fro');
    t(i) = trace(W'*X(i-L+1:i,:));
    z(i)=DAS_out(i)-t(i);
    W=W+(mu/(frob_norm^2))*X(i-L+1:i,:)*z(i);
end

DAS_out=DAS_out(L/2+1:end);
z=z(L/2+1:end);
%% PLOTS
figure
plot(mic(:,1),'blue');
hold on
plot(DAS_out,'red');
hold on
plot(z,'green');
% hold on
% plot(speech_DAS(:,1),'black');

% The amplitude of GSC is smaller than that of DAS (due to the LMS filtering?)

%% SNR
signal_power=var(z(VAD==1));
noise_power=var(z(VAD==0));    % Calculate noise power only where noise is active (speech is not active)
SNR_out_GSC=10*log10((signal_power-noise_power)/noise_power)

%% EXTRA
%soundsc(X(:,1),fs); % There is a bit of speech leakage
                      % T60=0.5 causes even more speech leakage
%soundsc(DAS_out,fs);
%soundsc(z,fs);    % The noise seems to be more or less the same but the 
%soundsc(t,fs);                    % speech has a lot of echo/sounds a bit dull
