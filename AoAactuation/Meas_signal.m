function [signal, time] = Meas_signal(f_s, t_samp)

%---------------------------------------------------------------------------
% Function to measure a voltage signal with the DAQ
% Description: Creates a DAQ session on the NI board Dev1, reads analog
% input channel 0 (differential, +/-10 V range) at the requested sampling
% frequency for the requested time, then deletes the session. Requires the
% Data Acquisition Toolbox Support Package for National Instruments
% NI-DAQmx Devices.
%
% INPUTS: f_s    - desired sampling frequency (scans per second)
%         t_samp - desired sampling time (s)
% OUTPUTS: signal - measured voltage (V)
%          time   - time of each sample (s)
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

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
