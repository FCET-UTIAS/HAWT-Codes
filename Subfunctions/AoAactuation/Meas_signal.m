function [signal, time] = Meas_signal(f_s, t_samp)

% INPUT:
%   f_s: desired sampling frequency (scans per second)
%   t_samp: desired sampling time (s)
% OUTPUT:
%   PTdata: measurements acquired from pressure transducer
%   SWdata: measurements acquired from hot-wire
%   ActualRate: the sampling rate that was used by the DAQ board
% Requirements:
%   Data Acquisition Toolbox Support Package for National Instruments NI-DAQmx Devices



% Configure the data acquisition
session = daq.createSession('ni');  % 'ni' = National Instruments
CHANNELS = [0];  % The channel on the DAQ
session.addAnalogInputChannel('Dev1', CHANNELS, 'Voltage');

set(session.Channels, 'TerminalConfig', 'Differential');

session.Channels(1).Range = [-10 10];

session.DurationInSeconds = t_samp;
session.Rate = f_s;
actual_rate = f_s;
[data, time] = session.startForeground();

signal = data;

% Clear DAQ from system
delete(session);
clear ses chans CHANNELS;

end
