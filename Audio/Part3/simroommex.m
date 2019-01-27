% H = simroommex(Pmic,Psrc,Rdim,Reflec,N,fs)
%
% Simulation of Room Acoustics (MEX-version)
%
% REFERENCE	Image method for efficiently simulating small-room acoustics
%		J.B. Allen, D.A. Berkley
%		JASA, 65 (4), Apr. 1979, pp. 943-950
%
% OUTPUTS	H : impulse response of simulated room
%
% INPUTS	Pmic	: microphone position (m)
%		Psrc	: source position (m)
%		Rdim	: room dimensions (m)
%		Reflec	: reflection coefficients of the walls (0<=beta<=1)
%		N	: number of points to be calculated (length of H)
%		fs	: sampling frequency (Hz)
%
% FORMATS	H[1:N]
%		Pmic[x,y,z]
%		Psrc[x,y,z]
%		Rdim[Lx,Ly,Lz]
%		Reflec[bx1,bx2,by1,by2,bz1,bz2]
%		N
%		fs
%
