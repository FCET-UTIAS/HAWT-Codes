function [Rawdata, Volt_mean, Volt_std] = ZOC_quick_scan(f_s,time_per_sensor_in_a_loop,no_of_loops)
%%
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
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');

nzoc = length(serialnums); 


ai.DurationInSeconds = time_per_sensor_in_a_loop;
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

time = zeros(f_s*time_per_sensor_in_a_loop*no_of_loops, length(sensorLogic)/2);
rawdata = zeros(f_s*time_per_sensor_in_a_loop*no_of_loops, nzoc, length(sensorLogic)/2);
disp('Begin Scan')
disp(' ');
for i = 1:no_of_loops
    for j = 1:length(sensorLogic)/2
        disp(['Run ', num2str(i), ': Scanning Channel ', num2str(j), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
        outputSingleScan(d,sensorLogic(j,:));
        pause(0.1)
        confirm = isequal(sensorLogic(j,:),inputSingleScan(d));
        if confirm == 0
            disp('Error: The DAQ does not receive the commanded sensor logic')
        end
        [rawdata((i-1)*f_s*time_per_sensor_in_a_loop+1:(i-1)*f_s*time_per_sensor_in_a_loop+f_s*time_per_sensor_in_a_loop,:,j), time((i-1)*f_s*time_per_sensor_in_a_loop+1:(i-1)*f_s*time_per_sensor_in_a_loop+f_s*time_per_sensor_in_a_loop,j)] = ai.startForeground();
   end
end
disp('End Scan')
outputSingleScan(d,sensorLogic(1,:)) %reset channel addressing 
delete(ai)
clear ai
delete(d)
clear d
 Rawdata = reshape(rawdata, [length(rawdata),nzoc, length(sensorLogic)/2]);
Volt_mean = reshape(mean(rawdata), [nzoc, length(sensorLogic)/2]);
Volt_std = reshape(std(rawdata), [nzoc, length(sensorLogic)/2]);
