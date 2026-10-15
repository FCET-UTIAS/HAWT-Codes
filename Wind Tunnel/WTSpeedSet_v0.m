function [] = WTSpeedSet(tun_spd, TunnelStart, offset, Tsample_sec, tol)
%**************************************************************************

% WtSpeedSet sets the wind tunnel test section to the desired freestream
% speed within specified margin of error.

% This code can be used to start the wind tunnel and set the test section
% to a specified freestream speed, or it can be used to change the
% freestream speed from one value to another in the same run.

% This comes in handy when, for example, you are
% trying to maintain the same test section speed when the angle of attack
% of an airfoil changes (thus effectively changing the blockage ratio).

% Variables................................................................
% tun_spd: set the freestream speed using this variable

% TunnelStart: Trigger to start the tunnel. Acceptable values: 'Yes' or
% 'No'

% offset: Trigger to take pitot tube offset/bias measurements at when the
% tunnel is off

% tol: acceptable error between desired and actual freestream speed in the
% test section. Dont set this value too low, or the VFD (variable frequency
% drive) will never be able to converge to a final value. A value of 0.005
% is suggested. This corresponds to 0.5 percent error)

%% Primary Experiment Parameters

global WT
global P_offset_v_u
global Pt_e
global rho_kgpm3
global mu_Pas
global Vset_mps
global Convg_tnl_freq_hz

% Wind tunnel..............................................................

P_atm_kPa   = 102.3;                                                           % Obtained from North York Weather Network. Just Google.
P_gain_u    = 2*133.33;

%Tsample_sec = 30;
%% Wind tunnel activation..................................................

P_atm_mmHg       = P_atm_kPa *1e3 *0.0075;

%[T,data,timeStamps,triggerTime] = TCSession_Omega_FCETdaq(t_samp, f_s)
T_C              = Meas_TC;                                                        % TCSession_Omega_FCETdaq(1, 1000);
[rho_kgpm3, mu_Pas,~]  = fluid_prop(T_C, P_atm_mmHg);                               % determine fluid properties

if offset == 1
    disp('Pitot offset measurement...');
    [Pt_e, ~]       = Meas_pfluc(100000, 30);
    P_offset_v_u    = mean(Pt_e);
end

U_max_WT        = 50;                                                        % pre-set wind tunnel maximum frequency
U_corr          = 0.25;                                                      % amount needed to correct frequency to one expected
U_corr_norm     = U_corr / U_max_WT * 99.4;

if TunnelStart == 1
    
    U_WT_freq_des   = 30;%(tun_spd + 0.7)/0.675;                             %(tun_spd + 0.7)/0.675; % desired tunnel frequency (approximate rule of thumb)
    U_in            = 99.4 * U_WT_freq_des / U_max_WT;                       % input to tunnel
    U_in            = U_in + U_corr_norm;
    
    [WT] = WT_Start_Up;
    pause(5)
    
    fprintf(WT, num2str(U_in));                                              % set wind tunnel speed
    disp('Wind tunnel settling...');
    pause(30);
    
else
    
    U_WT_freq_des   = Convg_tnl_freq_hz;
    U_in            = 99.4 * U_WT_freq_des / U_max_WT;                       % input to tunnel
  
end

disp('First pitot measurement...');
[pt_e_u,~]              = Meas_pfluc(100000, Tsample_sec);
[Up, ~, ~, ~]           = get_pt_v(pt_e_u, P_offset_v_u, P_gain_u, rho_kgpm3);

j                       = 1;
delta_f_0               = 1 * abs(Up - tun_spd);
er_0                    = abs(Up - tun_spd);

while (abs(Up - tun_spd)/(tun_spd)) > tol
    
    disp(['Iteration: ',num2str(j),' - Up = ',num2str(Up),' m/s']);
    er      = abs(Up - tun_spd)
    del_f   = delta_f_0*(er/er_0);
    
    if Up > tun_spd
        
        U_WT_freq_des = U_WT_freq_des - del_f;
        
    else
        
        U_WT_freq_des = U_WT_freq_des + del_f;
        
    end
    
    U_in    = 99.4*U_WT_freq_des/U_max_WT;                                   % input to tunnel
    U_in    = U_in + U_corr_norm;                                            % add back amount lost in transmission
    
    fprintf(WT, num2str(U_in));                                              % set wind tunnel speed
    pause(5)
    
    [pt_e_u,~]          = Meas_pfluc(100000, Tsample_sec);
    [Up, ~, ~, ~]       = get_pt_v(pt_e_u, P_offset_v_u, P_gain_u, rho_kgpm3);
    
    j                   = j+1;
    delta_f_0           = del_f;
    er_0                = er;
    
end

[pt_e_u,~]      = Meas_pfluc(100000, Tsample_sec);
[Up, ~, ~, ~]   = get_pt_v(pt_e_u, P_offset_v_u, P_gain_u, rho_kgpm3);

disp(['Converged Up = ',num2str(Up),' m/s']);
Convg_tnl_freq_hz = U_WT_freq_des;
Vset_mps = Up;