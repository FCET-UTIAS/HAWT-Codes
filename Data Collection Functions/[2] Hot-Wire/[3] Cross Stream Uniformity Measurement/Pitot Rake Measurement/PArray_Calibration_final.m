%% PTAP ARRAY CALIBRATION
% This script is used to calibrate the 2 kPa transducer array. The DAQ 
% used to collect measuremetns from the array is the DAQ3035 board. The 
% baratron is used as the calibration sensor for the test.
% The current calibration manifold can calibrate up to 16 sensors at once.
% Expanison of the mainfold will allow for more sensors to be calibrated in
% a single trial.
%
%
% HISTORY:
%   Created: Daniel MacGregor (December 20, 2021)
%
%--------------------------------------------------------------------------
%% SECTION 1: Program Parameters
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM BEGIN -------------------------------')
disp('-------------------------------------------------------------------')
disp('BEGIN Program Initialization --------------------------------------')
%AddPaths;                               
% Add function groups folders to path
daqreset;
clear all; clc;

% Store start time of calibration
time_start = fix(clock);  % start time of trial 
date = DateFix(time_start);  % Generate 'yyyy-mm-dd' prefix for file generation

% Plotting Toggle
plot_run = 1;  % Turn on/off plotting after each measurement collection

% Baratron Pressure Transducer Settings
PT_f_s = 4000;  % Sampling frequency for Baratron transducer
PT_t_s = 30;  % Sampling time for Baratron Transducer
%PT_gain = 133.322;  % Gain for Baratron on 10 Torr setting
range_2 = 100;  % range of pressure transducer, 10 or 100 torr
P_gain_fs_2 = 133.322*range_2/10;  % for MKS 120AD on desired torr range, 10V range
disp('Make sure the Baratron is in 100 Torr mode');
pause;
%AWT_Control_off(0);
disp('END Program Initialization ----------------------------------------')
disp('-------------------------------------------------------------------')
load('U_calib_pitot_tube_taps05-04-2022_17-27_pt_final.mat', 'Cal_coef')

%% DAQ3035 Settings
num_sensors = 40;  % number of sensors on array
PArray_f_s = 4000;  % Sampling freq for pressure array
PArray_t_s = 30;  % Sampling time for pressure array
time_array = 0:1/PArray_f_s:PArray_t_s - 1/PArray_f_s;  % time series for plotting purposes

% Initialize DAQ3035
disp('    Initializing DAQ3035')
[ai_array,~] = ...                                                          % Initialize array DAQ
    DaqBoard3035_init(PArray_f_s,PArray_t_s,64);                            % ...
disp('    DAQ3035 Connected')

disp('END Program Initialization ----------------------------------------')
disp('-------------------------------------------------------------------')


%% SECTION 2: Parameter Entry

disp('BEGIN Parameter Entry ---------------------------------------------')

% trial = input('    Trial Number: ');  % Trial number
P_atm_kPa = input('    Atmospheric Pressure [kPa]: ');  % atmospheric pressure [kPa]
P_atm_mmHg = P_atm_kPa * 7.50062;
%U_min = input('    Minimum velocity to collect at [m/s]: ');  % minimum velocity to collect data at
U_max = input('    Maximum velocity to collect at [m/s]: ');  % maximum velocity to collect data at
num_pts = input('    Number of points to collect: ');  % number of velocities to calibrate ove
U_min = input('    Minimum velocity to collect at [m/s]: ');  
% T_temp = USB_TC01_read;
% [rho_air_kgpm3, ~, ~, ~] = fluid_prop(T_temp, P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity  (Commented out because it's unused right now)
% P_range = linspace(0,0.5*rho_air_kgpm3*U_max^2,num_pts);  % Commented out because it's unused right now

% U_test = [P_range flip(P_range(1:end-1))];                               % linearly spaced array of velcoity to collect calibration data at
% U_test = [P_range P_range(2:end)];
% U_test = sqrt(2*U_test/rho_air_kgpm3);
% num_pts = length(U_test);
U_test = linspace(U_min, U_max, num_pts);

% first_sensor_cal = input('    First sensor to be calibrated: ');  % Commented out because it's unused right now
last_sensor_cal  = input('    Last sensor to be calibrated: ');

disp('END Parameter Entry -----------------------------------------------')
disp('-------------------------------------------------------------------')

%% SECTION 3: Pressure Transducer Offset for Baratron
choice = input('        How would you like to measure the Cp baratron offset? Enter 1 to manually set the baratron offset, or 0 to block the nozzle and measure the offset: ');

if choice  == 0
    disp('--------------------------------------------------------------------')
    disp('    Cover nozzle exit...')
    disp('    Press Enter to continue...')
    pause;
    disp('--------------------------------------------------------------------')
    disp('    Nozzle exit covered...')
    disp('BEGIN Pressure Transducer Offset ----------------------------------')
    pause(0.5);
    [~, e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
    v_fs_offset = mean(e_PT);
    tic;
    disp(['    Initial offset voltage for Cp Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    %disp(['    Initial offset voltage for Velocity Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
    disp('-------------------------------------------------------------------')
elseif choice == 1
    disp('BEGIN Pressure Transducer Offset ----------------------------------')
    [~, e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
    v_fs_offset = mean(e_PT);
    tic;
    disp(['    Initial offset voltage for Cp Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    %disp(['    Initial offset voltage for Velocity Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
    disp('-------------------------------------------------------------------')
    disp('Replace total and static tubes -----------------------------------')
    disp('   Tubes replaced? Press Enter to continue...')
    pause;
end


%% SECTION 4: COLLECT TEST DATA
disp('BEGIN Main Code ---------------------------------------------------')
                                                            
PArray_e_mean_V = zeros(num_pts, num_sensors);  % Store mean voltage for each sensor on array
PArray_e_std_V  = zeros(num_pts, num_sensors);  % Store standard deviation for each sensor on array
PT_e            = zeros(num_pts, 1);  % Store voltage of Baratron signal
PT_P_Pa         = zeros(num_pts, 1);  % Store Baratron pressure readings for each calibration point
T               = zeros(num_pts, 1);  % Store temperature each calibration measurement was taken at
time_of_run     = zeros(num_pts, 1);  % Time that each measurement was recorded at
U_PT_mps        = zeros(num_pts, 1);  % Flow velcoity at each measurement

for i = 1:num_pts
%     if i == ceil((num_pts)/2 + 1)  % If we are halfway through the num_points
%         AWT_Control_on
%         AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test(i), Cal_coef(1), Cal_coef(2)));
%         disp(['Adjusting AWT to ' num2str(U_test(i),'%5.2f') ' m/s']);
%         disp('    Press Enter to continue...')
%         pause;
%         disp('    Allow tunnel to settle')
%         disp(' ')
%         pause(30);
%         disp('     Switch total and static tubing on manifolds')
%         disp('     Press Enter to continue...')
%         pause;
%         
%     elseif i ~= 1 
        AWT_Control_on
        AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test(i), Cal_coef(1), Cal_coef(2)));
        disp(['Adjusting AWT to ' num2str(U_test(i),'%5.2f') ' m/s']);
        %disp('    Press Enter to continue...')
        %pause;
        disp('    Allow tunnel to settle')
        disp(' ')
        pause(10);
%     end
    disp(['    Calibration measurement: ', int2str(i), ' of ', int2str(num_pts)]);
    disp('    Collecting Baratron Measurement')
    T_read(1) = USB_TC01_read;  % ????
    %[e_PT, time_PT, ~] = Meas_PT(PT_f_s, PT_t_s);
    [~, e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
    time_of_run(i) = toc;
    disp('    Baratron Measurement Collected')
    
    disp('    Collecting Array Measurement')
    [array_V,array_std_V,array_raw_V] = PTA_get_pressure(ai_array);
    T_read(2) = USB_TC01_read;   % ????
    disp('    Array Measurement Collected')
    
    PArray_e_mean_V(i,:) = array_V;
    PArray_e_std_V(i,:) = array_std_V;
    PT_e(i) = mean(e_PT);
    PT_P_Pa(i) = mean(e_PT - v_fs_offset) * P_gain_fs_2;
    T(i) = mean(T_read);
    [rho_air, visc_air, rho_w, g] = fluid_prop(T(i), P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity 
    U_PT_mps(i) = sqrt(2*abs(PT_P_Pa(i))/rho_air);
    
    
    if plot_run
        % Plot signal from last sensor being calibrated and signal from
        % Baratron
        close(figure(1));
        figure(1)
        hold on
        plot(time_array, array_raw_V(:, last_sensor_cal));
        plot(e_PT)
        xlabel('time (s)', 'Interpreter', 'latex')
        ylabel('Voltage (V)', 'Interpreter', 'latex')
        legend('Array sensor', 'Baratron')
        hold off
        
        % Plot what current relation looks like for first sensor
        figure(2)
        plot(PT_P_Pa(1:i), PArray_e_mean_V(1:i, 1), '*')
        xlabel('Pressure (Pa)', 'Interpreter', 'latex')
        ylabel('Voltage (V)', 'Interpreter', 'latex')
        
        % Bar plot of voltages from all sensors
        figure(3)
        bar(array_V);
        xlabel('Sensor', 'Interpreter', 'latex')
        ylabel('Voltage (V)', 'Interpreter', 'latex')
    end
    
    % Summary of measurement 
    disp('    CURRENT FLOW CHARACTERISTICS:')
    disp(['         T = ' num2str(T(i), '%10.2f') ' deg C']);
    disp(['      P_pt = ' num2str(PT_P_Pa(i), '%10.2f') ' Pa']);
    disp(['      U_pt = ' num2str(U_PT_mps(i), '%10.2f') ' m/s']);
    disp(' ')
end


%% SECTION 6: Shutdown Wind Tunnel

disp('BEGIN Shutdown Wind Tunnel ----------------------------------------')
disp('     Turn off Tunnel')
AWT_Control_off(AWT_Control_U2V_Creighton(U_test(i),Cal_coef(1),Cal_coef(2)));
disp('     Tunnel Shutting down')
% pause(120);
disp('END Shutdown Wind Tunnel ------------------------------------------')
disp('-------------------------------------------------------------------')

%% SECTION 7: Pressure Transducer Offset
% Determine final pressure offset
disp('BEGIN Pressure Trasnsducer Offset ---------------------------------')
disp('    Need to take an offset measurement');
choice = input('        How would you like to measure the Cp baratron offset? Enter 1 to manually set the baratron offset, or 0 to block the nozzle and measure the offset: ');

if choice  == 0
    disp('--------------------------------------------------------------------')
    disp('    Cover nozzle exit...')
    disp('    Press Enter to continue...')
    pause;
    disp('--------------------------------------------------------------------')
    disp('    Nozzle exit covered...')
    disp('BEGIN Pressure Transducer Offset ----------------------------------')
    pause(0.5);
    [~,e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
    PT_offset_post_V = mean(e_PT);
    disp(['    Initial offset voltage for Cp Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    %disp(['    Initial offset voltage for Velocity Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
    disp('-------------------------------------------------------------------')
elseif choice == 1
    disp('BEGIN Pressure Transducer Offset ----------------------------------')
    [~,e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
    PT_offset_post_V = mean(e_PT);
    disp(['    Initial offset voltage for Cp Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    %disp(['    Initial offset voltage for Velocity Baratron: ' num2str(v_fs_offset,'%10.5f') ' V']);
    disp('END Pressure Trasnsducer Offset -----------------------------------')
end

clear e_PT;
t_final = toc;
disp(['    Initial offset voltage: ' num2str(v_fs_offset,'%10.5f') ' V']);
disp(['    Final offset voltage: ' num2str(PT_offset_post_V,'%10.5f') ' V']);
disp(' ');
disp('END Pressure Trasnsducer Offset -----------------------------------')
disp('-------------------------------------------------------------------')

%% SECTION 8: Post Trial Analysis
% Apply temperature corrections
disp('BEGIN Post-trial Analysis -----------------------------------------')

% determine relative offset weightings
PT_off = ((1-(time_of_run./t_final))*v_fs_offset + (time_of_run./t_final)*PT_offset_post_V);
PT_P_Pa = (PT_e - PT_off)*P_gain_fs_2;
% PT_P_Pa((((num_pts+1)/2)+1):end) = PT_P_Pa((((num_pts+1)/2)+1):end)*-1;     % Negate Baratron readings to build lower portion of calibration curve
%%
% Calibration Curve Fit
CALIB_PTA = zeros(num_sensors,2);                                           % Store Calibration constants for linear fit
CALIB_PTA_Error = cell(num_sensors,1);                                      % Store error structure produced by polyfit to determine error on fit
for i = 1:num_sensors
    [coeff,error] = polyfit(PArray_e_mean_V(:,i),PT_P_Pa, 1);
    CALIB_PTA(i,:) = coeff;
    CALIB_PTA_Error{i} = {error};
end
%%    
num_fig = 33;
Calib_voltages = linspace(0, 5);
Calib_pressure = polyval(CALIB_PTA(num_fig,:), Calib_voltages);
figure(3)
hold on
plot(PArray_e_mean_V(:, num_fig), PT_P_Pa(:,1),'*')
plot(Calib_voltages,Calib_pressure, '--');
hold off
ylabel('Pressure (Pa)','Interpreter','latex')
xlabel('Voltage (V)','Interpreter','latex')

disp('END Post-trial Analysis -------------------------------------------')
disp('-------------------------------------------------------------------')
%% SECTION 10: Save Results
disp('BEGIN Saving of Results -------------------------------------------')
date_time = datestr(now,'mm-dd-yyyy_HH-MM');
filename = strcat('Array_Calib_' ,date_time);
save(['C:\Users\FCET\Documents\MATLAB\AWT_Zhe\20220514\' filename]);
% Close out program and clean up
temp = clock;
disp(['    Data Saved to ' filename]);
disp('    Calibration complete');
disp('END Saving of Results ---------------------------------------------')
disp('-------------------------------------------------------------------')
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM COMPLETED ---------------------------')
disp('-------------------------------------------------------------------')

