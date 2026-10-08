%AWT_Control_Integrated allows you to specify and change the wind tunnel
%velocity and saves the flow information
%   INPUTS:
%       
%
%   OUTPUTS: 
%       
%        
%
%   HISTORY:
%       Created - Zhe Lu (2022-06)
%
% -------------------------------------------------------------------------%   

%%
clear all; clc;
%% Parameter Input
disp('Please make sure that the folder for the flow info data is created...');
file_name_1 = input('Please input date in the form of YYYYMMDD:  ','s');
file_name_2 = input('Please input trial number [3 digit]:  ','s');   
savedir = ['C:\Users\FCET\Documents\MATLAB\AWT_Zhe\', file_name_1, '\FlowInfo-', file_name_1, file_name_2];
U_target = input('Please input target velocity [m/s]:  ');          % Target freestream velocity [m/s]
P_atm_in = input('Please input atmospheric pressure [kPa]:  ');          % Atmospheric pressure [kPa]
L = 1;                  % Characteristic length for Re calculation [m]
fs_Baratron = 4000;
ts_Baratron = 30;

%% Fixed Parameters
AR = 0.845^2;
P_atm = P_atm_in*1e3*0.0075;   % [mmHg]
disp('Make sure the Baratron is in 10 Torr and press Enter to continue...')
pause;
range = 10;                      % range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;    % for MKS 120AD on desired torr range, 10V range
load('C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-04\U_calib_pitot_tube_04-04-2022_15-07','Cal_coef');
date_time_start = datestr(now,'mm-dd-yyyy_HH-MM');
%% Baratron Offset Measurement
disp('Please ZERO the Baratron for offset measurement and press any key to continue...');
pause;
disp('BEGIN Pressure Transducer Offset ----------------------------------')
[T,PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
v_fs_offset_initial = mean(PT_e);
tic;
disp(['    Initial offset voltage: ' num2str(v_fs_offset_initial,'%10.5f') ' V']);
disp('END Pressure Trasnsducer Offset -----------------------------------')
disp('-------------------------------------------------------------------')
disp('Restore the Baratron valve and press any key to continue...')

load laughter.mat
sound(y, Fs)

pause;

%% Velocity Control
disp('Turning on the wind tunnel...');
AWT_Control_on;                                                             % VFD initialization
[rho_air, ~, ~, ~, ~] = fluid_prop(T, P_atm);                           % Target dynamic pressure calculation
[V] = AWT_Control_U2V_Creighton(U_target, Cal_coef(1), Cal_coef(2));        % Start the tunnel using Cal_coef
if V > 2                                                                    % Gradual start of the tunnel
    AWT_Control_setVref(2);
    pause(2);
    if V > 4
        AWT_Control_setVref(4);
        pause(2);
        if V > 6
            AWT_Control_setVref(6);
            pause(2);
            if V > 8
                AWT_Control_setVref(8);
                pause(2);
                AWT_Control_setVref(V);
                pause(5);
            else
                AWT_Control_setVref(V);
                pause(5);
            end
        else
            AWT_Control_setVref(V);
            pause(5);
        end
    else
        AWT_Control_setVref(V);
        pause(5);
    end
else
    AWT_Control_setVref(V);
    pause(5);
end
disp('Target velocity reached initially, starting correction...');
% for i = 1:3
    [T,PT_e] = Meas_T_PS(fs_Baratron, 15);
    [rho_air, ~, ~, ~, ~] = fluid_prop(T, P_atm);   % update air density
    Q_actual = (mean(PT_e) - v_fs_offset_initial)* P_gain_fs;
    U_actual = sqrt(abs(2*Q_actual/(rho_air*(1 - AR^2)))).*(Q_actual./abs(Q_actual));
    V_target = V/U_actual*U_target;             % correct the input voltage based on linear assumption for the V-U curve
    AWT_Control_setVref(V_target);
pause(10);
disp('Velocity corrected, checking the final velocity and saving flow information...');

%% Velocity Check
[T, PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
[rho_air, visc_air, c, ~, ~] = fluid_prop(T, P_atm);   % determine fluid properties
Q_final_s = (PT_e - v_fs_offset_initial)* P_gain_fs;
U_final_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*(Q_final_s./abs(Q_final_s));       % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
U_final = mean(U_final_s);
std_U_final = std(U_final_s);
Re = rho_air*U_final*L/visc_air;                  % Re number
Ma = U_final/c;
disp(['The final velocity is ' num2str(U_final) ' m/s']);
disp(['Re is ' num2str(Re)]);
disp(['Ma is ' num2str(Ma)]);

k = 1;
P_atm_save(k) = P_atm_in;
AR_save(k) = AR;
c_save(k) = c;
Ma_save(k) = Ma;
Re_save(k) = Re;
L_save(k) = L;
rho_air_save(k) = rho_air;
T_save(k) = T;
U_final_save(k) = U_final;
std_U_final_save(k) = std_U_final;
V_final_save(k) = V_target;                 % Final input voltage
visc_air_save(k) = visc_air;

%% Velocity Change and Check
while 1 == 1

    load laughter.mat
    sound(y, Fs)

    index = input('Do nothing if you want the AWT to keep running at the current velocity... If you want to change the velocity, input 1; If you want to stop the AWT, input 0:  ');
    if index == 1
        U_target = input('Please input the target velocity:  ');
        P_atm_in = input('Please update the atmospheric pressure:  ');
        P_atm = P_atm_in*1e3*0.0075;   % [mmHg]
%         Q_target = U_target^2*rho_air*(1 - AR^2)/2;
        [V] = AWT_Control_U2V_Creighton(U_target, Cal_coef(1), Cal_coef(2));        % Start the tunnel using Cal_coef
        if abs(V - V_target) > 2                                                                    % Gradual start of the tunnel
            V_temp = V_target + 2*sign(V - V_target);
            AWT_Control_setVref(V_temp);
            pause(2);
            if abs(V - V_target) > 4
                V_temp = V_target + 4*sign(V - V_target);
                AWT_Control_setVref(V_temp);
                pause(2);
                if abs(V - V_target) > 6
                    V_temp = V_target + 6*sign(V - V_target);
                    AWT_Control_setVref(V_temp);
                    pause(2);
                    if abs(V - V_target) > 8
                        AWT_Control_setVref(V_temp);
                        pause(2);
                        AWT_Control_setVref(V);
                        pause(5);
                    else
                        AWT_Control_setVref(V);
                        pause(5);
                    end
                else
                    AWT_Control_setVref(V);
                    pause(5);
                end
            else
                AWT_Control_setVref(V);
                pause(5);
            end
        else
            AWT_Control_setVref(V);
            pause(5);
        end
        disp('Target velocity reached initially, starting correction...');
        % for i = 1:3
        [T,PT_e] = Meas_T_PS(fs_Baratron, 15);
        [rho_air, ~, ~, ~, ~] = fluid_prop(T, P_atm);   % update air density
        Q_actual = (mean(PT_e) - v_fs_offset_initial)* P_gain_fs;
        U_actual = sqrt(abs(2*Q_actual/(rho_air*(1 - AR^2)))).*(Q_actual./abs(Q_actual));
        V_target = V/U_actual*U_target;
        AWT_Control_setVref(V_target);
        
        pause(10);
        disp('Velocity corrected, checking the final velocity...');
        [T, PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
        [rho_air, visc_air, c, ~, ~] = fluid_prop(T, P_atm);   % determine fluid properties
        Q_final_s = (mean(PT_e) - v_fs_offset_initial)* P_gain_fs;
        U_final_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*(Q_final_s./abs(Q_final_s));       % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
        U_final = mean(U_final_s);
        std_U_final = std(U_final_s);
        Re = rho_air*U_final*L/visc_air;                  % Re number
        Ma = U_final/c;
        disp(['The final velocity is ' num2str(U_final) ' m/s']);
        disp(['Re is ' num2str(Re)]);
        disp(['Ma is ' num2str(Ma)]);

        k = k + 1;
        P_atm_save(k) = P_atm_in;
        AR_save(k) = AR;
        c_save(k) = c;
        Ma_save(k) = Ma;
        Re_save(k) = Re;
        L_save(k) = L;
        rho_air_save(k) = rho_air;
        T_save(k) = T;
        V_final_save(k) = V_target;                 % Final input voltage
        U_final_save(k) = U_final;
        std_U_final_save(k) = std_U_final;
        visc_air_save(k) = visc_air;
    elseif index == 0
        break;
        
    else
        disp('Wrong input, please input again...');
    end
end

%% Tunnel Shutdown
AWT_Control_off(V_target);

%% Save Data
date_time_end = datestr(now,'mm-dd-yyyy_HH-MM');
save([savedir,'.mat'],'P_atm_save','AR_save','c_save','Ma_save','Re_save','L_save','rho_air_save','T_save','U_final_save','V_final_save','visc_air_save','date_time_start','date_time_end','-mat');

