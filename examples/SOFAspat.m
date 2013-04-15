function [out, azi, ele, idx] = SOFAspat(in,Obj,azi,ele)
% SOFAspat
% [OUT, A, E] = SOFAspat(IN, OBJ, AZI, ELE) spatializes the sound IN using
% the HRTFs from OBJ according to the trajectory given in AZI and ELE.
% Input: 
%		IN: vector with the sound
%		OBJ: SOFA object containing the HRTFs
%		AZI, ELE: vectors with the trajectory (in degrees) independent for
%							azimuth and elevation
% 
% Output: 
%		OUT: binaural signal
%		AZI, ELE: azimuth and elevation of the actual trajectory (degrees)
%		IDX: index of the filters (corresponds to AZI and ELE)
%
% This is an example of how to use SOFA.
%
% Piotr Majdak, 2013

%% Define required parameters
hop=0.5;		% the hop size for the time-variant filtering (in fraction of the filter length)

%% Initial checks 
if ~strcmp(Obj.GLOBAL_SOFAConventions,'SimpleFreeFieldHRIR')
	error('HRTFs must be saved in the SOFA conventions SimpleFreeFieldHRIR');
end
if min(azi)<0,	% Check for the required coordinate system
	Obj.ListenerRotation(:,1)=sph2nav(Obj.ListenerRotation(:,1)); % if negative azimuths are required, swith to -90/+90 system
end

%% resize the input signal to be integer multiple of HRIR
L=length(in);
in=[in; zeros(Obj.N-mod(L,Obj.N),1)];
L=length(in);		% correct length of the input signal
S=L/Obj.N/hop;	% number of segments to filter

%% Resample the trajectory
if length(azi)>1, 
	azi= interp1(0:1/(length(azi)-1):1,azi,0:1/(S-1):1); 
else
	azi=repmat(azi,1,S);
end;
if length(ele)>1, 
	ele= interp1(0:1/(length(ele)-1):1,ele,0:1/(S-1):1); 
else
	ele=repmat(ele,1,S);
end;

%% create a 2D-grid with nearest positions of the moving source
idx=zeros(S,1);
for ii=1:S % find nearest point on grid (LSP)
    dist=(Obj.ListenerRotation(:,1)-azi(ii)).^2+(Obj.ListenerRotation(:,2)-ele(ii)).^2;
    [~,idx(ii)]=min(dist);
end

%% normalize HRTFs to the frontal, eye-level position
ii=find(Obj.ListenerRotation(:,1)==0 & Obj.ListenerRotation(:,2)==0);   % search for position 0�/0�
if isempty(ii)
	peak=max([sqrt(sum(Obj.Data.IR(:,1,:).*Obj.Data.IR(:,1,:))) sqrt(sum(Obj.Data.IR(:,2,:).*Obj.Data.IR(:,2,:)))]);   % not found - normalize to IR with most energy
else
	peak=([sqrt(sum(Obj.Data.IR(ii,1,:).*Obj.Data.IR(ii,2,:))) sqrt(sum(Obj.Data.IR(ii,2,:).*Obj.Data.IR(ii,2,:)))]);  % found - normalize to this position
end

%% Spatialize   
out=zeros(L+Obj.N/hop,2);
window=hanning(Obj.N);
ii=0;
jj=1;
iiend=L-Obj.N;
while ii<iiend    
		segT=in(ii+1:ii+Obj.N).*window;	% segment in time domain
		segF=fft(segT,2*Obj.N);	% segment in frequency domain with zero padding
		%-----------
		segFO(:,1)=squeeze(fft(Obj.Data.IR(idx(jj),1,:),2*Obj.N)).*segF;
		segFO(:,2)=squeeze(fft(Obj.Data.IR(idx(jj),2,:),2*Obj.N)).*segF;
		%-----------
		segTO=real(ifft(segFO));   % back to the time domain
		out(ii+1:ii+2*Obj.N,:)=out(ii+1:ii+2*Obj.N,:)+segTO;  % overlap and add
		ii=ii+Obj.N*hop;
		jj=jj+1;
end	

%% Normalize
out(:,1)=out(:,1)/peak(1);
out(:,2)=out(:,2)/peak(2);