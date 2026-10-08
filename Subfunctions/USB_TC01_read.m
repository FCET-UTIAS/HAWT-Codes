function [T] = USB_TC01_read()
warning('off')
s1 = daq.createSession('ni');
addAnalogInputChannel(s1,'Dev9','ai0','Thermocouple');
tc = s1.Channels(1);
tc.ThermocoupleType = 'T';

data = zeros(10,1);
for i = 1:length(data)
    
    data(i,1)=s1.inputSingleScan();
    
    pause(0.5)
end

T = mean(data);

warning('on')
delete(s1);
 