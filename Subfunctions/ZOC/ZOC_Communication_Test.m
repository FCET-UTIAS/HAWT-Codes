%% Communication with ZOC Scanivalve modules
clc;clear all; close all;

%% DAQ and channel initialization

disp('Establishing DAQ Connection');

device = 'Dev6';
d = daq.createSession('ni');
ai = daq.createSession('ni');

% Establish channels for Digital Output (channel on ZOC module)

d.addDigitalChannel(device,'Port0/Line0:5','OutputOnly');
d.addDigitalChannel(device,'Port2/Line0:5','InputOnly');

% Establish Channels for Analog Input 
AI_CHANNELS = [1,2,3,4];
% AI_CHANNELS = 1;

ai.addAnalogInputChannel(device,AI_CHANNELS,'Voltage');
% ai.Channels.TerminalConfig = 'Differential';
% ai.Channels.Coupling = "DC" ;
% 
ai.Channels(1).TerminalConfig = 'Differential';
ai.Channels(2).TerminalConfig = 'Differential';
ai.Channels(3).TerminalConfig = 'Differential';
ai.Channels(4).TerminalConfig = 'Differential';

ai.Channels(1).TerminalConfig = 'SingleEnded';
ai.Channels(2).TerminalConfig = 'SingleEnded';
ai.Channels(3).TerminalConfig = 'SingleEnded';
ai.Channels(4).TerminalConfig = 'SingleEnded';

serialnums = {'M270', 'M276', 'M275', 'M267'}; %Input the zoc serial numbers, in order they are connected to system
% serialnums = {'093'};
% serialnums = {'093', '092'};
num_sensors_per_ZOC = 32;
nzoc = length(serialnums); 
%zocs = zoc_setupzocs(serialnums);
t_s = 10;
f_s = 4000;
ai.DurationInSeconds = t_s;
ai.Rate = f_s;
ActualRate = ai.Rate;
% 
ai.Channels(1).Coupling = "DC" ;
ai.Channels(2).Coupling = "DC" ;
ai.Channels(3).Coupling = "DC" ;
ai.Channels(4).Coupling = "DC" ;

disp('DAQ Connection Established');
disp(' '); 
disp(' ');

%% Load in Calibration File
cal_file = "M276_Calibration.mat";
load(cal_file,"poly")
fprintf("%s loaded into workspace\n",cal_file);

% Manual Load in of each file
M276_poly = load("M276_Calibration.mat","poly");
M275_poly = load("M275_Calibration.mat","poly");
M273_poly = load("M273_Calibration.mat","poly");
M270_poly = load("M270_Calibration.mat","poly");
M267_poly = load("M267_Calibration.mat","poly");

load('M276_offset_raw_voltage_2023_05_10_11_14.mat')
v_offset_M276 = mean(Voltages)';
load('M275_offset_raw_voltage_2023_05_10_12_52.mat')
v_offset_M275 = mean(Voltages)';
load('M270_offset_raw_voltage_2023_05_10_12_16.mat')
v_offset_M270 = mean(Voltages)';
load('M267_offset_raw_voltage_2023_05_10_12_35.mat')
v_offset_M267 = mean(Voltages)';

%% Go through all channels
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
rawdata = zeros(f_s*t_s, nzoc, length(sensorLogic)/2);
time = zeros(f_s*t_s, length(sensorLogic)/2);
disp('Begin Scan')
disp(' ');
for i = 1:length(sensorLogic)/2
    disp(['Scanning Channel ', num2str(i), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
    outputSingleScan(d,flip(sensorLogic(i,:)));
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
%% Discrete tests

Voltages = zeros(f_s*t_s,num_sensors_per_ZOC,nzoc);
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
disp('Begin Scan')
disp(' ');
for i = 1:32
    flip(sensorLogic(i,:));
    disp(['Scanning Channel ', num2str(i), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
    outputSingleScan(d,flip(sensorLogic(i,:)));
    read_back(i,:) = (inputSingleScan(d));
    Voltages(:,i,:) = ai.startForeground();
%     pause(3)
end
time = linspace(0,t_s,f_s*t_s)';
v_offset_all = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
%%
%v_mean = mean(Voltages)';
% v_offset_M273 = v_mean';

% p_mean_267 = v_mean.*M267_poly.poly(:,1) + M267_poly.poly(:,2);
% p_mean_270 = v_mean.*M270_poly.poly(:,1) + M270_poly.poly(:,2);
% p_mean_270 = (v_mean - v_offset_M270').*M270_poly.poly(:,1);
% p_mean_273 = v_mean.*M273_poly.poly(:,1) + M273_poly.poly(:,2);
% p_mean_273 = (v_mean - v_offset_M273').*M273_poly.poly(:,1);
% p_mean_275 = v_mean.*M275_poly.poly(:,1) + M275_poly.poly(:,2);
% p_mean_275 = (v_mean - v_offset_M275').*M275_poly.poly(:,1);
% p_mean_276 = v_mean.*M276_poly.poly(:,1) + M276_poly.poly(:,2);
% p_mean_276 = (v_mean - v_offset_M276).*M276_poly.poly(:,1);
% p_mean_267 = (v_mean - v_offset_M267').*M267_poly.poly(:,1);

figure
bar(p_mean)
% bar(v_offset_M273)
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')

% figure
% plot(time,Voltages(:,14:20),'Linewidth',2)
% xlabel('time [s]','Interpreter','Latex')
%%

v_mean_all = reshape(mean(Voltages_all),[num_sensors_per_ZOC,nzoc]);
v_offset_all = [v_offset_M270, v_offset_M276, v_offset_M275, v_offset_M267];
v_gain_all = [M270_poly.poly(:,1), M276_poly.poly(:,1), M275_poly.poly(:,1), M267_poly.poly(:,1)];

p_mean_all = (v_mean_all - v_offset_all).*v_gain_all; 

figure
subplot(2,2,1)
bar(p_mean_all(:,1))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')

subplot(2,2,2)
bar(p_mean_all(:,2))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')

subplot(2,2,3)
bar(p_mean_all(:,3))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')

subplot(2,2,4)
bar(p_mean_all(:,4))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')

%%
figure
subplot(2,2,1)
%plot(time,Voltages(:,1:8),'Linewidth',2)
bar(p_mean_276(1:8))
%legend('1','2','3','4','5','6','7','8','Interpreter','Latex')
xlabel('time [s]','Interpreter','Latex')
ylabel('Voltage [V]','Interpreter','Latex')

subplot(2,2,2)
%plot(time,Voltages(:,9:16),'Linewidth',2)
bar(p_mean_276(9:16))
%legend('9','10','11','12','13','14','15','16','Interpreter','Latex')
xlabel('time [s]','Interpreter','Latex')
ylabel('Voltage [V]','Interpreter','Latex')

subplot(2,2,3)
%plot(time,Voltages(:,17:24),'Linewidth',2)
bar(p_mean_276(17:24))
%legend('17','18','19','20','21','22','23','24','Interpreter','Latex')
xlabel('time [s]','Interpreter','Latex')
ylabel('Voltage [V]','Interpreter','Latex')

subplot(2,2,4)
%plot(time,Voltages(:,25:end),'Linewidth',2)
bar(p_mean_276(25:32))
%legend('25','26','27','28','29','30','31','32','Interpreter','Latex')
xlabel('time [s]','Interpreter','Latex')
ylabel('Voltage [V]','Interpreter','Latex')



%% Manual scan
n = length(d.Channels)/2;
sensorLogic = flip(dec2bin(2^n-1:-1:0)-'0');
rawdata = zeros(f_s*t_s, nzoc, length(sensorLogic)/2);

disp('Begin Scan')
disp(' ')
for i = 1:length(sensorLogic)/2
    disp(['Manually move logic to sensor logic [', num2str(sensorLogic(i,:)), '] to scan channel ', num2str(i), ' of ', num2str(length(sensorLogic)/2), ' for all connected modules'])
    disp(' ')
    disp('Press Enter to continue')
    pause
    [rawdata(:,:,i), time(:,i)] = ai.startForeground();
    pause(1);
end
Volt_mean = reshape(mean(rawdata), [nzoc, length(sensorLogic)/2]);
%%
figure
hold on
%plot(ans(:,1))
plot(ans(:,2))
plot(ans(:,3))
plot(ans(:,4))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
box on
%%

figure
hold on
plot(time(:,29),rawdata(:,1,29))
plot(time(:,29),rawdata(:,2,29))
plot(time(:,29),rawdata(:,3,29))
plot(time(:,29),rawdata(:,4,29))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
title('Channel 29')
box on

figure
hold on
plot(time(:,30),rawdata(:,1,30))
plot(time(:,30),rawdata(:,2,30))
plot(time(:,30),rawdata(:,3,30))
plot(time(:,30),rawdata(:,4,30))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
title('Channel 30')
box on

figure
hold on
plot(time(:,31),rawdata(:,1,31))
plot(time(:,31),rawdata(:,2,31))
plot(time(:,31),rawdata(:,3,31))
plot(time(:,31),rawdata(:,4,31))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
title('Channel 31')
box on

figure
hold on
plot(time(:,32),rawdata(:,1,32))
plot(time(:,32),rawdata(:,2,32))
plot(time(:,32),rawdata(:,3,32))
plot(time(:,32),rawdata(:,4,32))
legend('Module 091','Module 092','Module 093','Module 094')
xlabel('Time [sec]')
ylabel('Voltage [V]')
title('Channel 32')
box on



%% 
for i = 1:num_sensors_per_ZOC 
    disp(' ')
    disp(['set correct sensor logic manually to [', num2str(sensorLogic(i,:)), ']'])
    disp(' ')
    disp('Press Enter to continue')
    pause
    ai.startForeground();
    offset_manual(i) =  mean(ans);
end

%%
load ZOC_no091_ASCII
load ZOC_no092_ASCII
load ZOC_no093_ASCII
load ZOC_no094_ASCII
Voltages(1:16,:) = [];
gain = [ZOC_no091_ASCII(1,:); ZOC_no092_ASCII(1,:); ZOC_no093_ASCII(1,:); ZOC_no094_ASCII(1,:)]';
offset = [ZOC_no091_ASCII(2,:); ZOC_no092_ASCII(2,:); ZOC_no093_ASCII(2,:); ZOC_no094_ASCII(2,:)]';

for i = 1:nzoc
    check(:,i) = Voltages(:,i).*gain(17:24,i) + offset(17:24,i);
end
%check(1:16,:) = [];
%%
calib_Data = [offset',p2',p4',p6',p8',p10'];
PT_P_Pa = 0.1*(0:2:10);
CALIB_PTA = zeros(2, 32);  % Store calibration constants for linear fit
CALIB_PTA_Error = cell(1, 32);  % Store error structure produced by polyfit to determine error on fit
for i = 1:num_sensors_per_ZOC
        [coeff,error] = polyfit(calib_Data(i,:),PT_P_Pa,1);
        CALIB_PTA(:,i) = coeff;
        CALIB_PTA_Error{i} = {error};
end

%%
%PT_P_Pa = PT_P_Pa';
calib_Data = calib_Data';
scrz = get(0,'ScreenSize');
for j = 1:nzoc
    figure('Position',[1 0.1*scrz(4) 0.8*scrz(3) 0.8*scrz(4)]);
    for i = 1:num_sensors_per_ZOC/4
        subplot(2,4,i)
        hold on
        scatter(calib_Data(:,i,j), PT_P_Pa(:))
        plot(calib_Data(:,i,j),polyval(CALIB_PTA(:,i,j),calib_Data(:,i,j)))
        xlabel('Voltage [V]')
        ylabel('Pressure [psi]')
        title([sprintf('Module %s', string(serialnums(j))), sprintf(' Port %s', string(i))], 'Interpreter', 'latex')
        box on
    end
    hold off
    figure('Position',[1 0.1*scrz(4) 0.8*scrz(3) 0.8*scrz(4)]);
    for i = num_sensors_per_ZOC/4+1:num_sensors_per_ZOC/2
        subplot(2,4,i-num_sensors_per_ZOC/4)
        hold on
        scatter(calib_Data(:,i,j), PT_P_Pa(:))
        plot(calib_Data(:,i,j),polyval(CALIB_PTA(:,i,j),calib_Data(:,i,j)))
        xlabel('Voltage [V]')
        ylabel('Pressure [psi]')
        title([sprintf('Module %s', string(serialnums(j))), sprintf(' Port %s', string(i))], 'Interpreter', 'latex')
        box on
    end
    hold off
    figure('Position',[1 0.1*scrz(4) 0.8*scrz(3) 0.8*scrz(4)]);
    for i = num_sensors_per_ZOC/2+1:3*num_sensors_per_ZOC/4
        subplot(2,4,i-num_sensors_per_ZOC/2)
        hold on
        scatter(calib_Data(:,i,j), PT_P_Pa(:))
        plot(calib_Data(:,i,j),polyval(CALIB_PTA(:,i,j),calib_Data(:,i,j)))
        xlabel('Voltage [V]')
        ylabel('Pressure [psi]')
        title([sprintf('Module %s', string(serialnums(j))), sprintf(' Port %s', string(i))], 'Interpreter', 'latex')
        box on
    end
    hold off
    figure('Position',[1 0.1*scrz(4) 0.8*scrz(3) 0.8*scrz(4)]);
    for i = 3*num_sensors_per_ZOC/4+1:num_sensors_per_ZOC
        subplot(2,4,i-3*num_sensors_per_ZOC/4)
        hold on
        scatter(calib_Data(:,i,j), PT_P_Pa(:))
        plot(calib_Data(:,i,j),polyval(CALIB_PTA(:,i,j),calib_Data(:,i,j)))
        xlabel('Voltage [V]')
        ylabel('Pressure [psi]')
        title([sprintf('Module %s', string(serialnums(j))), sprintf(' Port %s', string(i))], 'Interpreter', 'latex')
        box on
    end
    hold off
end

%%
filename = strcat('Calib_Meas_mode_module_',char(serialnums),'.mat');
save (strcat('C:\Users\FCET\Desktop\SO_ExCamp1\Cp\ZOC_Documents\Raw_voltage_for_all\',filename))
%%
savecalcheck = input("Save calibration to default file? (Y/N): ", "s");
if upper(string(savecalcheck)) == "Y"
    for i = 1:nzoc
        zoc_savecalibration(serialnums(i), CALIB_PTA(:,:,i), 1)  % saves to default file
    end
else
    for i = 1:nzoc
        zoc_savecalibration(serialnums(i), CALIB_PTA(:,:,i), 0)  % saves to alternate file
    end
end