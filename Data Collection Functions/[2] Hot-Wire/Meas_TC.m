function [T_C] = Meas_TC

% ActualRate: the sampling rate that was used by the DAQ board

% Configure the data acquisition
warning('off','daq:Session:onDemandOnlyChannelsAdded')
device = 'Dev11';
ai = daq.createSession('ni');
ai.addAnalogInputChannel(device,0,'Thermocouple');

tc = ai.Channels(1);
tc.ThermocoupleType = 'J';

T_C = ai.inputSingleScan;

% Clear DAQ from system
%delete(ai);
%delete(tc);

end