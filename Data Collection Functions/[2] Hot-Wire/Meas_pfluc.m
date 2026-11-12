function [p_trans, time] = Meas_pfluc( f_s, t_samp, CHANNELS)

% INPUT:
% f_s: desired sampling frequency
% t_samp: desired sampling time
% OUTPUT:
% PTdata: measurements acquired from pressure transducer
% SWdata: measurements acquired from hot-wire
% ActualRate: the sampling rate that was used by the DAQ board

%CHANNELS = [16];

% Configure the data acquisition
ses = daq.createSession('ni');
ses.addAnalogInputChannel('Dev7',CHANNELS, 'Voltage');

set(ses.Channels,'TerminalConfig','Differential');

ses.Channels(1).Range   = [-10 10];

ses.DurationInSeconds   = t_samp;
ses.Rate                = f_s;
ActualRate              = f_s;
[data, time]            = ses.startForeground();

p_trans                 = data;

% Clear DAQ from system
delete(ses);
clear ses chans CHANNELS;

end
