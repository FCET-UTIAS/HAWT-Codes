
function [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(P_atm_in,v_fs_offset,BaratronRange)


% Input:
% - P_atm_in: The atmospheric pressure. Obtained online
% - AR: Area ratio at two streamwise point where the pressure taps on the
%       contractions are positioned.
% - v_fd_offset: Baratron voltage offset. 
% - BaratronRange: Range of pressure transducer, 10 or 100 torr

% Output:
% - Ufinal: The measured speed of the wind tunnel 
% - MaFinal: The measured Mach number of the wind tunnel
% - stdUfinal: the standard deviation of the measured velocity

%% Fixed Parameters
load('I:\ExCamp1\CalibrationData\TunnelSpeedCalibration\CalculatedAR_03-07-2026_10-34.mat',"AR_new")
AR=AR_new;
P_atm = P_atm_in*1e3*0.0075;   % [mmHg]                   
P_gain_fs = 133.322*BaratronRange/10;    % for MKS 120AD on desired torr range, 10V range
fs_Baratron = 4000;
ts_Baratron = 10;
[T, PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
[rho_air, ~, ~, ~] = fluid_prop(T, P_atm);   % determine fluid properties
R_air = 286.9;  % j/kg K
c=sqrt(1.4*R_air*(T+287.15));
Q_final_s = (PT_e - v_fs_offset)* P_gain_fs;
Ufinal_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*(Q_final_s./abs(Q_final_s));       % Negative q_fs appears when the velocity is close to 0 and allowing the negative values in the result can better recover the ZERO velocity
Ufinal = mean(Ufinal_s);
stdUfinal = std(Ufinal_s);
MaFinal = Ufinal/c;