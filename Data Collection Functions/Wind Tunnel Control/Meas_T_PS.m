function [T, PT_data] = Meas_T_PS(f_s, time)

% Configurate the data acquisition
s1 = daq.createSession('ni');
s1.Rate = f_s;
s1.DurationInSeconds=time;
chans_PT = s1.addAnalogInputChannel('Dev5', 0, 'Voltage');
set(s1.Channels, 'TerminalConfig', 'SingleEnded');

warning('off')
s2 = daq.createSession('ni');
addAnalogInputChannel(s2, 'Dev9', 'ai0', 'Thermocouple');
tc = s2.Channels(1);
tc.ThermocoupleType = 'T';


% Start sampling
PT_data = startForeground(s1);

T_data = zeros(5, 1);
for i = 1:length(T_data)
    T_data(i, 1) = s2.inputSingleScan();
    pause(0.5)
end

T = mean(T_data);

% Clear DAQ from system
delete(s1);

warning('on')
delete(s2)
end

