%% Modified by SO - May 11
% added save snippet

clear all; close all; clc;

%% Initialize ZOC sampling variables

f_s = 40000;
time_per_sensor_in_a_loop = 0.1;
no_of_loops = 10;

addpath("NRC_ZOCs_Cal_files\CAL_files_gains_only\")

%% Get ZOC offset
ZOCcalbOption=input("Choose if calibration is necessary [Y/N]","s");
if strcmp(ZOCcalbOption,"Y")
    [v_offset, serialnums,zoc_offset_status] = zoc_offset(f_s,time_per_sensor_in_a_loop,no_of_loops);
else
    disp("Choose the calibration file ...")
    pause(0.5)
    CalibrationFileName=uigetfile("H:\ExCamp1\CalibrationData\ZOCcalibration");
    load(CalibrationFileName)
end

%% Turn on the tunnel
input("turn on the tunnel. Press enter")
oldPath=cd("H:\ExCamp1\AWTcontrol");
AWT_Control_on
AWT_Control_setVref(8)
pause(15)
cd(oldPath)
%% Take measurement

tic
[read_back, rawVoltage, t_stamp, v_mean, v_std, p_mean] = getZOC_pressure(f_s,time_per_sensor_in_a_loop,no_of_loops,v_offset);
toc


%% Plot pressures from different channels.

figure
subplot(2,2,1)
bar(p_mean(:,1))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')

subplot(2,2,2)
bar(p_mean(:,2))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')

subplot(2,2,3)
bar(p_mean(:,3))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')

subplot(2,2,4)
bar(p_mean(:,4))
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')


oldPath=cd("H:\ExCamp1\AWTcontrol");
AWT_Control_setVref(0)
AWT_Control_off(0)
cd(oldPath)

%% Saving p_mean data 

saveOption = input('Save data? [Y/N]: ', 's');
if strcmp(upper(saveOption), 'Y')
timestamp = datestr(now, 'yymmdd_HH');
filename = fullfile('ExCamp1', 'data', ['ZOC_measurement_', timestamp, '.csv']);

% Build column headers
headers = strings(1, 128);
for m = 1:length(serialnums)
    for ch = 1:32
        headers((m-1)*32 + ch) = sprintf('%s_Ch%d', serialnums{m}, ch);
    end
end

% Write to CSV
T = array2table(p_mean', 'VariableNames', headers);
writetable(T, filename);
    fprintf('Data saved to %s\n', filename);
else
    disp('Data not saved.')
end