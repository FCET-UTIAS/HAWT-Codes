%% Caliibration file for tunnel speed
clear all; clc;

addpath(genpath('..\..\CalibrationData')) % Add all relevant folders
addpath(genpath('..\..\ConfigurationData'))
addpath(genpath('..\..\Subfunctions'))
addpath(genpath('..\..\AWTcontrol'))

%% change these
V_test   = linspace(1,10,10);      % test voltages (volt increments for calibration 
P_atm_in = input('    Atmospheric Pressure [kPa]: ');                    % atmospheric pressure [kPa]
ts_Baratron = 30;       % Sampling time
fs_Baratron = 4000;     % Sampling rate

%load('C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-04\U_calib_pitot_tube_04-04-2022_15-07', 'Cal_coef');      % Load the old wind tunnel calibration coefficients for temporary use
Cal_coef=[10/50];
%% Do not change these

P_atm = P_atm_in*1e3*0.0075;   % in mmHg
% P_atm = 746.5;

disp('    Make sure the Baratron is in 100 Torr and press Enter to continue...')
pause;
range = 100;                      % range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;    % for MKS 120AD on desired torr range, 10V range

input('Confirm that the tunnel is off')

%% SECTION *: Initial Pressure Transducer Offset
disp("Choose baratron calibration file")
BaratronCalibrationFileName=uigetfile("..\..\CalibrationData\BaratronCalibration");
load(BaratronCalibrationFileName,"v_fs_offset");

tic;        % Start the stopwatch timer
%%

disp('Turning on AWT');
AWT_Control_on;
pause(5);
for i = 1:length(V_test)

    AWT_Control_setVref(V_test(i));
    disp(['Adjusting AWT to ' num2str(V_test(i),'%5.2f') 'V']);
    pause(20);
    
    [T(i), v(:,i)] = Meas_T_PS(fs_Baratron, ts_Baratron);
    [rho_air(i), visc_air, rho_w, g] = fluid_prop(T(i), P_atm);   % determine fluid properties
    
    q_fs(:,i) = (v(:,i) - v_fs_offset)* P_gain_fs;
    u_fs(:,i) = sqrt(2/rho_air(i)*abs(q_fs(:,i))).*(q_fs(:,i)./abs(q_fs(:,i)));        % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
    mean_u_fs(i) = mean(u_fs(:,i));
    std_u_fs(i) = std(u_fs(:,i));
    disp(['u_fs = ' num2str(mean_u_fs(i)) ' m/s']);
    
    time(i) = toc;
%     pdiff(:,i) = q_fs;
%     keyboard
        
end

% Slow down AWT before shutoff
AWT_Control_off(V_test(i));


time_final = toc;       % Read the final time after the final offset measurement


%%
Cal_coef = polyfit(mean_u_fs(1:9),V_test(1:9),1);

figure(1)
date_time = datestr(now,'mm-dd-yyyy_HH-MM');
filename = strcat('U_calib_pitot_tube_' ,date_time);
errorbar(V_test, mean_u_fs, std_u_fs,'.-');
xlabel('Voltage (V)');
ylabel('Freestream velocity (m/s)');
title('AWT freestream velocity pitot tube calibration curve (1:9 SPEED)');
hold on
plot(Cal_coef(1)*(5:1:80)+Cal_coef(2),5:1:80)
hold off

filename = strcat('U_calib_pitot_tube_' ,date_time);
OldPath=cd('..\..\CalibrationData\TunnelSpeedCalibration');
status=movefile(strcat('U_calib_pitot_tube_*'), 'Legacy');
save(strcat(filename,'.mat'));
savefig(strcat(filename,'.fig'))
cd(OldPath)
disp('Completed and saved');


