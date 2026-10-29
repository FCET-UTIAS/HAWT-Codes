function [Ufinal,MaFinal,stdUfinal]=AWT_Speed_Measurement_function(P_atm_in,v_fs_offset,BaratronRange)

%---------------------------------------------------------------------------
% Function to measure the Wind Tunnel speed
% Description: Measures the contraction pressure drop with the Baratron and
% the air temperature, then computes the tunnel velocity from the mean
% pressure drop and the contraction area ratio (AR, loaded from the tunnel
% calibration file). A sign-preserving square root is used so that speeds
% near zero are recovered correctly (noise can make the measured pressure
% drop slightly negative). Mach number uses the measured temperature.
%
% INPUTS: P_atm_in      - atmospheric pressure (kPa), obtained online
%         v_fs_offset   - Baratron zero offset voltage (V)
%         BaratronRange - range of the pressure transducer (torr), 10 or 100
% OUTPUTS: Ufinal    - measured tunnel velocity (m/s)
%          MaFinal   - measured Mach number
%          stdUfinal - standard deviation of the sample-by-sample velocity
%                      (m/s), a noise indicator for the measurement
%
% HISTORY: 
%   2026-10: Mach number temperature conversion corrected (287.15 -> 273.15)
%            Ufinal now computed from the mean pressure drop (sign-preserving
%            square root) instead of averaging sample-by-sample speeds
%            sign() replaces Q./abs(Q), which gave NaN at exactly 0 V
%            Header updated (AR is loaded from file, not an input)
%---------------------------------------------------------------------------

%% Fixed Parameters
load('I:\ExCamp1\CalibrationData\TunnelSpeedCalibration\CalculatedAR_03-07-2026_10-34.mat',"AR_new")
AR=AR_new;                                % contraction area ratio from calibration
P_atm = P_atm_in*1e3*0.0075;              % atmospheric pressure, kPa to mmHg
P_gain_fs = 133.322*BaratronRange/10;     % for MKS 120AD on desired torr range, 10V range
fs_Baratron = 4000;                       % Baratron sampling rate (Hz)
ts_Baratron = 10;                         % measurement time (s)

%% Measure pressure drop and temperature
[T, PT_e] = Meas_T_PS(fs_Baratron, ts_Baratron);
[rho_air, ~, ~, ~] = fluid_prop(T, P_atm);   % determine fluid properties

%% Speed of sound
R_air = 286.9;  % j/kg K
% c=sqrt(1.4*R_air*(T+287.15));           % OLD: 287.15 is not the Celsius to Kelvin offset (14 K too high)
c=sqrt(1.4*R_air*(T+273.15));             % corrected: T in deg C to K

%% Speed
Q_final_s = (PT_e - v_fs_offset)* P_gain_fs;    % pressure drop across contraction (Pa)

% Sample-by-sample speed, used for the standard deviation only.
% sign() replaces Q./abs(Q) (NaN at exactly 0). Negative values are kept
% because they let the speed recover ZERO when the velocity is close to 0.
% OLD: Ufinal_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*(Q_final_s./abs(Q_final_s));
Ufinal_s = sqrt(abs(2*Q_final_s/(rho_air*(1 - AR^2)))).*sign(Q_final_s);

% Speed from the mean pressure drop (less biased than averaging the
% sample-by-sample speeds, especially at low speed where noise is large)
% OLD: Ufinal = mean(Ufinal_s);
Q_mean = mean(Q_final_s);
Ufinal = sign(Q_mean)*sqrt(abs(2*Q_mean/(rho_air*(1 - AR^2))));

stdUfinal = std(Ufinal_s);
MaFinal = Ufinal/c;

end
