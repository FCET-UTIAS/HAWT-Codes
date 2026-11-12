
%% PTAP ARRAY MEASUREMENTS
% This script is used to measure the cross stream flow uniformity of the AWT
% in the open jet configuration. The FCET 40 channel pressure transducer
% that can go up to 2 kPa is used. The DAQ used to collect measuremetns from 
% the array is the DAQ3035 board. The Array is first of all calibrated, and
% the baratron is used as the calibration sensor for the test.
% 
%
% HISTORY:
%   -Created: Marinus Okoronkwo (March 2, 2022)
%   -Changed input parameter sweep from voltage to velocity; Neil F. and Zhe
%   L. (April 7, 2022)
%
% Usage notes:
%   - Start with traverse fully to the left
%--------------------------------------------------------------------------
%% SECTION 1: Program Parameters
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM BEGIN -------------------------------')
disp('-------------------------------------------------------------------')
disp('BEGIN Program Initialization --------------------------------------')

%addpath('C:\Users\FCET\Documents\MATLAB');                                                                   % Add C:\Users\FCET\Documents\MATLAB folder to path
daqreset;
clear all; clc;             % Clear old data and commands

% Store start time of calibration
time_start = fix(clock);                                                    % start time of trial 
date = DateFix(time_start);                                                % Generate 'yyyy-mm-dd' prefix for file generation

% Plotting Toggle
plot_run = 1;                                                               % Turn on/off plotting after each measurement collection

% Baratron Pressure Transducer Settings
PT_f_s = 4000;                                                              % Sampling frequency for Baratron transducer
PT_t_s = 30;                                                                % Sampling time for Baratron Transducer
PT_gain = 133.322;                                                          % Gain for Baratron on 100 Torr setting

% DAQ3035 Settings
num_sensors = 40;                                                           % number of sensors on array
PArray_f_s = 4000;                                                          % Sampling freq for pressure array
PArray_t_s = 30;                                                            % Sampling time for pressure array
time_Array = 0:1/PArray_f_s:PArray_t_s - 1/PArray_f_s;                      % time series for plotting purposes
range_2 = 100;  % range of pressure transducer, 10 or 100 torr
P_gain_fs_2 = 133.322*range_2/10;  % for MKS 120AD on desired torr range, 10V range
load('C:\Users\FCET\Documents\MATLAB\AWT_Zhe\20220514\Array_Calib_05-15-2022_15-05', 'CALIB_PTA');
% PArray_gain = CALIB_PTA(:, 1);
% PArray_offset = CALIB_PTA(:, 2);

% Initialize DAQ3035
disp('    Initializing DAQ3035')
[ai_array,~] = ...                                                          % Initialize array DAQ
    DaqBoard3035_init(PArray_f_s,PArray_t_s,64);                              % ...
disp('    DAQ3035 Connected')

disp('END Program Initialization ----------------------------------------')
disp('-------------------------------------------------------------------')
%% SECTION 2: Parameter Entry
disp('BEGIN Parameter Entry ---------------------------------------------')

Run       = input('    Run Number: ');                                      % Run number
P_atm_kPa   = input('    Atmospheric Pressure [kPa]: ');                    % atmospheric pressure [kPa]
P_atm_mmHg  = P_atm_kPa * 7.50062;

V_min       = input('    Minimum velocity to collect at [m/s]: ');           % minimum velocity to collect data at
V_max       = input('    Maximum velocity to collect at [m/s]: ');           % maximum velocity to collect data at
num_Vol     = input('    Number of velocity values to collect for: ');       % number of voltage values to measure at
num_pts     = input('    Number of Spanwise Points to Collect for. 26 is suggested: ');    % number of spanwise points to measure
num_str     = input('    Number of Streamwise Points to Collect for: ');    % number of streamwise locations to measure
trav_index  = input('    Input 1 if you want to use predefined traversing movement:');

% T_temp      = USB_TC01_read;
% [rho_air_kgpm3,kvisc_air,~,~] = fluid_prop(T_temp, P_atm_mmHg);             % Determine air density [kg/m^3] and viscosity 

V_test       = linspace(V_min, V_max, num_Vol);

disp('END Parameter Entry -----------------------------------------------')
disp('-------------------------------------------------------------------')

%% SECTION 4: Initialize Traverse System
dz_mm = 20;                % 2 cm traverse between measurements [mm]
zbounds = [0 500];
centrelinestep_ = interp1(zbounds, [1 num_pts], 0);
centreline_step = round(centrelinestep_);
steps_to_mm = 800;                  % Motor calibration
steps = dz_mm*steps_to_mm;
% steps_array = [ones(1,20)*10*steps_to_mm,ones(1,7)*40*steps_to_mm];
% pause_array = [ones(1,20)*15,ones(1,7)*30];
dy_array = ones(25,1)*20;
steps_array = dy_array*steps_to_mm;
pause_array = ones(25,1)*10;
dz = (linspace(0,80,40)-80/2)/80;  % The locations of the pitot tubes on the rake [cm]
%%
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

%% SECTION 5: COLLECT TEST DATA
disp('BEGIN Main Code ---------------------------------------------------')
                                                            
PArray_e_mean_V = zeros(num_sensors,num_pts,num_Vol,num_str);                       % Store mean voltage for each sensor on array at each spanwise and streamwise location
PArray_e_std_V  = zeros(num_sensors,num_pts,num_Vol,num_str);                       % Store standard deviation for each sensor on array at each spanwise and streamwise location
PArray          = zeros(num_sensors,num_pts,num_Vol,num_str);                       % Store differential pressure for each sensor on array at each spanwise and streamwise location
U_PT_mps        = zeros(num_sensors,num_pts,num_Vol,num_str);                       % Mean velocity for each sensor on array at each spanwise and streamwise location
PT_e            = zeros(PT_f_s*PT_t_s,num_Vol,num_str);                             % Store voltage of Baratron signal
PT_P            = zeros(PT_f_s*PT_t_s,num_Vol,num_str);                             % Store Baratron pressure readings for each calibration point
T_read          = zeros(2,num_Vol,num_str);                                           % Store temperature at which each measurement was taken at
time_of_run     = zeros(num_pts,num_Vol,num_str);                                   % Time that each measurement was recorded at
u_fs            = zeros(num_Vol,num_str);                                           % Flow freestream velcoity at each measurement
load U_calib_pitot_tube_taps05-04-2022_17-27_pt_final Cal_coef
for i = 1:num_str
    for j = 1:num_Vol
        AWT_Control_on
        voltage_input = AWT_Control_U2V_Creighton(V_test(j), Cal_coef(1), Cal_coef(2));
        AWT_Control_setVref(voltage_input);
        disp(['Adjusting AWT to ' num2str(V_test(j),'%5.2f') 'm/s']);
        disp('    Press Enter to continue...')
        pause;
        disp('    Allow Tunnel to Settle')
        disp(' ')
        pause(15);
       
%         disp('    Collecting Baratron Measurement')
%         [T_read(1,j,i), PT_e(:,j,i)] = Meas_T_PS(PT_f_s, PT_t_s);
%         [rho_air, ~, ~, ~] = fluid_prop(T_read(1,j,i), P_atm_mmHg);                 % determine fluid properties
%         time_of_run(i) = toc;
%         disp('    Baratron Measurement Collected')
%         PT_P(:,j,i) = (PT_e(:,j,i) -  PT_offset_pre_V)* PT_gain; 
%         u_fs(j,i) = mean(sqrt(abs(2*PT_P(:,j,i)/(rho_air*(1 - AR^2))))*1.91);
        
        for k = 1:num_pts
             [~, e_PT] = Meas_T_PS(PT_f_s, PT_t_s);
   
    disp('    Baratron Measurement Collected')
    PT_e(k,j,i) = mean(e_PT);
    PT_P_Pa(k,j,i) = mean(e_PT - v_fs_offset) * P_gain_fs_2;
     T_read = USB_TC01_read; 
    T(k,j,i) = mean(T_read);
    [rho_air, visc_air, rho_w, g] = fluid_prop(T(k,j,i), P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity 
    U_PT_mps_Baratron(k,j,i) = sqrt(2*abs(PT_P_Pa(k,j,i))/rho_air);
            disp(['   Pitot Rake measurement: ', int2str(k), ' of ', int2str(num_pts), ' at Streamwise Location ' , int2str(i)]);
            disp('    Collecting Array Measurement')
            [array_V,array_std_V,array_raw_V] = PTA_get_pressure(ai_array);
%             [T_read(2,j,i), ~] = Meas_T_PS(PArray_f_s, PArray_t_s);
            T_read(2,j,i) = USB_TC01_read;
            time_of_run(k,j,i) = toc;
            disp('    Array Measurement Collected')
            
            % Process measurements to extract pressure and velocity
            
            PArray_e_mean_V(:,k,j,i)        = array_V;
%             PArray_e_mean_ = array_V;
            PArray_e_std_V(:,k,j,i)         = array_std_V;
           
%             PArray                          = (PArray_e_mean_ - PArray_offset).*PArray_gain;
            for ii = 1:length(array_V)
                PArray(ii,k,j,i) = polyval(CALIB_PTA(ii,:), array_V(ii));
            end
            [rho_air, ~, ~, ~]   = fluid_prop(T_read(2,j,i), P_atm_mmHg);             % determine fluid properties
            U_PT_mps(:,k,j,i)               = sqrt(2*abs(PArray(:,k,j,i))/rho_air);
   
            % Summary of measurement 
            disp('    CURRENT FLOW CHARACTERISTICS:')
            disp(['         T = ' num2str(T_read(2,j,i), '%10.2f') ' deg C']);
            disp(['      P_pt = ' num2str(PArray(20,centreline_step,j,i), '%10.2f') ' Pa']);
            disp(['      U_PT = ' num2str(U_PT_mps(20,k,j,i), '%10.2f') ' m/s']);
            disp(' ')
            
            % add plot decison tree
         
            % Linear Traverse
            if trav_index == 1
                if k < num_pts
                    fprintf(['    Move traverse ', num2str(steps_array(k)/steps_to_mm/10), ' cm to measurement point: ',num2str(k + 1)]);
                    disp('    Traverse Moving')
                    disp(' ')
                    if mod(j, 2) == 0
                        sign = '-';
                        TwoTraverse_PitotRake(steps_array(k), sign);
                    else
                        sign = '+';
                        TwoTraverse_PitotRake(steps_array(k), sign);
                    end
                    pause(pause_array(k));
                    disp('    Traverse Finished Moving')
                    disp(' ')
                    disp('    Allow Tunnel to Settle')
                    disp(' ')
                    pause(15);
                else
                    disp('    End of traversed reached. Motor will reverse, and measurements will be made at next velocity.')
                end
            else
                if k < num_pts
                    fprintf('    Move traverse 2cm to measurement point : %d \n',k + 1);
                    %disp('    Press Enter to continue...')
                    %pause;
                    disp('    Traverse Moving')
                    disp(' ')
                    if mod(j, 2) == 0
                        sign = '+';
                        TwoTraverse_PitotRake(steps, sign);
                    else
                        sign = '-';
                        TwoTraverse_PitotRake(steps, sign);
                    end
                    pause(30);
                    disp('    Traverse Finished Moving')
                    disp(' ')
                    disp('    Allow Tunnel to Settle')
                    disp(' ')
                    pause(15);
                else
                    disp('    End of traversed reached. Motor will reverse, and measurements will be made at next velocity.')
                end
            end
        end
        decision  = input('    Do you want to see the velocity distribution at the tunnel centerline? Enter 1 for Yes, enter 0 for No ');
        if decision > 0
            figure
            y = U_PT_mps(:,centreline_step,j,i)/V_test(j);
            plot(dz, y, 'o-', 'LineWidth', 2)
            xlabel('$Z/D$','FontSize', 14, 'Interpreter','Latex')
            ylabel('$U/U_{\infty}$','FontSize', 14, 'Interpreter','Latex')
            ax = gca;
            ax.FontSize = 14;
            box off
        end
    end
    %slowly reduce tunnel speed and shut it down. 
    disp('BEGIN Shutdown Wind Tunnel ----------------------------------------')
    AWT_Control_off(voltage_input)
    disp('     Tunnel Shutting down')
    pause(20);
    disp('END Shutdown Wind Tunnel ------------------------------------------')
    disp('-------------------------------------------------------------------')
    if i < num_str
        disp('     Move setup to the next streamwise location')
        disp('     Press Enter to continue...')
        pause;
    else
        disp('     Measurements Completed')
    end
end


%% SECTION 10: Save Results
disp('BEGIN Saving of Results -------------------------------------------')
date_time = datestr(now,'mm-dd-yyyy_HH-MM');
filename = strcat('Pitot_rake_' ,date_time);
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

