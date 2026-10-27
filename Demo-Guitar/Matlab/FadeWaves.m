%       fade sound files
% 
%       input:  - 2 sound files
% 
%       output: - 1 sound file, fading from one wave file to the other
% 
%   (c) Michael Mihocic, ITU Linz
% 
%   #Author: Michael Mihocic: adaptions for 16 channels (ITU Angus Lab) (10.08.2026)
% 


clear;
tic;
fadeSamples=48000/1000*50; % fade duration: 50ms
offset=732000;        % where to fade (center of fading)
figures=0;

fadeSamples=fadeSamples/2;
close all;
% for ii=1:4

clear OUT*;

[A, FS]=audioread(['..\GitarreAnechoic\output_1.wav']);                  % load signal A
[S]    =audioread(['..\GitarreSmallRoom\output_1.wav']) / (sqrt(10)/2) ; % load signal S, and attenuate signal by 4 dB

OUT=zeros(max(size(A),size(S))); % prepare output file with zeros
OUT1(1:offset+fadeSamples,:) = fade(A, offset+fadeSamples, 0, fadeSamples, 0); % fade first signal
if figures==1;         figure; plot(OUT1(:,18)); title('OUT1');     end

OUT2=fade(S, size(OUT,1)-offset+fadeSamples, fadeSamples, 0, offset-fadeSamples); % fade second signal
if figures==1;         figure; plot(OUT2(:,18)); title('OUT2');     end

OUT(1:size(OUT1,1),:) = OUT1; % add signal 1 to output
if figures==1;         figure; plot(OUT(:,18)); title('Out (1)');     end

OUT(size(OUT,1)-size(OUT2,1) + 1 : size(OUT,1),:) = OUT(size(OUT,1)-size(OUT2,1) + 1 : size(OUT,1),:)    +    OUT2;  % add signal 2 to output
if figures==1;         figure; plot(OUT(:,18)); title('Out (1+2)');     end

%     OUT{ii}(offset+1-overlapSamples:size(OUT{ii},1),:) = fade(A{ii}, size(OUT{ii},1)-offset+overlapSamples, fadeSamples, 0, offset-overlapSamples) + OUT{ii}(offset+1-overlapSamples:size(OUT{ii},1),:);
disp(['saving: output_1.wav']);
audiowrite(['..\Data\output_1.wav'],OUT,FS);
%    figures=0;
% end
% fade function:
%   OUT = FADE(INP, LEN, FADEIN, FADEOUT, OFFSET) crops or extends with zeros the signal INP


toc;
disp('completed');