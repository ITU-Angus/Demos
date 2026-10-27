%      Matlab helper function to simulate room reverberation,
%       based on ARI LAS version, adatpted for ITU Linz
% 
%       input:  - file ITUGrid.mat
% 
%       output: - reverb_main X Y Z.mat
% 
%   #Author: Piotr Majdak, Michael Mihocic (2017-2026)
%   #Author: Michael Mihocic: adaptions for 16 channels (ITU Angus Lab) (10.08.2026)
% 


  % Small room
S=[4 1.6 1.1]; % position of the source
R=[1 1.5 1]; % position of the receiver
LWH=[6 4 2]; % length width and height of the room
T=.2; % skew from the shoebox (m), front wider and rear lower by T
Omax=7; % maximum reflection order to calculate
flags='noplot';
% from Beranek (1996) "Concert Halls and Opera Houses"
% f =    125  250  500  1.00 2.00 4.00
% RT60 = 2.25 2.18 2.04 1.96 1.80 1.62
RT60=1000; % reverberation time (ms)

tmix=20;       % mixing time (ms) of early reflections (mirror sources) and diffuse reverb (FDN)
tmixregion=10;  % the region within the mix happens (ms) after tmix


% loudspeaker array and signal parameters
% X=load('grid_latest.mat'); % loudspeaker grid X(x,y,z)
load ITUGrid.mat
fs=48000; % sampling rate (Hz)
c=340; % speed of sound (m/s)


% Corners of the room
C(1,:)=[0 0 0];
C(2,:)=[LWH(1) 0 0];
C(3,:)=[LWH(1) LWH(2)-T 0];
C(4,:)=[0+T LWH(2) 0];
C(5,:)=[0 0+T LWH(3)];
C(6,:)=[LWH(1)+T 0 LWH(3)-T];
C(7,:)=[LWH(1) LWH(2) LWH(3)];
C(8,:)=[0 LWH(2)-T LWH(3)];
W=[2 1 5 6; 3 2 6 7; 4 3 7 8; 1 4 8 5; 1 2 3 4; 5 8 7 6]'; % define walls by indicies to corners
if Omax>4, flags='noplot'; end;

% acoustic calculations
V=prod(LWH); % approx volume of the room
Ar=2*LWH*circshift(LWH',[-1,0]); % approx surface of the room
% RT60=0.1611*V/S/(1-mean(RF))*1000; % reverberation time (ms) estimated from RFs
rH=0.057*sqrt(V/RT60*1000); % Hallradius (m)
RFall=1-0.1611*V/Ar/RT60*1000;
RF=ones(1,8)*RFall; % reflection factors of each wall


%% calculate mirror sources
Y=reverb_mirrorsources(Omax,C,W,S,R,RF,flags); % Y=[Sx Sy Sz o s w RFcum flag]
if strcmp(flags,'plot'), plot3(R(:,1),R(:,2),R(:,3),'d'); end
disp([num2str(size(Y,1)) ' reflections calculated.']);
%% calculate SRIRs based on mirror sources only

[~,~,avrgR] = cart2sph(X.X(:,1),X.X(:,2),X.X(:,3));
LS=[X.X; [0 0 -mean(avrgR)]]; % add a silent south pole
disp('Projecting to spatial impulse responses...');
IRm=reverb_SRIR(Y,R,c,fs,LS); % IR(ch1,ch2,chN) with N louspeakers
IRm=IRm(:,1:size(IRm,2)-1); % remove the silent loudspeaker

%% add diffuse tail
N=size(IRm,2); % number of channels

rng(0); % init random generator
D=primes(600)';
Di=D(15:14+N)/30;
Ds=Di(randperm(N));
Ds=rangeangle(Y(1:N,1:3)',R');

Gcorr=0.95;

G=exp(-3*log(10)/(RT60/mean(Ds))); % estimate decay
Ap=(randn(N,N));
A=Ap/max(abs(eig(Ap)))*G*Gcorr;

disp('Calculating diffuse field responses...');
IRd=reverb_fdn([1,zeros(1,N-1)],A,Ds,RT60*1.5,fs);
%% plot the diffuse IR
figure;
plot(0:1000/fs:(size(IRd,1)-1)/fs*1000,etc(sum(IRd,2)));
title('Summed diffuse IR');
xlabel('Time (ms)'); ylabel('ETC (dB)');
%% compare the spatial distributions to estimate the mixing region
y=resample(IRm,fs/10,fs);
figure;
pcolor(0:10000/fs:(size(y,1)-1)/fs*10000,1:N,etc(y(1:size(y,1),:))')
shading interp
xlabel('Time (ms)');
ylabel('Loudspeaker index');
title('Mirror sources only');
figure;
yd=resample(IRd,fs/10,fs);
pcolor(0:10000/fs:(size(yd,1)-1)/fs*10000,1:N,etc(yd(1:size(yd,1),:))');
shading interp
xlabel('Time (ms)');
ylabel('Loudspeaker index');
title('FDN only');

figure; hold on;
plot(0:10000/fs:(size(y,1)-1)/fs*10000,std(etc(y./repmat(sum(y.*y,2),1,N))'))
plot(0:10000/fs:(size(yd,1)-1)/fs*10000,std(etc(yd./repmat(sum(yd.*yd,2),1,N))'),'r')
legend('Mirror only','FDN based on mirror');
title('Normalized STD across loudspeakers');
%% mix mirror sources (IRm) with FDN (IRd) beginning from tmix
% tmix=20*V/Ar+12; % mixing time (ms), see Lindau A. Lindau,“Perceptual evaluation of physical predictors of the mixing time in binaural room impulse responses,” Proc. AES 128th Conv., London, UK, 2010.
disp('Mixing...');

Nmix=round(tmix/1000*fs); % tmix in samples
Nmixregion=round(tmixregion/1000*fs); % Nmixregion in samples
IRmo = fade(IRm(1:Nmix+Nmixregion,:), size(IRd,1), 0, Nmix);
IRdo = fade(IRd(Nmix+1:end,:), 0, Nmixregion, 0, -Nmix);
IRt=IRmo+IRdo;
%% Plot mixes
yo=resample(IRmo,fs/10,fs);
figure;
pcolor(0:10000/fs:(size(y,1)-1)/fs*10000,1:N,etc(yo(1:size(y,1),:))')
shading interp
xlabel('Time (ms)');
ylabel('Loudspeaker index');
title('Mirror sources only');

ydo=resample(IRdo,fs/10,fs);
figure;
pcolor(0:10000/fs:(size(y,1)-1)/fs*10000,1:N,etc(ydo(1:size(y,1),:))')
shading interp
xlabel('Time (ms)');
ylabel('Loudspeaker index');
title('FDN only');

yto=resample(IRt,fs/10,fs);
figure;
pcolor(0:10000/fs:(size(y,1)-1)/fs*10000,1:N,etc(yto(1:size(y,1),:))')
shading interp
xlabel('Time (ms)');
ylabel('Loudspeaker index');
title('Total mix');

figure;
plot(0:1000/fs:(size(IRt,1)-1)/fs*1000,etc(IRt));

%% Saving
disp('Saving...');
% save([mfilename ' ' num2str(RT60) ' ' strrep(datestr(now),':','-')],'Y','W','T','S','RT60','R','Omax','LWH','C','IRm','IRd','IRt','-v7.3');
clear y* IRdo IRmo
save([mfilename ' ' num2str(S) '.mat'],'-v7.3');

disp('Done.');