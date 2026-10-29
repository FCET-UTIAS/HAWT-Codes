function [] = WTSpeedSet(tun_spd_mps, TunnelStart, offset, Tsample_sec, tol)
%**************************************************************************

% WtSpeedSet sets the wind tunnel test section to the desired Reynolds 
% number within specified margin of error.

% The first iteration of the code set the speed, but this version sets the
% desired Re, hence the name WTSpeedSet and not WTReSet. 

% This code can be used to start the wind tunnel and set the test section
% to a specified Re, or it can be used to change the
% Re from one value to another in the same run.

% This comes in handy when, for example, you are
% trying to maintain the same Re when the angle of attack
% of an airfoil changes (thus effectively changing the blockage ratio).

% A few lines in the earlier version of code were taken from other peoples 
% script, hence the weird variable name choices and missing units at the 
% end of the variables in some places. 

% The variables in this version of the code include respective units 
% in the end to make life easier. Although the weird variable names
% remain..for now. 

% Variables................................................................
% tun_spd: set the freestream speed using this variable

% TunnelStart: Trigger to start the tunnel. Acceptable values: '1' or '0'

% offset: Trigger to take pitot tube offset/bias measurements at when the
% tunnel is off.  Acceptable values: '1' or '0'

% tol: acceptable error between desired and actual freestream speed in the
% test section. Dont set this value too low, or the VFD (variable frequency
% drive) will never be able to converge to a final value. A value of 0.005
% is suggested. This corresponds to 0.5 percent error)

%% Primary Experiment Parameters

global WT                                                                  % I would suggest you modify the function to not use global variables. Its usually not a good practice to use them
global P_offset_v_u_V                                                      % When I wrote the code, I was short on time and this made my life easier. 
global Pt_e_V                                                              % If you want to stick to global variables, make sure to declare them in the main script...obviously.
global rho_kgpm3
global mu_Pas
global Vset_mps
global Convg_tnl_freq_hz
global P_atm_kPa                                                           % Get this value from the North York Weather Network and specify in the main function as a global variable. It assumes that our lab
                                                                           % Operates at atmospheric pressure, which is not necessarily true if the lab is not open to the atmosphere (Doors and windows closed). 
                                                                           % But turns out, this method works well enough..
global ReSet
global Re
global Tset_C
global chord_m
global P_gain

%% Wind tunnel activation..................................................

if offset == 1
    disp('Pitot offset measurement...');
    [Pt_e_V, ~]       = Meas_pfluc(100000, Tsample_sec);                        % _V stands for volts...
    P_offset_v_u_V    = mean(Pt_e_V);
end

U_max_WT_hz        = 50;                                                        % pre-set wind tunnel maximum frequency
U_corr_hz          = 0.25;                                                      % amount needed to correct frequency to one expected
U_corr_norm_hz     = U_corr_hz / U_max_WT_hz * 99.4;

if TunnelStart == 1
    
    U_WT_freq_des_hz   = (tun_spd_mps + 0.7)/0.675;                             % desired tunnel frequency (tun_spd + 0.7)/0.675 (approximate rule of thumb)
    U_in_hz            = 99.4 * U_WT_freq_des_hz / U_max_WT_hz;                 % input to tunnel
    U_in_hz            = U_in_hz + U_corr_norm_hz;
    
    [WT] = WT_Start_Up;
    pause(5)
    
    fprintf(WT, num2str(U_in_hz));                                              % set wind tunnel speed
    disp('Wind tunnel settling...');
    pause(60);                                                                 % Let the tunnel run for 5 mins when starting for the first time, to let the flow temperature settle. 
    
else
    
    U_WT_freq_des_hz   = Convg_tnl_freq_hz;
    U_in_hz            = 99.4 * U_WT_freq_des_hz / U_max_WT_hz;                 % input to tunnel
    pause(5)
    
end

% P_atm_mmHg              = P_atm_kPa * 1e3 * 0.0075;                           % If using Suraj's fluid_prop function. 
Tset_C                  = Meas_TC;                                              % Ignore this: TCSession_Omega_FCETdaq(1, 1000);
[rho_kgpm3, mu_Pas,~]   = fluid_props(Tset_C, P_atm_kPa);                       % determine fluid properties
tun_spd_mps             = Re * mu_Pas / (chord_m * rho_kgpm3);                  % Updates the desired tunnel speed as per the target Re due to temperature changes. 

disp('First pitot measurement...');
[pt_e_u_V,~]            = Meas_pfluc(100000, Tsample_sec);
[Up_mps, ~, ~, ~]       = get_pt_v(pt_e_u_V, P_offset_v_u_V, P_gain, rho_kgpm3); % Lots of weird variable names in the code..but as long as the script worked, I didnt bother to rename them. 

j                       = 1;
delta_f_0               = 1 * abs(Up_mps - tun_spd_mps);
er_0                    = abs(Up_mps - tun_spd_mps);

while (abs(Up_mps - tun_spd_mps)/(tun_spd_mps)) > tol
    
    disp(['Iteration: ',num2str(j),' - Up = ',num2str(Up_mps),' m/s']);
    er      = abs(Up_mps - tun_spd_mps);
    del_f   = delta_f_0*(er/er_0);
    
    if Up_mps > tun_spd_mps
        
        U_WT_freq_des_hz = U_WT_freq_des_hz - del_f;
        
    else
        
        U_WT_freq_des_hz = U_WT_freq_des_hz + del_f;
        
    end
    
    U_in_hz    = 99.4 * U_WT_freq_des_hz / U_max_WT_hz;                               % input to tunnel
    U_in_hz    = U_in_hz + U_corr_norm_hz;                                            % add back amount lost in transmission
    
    fprintf(WT, num2str(U_in_hz));                                                    % set wind tunnel speed
    pause(15)
    
    [pt_e_u_V,~]        = Meas_pfluc(100000, Tsample_sec);
    [Up_mps, ~, ~, ~]   = get_pt_v(pt_e_u_V, P_offset_v_u_V, P_gain, rho_kgpm3);
    
    j                   = j+1;
    delta_f_0           = del_f;
    er_0                = er;
    
end

[pt_e_u_V,~]        = Meas_pfluc(100000, Tsample_sec);
[Up_mps, ~, ~, ~]   = get_pt_v(pt_e_u_V, P_offset_v_u_V, P_gain, rho_kgpm3);
ReSet               = rho_kgpm3 * Up_mps * chord_m / mu_Pas;

disp(['Converged Up = ',num2str(Up_mps),' m/s']);
fprintf('Converged Re = %f\n', ReSet)

Convg_tnl_freq_hz   = U_WT_freq_des_hz;
Vset_mps            = Up_mps;