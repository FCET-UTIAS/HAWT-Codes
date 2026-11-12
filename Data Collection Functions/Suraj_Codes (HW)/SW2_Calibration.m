% This script calibrates two single-wire probes.  It is based upon and adapted 
% from Jason's SW_XW_Calibration.m script.

filename = '2017_07_09_dn_further_back';

% Set pressure variables
P_atm_kPa = 101.4; % Need to update this daily, pressure in kPa  
P_atm_mmHg = P_atm_kPa*1e3*0.0075;  % this is in mmHg for Phil's code 
% Conversion from voltage to Pa (10 Torr, 10 V full scale)
% P_gain_u = 2*133.322/7.714;
% P_gain_d = 2*133.322/7.931; %Make sure both transducers have same conversion otherwise assign P_gain for up and down stream
P_gain_u = ((2*133.322)/8.07)+0.252;
P_gain_d = ((2*133.322)/9.69)+0.444;
% P_gain = 2*133.322;

n_pts_U     = 12;       % number of velocities to calibrate over
a_sw1       = 1.60;     % overheat ratio
T0          = 30.29;       % temperature of overheat measurements
type        = 'poly';   % type of calibration
Tcorr_co_SW = 0.50;     % dampens the effect of temperature correction (typically 0.5)
alpha0_sw1 = 0.0032;    % value for tungsten

U_max_WT = 50;             % pre-set wind tunnel maximum frequency
U_corr   = 0.25;           % amount needed to correct frequency to one expected
U_WT_freqmin = 4;
U_WT_freqmax = 40;
U_WT_freq = logspace(log10(U_WT_freqmin),log10(U_WT_freqmax),n_pts_U);
U_in = 99.4*U_WT_freq/U_max_WT;
U_corr_norm = U_corr/U_max_WT*99.4;
U_in   = U_in + U_corr_norm;   % add back amount lost in transmission

% Sampling variables
t_samp_long = 45;
indlongsamp = 4;        % longer sample times will be used for j=1,..,indlongsamp
t_samp_reg = 29;        % sample time for j>indlongsamp
t_samp = t_samp_reg;    % sampling time variable, initialize to regular
% Choose sampling frequency (Hz)- ensure it is high enough to prevent
% aliasing.  The DAQ might choose a slightly different value that will be
% saved later as ActualRate
f_s = 25000;
Nfft = 2^13;

% --- MAIN CODE ---
close all

disp(' ');
disp('*******************************************');
disp('* Single-Wire Calibration Script *');
disp('*******************************************');
disp(' ');

% Declare variables
Up_u     = zeros(n_pts_U,1);       % mean velocity from Pitot Tube upstream
Up_d     = zeros(n_pts_U,1);       % mean velocity from Pitot Tube downstream
es1cal_tc_u = zeros(n_pts_U,1);    % temperature corrected SW upstream
es1cal_tc_d = zeros(n_pts_U,1);    % temperature corrected SW downstream
es1cal_raw_u = zeros(n_pts_U,1);   % calibration from raw voltages upstream
es1cal_raw_d = zeros(n_pts_U,1);   % calibration from raw voltages downstream
T      = zeros(n_pts_U,1);         % temperature
Pm_u     = zeros(n_pts_U,1);       % mean pressure at each point
Pm_d     = zeros(n_pts_U,1);       % mean pressure at each point
ePm    = zeros(n_pts_U,1);         % mean electrical pressure signal

% save time each measurement is taken at
time_of_run = zeros(n_pts_U,1);
rho_air     = zeros(n_pts_U,1);      

% Store start time of calibration
Date = clock;
disp(['START TIME: ' num2str(Date(4)) ':' num2str(Date(5)) ':' num2str(Date(6))]);
disp(' ');

% Determine P_offset_v
disp('Determine Pitot tube offset');
pause(0.5);
[Pt_e_u,~,Pt_e_d,~,~,ActualRate] = Meas_2PT_2SW(f_s, 45, Nfft);
warning('off')
P_offset_v_u = mean(Pt_e_u);
P_offset_v_d = mean(Pt_e_d);
P_offset_v = mean([P_offset_v_u,P_offset_v_d]);
tic;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(' ');

Tw_sw1 = (a_sw1-1) / alpha0_sw1 + T0;

% Turn on wind tunnel
disp('Start-up wind tunnel');
[WT] = WT_Start_Up;
pause(5);
t_settle = 45;

for j=1:n_pts_U
    disp(['Calibration measurement: ' int2str(j) ' of ' int2str(n_pts_U)]);
    fprintf(WT, num2str(U_in(j)));  % set wind tunnel speed
    if j > 1
        pause(t_settle);                % let tunnel circulate and settle
    else
        pause(60);
    end
    
    if j <= indlongsamp
        t_samp = t_samp_long;
    else
        t_samp = t_samp_reg;
    end
    
    % set temperature storage variable to zero
    T_read = zeros(2,1);
    
    % save temperature
    T_read(1) = TC_Omega_FCETdaq(2, 1000); % measure temperature
        
    % take readings from wires
    time_of_run(j) = toc;
    [pt_e_u,er_sw1_u,pt_e_d,er_sw1_d,~,~] = Meas_2PT_2SW(f_s, t_samp, Nfft);
    
    %save temperature
    T_read(2) = TC_Omega_FCETdaq(2, 1000); % measure temperature
    
    T(j) = mean(T_read);
        
    [rho_air(j),visc_air,~,~] = fluid_prop(T(j), P_atm_mmHg);   % determine fluid properties

    % upstream velocity and pressure from pitot tube
    [Up_u(j), Pm_u(j), ePm_u(j),u_p_u] = get_pt_v(pt_e_u, P_offset_v_u, P_gain_u, rho_air(j));
    
    % downstream velocity and pressure from pitot tube
    [Up_d(j), Pm_d(j), ePm_d(j),u_p_d] = get_pt_v(pt_e_d, P_offset_v_d, P_gain_d, rho_air(j));
  
    tu = (0:1:(length(u_p_u)-1))/ActualRate;
    figure(1); %plot upstream measurements from pitot and SW
    plot(tu,u_p_u,'b',tu,er_sw1_u,'r');
    ylabel('up (m/s), SW reading (V)');
    title('Pitot tube velocity and hot-wire time series (upstream)');
    
    td = (0:1:(length(u_p_d)-1))/ActualRate;
    figure(2); %plot downstream measurements from pitot and SW
    plot(td,u_p_d,'b',td,er_sw1_d,'r');
    ylabel('up (m/s), SW reading (V)');
    title('Pitot tube velocity and hot-wire time series (downstream)');
    
    % save raw value 
    es1cal_raw_u(j) = mean(er_sw1_u);
    es1cal_raw_d(j) = mean(er_sw1_d);
    if j~= n_pts_U
        clear P pt_e er_sw1;
    end
    
    figure(3);
    plot(Up_u(1:j), es1cal_raw_u(1:j), 'ob');
    xl = xlabel('$U_p$');
    yl = ylabel('$E_U$');
    set(xl,'unit','character');
    set(xl,'interpreter','latex');
    set(yl,'unit','character');
    set(yl,'interpreter','latex');
    title('Pitot tube velocity vs hot-wire voltage (upstream)');
    
    figure(4);
    plot(Up_d(1:j), es1cal_raw_d(1:j), 'ob');
    xl = xlabel('$U_p$');
    yl = ylabel('$E_U$');
    set(xl,'unit','character');
    set(xl,'interpreter','latex');
    set(yl,'unit','character');
    set(yl,'interpreter','latex');
    title('Pitot tube velocity vs hot-wire voltage (downstream)');
    
    % print general info to screen
    disp(['Up (upstream) = ' num2str(Up_u(j),'%10.2f') ' m/s ;  ' ...
          'Up (downstream) = ' num2str(Up_d(j),'%10.2f') ' m/s ;  ' ...
          ' T = '  num2str(T(j), '%10.2f') ' degC']);
            
end

% Turn off wind tunnel
disp('Shut down wind tunnel');
WT_shutdown;
pause(1)

% Apply temperature corrections
disp('Applying temperature corrections');

T_ref = T0;
es1cal_tc_u = ( (Tw_sw1-T_ref)./(Tw_sw1-T) ).^Tcorr_co_SW .* es1cal_raw_u;
es1cal_tc_d = ( (Tw_sw1-T_ref)./(Tw_sw1-T) ).^Tcorr_co_SW .* es1cal_raw_d;

% Plot temperature corrected and raw calibration voltages
figure;
plot(Up_u, es1cal_raw_u, 'rs');
hold on;
plot(Up_u, es1cal_tc_u, 'bs');
xl = xlabel('$U_p$');
yl = ylabel('$E_U$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
legend('raw','temp corrected');
title('Comparison of raw and corrected calibration voltages (upstream)');

figure;
plot(Up_d, es1cal_raw_d, 'rs');
hold on;
plot(Up_d, es1cal_tc_d, 'bs');
xl = xlabel('$U_p$');
yl = ylabel('$E_U$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
legend('raw','temp corrected');
title('Comparison of raw and corrected calibration voltages (downstream)');

% Determine final pressure offset
disp('Need to take an offset measurement.');
pause(60);
[Pt_e_u,~,Pt_e_d,~,~,~] = Meas_2PT_2SW(f_s, 45, Nfft);
P_offset_v_end = mean([Pt_e_u,Pt_e_d]);
clear Pt_e_u Pt_e_d;
t_final = toc;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(['Final offset voltage: ' num2str(P_offset_v_end,'%10.5f') ' V']);
disp(' ');

% HC: I'm not sure if I like this step and might not use, so I modified the
% script from Jason's original.  Now it saves two velocity arrays, Up and
% Up_cal (adjusted). Seems difficult to know how offset was changing. 
% determine relative offset weightings
% P_off = ((1-(time_of_run./t_final))*P_offset_v + (time_of_run./t_final)*P_offset_v_end);
% 
% % Calculate corrected Pitot velocity
% Pm = (ePm - P_off) * P_gain;
% Up_adj = (2 * abs(Pm)./rho_air).^0.5 .* (Pm ./ abs(Pm));
% 
% figure;
% plot(Up_u,Up_adj,'ks',Up_u,Up_u);
% legend('Adjusted U_p','U_p','location','NorthWest');
% xl = xlabel('$U_p$');
% yl = ylabel('$U_p$ adjusted');
% set(xl,'unit','character');
% set(xl,'interpreter','latex');
% set(yl,'unit','character');
% set(yl,'interpreter','latex');
% title('Comparison of initial and adjusted calibration velocities');

% Select type of calibration fit for SW:

if strcmp(type,'king')==1 || strcmp(type,'King')==1 || strcmp(type,'KING')==1
% King's Law
CALIB_SW_u = fit_king_law_arash(Up_u, es1cal_tc_u);
CALIB_SW_r_u = fit_king_law_arash(Up_u, es1cal_raw_u);
CALIB_SW_d = fit_king_law_arash(Up_d, es1cal_tc_d);
CALIB_SW_r_d = fit_king_law_arash(Up_d, es1cal_raw_d);

% Polynomial Fit
elseif strcmp(type(1:4),'poly')==1 || strcmp(type(1:4),'Poly')==1 || strcmp(type(1:4),'POLY')==1
n_order = 4;
CALIB_SW_u = fit_polynomial(Up_u, es1cal_tc_u,n_order);
CALIB_SW_r_u = fit_polynomial(Up_u, es1cal_raw_u,n_order);
CALIB_SW_d = fit_polynomial(Up_d, es1cal_tc_d,n_order);
CALIB_SW_r_d = fit_polynomial(Up_d, es1cal_raw_d,n_order);

elseif strcmp(type,'spline')==1 || strcmp(type,'Spline')==1 || strcmp(type,'SPLINE')==1
%Spline Fit
CALIB_SW_u = fit_spline(Up_u, es1cal_tc_u);
CALIB_SW_r_u = fit_spline(Up_u, es1cal_raw_u);
CALIB_SW_d = fit_spline(Up_d, es1cal_tc_d);
CALIB_SW_r_d = fit_spline(Up_d, es1cal_raw_d);
end

% Save calibration data
cd SWData\Calibrations
save([filename '_CALIBSW'], 'Pm_u', 'Pm_d', 'ePm_u', 'ePm_d', 'Up_u', 'Up_d', ...
     'es1cal_raw_u', 'es1cal_raw_d','es1cal_tc_u', 'es1cal_tc_d', 'CALIB_SW_u', 'CALIB_SW_d', 'CALIB_SW_r_u', 'CALIB_SW_r_d',...
     'alpha0_sw1', 'T', 'T_ref', 'T0', 'Tw_sw1', 'Tcorr_co_SW', 'P_atm_mmHg', 'rho_air', ...
     'P_gain_u', 'P_gain_d', 'P_offset_v', 'P_offset_v_end', 'a_sw1', 'ActualRate', 'type', 'Date');
cd ..\..\;
% Close out program and clean up
temp = clock;
disp(' Calibration complete.');
disp(['END TIME: ' num2str(temp(4)) ':' num2str(temp(5)) ':' num2str(temp(6))]);
disp(' ');
disp('**********************************');
disp(' ');

clear j

% --- END OF CODE ---