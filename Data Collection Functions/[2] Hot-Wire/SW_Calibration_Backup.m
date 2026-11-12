%function [CALIB_SW, HW_RefT_degC, HW_WireT_degC, Offset_V, Gain] = SW_Calibration(filename)
clear
clc
close all
format long

global Pambient_kPa
Gain = 16;
Offset_V = 1.575;
global WT
global fs_hz
global P_gain_u

P_gain_u = 1*133.33;
Pambient_kPa = 98.3;
fs_hz = 1e5;

filename = 'Hotwire_1476';

% This script calibrates a single-wire probe.  It is based upon and adapted 
% from Jason's SW_XW_Calibration.m script.

% --- MAIN CODE -----------------------------------------------------------
disp(' ');
disp('*******************************************');
disp('* Single-Wire Calibration Script *');
disp('*******************************************');
disp(' ');


% Set pressure variables...................................................                                                       
P_atm_mmHg      = Pambient_kPa * 1e3 * 0.0075;                                    % this is in mmHg for Phil's code 

% Conversion from voltage to Pa (10 Torr, 10 V full scale).................
P_gain          = P_gain_u; 

% Other Inputs.............................................................
n_pts_U         = 12;                                                           % number of velocities to calibrate over
a_sw1           = 1.60;                                                         % overheat ratio




HW_RefT_degC    = Meas_TC;                                                      % temperature of overheat measurements
type            = 'king';                                                       % type of calibration
Tcorr_co_SW     = 0.50;                                                         % dampens the effect of temperature correction (typically 0.5)
alpha0_sw1      = 0.0032;                                                       % value for tungsten

U_max_WT        = 50;                                                       % pre-set wind tunnel maximum frequency
U_corr          = 0.25;                                                     % amount needed to correct frequency to one expected
U_WT_freqmin    = 3;
U_WT_freqmax    = 30;
U_WT_freq       = logspace(log10(U_WT_freqmin), log10(U_WT_freqmax), n_pts_U);
U_in            = 99.4 * U_WT_freq / U_max_WT;
U_corr_norm     = U_corr / U_max_WT * 99.4;
U_in            = U_in + U_corr_norm;                                       % add back amount lost in transmission

% Sampling variables.......................................................
t_samp_long     = 30;
indlongsamp     = 5;                                                            % longer sample times will be used for j=1,..,indlongsamp
t_samp_reg      = 30;                                                           % sample time for j>indlongsamp
t_samp          = t_samp_reg;                                                   % sampling time variable, initialize to regular
% Choose sampling frequency (Hz)- ensure it is high enough to prevent

% Aliasing.  The DAQ might choose a slightly different value that will be
% saved later as ActualRate
Nfft            = 2^13;


% Declare variables........................................................
Up          = zeros(n_pts_U,1);                                             % mean velocity from Pitot Tube
es1cal_tc   = zeros(n_pts_U,1);                                             % temperature corrected SW
es1cal_raw  = zeros(n_pts_U,1);                                             % calibration from raw voltages
T           = zeros(n_pts_U,1);                                             % temperature
Pm          = zeros(n_pts_U,1);                                             % mean pressure at each point
ePm         = zeros(n_pts_U,1);                                             % mean electrical pressure signal

% save time each measurement is taken at...................................
time_of_run = zeros(n_pts_U,1);
rho_air     = zeros(n_pts_U,1);      

% Store start time of calibration..........................................
Date = clock;
disp(['START TIME: ' num2str(Date(4)) ':' num2str(Date(5)) ':' num2str(Date(6))]);
disp(' ');

% Determine P_offset_v.....................................................
disp('Determine Pitot tube offset');
pause(0.5);
[Pt_e, ~, ActualRate]= Meas_PT_2SW(fs_hz, 60, Nfft);
warning('off')
P_offset_v              = mean(Pt_e);
tic;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(' ');

HW_WireT_degC           = (a_sw1-1) / alpha0_sw1 + HW_RefT_degC;

f1 = figure(1);
f2 = figure(2);
f3 = figure(3);

% Turn on wind tunnel.....................................................
disp('Start-up wind tunnel');

[WT]        = WT_Start_Up;
pause(5);
t_settle    = 30;

for j = 1 : n_pts_U
    disp(['Calibration measurement: ' int2str(j) ' of ' int2str(n_pts_U)]);
    fprintf(WT, num2str(U_in(j)));                                          % set wind tunnel speed
    if j > 1
        pause(t_settle);                                                    % let tunnel circulate and settle
    else
        pause(10);
    end
    
    if j <= indlongsamp
        t_samp                  = t_samp_long;
    else
        t_samp                  = t_samp_reg;
    end
    
    % set temperature storage variable to zero.............................
    T_read                      = zeros(2,1);
    
    % save temperature.....................................................
    T_read(1)                   = Meas_TC;
        
    % take readings from wires.............................................
    time_of_run(j)              = toc;
    [pt_e, er_sw{j}, ~]         = Meas_PT_2SW(fs_hz, t_samp, Nfft);
    
    er_sw_orig{j}               =  er_sw{j}/Gain - Offset_V;
    % save temperature.....................................................
    T_read(2)                   =  Meas_TC;
    
    T(j)                        = mean(T_read);
        
    [rho_air(j),visc_air,~,~]   = fluid_prop(T(j), P_atm_mmHg);               % determine fluid properties

    P                           = (pt_e - P_offset_v) * P_gain;                                  % find pressure
    Pm(j)                       = mean(P);                                                       % save mean pressure
    ePm(j)                      = mean(pt_e);                                                    % save electrical mean
    u_p                         = (2 * abs(P)./rho_air(j)).^0.5 .* (P ./ abs(P));
    Up(j)                       = mean(u_p);                                                     % Save Pitot tube velocity

    t = (0 : 1 : (length(u_p) - 1)) / ActualRate;
    
    figure(1);
    plot(t,u_p,'b',t,er_sw_orig{j},'r');
    ylabel('up (m/s), SW reading(V)');
    title('Pitot tube velocity and hot-wire time series');
    
    % save raw value...................................................... 
    es1cal_raw_orig(j)  = mean(er_sw_orig{j});
    if j ~= n_pts_U
        clear P pt_e er_sw1;
    end
    
    figure(2);
    plot(Up(1:j), es1cal_raw_orig(1:j), 'ob');
    xl = xlabel('$U_p$');
    yl = ylabel('$E_U (No Offset/No Gain)$');
    set(xl,'unit','character');
    set(xl,'interpreter','latex');
    set(yl,'unit','character');
    set(yl,'interpreter','latex');
    
    % print general info to screen.........................................
    disp(['Up = ' num2str(Up(j),'%10.2f') ' m/s ;  ' ...
          ' T = '  num2str(T(j), '%10.2f') ' degC']);
            
end

% --- END OF CODE ---------------------------------------------------------

% Turn off wind tunnel.....................................................
disp('Shut down wind tunnel');
WT_shutdown;
pause(1)

% Apply temperature corrections............................................
disp('Applying temperature corrections');

T_ref = HW_RefT_degC;
es1cal_tc = (( (HW_WireT_degC-T_ref)./(HW_WireT_degC-T) ).^Tcorr_co_SW) .* es1cal_raw_orig';

% Plot temperature corrected and raw calibration voltages..................
figure;
plot(Up, es1cal_raw_orig, 'ks')
hold on;
plot(Up, es1cal_tc, 'bs');

xl = xlabel('$U_p$');
yl = ylabel('$E_U$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
legend('raw - converted from gain/offset','temp corrected');
title('Comparison of raw and corrected calibration voltages');

% Determine final pressure offset..........................................
disp('Need to take an offset measurement.');
pause(60);

[Pt_e,~,~]      = Meas_PT_2SW(fs_hz, 15, Nfft);
P_offset_v_end  = mean(Pt_e);
clear Pt_e;

t_final         = toc;

fprintf('\n')
disp(['Initial offset voltage: ' num2str(P_offset_v, '%10.5f') ' V']);
disp(['Final offset voltage: ' num2str(P_offset_v_end, '%10.5f') ' V']);
disp(' ');

% HC: I'm not sure if I like this step and might not use, so I modified the
% script from Jason's original.  Now it saves two velocity arrays, Up and
% Up_cal (adjusted). Seems difficult to know how offset was changing. 
% determine relative offset weightings

P_off       = ((1 - (time_of_run ./ t_final)) * P_offset_v + ...
    (time_of_run ./ t_final) * P_offset_v_end);

% Calculate corrected Pitot velocity.......................................
Pm          = (ePm - P_off) * P_gain;
Up_adj      = (2 * abs(Pm)./rho_air).^0.5 .* (Pm ./ abs(Pm));

figure;
plot(Up, Up_adj, 'ks', Up, Up);
legend('Adjusted U_p', 'U_p', 'location', 'NorthWest');
xl = xlabel('$U_p$');
yl = ylabel('$U_p$ adjusted');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
title('Comparison of initial and adjusted calibration velocities');

% Select type of calibration fit for SW:...................................
% King's Law

CALIB_SW    = fit_king_law_arash(Up, es1cal_tc);

% Save calibration data....................................................
cd ../Data/Raw-Data
save([filename '_CALIBSW.mat']);
cd ../../Codes

% Close out program and clean up...........................................
temp = clock;
disp(' Calibration complete.');
fprintf('\nA = %f, B = %f, and n = %f\n\n', CALIB_SW(1), CALIB_SW(2), CALIB_SW(3));
disp(['END TIME: ' num2str(temp(4)) ':' num2str(temp(5)) ':' num2str(temp(6))]);
disp(' ');
disp('**********************************');
disp(' ');

clear j
