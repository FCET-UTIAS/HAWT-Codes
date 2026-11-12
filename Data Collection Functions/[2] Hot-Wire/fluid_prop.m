function [rho_air, visc_air, rho_w, g] = fluid_prop(T_atm, P_atm)

% This program computes fluid properties of air and water from the inputed
% atmospheric conditions.
% Temperature given in Celsius
% Pressure given in mmHg

% Philippe Lavoie 28-07-2003
% Revised: 

rho_w4 = 1000;  % density of water at 4oC in kg/m^3
R_air = 286.9;  % j/kg K
g = 9.797;  % m/s^2

C_air = 1.458e-6;     %Curve fit constant from thermodynamics
S_air = 110.4;       %Another curve fit constant!
a1 = 583.63;         % This is the coefficient for a quick curve fit made based on the thermodynamic data foun in 'Fundamental of Heat and Mass Transfer', 4th Ed. by Incropera and DeWitt
a2 = 3.0514;         % same as a1
a3 = -0.0056;       % same as a1
SG_Hg = 13.6 - 0.0024 * T_atm;  %Specific gravity of Hg

P_atm = rho_w4 * SG_Hg * P_atm * g / 1000;  % Give pressure in Pascals
T_atm = T_atm + 273.15;      % Changes temperature to Kelvin

rho_air = P_atm / (R_air * T_atm);
visc_air = C_air * T_atm^(3/2) / (S_air + T_atm);   % Dynamic pressure (mu)
rho_w = a1 + a2 * T_atm + a3 * T_atm^2;
