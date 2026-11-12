function [ PTdata, XW1_data, XW2_data] = Meas_PT_XW( f_s, t_samp, Nfft)

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board

CHANNELS = [17,19,20];

% Configure the data acquisition
ai = daq.createSession('ni');
ch = addAnalogInputChannel(ai, 'Dev7', CHANNELS, 'Voltage');

for ii = 1:length(CHANNELS)
    ch(ii).TerminalConfig    = 'Differential';
    ch(ii).Range             = [-10, 10];
end

ai.Rate                 = f_s;
ActualRate              = get(ai, 'Rate');     % Actual sampling rate may differ from f_s, this returns value set
Nsampmin                = t_samp*ActualRate;     % minimum number of samples at this rate
nrec                    = ceil(Nsampmin/Nfft);       % generate an integer number of FFT records
Nsamp                   = Nfft*nrec;

% Nsamp = ceil(t_samp*ActualRate);
ai.NumberOfScans        = Nsamp;
[data,time]             = ai.startForeground;

PTdata                  = data(:,1);
XW1_data                 = data(:,2);
XW2_data                 = data(:,3);

% Clear DAQ from system
delete(ai);
clear ai chans CHANNELS;

end

