%       function Save_LS(SPAT, LS_SIGNAL, fs, fn)
% 
%       input:  - file Track13_short.wav
% 
%       output: 
%               - file output_1.wav
%               - reverb_main X Y Z.mat
% 
%   #Author: Franz Zagala
%   #Author: Piotr Majdak: adapted from F. Zagalas GUI (12.09.2017)
%   #Author: Michael Mihocic: adaptions for 16 channels (ITU Angus Lab) (10.08.2026)
% 

function Save_LS(SPAT, LS_SIGNAL, fs, fn)

if ~exist('fn','var')
    [fn , dir_save] = uiputfile('*.wav');
    if isequal(fn,0) || isequal(dir_save,0)
        error('file won''t be saved. You must enter a correct filename and a directory.');
    end
    SPAT.filename1 = [dir_save fn];
    [pa,na,ext]=fileparts(SPAT.filename1);
else
    [pa,na]=fileparts(fn);
    ext='wav';
end
    OutGain = 1/max(abs(LS_SIGNAL(:)));
    % readsf~ in Pd doesn't work for 91-channels .wav-files ->
    % decompose into 4 .wav-files
    disp(['Saving ' fullfile(pa,[na '_1.' ext])]);
    audiowrite(fullfile(pa,[na '_1.' ext]) , OutGain.*LS_SIGNAL(:,1:16) , fs);
