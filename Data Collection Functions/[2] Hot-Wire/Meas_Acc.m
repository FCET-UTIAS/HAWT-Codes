
function [data, time] = Meas_Acc( f_s, t_samp, Ch)

CHANNELS = Ch;


% Configure the data acquisition
ses = daq.createSession('ni');
ses.addAnalogInputChannel('Dev5', CHANNELS, 'Voltage');

set(ses.Channels,'TerminalConfig','Differential');

for ii = 1:length(CHANNELS)
    ses.Channels(1).Range   = [-10 10];
end

ses.DurationInSeconds   = t_samp;
ses.Rate                = f_s;
ActualRate              = f_s;
[data, time]            = ses.startForeground();

% Clear DAQ from system
delete(ses);
clear ses chans CHANNELS;

