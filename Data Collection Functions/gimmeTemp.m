function T = gimmeTemp()
f_s = 200000;
time = 5; 



warning('off')
s2 = daq.createSession('ni');
addAnalogInputChannel(s2, 'Dev9', 'ai0', 'Thermocouple');
tc = s2.Channels(1);
tc.ThermocoupleType = 'T';

T_data = zeros(5, 1);
for i = 1:length(T_data)
    T_data(i, 1) = s2.inputSingleScan();
    pause(0.1)
end

T = mean(T_data);


end