% This script calibrates a single-wire probe.  It is based upon and adapted 
% from Jason's SW_XW_Calibration.m script.

filename = 'cal_2019_09_28_1';

% Set pressure variables
P_atm_kPa = 101.1; % Need to update this daily, pressure in kPa  
P_atm_mmHg = P_atm_kPa*1e3*0.0075;  % this is in mmHg for Phil's code 
% Conversion from voltage to Pa (10 Torr, 10 V full scale)
P_gain = 2*133.322;

man_WT = 1; %Manually run the wind tunnel

n_pts_U     = 12;       % number of velocities to calibrate over
a_sw1       = 1.60;     % overheat ratio
T0          = 26.04;  % temperature of overheat measurements
type        = 'king';   % type of calibration
Tcorr_co_SW = 0.50;     % dampens the effect of temperature correction (typically 0.5)
alpha0_sw1 = 0.0032;    % value for tungsten
offset = 0;         % offset applied to hotwire signal (defaults: 5um - 1.8, 2.5 um - 1.2)
gain = 1;               % gain applied to hotwire signal (defaults: 5um - 16, 2.5 um - 64)

U_max_WT = 50;             % pre-set wind tunnel maximum frequency
U_corr   = 0.25;           % amount needed to correct frequency to one expected
U_WT_freqmin = 3;
U_WT_freqmax = 30;
U_WT_freq = logspace(log10(U_WT_freqmin),log10(U_WT_freqmax),n_pts_U);
U_in = 99.4*U_WT_freq/U_max_WT;
U_corr_norm = U_corr/U_max_WT*99.4;
U_in   = U_in + U_corr_norm;   % add back amount lost in transmission

% Sampling variables
t_samp_long = 45;
indlongsamp = 5;        % longer sample times will be used for j=1,..,indlongsamp
t_samp_reg = 25;        % sample time for j>indlongsamp
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
Up     = zeros(n_pts_U,1);       % mean velocity from Pitot Tube
es1cal_tc = zeros(n_pts_U,1);    % temperature corrected SW
es1cal_raw = zeros(n_pts_U,1);   % calibration from raw voltages
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

% Determine P_offset_v
disp('Determine Pitot tube offset');
pause(0.5);
[~,Pt_e,~,ActualRate] = MeasSession_Short_PT_SW(f_s, 45);
warning('off')
P_offset_v = mean(Pt_e);
tic;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(' ');

Tw_sw1 = (a_sw1-1) / alpha0_sw1 + T0;

% Turn on wind tunnel
if ~man_WT
    disp('Start-up wind tunnel');
    [WT] = WT_Start_Up;
    pause(5);
end
t_settle = 45;

for j=1:n_pts_U
    disp(['Calibration measurement: ' int2str(j) ' of ' int2str(n_pts_U)]);
    if man_WT
        disp(['Set the wind tunnel to: ',num2str(U_WT_freq(j)),' Hz'])
        disp('Hit Enter to continue')
        pause;
    else
        fprintf(WT, num2str(U_in(j)));  % set wind tunnel speed
    end
    
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
    %T_read(1) = TCSession_Omega_FCETdaq(2, 1000); % measure temperature
    T_read(1) = Meas_TC; 
    
    % take readings from wires
    time_of_run(j) = toc;
    [~,pt_e,er_sw1,~] = MeasSession_Short_PT_SW(f_s, t_samp);
    
    %save temperature
    %T_read(2) = TCSession_Omega_FCETdaq(2, 1000); % measure temperature
    T_read(2) = Meas_TC;
    
    % check to make sure temperature is reasonable
    %IX = find(T > 0);
    %if abs(mean(T(IX))-mean(T_read))/mean(T(IX)) > 0.05
    %    T(j) = mean(T(IX));
    %else
    %    T(j) = mean(T_read);
    %end
    %clear IX
    T(j) = mean(T_read);
        
    [rho_air(j),visc_air,~,~] = fluid_prop(T(j), P_atm_mmHg);   % determine fluid properties

    P      = (pt_e - P_offset_v) * P_gain;    % find pressure
    Pm(j)  = mean(P);                         % save mean pressure
    ePm(j) = mean(pt_e);                      % save electrical mean
    u_p = (2 * abs(P)./rho_air(j)).^0.5 .* (P ./ abs(P));
    Up(j)  = mean(u_p); % Save Pitot tube velocity
    %Up(j)  = mean((2 * abs(P)./rho_air(j)).^0.5 .* (P ./ abs(P)));  % Save Pitot tube velocity
    
    t = (0:1:(length(u_p)-1))/ActualRate;
    figure(1);
    plot(t,u_p,'b',t,er_sw1,'r');
    ylabel('up (m/s), SW reading (V)');
    title('Pitot tube velocity and hot-wire time series');
    
    % save raw value 
    es1cal_raw(j) = mean(er_sw1)/gain + offset;
    if j~= n_pts_U
        clear P pt_e er_sw1;
    end
    
    % print general info to screen
    disp(['Up = ' num2str(Up(j),'%10.2f') ' m/s ;  ' ...
          ' T = '  num2str(T(j), '%10.2f') ' degC']);
    
    testcal = fit_king_law_arash(Up(1:j), es1cal_raw(1:j));
    disp(testcal)
end

% Turn off wind tunnel
disp('Shut down wind tunnel');
if man_WT
    disp('Hit Enter to continue')
    pause;
else
    WT_shutdown;
end
pause(1)

% Apply temperature corrections
disp('Applying temperature corrections');

T_ref = T0;
es1cal_tc = ( (Tw_sw1-T_ref)./(Tw_sw1-T) ).^Tcorr_co_SW .* es1cal_raw;

% Plot temperature corrected and raw calibration voltages
figure;
plot(Up, es1cal_raw, 'rs');
hold on;
plot(Up, es1cal_tc, 'bs');
xl = xlabel('$U_p$');
yl = ylabel('$E_U$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');
legend('raw','temp corrected');
title('Comparison of raw and corrected calibration voltages');

% Determine final pressure offset
disp('Need to take an offset measurement.');
pause(60);
[~,Pt_e,~,~] = MeasSession_Short_PT_SW(f_s, 45);
P_offset_v_end = mean(Pt_e);
clear Pt_e;
t_final = toc;
disp(['Initial offset voltage: ' num2str(P_offset_v,'%10.5f') ' V']);
disp(['Final offset voltage: ' num2str(P_offset_v_end,'%10.5f') ' V']);
disp(' ');

opt_offset = (max(es1cal_raw) + min(es1cal_raw))/2; %optimal offset
opt_gain0p1 = 0.2/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain0p2 = 0.4/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain0p5 = 1/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain1 = 2/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain2 = 4/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain5 = 10/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range
opt_gain10 = 20/(max(es1cal_raw) - min(es1cal_raw)); %optimal gain for [-10, 10] V DAQ range

disp(['Optimal hw offset voltage: ' num2str(opt_offset,'%10.3f') ' V'])
disp(['Optimal hw gain [-0.1,0.1]: ' num2str(round(opt_gain0p1))])
disp(['Optimal hw gain [-0.2,0.2]: ' num2str(round(opt_gain0p2))])
disp(['Optimal hw gain [-0.5,0.5]: ' num2str(round(opt_gain0p5))])
disp(['Optimal hw gain [-1,1]: ' num2str(round(opt_gain1))])
disp(['Optimal hw gain [-2,2]: ' num2str(round(opt_gain2))])
disp(['Optimal hw gain [-5,5]: ' num2str(round(opt_gain5))])
disp(['Optimal hw gain [-10,10]: ' num2str(round(opt_gain10))])
disp(' ')

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
CALIB_SW = fit_king_law_arash(Up_adj, es1cal_tc);
CALIB_SW_r = fit_king_law_arash(Up_adj, es1cal_raw);

% Save calibration data
cd SWData
save([filename '_CALIBSW'], 'Pm', 'ePm', 'Up', 'Up_adj', ...
     'es1cal_raw', 'es1cal_tc', 'CALIB_SW', 'CALIB_SW_r', ...
     'alpha0_sw1', 'T', 'T_ref', 'T0', 'Tw_sw1', 'Tcorr_co_SW', 'P_atm_mmHg', 'rho_air', ...
     'P_gain', 'P_offset_v', 'P_offset_v_end', 'a_sw1', 'ActualRate', 'type', 'Date','gain','offset');
cd ..\;
% Close out program and clean up
temp = clock;
disp(' Calibration complete.');
disp(['END TIME: ' num2str(temp(4)) ':' num2str(temp(5)) ':' num2str(temp(6))]);
disp(' ');
disp('**********************************');
disp(' ');

clear j

% --- END OF CODE ---