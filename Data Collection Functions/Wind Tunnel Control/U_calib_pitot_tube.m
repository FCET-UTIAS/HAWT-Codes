%% Caliibration file for tunnel speed
clear all; clc;

%% change these
V_test   = linspace(4,9,10);      % test voltages (volt increments for calibration 
P_atm_kPa = input('    Atmospheric Pressure [kPa]: ');                    % atmospheric pressure [kPa]
foldername = input('Please input date in the form of YYYYMMDD:  ','s');      % input date information for saving
ts_Baratron = 60;       % Sampling time
fs_Baratron = 4000;     % Sampling rate
%load('U_calib_pitot_tube08-02-2022_12-37', 'Cal_coef');      % Load the old wind tunnel calibration coefficients for temporary use

%% Do not change these
P_atm_mmHg = (P_atm_kPa) * 7.50062;
disp('    Make sure the Baratron is in 100 Torr and press Enter to continue...')
pause;
range = 100;                      % range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;    % for MKS 120AD on desired torr range, 10V range

index_tunnel = input(['    Is the wind t' ...
    'unnel turned off? Input 1 if it is not...'])
if index_tunnel == 1
    vel_tunnel = input('    Input the velocity the tunnel is roughly at...')
    AWT_Control_off(AWT_Control_U2V_Creighton(vel_tunnel,Cal_coef(1),Cal_coef(2)));
    disp(' Tunnel turned off now...')
else
    disp(' Tunnel already turned off, the code will continue...')
end

%% Initial Baratron Offset
disp('  Initial Baratron offset measurement:');
% v_fs_offset_initial = BaratronOffset(fs_Baratron,ts_Baratron);
% v_fs_offset = Baratron_offsetTwoBaratron(fs_Baratron, 30);
v_fs_offset_initial = Baratron_offset(fs_Baratron,30);
% v_fs_offset_initial = v_fs_offset(2); 

tic;        % Start the stopwatch timer
%% Voltage Sweep and Measurement
disp('Turning on AWT');
AWT_Control_on;
pause(5);
for i = 1:length(V_test)
    AWT_Control_setVref(V_test(i));
    disp(['Adjusting AWT to ' num2str(V_test(i),'%5.2f') 'V']);
    pause(20);
    
%     [T(i), v(:,i)] = Meas_T_PS(0, fs_Baratron, ts_Baratron, 1);
    [T(i), v(:,i)] = Meas_T_PS(fs_Baratron, ts_Baratron);
%     [ v] = Meas_T_PS(fs_Baratron, ts_Baratron);
    [rho_air(i), visc_air, rho_w, g] = fluid_prop(T(i), P_atm_mmHg);   % determine fluid properties
    
    q_fs(:,i) = (v(:,i) - v_fs_offset_initial).* P_gain_fs;
%     q_fs(:,i) = (v(:,i) - baratron_top_offset)* P_gain_fs;
    u_fs(:,i) = (2 * abs(q_fs(:,i)./rho_air(i))).^0.5 .* (q_fs(:,i) ./ abs(q_fs(:,i))); 
    
%     sqrt(2/rho_air(i)*abs(q_fs(:,i))).*(q_fs(:,i)./abs(q_fs(:,i)));        % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
    
    mean_u_fs(i) = mean(u_fs(:,i));
    std_u_fs(i) = std(u_fs(:,i));
    disp(['u_fs = ' num2str(mean_u_fs(i)) ' m/s']);
    
    time(i) = toc;
end

% Slow down AWT before shutoff
AWT_Control_off(V_test(i));

%% SECTION *: Final Pressure Transducer Offset
disp('  Final Baratron offset measurement:');
% v_fs_offset_final = BaratronOffset(fs_Baratron,ts_Baratron);
% v_fs_offset = Baratron_offsetTwoBaratron(fs_Baratron, 30);
% v_fs_offset_final = v_fs_offset(2); 

time_final = toc;       % Read the final time after the final offset measurement

%% Process Data

clear PT_e;
v_fs_offset_final = v_fs_offset_initial;
v_offset_weighted = ((1-(time/time_final))*v_fs_offset_initial + (time/time_final)*v_fs_offset_final);
q_fs_offset_weighted = (v - repmat(v_offset_weighted, [length(v) 1]))* P_gain_fs;
u_fs_offset_weighted = sqrt(repmat(2, [length(v) length(rho_air)])./repmat(rho_air, [length(v) 1]).*abs(q_fs_offset_weighted)).*(q_fs_offset_weighted./abs(q_fs_offset_weighted));       % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
mean_u_fs_offset_weighted = mean(u_fs_offset_weighted,1);
std_u_fs_offset_weighted = std(u_fs_offset_weighted);
Cal_coef = polyfit(mean_u_fs,V_test,1);

%% Make Plot

figure
errorbar(V_test, mean_u_fs, std_u_fs,'.-');
xlabel('Voltage (V)');
ylabel('Freestream velocity (m/s)');
title('AWT freestream velocity calibration curve');
hold on
plot(Cal_coef(1)*(5:1:80)+Cal_coef(2),5:1:80)
hold off

%% Save Data

date_time = datestr(now,'mm-dd-yyyy_HH-MM');
filename = strcat('U_calib_pitot_tube_hybrid_modelIN_' ,date_time);
save(['F:\2026-02-00\TunnelCalib\', filename]);
% save(filename);
disp('Completed and saved');

