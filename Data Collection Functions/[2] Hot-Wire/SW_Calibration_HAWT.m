function [CALIB_SW_MOV, CALIB_SW_STAT, HW_RefT_degC, HW_WireT_degC_mov, Offset_V, Gain] = SW_Calibration_HAWT(directory_filename)
%% Testing Variables

clear
clc
close all
format long

date_time = datestr(now, 'yyyy-mm-dd_HH-MM');
directory_filename = ['H:\July2025_JessicaData\HW\Calibrations\011--HWCalibration_',char(string(round(gimmeTemp))),'degC_',date_time];

%%
global Pambient_kPa
global WT
global f_s_HW
global P_gain_u

% P_gain_u = 1*133.33;
Pambient_kPa = 102.6; 
% f_s_HW = 1e5;

Gain = [16];
Offset_V = -2.265;  %Moving, Stationary  
% HW_WireT_degC_mov = 216; %Wire Temperature (Overtemp)
HW_overheat = 0.75; 
% HW_WireT_degC_stat = ; 
HW_RefT_degC = 30.4; %Reference temperature from StreamLine
f_s_HW = 2^15; 
PT_f_s = 500; PT_t_s = 20; 

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
% P_gain          = P_gain_u; 
range = 100; 
P_gain = 133.322*range/10;

% Other Inputs.............................................................
n_pts_U         = 12;                                                           % number of velocities to calibrate over
a_sw1           = 1+HW_overheat;                                                % overheat ratio
type            = 'king';                                                       % type of calibration
Tcorr_co_SW     = 0.50;                                                         % dampens the effect of temperature correction (typically 0.5)
alpha0_sw1      = 0.0032;                                                       % value for tungsten
HW_WireT_degC_mov   = (a_sw1-1) / alpha0_sw1 + HW_RefT_degC;

% U_max_WT        = 50;                                                         % pre-set wind tunnel maximum frequency
% U_corr          = 0.6465;                                                     % amount needed to correct frequency to one expected
% U_WT_freqmin    = 4;
% U_WT_freqmax    = 25;
% U_WT_freq       = logspace(log10(U_WT_freqmin), log10(U_WT_freqmax), n_pts_U);
% U_in            = 99.4 * U_WT_freq / U_max_WT;
% U_corr_norm     = U_corr / U_max_WT * 99.4;
% U_in            = (U_in + U_corr_norm)/0.6945;                                       % add back amount lost in transmission

U_max = 59; 
U_min = 20; 
U_in       = logspace(log10(U_min), log10(U_max), n_pts_U);                 % Setting range of WT speeds 

load('U_calib_pitot_tube_07-29-2025_17-03.mat','Cal_coef'); %hybrid tunnel file for Cal_coef 
% load('Empty_tunnel_cal_pressure_system_07-04-2025_15-49.mat', 'Cal_coef',
% 'AR'); %If using tunnel contraction speed method 


% Sampling variables.......................................................
t_samp_long     = 60; 
indlongsamp     = 5;                                                            % longer sample times will be used for j=1,..,indlongsamp
t_samp_reg      = 45;                                                           % sample time for j>indlongsamp
t_samp          = t_samp_reg;                                                   % sampling time variable, initialize to regular
% Choose sampling frequency (Hz)- ensure it is high enough to prevent

% Aliasing.  The DAQ might choose a slightly different value that will be
% saved later as ActualRate
Nfft            = 2^13;

%%

% Declare variables........................................................
Up          = zeros(n_pts_U,1);                                             % mean velocity from Pitot Tube
es1cal_tc   = zeros(n_pts_U,1);                                             % temperature corrected SW
es1cal_raw  = zeros(n_pts_U,1);                                             % calibration from raw voltages
es2cal_tc   = zeros(n_pts_U,1);                                             % temperature corrected SW
es2cal_raw  = zeros(n_pts_U,1);                                             % calibration from raw voltages
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
% [Pt_e, ~, ActualRate]= Meas_PT_2SW(fs_hz, 60, Nfft);

do_zerobaratron = input('Re-zero the Baratron? 1 if yes, 0 if no: ');
if do_zerobaratron
    disp('BEGIN pressure transducer offset ----------------------------------')
    disp('  Turn the knob on the Baratron to 0. Press Enter after you are done.')
    pause;  % Prompt the user for input
    disp('Measuring offset...')
    v_fs_offset = Baratron_offset(PT_f_s,PT_t_s);
    % P_offset_v_end  = mean(Pt_e);
    % Pt_e = Baratron_offsetTwoBaratron(PT_f_s, PT_t_s);
    warning('off')
    P_offset_v             = v_fs_offset;
    disp('END pressure trasnsducer offset -----------------------------------')
    disp('  Turn back the knob on the Baratron to 1? Press Enter after you are done.')
    pause;  % Prompt the user for input
else
    load Baratron_offset_2025-08-05.mat v_fs_offset  
    P_offset_v = v_fs_offset; 
end

if length(P_offset_v) > 1
    P_offset_v = P_offset_v(2); 
end

warning('off')
% P_offset_v              = mean(Pt_e);
tStart = tic;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(' ');


f1 = figure(1);
f2 = figure(2);
f3 = figure(3);

% Turn on wind tunnel.....................................................
disp('Start-up wind tunnel');

input('Ensure the baratron is set to measure Pitot Tube [Enter to continue]: '); 

AWT_Control_on
pause(5);
t_settle    = 15;                                                        

for j = 1 : n_pts_U
    disp(['Calibration measurement: ' int2str(j) ' of ' int2str(n_pts_U)]);
    
    disp(['Adjusting AWT to ' num2str(U_in(j), '%5.2f') ' m/s']);
    AWT_Control_setVref(AWT_Control_U2V_Creighton(U_in(j), Cal_coef(1), Cal_coef(2)));
    disp('    Allow tunnel to settle')
    disp(' ')
%     fprintf(WT, num2str(U_in(j)));                                          % set wind tunnel speed
    if j == 1
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
    T_read(1)                   = gimmeTemp;
        
    % take readings from wires.............................................
    time_of_run(j)              = toc(tStart);
    [pt_e, er_sw{j}, ActualRate]         = Meas_PT_SW(f_s_HW, t_samp, Nfft);           % Measures pitot tube and single wire data simultaneouly
    
    er_sw_orig_mov{j}               = er_sw{j}(:,1)/Gain(1) - Offset_V(1);
    er_sw_orig_stat{j}              = er_sw{j}(:,2);%/Gain(2) - Offset_V(2); 
    %save temperature.....................................................
    T_read(2)                   = gimmeTemp;
    
    T(j)                        = mean(T_read);
        
    [rho_air(j),visc_air,~,~]   = fluid_prop(T(j), P_atm_mmHg);               % determine fluid properties

    P                           = (pt_e - P_offset_v) * P_gain;                                  % find pressure
    Pm(j)                       = mean(P);                                                       % save mean pressure
    ePm(j)                      = mean(pt_e);                                                    % save electrical mean
    u_p                         = (2 * abs(P)./rho_air(j)).^0.5 .* (P ./ abs(P));
%     u_p                         = sqrt(2.*abs(P)./( rho_air(j).*(1-AR^2)));
    Up(j)                       = mean(u_p);                                                     % Save Pitot tube velocity

    t = (0 : 1 : (length(u_p) - 1)) / ActualRate;
    
    figure(1);
    plot(t,u_p,'b',t,er_sw_orig_mov{j},'r');
%     hold on
%     plot(t, er_sw_orig_stat{j}, 'g'); 
%     hold off
    ylabel('up (m/s), SW reading(V)');
    title('Pitot tube velocity and hot-wire time series');
    
    % save raw value...................................................... 
    es1cal_raw_orig(j)  = mean(er_sw_orig_mov{j});
%     es2cal_raw_orig(j)  = mean(er_sw_orig_stat{j}); 
    if j ~= n_pts_U
        clear P pt_e er_sw1;
    end
    
    figure(2);
    plot(Up(1:j), es1cal_raw_orig(1:j), 'ob');
%     hold on
%     plot(Up(1:j), es2cal_raw_orig(1:j), 'or');
%     hold off
    xl = xlabel('$U_p$');
    yl = ylabel('$E_U$ (No Offset/No Gain)');
    set(xl,'unit','character');
    set(xl,'interpreter','latex');
    set(yl,'unit','character');
    set(yl,'interpreter','latex');
    legend("Moving wire (Wire 1)", 'interpreter', 'latex')

    figure(3); 
    LL = length(er_sw_orig_mov{j}); 
    [Gdat_mov, f]         = pwelch(er_sw_orig_mov{j}-mean(er_sw_orig_mov{j}), LL/16, round(0.75*LL/16), LL/16, f_s_HW);
%     [Gdat_stat, f]        = pwelch(er_sw_orig_stat{j}-mean(er_sw_orig_stat{j}), LL/16, round(0.75*LL/16), LL/16, 2e5);
    
    loglog(f, Gdat_mov)
%     hold on
%     loglog(f, Gdat_stat)
%     hold off
    title('Voltage spectra', 'Interpreter','latex')
    xlabel('Frequency [Hz]', 'Interpreter', 'latex')
    legend('Moving Wire', 'Interpreter', 'latex'); 
%     
    figure(4); 
    loglog(f, f.*Gdat_mov)
%     hold on
%     loglog(f, Gdat_stat)
%     hold off
    title('Premultiplied Voltage spectra', 'Interpreter','latex')
    xlabel('Frequency [Hz]', 'Interpreter', 'latex')
    legend('Moving Wire', 'Interpreter', 'latex'); 

    % print general info to screen.........................................
    disp(['Up = ' num2str(Up(j),'%10.2f') ' m/s ;  ' ...
          ' T = '  num2str(T(j), '%10.2f') ' degC']);
            
end

% --- END OF CODE ---------------------------------------------------------

% Turn off wind tunnel.....................................................
disp('Turning off the tunnel...')
AWT_Control_off;
disp('Tunnel shutting down.')
pause(1)

% Apply temperature corrections............................................
disp('Applying temperature corrections');

T_ref = HW_RefT_degC;
es1cal_tc = (( (HW_WireT_degC_mov-T_ref)./(HW_WireT_degC_mov-T) ).^Tcorr_co_SW) .* es1cal_raw_orig';
% es2cal_tc = (( (HW_WireT_degC_stat-T_ref)./(HW_WireT_degC_stat-T) ).^Tcorr_co_SW) .* es2cal_raw_orig';

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
title('Comparison of raw and corrected calibration voltages (Wire 1)');
% 
% figure;
% plot(Up, es2cal_raw_orig, 'ks')
% hold on;
% plot(Up, es2cal_tc, 'bs');

% xl = xlabel('$U_p$');
% yl = ylabel('$E_U$');
% set(xl,'unit','character');
% set(xl,'interpreter','latex');
% set(yl,'unit','character');
% set(yl,'interpreter','latex');
% legend('raw - converted from gain/offset','temp corrected');
% title('Comparison of raw and corrected calibration voltages (Wire 2)');

% Determine final pressure offset..........................................
disp('Need to take an offset measurement.');
disp('BEGIN pressure transducer offset ----------------------------------')
% slowdowntime = tic;
% input('  Turn the knob on the Baratron to 0. Press Enter after you are done.');
% tslow = toc(slowdowntime); 
% if tslow < 60
%     pause(60 - tslow)
% end
disp('Measuring offset...')

%%

% P_offset_v_end = Baratron_offset(PT_f_s,PT_t_s);
P_offset_v_end = P_offset_v; %skip final offset 

% P_offset_v_end  = mean(Pt_e);
% Pt_e = Baratron_offsetTwoBaratron(PT_f_s, PT_t_s);
warning('off')
% P_offset_v_end              = mean(Pt_e);
% clear Pt_e;
disp('END pressure trasnsducer offset -----------------------------------')
% disp('  Turn back the knob on the Baratron to 1? Press Enter after you are done.')
% pause;  % Prompt the user for input

t_final         = toc(tStart);

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

[CALIB_SW_MOV, fitdata_mov]    = fit_king_law_arash_MOD(Up, es1cal_tc); %(1:end-1,:)
% [CALIB_SW_MOV, fitdata_mov]    = fit_king_law_arash_MOD(Up_adj, es1cal_raw_orig); %(1:end-1,:)

% [CALIB_SW_STAT, fitdata_stat]    = fit_king_law_arash_MOD(Up(1:end-1,:), es2cal_tc(1:end-1,1));

% Save calibration data....................................................
save(append(directory_filename,'_CALIBSW.mat'));

% Close out program and clean up...........................................
temp = clock;
disp(' Calibration complete.');
fprintf('Wire 1: \nA = %f, B = %f, and n = %f\n\n', CALIB_SW_MOV(1), CALIB_SW_MOV(2), CALIB_SW_MOV(3));
% fprintf('Wire 2: \nA = %f, B = %f, and n = %f\n\n', CALIB_SW_STAT(1), CALIB_SW_STAT(2), CALIB_SW_STAT(3));
disp(['END TIME: ' num2str(temp(4)) ':' num2str(temp(5)) ':' num2str(temp(6))]);
disp(' ');
disp('**********************************');
disp(' ');

clear j
