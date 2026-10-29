function [rawdata, Volt_mean, Volt_std] = ZOC_serial_scan(f_s,t_s)
disp('Establishing DAQ Connection');

device = 'Dev4';
d = daq.createSession('ni');
ai = daq.createSession('ni');

% Establish channels for Digital Output (channel on ZOC module)

d.addDigitalChannel(device,'Port0/Line6','OutputOnly');
d.addDigitalChannel(device,'Port1/Line5:7','OutputOnly');
d.addDigitalChannel(device,'Port2/Line0:1','OutputOnly');
d.addDigitalChannel(device,'Port0/Line1','InputOnly');
d.addDigitalChannel(device,'Port1/Line1:2','InputOnly');
d.addDigitalChannel(device,'Port2/Line2','InputOnly');
d.addDigitalChannel(device,'Port2/Line5:6','InputOnly');

% Establish Channels for Analog Input 
AI_CHANNELS = [2,3,5,6];
%AI_CHANNELS = 5;

ai.addAnalogInputChannel(device,AI_CHANNELS,'Voltage');
% 
% ai.Channels(1).TerminalConfig = 'Differential';
% ai.Channels(2).TerminalConfig = 'Differential';
% ai.Channels(3).TerminalConfig = 'Differential';
% ai.Channels(4).TerminalConfig = 'Differential';

ai.Channels(1).TerminalConfig = 'SingleEnded';
ai.Channels(2).TerminalConfig = 'SingleEnded';
ai.Channels(3).TerminalConfig = 'SingleEnded';
ai.Channels(4).TerminalConfig = 'SingleEnded';

serialnums = {'091', '092', '093', '094'}; %Input the zoc serial numbers, in order they are connected to system
%serialnums = {'093'};
nzoc = length(serialnums); 

%t_s = 10;
%f_s = 4000;
ai.DurationInSeconds = t_s;
ai.Rate = f_s;
ActualRate = ai.Rate;

ai.Channels(1).Coupling = "DC" ;
ai.Channels(2).Coupling = "DC" ;
ai.Channels(3).Coupling = "DC" ;
ai.Channels(4).Coupling = "DC" ;

disp('DAQ Connection Established');
disp(' '); 
disp(' ');


%%
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
rawdata = zeros(f_s*t_s, nzoc, length(sensorLogic)/2);
time = zeros(f_s*t_s, length(sensorLogic)/2);
disp('Begin Scan')

for i = 1:length(sensorLogic)/2
    disp(['Scanning Channel ', num2str(i), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
    outputSingleScan(d,sensorLogic(i,:));
    confirm = isequal(sensorLogic(i,:),inputSingleScan(d));
    if confirm == 0
        disp('Error: The DAQ does not receive the commanded sensor logic')
    end
    pause(1);
    [rawdata(:,:,i), time(:,i)] = ai.startForeground();
    pause(1);
end
disp('End Scan')
outputSingleScan(d,sensorLogic(1,:)) %reset channel addressing 
delete(ai)
clear ai
delete(d)
clear d
Volt_mean = reshape(mean(rawdata), [nzoc, length(sensorLogic)/2]);
Volt_std = reshape(std(rawdata), [nzoc, length(sensorLogic)/2]);
