
clear all; close all; clc;

%% Initialize ZOC sampling variables

f_s = 40000;
time_per_sensor_in_a_loop = 0.1;
no_of_loops = 5;

addpath("F:\Experimental Data 2023\ZOC\NRC_ZOCs_Cal_files\CAL_files_gains_only\")

%% Get ZOC offset
% 

[v_offset, serialnums,zoc_offset_status] = zoc_offset(f_s,time_per_sensor_in_a_loop,no_of_loops);

%% Turn on the tunnel
input("turn on the tunnel. Press enter")
oldPath=cd("H:\ExperimentalCampaign2\AWTcontrol");
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


oldPath=cd("H:\ExperimentalCampaign2\AWTcontrol");
AWT_Control_setVref(0)
AWT_Control_off(0)
cd(oldPath)

