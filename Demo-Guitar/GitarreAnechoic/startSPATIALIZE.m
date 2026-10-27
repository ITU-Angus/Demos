%   startSPATIALIZE.m
% 
%       spatialize sound files
% 
%       input:  file Track13_short.wav
%       output: file output_1.wav
% 
%   (c) Michael Mihocic, ITU Linz
% 
%   #Author: Michael Mihocic: adaptions for 16 channels (ITU Angus Lab) (10.08.2026)
%   #Author: Michael Mihocic: fix for proper VBAP triangulations (10.2026)
% 

% Gitarre Anechoic
clear;
addpath('..\Matlab\');
addpath('..\Data\');
addpath('..\..\..\MatlabMM\');
addpath('..\..\..\Lautsprecherkoordinaten\');

% load SPAT_default; % load default spatialization parameters
load ITUGrid.mat;

% S=[40 6 2.5];
S=[3 1.5 1.1];
% R=[1 1.5 1];
R=[1 1.5 1.2];
fs=48000;
c=340; % speed of sound (m/s)

[in,fsx]=audioread('Track13_short.wav');
if fsx~=fs, in=resample(in,fs,fsx); end

% X=load('grid_latest.mat'); % loudspeaker grid X(x,y,z)
% Compute the radius of each loudspeaker (cart2sph returns [az, el, r])
[~,~,r] = cart2sph(X.X(:,1), X.X(:,2), X.X(:,3));

% Normalize all loudspeaker positions to unit sphere.
% This is required for VBAP: the triangulation must be performed on a sphere
% so that triangle faces correspond to actual spatial sectors.
% Without normalization, speakers at different distances produce a skewed
% convex hull, which causes geometrically nonsensical triplets (e.g. 5/6/9).
LS_raw = X.X;
LS_norm = LS_raw ./ r;                          % normalize to unit sphere
LS = [LS_norm; [0 0 -1]];                        % add silent south pole at unit distance

TR = freeBoundary(delaunayTriangulation(LS));    % set of triangular facets (on unit sphere)

% Normalize source direction to unit sphere (consistent with normalized LS grid)
Sdir = S - R;
Sdir = Sdir / norm(Sdir);
[g,TRidx,par,Pi] = VBAPgain(Sdir, LS, TR);
IR=zeros(1,size(LS,1));
IR(TR(TRidx,:))=g;
IR=IR(1:end-1);
out=repmat(in,1,size(IR,2)).*repmat(IR,size(in,1),1);
Save_LS([], out, fs, 'output');
