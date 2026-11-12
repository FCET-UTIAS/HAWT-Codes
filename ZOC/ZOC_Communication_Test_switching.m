%% Communication with ZOC Scanivalve modules
clc;clear all; close all;

%%
disp('Establishing DAQ Connection');

device = 'Dev5';
d = daq.createSession('ni');
ai = daq.createSession('ni');

% Establish channels for Digital Output (channel on ZOC module)

d.addDigitalChannel(device,'Port0/Line1','OutputOnly');
d.addDigitalChannel(device,'Port1/Line5:7','OutputOnly');
d.addDigitalChannel(device,'Port2/Line0:1','OutputOnly');
d.addDigitalChannel(device,'Port0/Line6','InputOnly');
d.addDigitalChannel(device,'Port1/Line1:2','InputOnly');
d.addDigitalChannel(device,'Port2/Line2','InputOnly');
d.addDigitalChannel(device,'Port2/Line5:6','InputOnly');

% Establish Channels for Analog Input 
AI_CHANNELS = [2,3,5,6];
%AI_CHANNELS = 2;

ai.addAnalogInputChannel(device,AI_CHANNELS,'Voltage');

ai.Channels(1).TerminalConfig = 'SingleEnded';
ai.Channels(2).TerminalConfig = 'SingleEnded';
ai.Channels(3).TerminalConfig = 'SingleEnded';
ai.Channels(4).TerminalConfig = 'SingleEnded';

serialnums = {'091', '092', '093', '094'}; %Input the zoc serial numbers, in order they are connected to system
%serialnums = {'091'};
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
no_of_times_to_loop = 5;
%timetoreadzoc = length(sensorLogic)/2*no_of_times_to_loop;
nzoc = length(serialnums); 
t_s = 1;
f_s = 4000;

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

time = zeros(f_s*t_s*no_of_times_to_loop, length(sensorLogic)/2);
rawdata = zeros(f_s*t_s*no_of_times_to_loop, nzoc, length(sensorLogic)/2);
%time = zeros(f_s*t_s*no_of_times_to_loop, 4);
%rawdata = zeros(f_s*t_s*no_of_times_to_loop, nzoc, 4);
disp('Begin Scan')
disp(' ');
% commands = load("zoc_systemcommands.mat"); 
% [~, s_dq, ~] = zoc_setupdaqchannels(nzoc, f_s, 'AWT', 0);
% write(s_dq, commands.measure_A)
disp('Solenoid set to measure mode')
disp(' ');
for i = 1:no_of_times_to_loop
    for j = 1:length(sensorLogic)/2
        disp(['Run ', num2str(i), ': Scanning Channel ', num2str(j), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
        outputSingleScan(d,sensorLogic(j,:));
        pause(0.5)
        confirm = isequal(sensorLogic(j,:),inputSingleScan(d));
        if confirm == 0
            disp('Error: The DAQ does not receive the commanded sensor logic')
        end
        [rawdata((i-1)*f_s*t_s+1:(i-1)*f_s*t_s+f_s*t_s,:,j), time((i-1)*f_s*t_s+1:(i-1)*f_s*t_s+f_s*t_s,j)] = ai.startForeground();
   end
end
disp('End Scan')
outputSingleScan(d,sensorLogic(1,:)) %reset channel addressing 
% write(s_dq, commands.purge);                    %Resets the solenoid valves
% delete(s_dq);
% clear s_dq
delete(ai)
clear ai
delete(d)
clear d


%%
% load ZOC_no091_ASCII
% load ZOC_no092_ASCII
% load ZOC_no093_ASCII
% load ZOC_no094_ASCII
% Volt_mean = reshape(mean(rawdata), [nzoc, length(sensorLogic)/2]);
% V_091 = Volt_mean(1,:);
% V_092 = Volt_mean(2,:);
% V_093 = Volt_mean(3,:);
% V_094 = Volt_mean(4,:);
% P_091 = ZOC_no091_ASCII(1,:).*Volt_mean(1,:)+ZOC_no091_ASCII(2,:);
% P_092 = ZOC_no092_ASCII(1,:).*Volt_mean(2,:)+ZOC_no092_ASCII(2,:);
% P_093 = ZOC_no093_ASCII(1,:).*Volt_mean(3,:)+ZOC_no093_ASCII(2,:);
% P_094 = ZOC_no094_ASCII(1,:).*Volt_mean(4,:)+ZOC_no094_ASCII(2,:);
% P = [P_091;P_092;P_093;P_094];
% cp_091 = P_091/status.dynamic_pressure_psi;
% cp_092 = P_092/status.dynamic_pressure_psi;
% cp_093 = P_093/status.dynamic_pressure_psi;
% cp_094 = P_094/status.dynamic_pressure_psi;
% cp = [cp_091;cp_092;cp_093;cp_094];
% 
% V_main =  [V_091(17:20), V_092(2:30)]';
% P_main  = [P_091(17:20), P_092(2:30)]';
% cp_main  = [cp_091(17:20), cp_092(2:30)]';
%%

figure
hold on
%plot(rawdata(:,1,5))
plot(rawdata(:,2,5))
plot(rawdata(:,3,5))
plot(rawdata(:,4,5))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
%%
% figure
% scatter(main(1:end-1,2)/15.78,V_main)
% set(gca, 'YDir','reverse')
% figure
% scatter(main(1:end-1,2)/15.78,P_main)
% set(gca, 'YDir','reverse')
% ylabel('Pressure [psi]')
% xlabel('x/c') 
% box on
%     
% figure
% scatter(main(1:end-1,2)/15.78,cp_main)
% set(gca, 'YDir','reverse')