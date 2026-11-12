function [status, v_fs_offset_initial] = AWT_Control_set_Re(Re_target, chord, P_atm_in, T, TunnelOn)

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
%       Modified - Satoshi Baba (2022-08)
%       Modified - Marinus Okoronkwo (2022-11)
% -------------------------------------------------------------------------%   


%% Parameter Input
fs_Baratron = 4000;
ts_Baratron = 30;
load('U_calib_Both_hybrid10-28-2022_13-15.mat','Cal_coef_10Torr')
Cal_coef = Cal_coef_10Torr;
AR = 0.8376^2;
%% Fixed Parameters
%AR = 0.845^2;
P_atm = P_atm_in*1e3*0.0075;   % [mmHg]

range = 10;                      % range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;    % for MKS 120AD on desired torr range, 10V range

%% Initial offset measurement
W = evalin('base','whos');
doesAexist = ismember('v_fs_offset_initial',{W(:).name});         % Check if initial offset exists in the base workspace
if length(doesAexist) ~= 1
    doesAexist = 0;
end

if doesAexist == 0
    disp('Please ZERO the two Baratrons for initial offset measurement and press any key to continue...');
    pause;
    disp('BEGIN Pressure Transducer Offset ----------------------------------')
    [~, PT_e] = Meas_T_PS2(7, fs_Baratron, ts_Baratron, 0);
    tic;        % Starting time of the Baratron offset
    v_fs_offset_initial = mean(PT_e);
    disp(['    Initial offset voltage is: ' num2str(v_fs_offset_initial,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
    disp('-------------------------------------------------------------------')
    disp('Restore the two Baratrons and press any key to continue...')
    assignin("base",'v_fs_offset_initial',v_fs_offset_initial)
    %load('ChampionsLeagueSample.mat');
    %sound(ChampionsY, ChampionsFs);
    pause;
else
    v_fs_offset_initial = evalin("base",'v_fs_offset_initial');
end

%% Velocity Control
if TunnelOn==0
    disp('Turning on the wind tunnel...');
    AWT_Control_on;
elseif TunnelOn==1
    disp('Changing the wind tunnel speed...');
end
                                                           % VFD initialization
[rho_air, visc_air, ~, ~] = fluid_prop(T, P_atm);                           % Target dynamic pressure calculation
U_target = Re_target*visc_air/(rho_air*chord);
[V] = AWT_Control_U2V_Creighton(U_target, Cal_coef(1), Cal_coef(2));        % Start the tunnel using Cal_coef
AWT_Control_setVref(V);
pause(15);

disp('Target velocity reached initially, starting correction...');
% for i = 1:3
    [T,PT_e] = Meas_T_PS2(7, fs_Baratron, 15, 1);
    [rho_air, ~, ~, ~] = fluid_prop(T, P_atm);   % update air density
    Q_actual = (mean(PT_e) - v_fs_offset_initial)* P_gain_fs;
    U_actual = sqrt(abs(2*Q_actual/(rho_air*(1 - AR^2)))).*(Q_actual./abs(Q_actual));
    V_target = V/U_actual*U_target;             % correct the input voltage based on linear assumption for the V-U curve
    AWT_Control_setVref(V_target);
pause(10);
disp('Velocity corrected, checking the final velocity and saving flow information...');

%% Velocity Check
[T, PT_e] = Meas_T_PS2(7, fs_Baratron, 15, 1);
[rho_air, ~, ~, ~] = fluid_prop(T, P_atm);   % determine fluid properties
R_air = 286.9;  % j/kg K
c=sqrt(1.4*R_air*(T+273.15));
Q_final_s = (PT_e - v_fs_offset_initial)* P_gain_fs;
U_final_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*(Q_final_s./abs(Q_final_s));       % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
U_final = mean(U_final_s);
Re_final = rho_air*U_final*chord/visc_air;
std_U_final = std(U_final_s);
Ma = U_final/c;
disp(['The final velocity is ' num2str(U_final) ' m/s']);
disp(['The final Reynolds number is ' num2str(Re_final)]);
disp(['Ma is ' num2str(Ma)]);

status.U_target=U_target;
status.Ma=Ma;
status.U_final=U_final;
status.V_current=V_target;
status.Re_final = Re_final;
status.rho_air = rho_air;
status.dynamic_pressure_psi = mean(Q_final_s)/6894.76;
end
