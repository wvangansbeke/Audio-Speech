function x=sam2frame(sam,FrameLen,FrameShift);
% function x=sam2frame(sam,FrameLen,FrameShift);
% Take FrameLen consecutive samples from sam and put them in the 1st column
% of x. Then shift by FramsShift and put FrameLen samples in the next
% column of x, etc.
%
% Each column of x is one frame.
% x: FrameLen * number_of_frames

% framing
ind1=1:FrameShift:length(sam)-FrameLen+1; % start times
NbFr=length(ind1);
ind2=(0:FrameLen-1)';
x=sam(ind1(ones(FrameLen,1),:)+ind2(:,ones(1,NbFr)));
