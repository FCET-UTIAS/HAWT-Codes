%% Communication with ZOC Scanivalve modules

%% MY IDEA FOR SAMPLING FROM ZOC MODULE
clc;clear all; close all;
disp('Establishing DAQ Connection');

device = 'Dev2';
d = daq.createSession('ni');
ai = daq.createSession('ni');

% Establish channels for Digital Output (channel on ZOC module)
d.addDigitalChannel(device,'Port0/Line0:3','InputOnly');
d.addDigitalChannel(device,'Port1/Line0:3','OutputOnly');

% Establish Channels for Analog Input 
%AI_CHANNELS = [0,1,2,3,5];
AI_CHANNELS = 0;

ai.addAnalogInputChannel(device,AI_CHANNELS,'Voltage');

ai.Channels(1).TerminalConfig = 'Differential';


% Overall sample time and sample frequency for each channel on module
t_s = 1;     
f_s = 100;      

% Number of sensors on each module
num_sensors = 16;    

% Sample freq per sensor (just make it high for now, we can come up with a
% better way and optimize this later).
f_s_channel = 10000;   

% Sample time needed to ensure f_s met for each sensor on module. Might 
% need to incorporate the time delay between samples being collected for
% imporved accuracy here
t_s_channel = 1/(f_s*num_sensors); 

% Configure DAQ to sample one channel per instance that it is called
ai.DurationInSeconds = t_s_channel;
ai.Rate = f_s_channel;
ActualRate = ai.Rate;
ai.Channels(1).Range = [-10 10];

disp('DAQ Connection Established');
disp(' '); 
disp(' ');

% Set channel addressing logic
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');

% Data storage 
data = zeros(f_s*t_s, length(sensorLogic));
time_start = data;
time_end   = data;
%%
% Start taking data
disp('Begin Scan')
disp(' ');

tic;
for i = 1:f_s*t_s 
    % This for loop collects one sample for each channel. (To build full
    % data set, this loop will need to be repeated f_s*t_s times)
    for channel = 1:num_sensors
        %disp(['Scanning Channel ', num2str(channel), ' of ', num2str(length(sensorLogic))])
        
        % Address channel in ZOC Module
        outputSingleScan(d,sensorLogic(channel,:));
        confirm = isequal(sensorLogic(channel,:),inputSingleScan(d));
        
        if confirm == 0
            disp('Error: The DAQ does not receive the commanded sensor logic')
        end

        % Collect data
        time_start(i,channel) = toc;
        [data_temp,~] = ai.startForeground();
        time_end(i,channel) = toc;

        % Store mean of collected sample into data matrix (it is only one
        % sample of f_s needed over 1 second)
        data(i,channel) = mean(data_temp);
    end
end

%%
t = 0:1/f_s:t_s-1/f_s;
figure(1)
hold on;
bar(mean(data))
hold off;
figure
plot(data)
