function [PTdata, SW_data, XW1_data, XW2_data] = Meas_PT_SW_XW(f_s, t_samp_sec, CHANNELS)

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board


% Configure the data acquisition
ai = daq.createSession('ni');
ch = addAnalogInputChannel(ai, 'Dev7', CHANNELS, 'Voltage');

for ii = 1:length(CHANNELS)
    ch(ii).TerminalConfig    = 'Differential';
    ch(ii).Range             = [-10, 10];
end

ai.Rate                 = f_s;
ai.DurationInSeconds    = t_samp_sec;
[data,time]             = ai.startForeground;

PTdata{1}               = data(:,1);
PTdata{2}               = data(:,2);
SW_data                 = data(:,3);
XW1_data                = data(:,4);
XW2_data                = data(:,5);

% Clear DAQ from system
delete(ai);
clear ai chans CHANNELS;

end

