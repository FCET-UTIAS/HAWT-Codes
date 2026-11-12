function [ PTdata, SW_data_orig, ActualRate] = Meas_PT_2SW( f_s, t_samp, Nfft )

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board

CHANNELS = [7, 2];

% Configure the data acquisition
ai = daq.createSession('ni');
ch = addAnalogInputChannel(ai, 'Dev5', CHANNELS, 'Voltage');

ch(1).TerminalConfig    = 'Differential';
ch(2).TerminalConfig    = 'Differential';

ch(1).Range             = [-10, 10];
ch(2).Range             = [-10, 10];

ai.Rate                 = f_s;

ActualRate              = get(ai, 'Rate');     % Actual sampling rate may differ from f_s, this returns value set
Nsampmin                = t_samp*ActualRate;     % minimum number of samples at this rate
nrec                    = ceil(Nsampmin/Nfft);       % generate an integer number of FFT records
Nsamp                   = Nfft*nrec;

% Nsamp = ceil(t_samp*ActualRate);
ai.NumberOfScans        = Nsamp;
[data,time]             = ai.startForeground;

PTdata                  = data(:,1);
SW_data_orig            = data(:,2);

% Clear DAQ from system
delete(ai);
clear ai chans CHANNELS;

end

