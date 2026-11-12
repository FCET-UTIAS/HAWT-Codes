% This script calibrates a single-wire probe.  It is based upon and adapted
% from Jason's SW_XW_Calibration.m script.
close all
clear
clc


P_atm_kPa = 101.9; % Need to update this daily, pressure in kPa
P_atm_mmHg = P_atm_kPa*1e3*0.0075;  % this is in mmHg for Phil's code

% Sampling variables
t_samp = 5;
f_s = 10000;

T = 23.33; % temperature in degrees Celsius

% Conversion from voltage to Pa (10 Torr, 10 V full scale)
P_gain = 133.322;

[rho_air,visc_air,~,~] = fluid_prop(T, P_atm_mmHg);   % determine fluid properties

%Before wind tunnel is on
[Pt_e, t] = Meas_pfluc(f_s, t_samp);
P_offset_v = mean(Pt_e);

[p_t, t] = Meas_pfluc(f_s, t_samp);
P = (p_t - P_offset_v) * P_gain;    % find pressure
Pm  = mean(P);                         % save mean pressure
ePm = mean(p_t);                      % save electrical mean
u_p = 6.25*(2 * abs(P)./(rho_air*((6.25^2)-1)).^0.5) .* (P ./ abs(P));
Up  = mean(u_p) % Save Pitot tube velocity
