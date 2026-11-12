% This script calibrates a single-wire probe.  It is based upon and adapted
% from Jason's SW_XW_Calibration.m script.

% R. Jason Hearst
% May 29, 2012
% Modified from SW_XW_Calibration_v4

% Version 1.1 - June 5, 2012 - Modified to record a temperature corrected
% raw signal as well for cases where frequencies above the highest filter
% are desired.

% Modified from SW_XW_Calibration.m by Heather Clark on August 29, 2012 to
% accommodate single wire only and using C-serie s anemometer for measurement
% Modified on April 17, 2014 by HC for some new functions

%Modified October 16 by Ross Cruikshank for calibration with the external
%jet: Removed all wind tunnel related code

clear all; clc;
filename = 'cal_2022_April_20_probe1to5';


%% Input variables
% Pressure setup
P_atm_kPa = 102.9; % Need to update this daily, pressure in kPa
% Baratron setup
PT_range = 100;       % Range of PT in torr (check the sensor switch setting
% Velocity points
U_min =     5; % user choose the range of velocities needed NOTE: use 10 torr setting for U max < 46 m/s
U_max =     55;
n_pts_U =   25;       % number of velocities to calibrate over
% Sample parameters
t_samp_long = 60;
indlongsamp = 4;        % longer sample times will be used for j=1,..,indlongsamp i.e. first few points
t_samp_reg = 30;        % sample time for j>indlongsamp
t_s = 60;        % sample time for offset measurement

% Choose sampling frequency (Hz)- ensure it is high enough to prevent
% aliasing.  The DAQ might choose a slightly different value that will be
% saved later as ActualRate
f_s = 24000;

% DAQ channels
channels = [2,6,7,8,9,10];      % First channel reads from the Baratron; The rest read from the Hotwires

% Load speed calibration coefficients
load('C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-04\U_calib_pitot_tube_04-04-2022_15-07','Cal_coef');
%%
P_atm_mmHg = P_atm_kPa*1e3*0.0075;  % this makessthe pressure in mmHg

% Conversion from voltage to Pa (100 Torr, 10 V full scale)
PT_Vout = 10;         % Voltage output range of transducer
P_gain = (PT_range/PT_Vout)*133.322; % Conversion from voltage to Pa for 1 torr

% Set volocities to calibrate over
V_min = AWT_Control_U2V_Creighton(U_min,Cal_coef(1),Cal_coef(2)); %just input appproximate values for the velocities (exact values are written in the output)
V_max = AWT_Control_U2V_Creighton(U_max,Cal_coef(1),Cal_coef(2));
if V_max > 10
    disp('Error, max velocity selected is too high.');
    return
else
    disp('Max velocity OK.');
end
V_i = logspace(log10(V_min),log10(V_max),n_pts_U);

% Set parameters
a_sw1       = 1.79;     % overheat ratio
T0          = 0;     % temperature of overheat measurements
type        = 'Poly4';  % type of calibration
Tcorr_co_SW = 0.50;     % dampens the effect of temperature correction (typically 0.5)
alpha0_sw1 = 0.0036;    % value for tungsten
sw1_gain = 1;

% Sampling variables
t_samp = t_samp_reg;    % sampling time variable, initialize to regular
num_channels = length(channels);

% --- MAIN CODE ---
close all

disp(' ');
disp('*******************************************');
disp('* Single-Wire Calibration Script *');
disp('*******************************************');
disp(' ');

% Declare variables
Up     = zeros(n_pts_U,1);       % mean velocity from Pitot Tube
es1cal_tc = zeros(n_pts_U,num_channels - 1);    % temperature corrected SW
es1cal_raw = zeros(n_pts_U,num_channels - 1);   % calibration from raw voltages
T      = zeros(n_pts_U,1);       % temperature
Pm     = zeros(n_pts_U,1);       % mean pressure at each point
ePm    = zeros(n_pts_U,1);       % mean electrical pressure signal

% save time each measurement is taken at
time_of_run = zeros(n_pts_U,1);
rho_air     = zeros(n_pts_U,1);

% Store start time of calibration
Date = clock;
disp(['START TIME: ' num2str(Date(4)) ':' num2str(Date(5)) ':' num2str(Date(6))]);
disp(' ');

% Determine P_offset_v (Zero error in Pitot tube)
disp('Ensure HW is ON, press any key to continue.');
pause;
disp('Determine Pitot tube offset');
AWT_Control_off(0);
% pause(0.5);
disp('Block nozzle to ensure zero velocity, then press any key to continue.');

pause;
disp('Measuring offset...');
[sw1_Offset,Pt_e,ActualRate] = Meas_SW_PT(t_s, f_s, channels);
warning('off')
P_offset_v = mean(Pt_e);
sw1_Offset_v = mean(sw1_Offset);
tic;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp('Unblock nozzle, then press any key to continue');
pause;
disp(' ');

Tw_sw1 = (a_sw1-1) / alpha0_sw1 + T0;

f1 = figure(1);
f2 = figure(2);

% Take Pitot and HW measurements
disp('Commence calibration measurements...');
AWT_Control_on;

for j=1:n_pts_U
    disp(['Calibration measurement: ' int2str(j) ' of ' int2str(n_pts_U)]);
    AWT_Control_setVref(V_i(j))
    pause(20);
    
    if j <= indlongsamp
        t_samp = t_samp_long;
    else
        t_samp = t_samp_reg;
    end
    
    % set temperature storage variable to zero
    T_read = zeros(2,1);
    
    % save temperature
    T_read(1) = USB_TC01_read();
    
    % take readings from wires
    try % this is just to ensure that the card is reading something
        time_of_run(j) = toc;
        [er_sw1,pt_e,~] = Meas_SW_PT(t_samp, f_s, channels);
    catch
        try
            disp('Error taking velocity measurements.  Trying again...');
            pause(1);
            time_of_run(j) = toc;
            [er_sw1,pt_e,~] = Meas_SW_PT(t_samp, f_s, channels);
        catch
            try
                disp('Error taking velocity measurements again.  Trying again...');
                pause(10);
                resetNIcard;
                pause(5);
                time_of_run(j) = toc;
                [er_sw1,pt_e,~] = Meas_SW_PT(t_samp, f_s, channels);
            catch
                disp('THREE ERRORS READING VELOCITY.  Please check system.');
                disp('Run terminating.');
            end
        end
    end
    
    %save temperature
    T_read(2)=USB_TC01_read();
    T(j) = mean(T_read);
    
    [rho_air(j),visc_air,~,~] = fluid_prop(T(j), P_atm_mmHg);   % determine fluid properties
    
    P      = (pt_e - P_offset_v) * P_gain;    % find pressure
    Pm(j)  = mean(P);                         % save mean pressure
    ePm(j) = mean(pt_e);                      % save electrical mean
    u_p = (2 * abs(P)./rho_air(j)).^0.5 .* (P ./ abs(P));
    Up(j)  = mean(u_p); % Save Pitot tube velocity
    
    t = (0:1:(length(u_p)-1))/ActualRate;
    
    figure(1);
    %     plot(t,u_p,'b',t,er_sw1(:,1),'r');
    for k = 1:num_channels
        if k == 1
            plot(t,u_p);
            hold on;
        elseif k == num_channels
            plot(t,er_sw1(:,k - 1));
            hold off;
        else
            plot(t,er_sw1(:,k - 1));
        end
    end
    ylabel('up (m/s), SW reading (V)');
    title('Pitot tube velocity and hot-wire time series');
    
    % save raw value
    es1cal_raw(j,:) = mean(er_sw1);
    if j~= n_pts_U
        clear P pt_e er_sw1;
    end
    
    figure(2);
    %     plot(Up(1:j), es1cal_raw(1:j,1), 'ob');
    scatter(repmat(Up(j),[1 num_channels - 1]),es1cal_raw(j,:));
    if j == 1
        hold on;
    elseif j == n_pts_U
        hold off;
    end    
    xl = xlabel('$U_p$');
    yl = ylabel('$E_U$');
    set(xl,'unit','character');
    set(xl,'interpreter','latex');
    set(yl,'unit','character');
    set(yl,'interpreter','latex');
    
    % print general info to screen
    disp(['Up = ' num2str(Up(j),'%10.2f') ' m/s ;  ' ...
        ' T = '  num2str(T(j), '%10.2f') ' degC']);
    
end

figure(3)
for k = 1:num_channels - 1
    scatter(Up,es1cal_raw(:,k));
    if k == 1
        hold on;
    elseif k == num_channels - 1
        hold off;
    end
end

% Apply temperature corrections
disp('Applying temperature corrections');

T_ref = T0;

es1cal_tc = repmat(( (Tw_sw1-T_ref)./(Tw_sw1-T) ).^Tcorr_co_SW,[1 num_channels - 1]) .* es1cal_raw;

% Check to make sure no mistakes were made during temperature correction
if es1cal_tc(1,1)>1.05*es1cal_raw(1,1) || es1cal_tc(1,1)<0.95*es1cal_raw(1,1)
    disp('Check on temperature correction, potential problems?');
    
end

% Plot temperature corrected and raw calibration voltages
figure(4);
for k = 1:num_channels - 1
    if k == 1
        hold on;
    end
    plot(Up, es1cal_raw(:,k), '*');
    plot(Up, es1cal_tc(:,k), 'o');
    if k == num_channels - 1
        hold off;
    end
end
xl = xlabel('$U_p$');
yl = ylabel('$E_U$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
legend('raw (*)','temp corrected (square)');
title('Comparison of raw and corrected calibration voltages');

AWT_Control_off(V_i(j));
% pause(10);
% Determine final pressure offset
disp('Need to take an offset measurement.');
disp('Block nozzle to ensure zero velocity, then press any key to continue.');
pause;
disp('Measuring offset...');
[~,Pt_e,~] = Meas_SW_PT(t_s, f_s, channels);
P_offset_v_end = mean(Pt_e);
clear Pt_e;
t_final = toc;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(['Final offset voltage: ' num2str(P_offset_v_end,'%10.5f') ' V']);
disp(' ');

% HC: I'm not sure if I like this step and might not use, so I modified the
% script from Jason's original.  Now it saves two velocity arrays, Up and
% Up_cal (adjusted). Seems difficult to know how offset was changing.
% determine relative offset weightings
P_off = ((1-(time_of_run./t_final))*P_offset_v + (time_of_run./t_final)*P_offset_v_end);

% Calculate corrected Pitot velocity
Pm = (ePm - P_off) * P_gain;
Up_adj = (2 * abs(Pm)./rho_air).^0.5 .* (Pm ./ abs(Pm));

figure;
plot(Up,Up_adj,'ks',Up,Up);
legend('Adjusted U_p','U_p','location','NorthWest');
xl = xlabel('$U_p$');
yl = ylabel('$U_p$ adjusted');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
title('Comparison of initial and adjusted calibration velocities');

% Select type of calibration fit for SW:
% King's Law
if strcmp(type,'king')==1 || strcmp(type,'King')==1 || strcmp(type,'KING')==1
    for k = 1:num_channels - 1
        CALIB_SW(k,:) = fit_king_law_arash(Up, es1cal_tc(:,k));
        CALIB_SW_r(k,:) = fit_king_law_arash(Up, es1cal_raw(:,k));
    end
    % Spline
elseif strcmp(type,'spline')==1 || strcmp(type,'Spline')==1 || strcmp(type,'SPLINE')==1
    for k = 1:num_channels - 1
        CALIB_SW(k,:)   = fit_spline(Up, es1cal_tc(:,k));
        CALIB_SW_r(k,:) = fit_spline(Up, es1cal_raw(:,k));
    end
    % Polynomial fit of a given order
elseif length(type) > 4 && (strcmp(type(1:4),'poly')==1 || strcmp(type(1:4),'Poly')==1 || strcmp(type(1:4),'POLY')==1)
    order = str2num(type(5:end));
    for k = 1:num_channels - 1
        CALIB_SW(k,:) = fit_polynomial(Up, es1cal_tc(:,k), order);
        CALIB_SW_r(k,:) = fit_polynomial(Up, es1cal_raw(:,k), order);
    end
    % 4th-order Polynomial if order not specified
else
    for k = 1:num_channels - 1
        CALIB_SW(k,:)   = fit_polynomial(Up, es1cal_tc(:,k), 4);
        CALIB_SW_r(k,:) = fit_polynomial(Up, es1cal_raw(:,k), 4);
    end
%     CALIB_SW   = fit_polynomial(Up, es1cal_tc(:,1), 4);
%     CALIB_SW_r = fit_polynomial(Up, es1cal_raw(:,1), 4);
end


E_plot = linspace(min(min(es1cal_tc)), max(max(es1cal_tc)), 100);
U_plot = zeros(num_channels - 1, length(E_plot));
for k = 1:num_channels - 1
    U_plot(k,:) = polyval(CALIB_SW(k,:), E_plot);
end
figure;
plot(Up, es1cal_tc, 'o', U_plot, E_plot, '--');
legend('data points', 'polynomial curve fit', 'Location', 'SouthEast');
xl = xlabel('$U_p$ [m/s]');
yl = ylabel('$E_{U}$ [V]');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
grid on;

% Save calibration data
% save([filename '_CALIBSW'], 'Pm', 'ePm', 'Up', 'Up_adj', ...
%     'es1cal_raw', 'es1cal_tc', 'CALIB_SW', 'CALIB_SW_r', ...
%     'alpha0_sw1', 'T', 'T_ref', 'T0', 'Tw_sw1', 'Tcorr_co_SW', 'P_atm_mmHg', 'rho_air', ...
%     'P_gain', 'P_offset_v', 'P_offset_v_end', 'a_sw1', 'ActualRate', 'type', 'Date');
% 
% 
% % Close out program and clean up
% temp = clock;
% disp(' Calibration complete.');
% disp(['END TIME: ' num2str(temp(4)) ':' num2str(temp(5)) ':' num2str(temp(6))]);
% disp(' ');
% disp('**********************************');
% disp(' ');
% 
% clear j
% clear k

% --- END OF CODE ---