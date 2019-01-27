function [RIR_sources,RIR_noise]=create_rirs(m_pos,s_pos,v_pos,room_dim,rev_time,fs_RIR,n)
%fs_RIR= RIR sampling rate
%m_pos= position of microphones
%s_pos= position of sources
%v_pos= position of noise sources
%room_dim=2D room dimensions
%rev_time= T60 reverberation time in seconds
%n=length of impulse response (in number of samples)

c = 340;                    % Sound velocity (m/s)
L = [room_dim 4];                % Room dimensions [x y z] (m)
r=[m_pos ones(size(m_pos,1),1)*2];
s=[s_pos ones(size(s_pos,1),1)*2];
v=[v_pos ones(size(v_pos,1),1)*2];

%rev_time=0.161*L(1)*L(2)*L(3)/((1-refl)*(L(1)*L(2)*2+L(1)*L(3)*2+L(3)*L(2)*2)) %Sabine's formula
if rev_time==0
    refl=0;
else
    refl=max(0,1-0.161*L(1)*L(2)*L(3)/(rev_time*(L(1)*L(2)*2+L(1)*L(3)*2+L(3)*L(2)*2))) %Sabine's formula
    if refl>0.92
        refl=0.92
        rev_time=0.161*L(1)*L(2)*L(3)/((1-refl)*(L(1)*L(2)*2+L(1)*L(3)*2+L(3)*L(2)*2));
        disp(['DANGER: too large reverberation time, RIRs created with reverberation time T60=' num2str(rev_time) 's'])
        
    end
end
if isempty(n)
n = round(max(rev_time*1.2*fs_RIR,2*fs_RIR*max(L)/c));                     % Number of samples
n=n+rem(n,2);
end

disp('Computing RIRs... please wait until confirmation appears')
R=zeros(n,size(r,1),size(s,1));
RIR_sources=zeros(n,size(r,1),size(s,1));
for j=1:size(s,1)
    for m=1:size(r,1)
        R(:,m,j) = simroommex(r(m,:),s(j,:),L,refl*ones(1,6),n,fs_RIR)';
    end
    %small tweak to avoid having reflections with larger amplitude than direct
    %path
    for l=1:size(R,2)
        imp=R(:,l,j);
        while 1
            [z,indmax]=max(imp);
            [ind]=find(imp>z/3);
            if ind(1)<indmax
                imp(indmax)=0.8*imp(indmax);
            else
                [close_ones]=find(imp(ind(2:end))>0.8*imp(indmax)); %reflections should at most 80% of direct path amplitude
                imp(ind(1+close_ones))=0.8*imp(ind(1+close_ones));
                R(:,l,j)=imp;
                break
            end
        end
        
    end
    RIR_sources(:,:,j) = R(:,:,j);
end


if ~isempty(v_pos)
    R=zeros(n,size(r,1),size(v,1));
    RIR_noise=zeros(n,size(r,1),size(v,1));
    for j=1:size(v,1)
        for m=1:size(r,1)
            R(:,m,j) = simroommex(r(m,:),v(j,:),L,refl*ones(1,6),n,fs_RIR)';
        end
        %small tweak to avoid having reflections with larger amplitude than direct
        %path
        for l=1:size(R,2)
            imp=R(:,l,j);
            while 1
                [z,indmax]=max(imp);
                [ind]=find(imp>z/3);
                if ind(1)<indmax
                    imp(indmax)=0.8*imp(indmax);
                else
                    [close_ones]=find(imp(ind(2:end))>0.8*imp(indmax)); %reflections should at most 80% of direct path amplitude
                    imp(ind(1+close_ones))=0.8*imp(ind(1+close_ones));
                    R(:,l,j)=imp;
                    break
                end
            end
            
        end
        RIR_noise(:,:,j) = R(:,:,j);
    end
else
    RIR_noise=[];
end
disp(['RIRs are ready for use in variable RIR, note that the RIRs are sampled at ' num2str(fs_RIR) ' Hz'])
save('Computed_RIRs','RIR_sources','RIR_noise','fs_RIR','m_pos','s_pos','v_pos','room_dim','rev_time')
end

