function [Tu, u_mean_mps, u_prime_mps, u_pt_mean_mps] = HW_turbulence_int(HWdata,PTdata,P_gain, P_offset_v_u, rho_kgpm3)
% AUTHOR: BLAGO HRISTOVSKI
% REVISION: NC - 28 JAN 2020
% 
% DESCRIPTION: Adapted from 'Turbulence_Intensity.m' script, unknown author
%              but assume it was Suraj. This function takes in hot-wire
%              data and pitot data and calculates the turbulence intensity.
% INPUTS: 
%  - HWdata: HWdata stream that was collected (see Meas_PT_SW)
%  - PTdata: PTdata stream that was collected (see Meas_PT_SW)
%  - P_gain: Voltage to Pascals conversion for Baratron pressure transducer
%  - P_offset_v_u: Offset pressure taken by pitot
%  - rho_kgpm3: Air density

% OUTPUTS:
%  - Tu: Turbulence intensity
%  - u_mean_mps:  Mean horizontal velocity
%  - u_prime_mps: Variation in horizontal velocity
%
% 

date = datestr(now,'yyyymmdd');
load([pwd,'\Calibration_files\',num2str(date),'_HW_Calib.mat'],'CALIB_SW','T_atm','T_ref','Tw_sw','Tcorr_co_SW')
format long
T = Meas_TC;
% Calculate mean velocity from pitot data ................................
[~, ~, ~, u_pt_mps_series] = get_pt_v(PTdata, P_offset_v_u, P_gain, rho_kgpm3); % Convert PTdata (Voltage) to u (velocity)
u_pt_mean_mps              = mean(u_pt_mps_series);                             % Calculate mean velocity component
u_pt_prime_mps             = u_pt_mps_series - u_pt_mean_mps;                   % Calculate fluctuating velocity component
u_pt_rms_mps               = rms(u_pt_prime_mps);                               % Calculate rms velocity
Tu_pt                      = u_pt_rms_mps / u_pt_mean_mps * 100;                % Calculate turbulence intensity, Tu [%]

% Calculate hot-wire velocity from pitot data ............................
T_ref = T_atm;
HW_data_tcorr = (( (Tw_sw-T_ref)./(Tw_sw-T) ).^Tcorr_co_SW) .* HWdata;          % Temperature correction for HWdata
u_mps_raw               = SW_data2vel(HW_data_tcorr,CALIB_SW,'king');           % Convert HWdata (Voltage) to u (velocity)
u_mean_mps              = mean(u_mps_raw)            ;                          % Calculate mean velocity component
u_prime_mps             = u_mps_raw - u_mean_mps     ;                          % Calculate fluctuating velocity component
u_rms_mps               = rms(u_prime_mps)           ;                          % Calculate rms velocity
Tu                      = u_rms_mps/u_mean_mps * 100 ;                          % Calculate turbulence intensity, Tu [%]
end
