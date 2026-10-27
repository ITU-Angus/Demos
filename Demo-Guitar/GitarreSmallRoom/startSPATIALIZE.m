%   startSPATIALIZE.m
% 
%       spatialize sound files
% 
%       input:  - file Track13_short.wav
% 
%       output: 
%               - file output_1.wav
%               - reverb_main X Y Z.mat
% 
%   (c) Michael Mihocic, ITU Linz
% 
%   #Author: Michael Mihocic: adaptions for 16 channels (ITU Angus Lab) (10.08.2026)
%   #Author: Michael Mihocic: fix for proper VBAP triangulations (10.2026)
% 


%  Small Room
clear;
addpath('..\Matlab\');
addpath('..\Data\');
addpath('..\..\..\MatlabMM\');
addpath('..\..\..\Lautsprecherkoordinaten\');

load ITUGrid.mat; % load default spatialization parameters

S=[3 1.5 1.1];
R=[1 1.5 1.2];
if ~exist(['reverb_main ' num2str(S) '.mat'],'file'), reverb_main(S), end
load(['reverb_main ' num2str(S) '.mat']);

[in,fsx]=audioread('Track13_short.wav');
if fsx~=fs, in=resample(in,fs,fsx); end

len=size(in,1)+size(IRt,1)-1;
out=ifft(repmat(fft(in,len),1,size(IRt,2)).*fft(IRt,len));
Save_LS([], out, fs, 'output');
