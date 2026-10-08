%% [spectralData,f] = spectraCalc(temporalData,f_s)
% The spectra calculation parameters are hard-coded.

% Input:
% - temporalData: Data in temproral domain.
% - f_s: Sampling frequency

% Output:
% - spectralData: Data in frequency domain.
% - f: Frequency of the spectra.

function [spectralData,f] = spectraCalc(temporalData,f_s)

Nwindow = 2^14;         % Number of points in one window section
Noverlap = 2^13;        % Number of points of the overlap
Nfft = 2^14;            % Number of points in one bin
SpecType = 'PSD';       % 'PSD' or 'power'
ENBW = f_s/Nwindow*1.5;

[spectralData, f] = pwelch(temporalData,hanning(Nwindow),Noverlap,Nfft,f_s,SpecType);
end