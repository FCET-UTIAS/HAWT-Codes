
%% HOTWIRE RAKE MEASUREMENTS
% This script is used to measure the cross stream flow uniformity of the AWT
% in the open jet configuration. The FCET 40 channel pressure transducer
% that can go up to 2 kPa is used. The DAQ used to collect measuremetns from
% the array is the DAQ3035 board. The Array is first of all calibrated, and
% the baratron is used as the calibration sensor for the test.
%
%
% HISTORY:
%   -
%
% Usage notes:
%   - Start with traverses at zero positions
%--------------------------------------------------------------------------
%% SECTION 1: Program Parameters
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM BEGIN -------------------------------')
disp('-------------------------------------------------------------------')
disp('BEGIN program initialization --------------------------------------')

%addpath('C:\Users\FCET\Documents\MATLAB');                                                                   % Add C:\Users\FCET\Documents\MATLAB folder to path
clear all; clc;             % Clear old data and commands

% Plotting toggle
plot_run = 1;  % Turn on/off plotting after each measurement collection

%% SECTION 2: Parameter Entry
disp('BEGIN parameter entry ---------------------------------------------')

Run       = 1;%input('    Run number: ');                                      % Run number
P_atm_kPa   = 103.2;%input('    Atmospheric pressure [kPa]: ');                    % atmospheric pressure [kPa]
P_atm_mmHg  = P_atm_kPa * 7.50062;

V_min    = 55;%input('    Minimum velocity to collect at [m/s]: ');           % minimum velocity to collect data at
V_max    = 55;%input('    Maximum velocity to collect at [m/s]: ');           % maximum velocity to collect data at
num_V    = 1;%input('    Number of velocity values to collect for: ');       % number of velocity values to measure at
num_str  = 1;%input('    Number of streamwise points to Collect for: ');    % number of streamwise locations to measure
mm_vertical    = 0;  % z = -300 mm to 0 (probe 3 as the reference point), with 100 mm interval
mm_horizontal  = linspace(0, 340, 9);  % y = -340 mm to 0, with 20 mm interval, with 20 mm interval
num_vertical  = length(mm_vertical);  % Number of vertical points
num_horizontal = length(mm_horizontal);  % Number of horizontal points
steps_p_mm_vertical = 400;
steps_p_mm_horizontal = 800;
steps_vertical = round(diff(mm_vertical)*steps_p_mm_vertical);  % Predefined vertical traversing movement
steps_horizontal = round(diff(mm_horizontal)*steps_p_mm_horizontal);   % Predefined horizontal traversing movement
pause_movement_horizontal = 35;  % Pause time for each horizontal traversing movement
pause_movement_vertical = 45;  % Pause time for each horizontal traversing movement
AWT_Control_setVref_cal = @(velocity) AWT_Control_setVref(AWT_Control_U2V_Creighton(velocity, Cal_coef(1), Cal_coef(2)));

D = 600;  % The edge length of the nozzle
AR = 0.87^2;

channels = [2, 6, 7, 8, 9, 10];
num_channels = length(channels);

t_samp = 15;  % Time for each sample
f_s = 2^16;  % Sampling rate (Hz)

input('Make sure the Baratron is at 10 Torr mode and press any key to continue...');
range = 10;  % Range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;  % For MKS 120AD on desired torr range, 10V range

V_test = linspace(V_min, V_max, num_V);

load U_calib_pitot_tube_04-04-2022_15-07 Cal_coef
load C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-20\cal_2022_April_20_probe1to5_CALIBSW CALIB_SW

disp('END parameter entry -----------------------------------------------')
disp('-------------------------------------------------------------------')

%% SECTION 4: Initialize Traverse System
% dz_mm = 20;                % 2 cm traverse between measurements [mm]
% zbounds = [-400 80];
% centrelinestep_ = interp1(zbounds, [1 num_pts], 0);
% centreline_step = round(centrelinestep_);
% steps_to_mm = 800;                  % Motor calibration
% steps = dz_mm*steps_to_mm;
% steps_array = [ones(1,20)*10*steps_to_mm,ones(1,7)*40*steps_to_mm];
% pause_array = [ones(1,20)*15,ones(1,7)*30];
dy = (-340 + mm_horizontal)/D;      % The locations of the hotwire probes on the horizontal direction
dz = (-300 + mm_vertical)/D;
% dz = sort([[-300, -300 + mm_vertical] - 40,[-300, -300 + mm_vertical] - 20,[-300, -300 + mm_vertical],[-300, -300 + mm_vertical] + 20,[-300, -300 + mm_vertical] + 40],'ascend')/D;      % The locations of the hotwire probes on the vertical direction

%% SECTION 5: COLLECT TEST DATA
disp('BEGIN Main Code ---------------------------------------------------')

PT_e            = zeros(num_vertical, num_horizontal);                             % Store voltage of Baratron signal
PT_P            = zeros(num_vertical, num_horizontal);                             % Store Baratron pressure readings for each calibration point
T_read          = zeros(2, num_vertical, num_horizontal);                                           % Store temperature at which each measurement was taken at
time_of_run     = zeros(num_vertical, num_horizontal);                                   % Time that each measurement was recorded at
u_fs            = zeros(num_vertical, num_horizontal);                                           % Flow freestream velcoity at each measurement
% data_raw        = zeros(num_vertical, num_channels - 1, t_samp*f_s);
es1cal_raw_mean      = zeros(num_vertical, num_horizontal, num_channels - 1);
es1cal_raw_std  = zeros(num_vertical, num_horizontal, num_channels - 1);
U_hw            = zeros(num_vertical, num_horizontal, num_channels - 1);
TI_hw_stddev           = zeros(num_vertical, num_horizontal, num_channels - 1);      % Calculated based on the local velocity measured by the hotwire
TI_pressure     = zeros(num_vertical, num_horizontal, num_channels - 1);      % Calculated based on the mean freestream velocity measured by the pressure taps on the first contraction

input('Zero the Baratron for offset measurement, press Enter when done');
disp('Measuring offset...')
tmeasure = 60; f_s_b = 4e3; channels_b = 2;
[~,offset_start,~] = Meas_SW_PT(tmeasure, f_s_b, channels_b);
tic;
input('Offset measurement done, open the Baratron, press Enter when done');
disp(['Initial Baratron offset voltage is ' num2str(mean(offset_start), '%5.4f') ' V']);

for j = 1:num_V
    AWT_Control_on
    voltage_input = AWT_Control_U2V_Creighton(V_test(j), Cal_coef(1), Cal_coef(2));
    AWT_Control_setVref(voltage_input);
    disp(['Adjusting AWT to ' num2str(V_test(j),'%5.2f') 'm/s']);
    disp('    Press Enter to continue...')
    pause;
    disp('    Allow tunnel to settle')
    disp(' ')
    pause(15);
    
    
    for l = 1:num_vertical
        for k = 1:num_horizontal
            disp(['   Pitot rake measurement: ', int2str(k), ' of ', int2str(num_horizontal), ' horizontal position at vertical position ' , int2str(l)]);
            disp('    Collecting array measurement')
            T_read(1,l,k) = USB_TC01_read;
            
            % Take the hot wire measurement
            [er_sw1,PT_e_V,~] = Meas_SW_PT(t_samp, f_s, channels);
            T_read(2,l,k) = USB_TC01_read;
            time_of_run(l,k) = toc;
            [rho_air_kgpm3,~,~,~] = fluid_prop(mean(T_read(:,l,k)), P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity
            PT_e(l,k) = mean(PT_e_V);
            PT_P(l,k) = PT_e(l,k)*P_gain_fs;
            u_fs(l,k) = sqrt(abs(2*PT_P(l,k)/(rho_air_kgpm3*(1 - AR^2))))*1.91;
            
            disp('    Array measurement collected')
            
            % Save the raw value
            date_time = datestr(now, 'mm-dd-yyyy_HH-MM');
            filename = ['C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-22_2D\RawdataOfPoint', num2str(num_horizontal*(l - 1) + k), '_', date_time];
            save(filename, 'er_sw1');
            es1cal_raw_mean(l,k,:) = mean(er_sw1);
            es1cal_raw_std(l,k,:) = std(er_sw1);
            for n = 1:num_channels - 1
                u_hw = polyval(CALIB_SW(n,:), er_sw1(:, n));
                U_hw(l,k,n) = mean(u_hw);
            end
            
            % Compute the turbulence intensity; calculate it two ways
            TI_hw_stddev(l,k,:) = std(u_hw)./U_hw(l,k,:);
            TI_pressure(l,k,:) = std(u_hw)/u_fs(l,k);
            
            % Summary of measurement
            disp('    CURRENT FLOW CHARACTERISTICS:')
            %             disp(['         T = ' num2str(T_read(2,j,i), '%10.2f') ' deg C']);
            %             disp(['      P_pt = ' num2str(PArray(20,centreline_step,j,i), '%10.2f') ' Pa']);
            for i = 2:num_channels - 1
                disp(['      U_hw number ', num2str(i), ' = ', num2str(U_hw(l,k,i), '%10.2f') ' m/s']);
            end
            disp(['      U_pressure = ' num2str(u_fs(l,k), '%10.2f') ' m/s']);
            disp(' ')
            
            % add plot decision tree
            
            % Linear traverse
            if k < num_horizontal
                movement = mm_horizontal(k+1) - mm_horizontal(k);
                fprintf(['    Move traverse horizontally by ', num2str(movement/10), ' cm to measurement point: ', num2str(k + 1), ' at vertical position ', int2str(l)]);
                disp('    Traverse moving')
                disp(' ')
                if mod(l, 2) ~= 0  % If l is odd
                    TwoTraverse_PitotRake(steps_horizontal(k), '-');
                else  % l is even
                    steps_temp = flip(steps_horizontal);
                    TwoTraverse_PitotRake(steps_temp(k), '+');
                end
                pause(pause_movement_horizontal);
                disp('    Traverse finished moving')
                disp(' ')
                disp('    Allow tunnel to settle')
                disp(' ')
            end
            pause(15);
        end
        
        if l < num_vertical
            movement = mm_vertical(l+1) - mm_vertical(l);
            fprintf(['    Move traverse vertically by ', num2str(movement/10),' cm to measurement vertical position: ', num2str(l + 1)]);
            disp('    Traverse moving')
            disp(' ')
            OneTraverse_str(steps_vertical(l), '+');
            pause(pause_movement_vertical);
            disp('    Traverse finished moving')
            disp(' ')
            disp('    Allow tunnel to settle')
            disp(' ')
        end
        pause(15);
        
    end
    
    
end

% Collect the Baratron offset following all the measurements
input('Zero the Baratron for offset measurement and press any key to continue...');
disp('Measuring offset...')
tmeasure = 60; f_s_b = 4e3; channels_b = 2;
[~,offset_end,~] = Meas_SW_PT(tmeasure, f_s_b, channels_b);
disp('Offset measurement done');
disp(['Final Baratron offset voltage is ' num2str(mean(offset_end),'%5.4f') ' V']);
time_of_end = toc;

% Flip the even-numbered rows, since we are going back and forth with the
% traverse measurements
for ll = 2:2:num_vertical
    U_hw(ll, :, :) = flip(U_hw(ll, :, :));
end
%%
decision  = 1;%input('    Do you want to see the results at the tunnel centerline? Enter 1 for Yes, enter 0 for No ');
if decision > 0
    figure(3)
    [DY, DZ] = meshgrid(dy, dz);
    %contourf(DY, DZ, U_hw(:, :, 3), 'linecolor', 'none')
    plot(dy, U_hw(1, :, 3), 'linewidth', 2)
    hold on
    scatter(reshape(DY, [], 1), reshape(DZ, [], 1), 'linewidth', 1);
    hold off
    %             plot(dz,  U_hw, 'o-', 'LineWidth', 2)
    xlabel('$y/D$', 'FontSize', 14, 'Interpreter', 'Latex')
    ylabel('$z/D$', 'FontSize', 14, 'Interpreter', 'Latex')
    ax = gca;
    ax.FontSize = 14;
    box off
end

% Slowly reduce tunnel speed and shut it down.
disp('BEGIN shutdown wind tunnel ----------------------------------------')
AWT_Control_off(voltage_input)
disp('     Tunnel shutting down')
disp('END shutdown wind tunnel ------------------------------------------')
disp('-------------------------------------------------------------------')

disp('     Measurements completed')


%% SECTION 10: Save Results
disp('BEGIN saving of results -------------------------------------------')
date_time = datestr(now,'mm-dd-yyyy_HH-MM');
filename = strcat('Hotwire_rake_' ,date_time);
save(['C:\Users\FCET\Documents\MATLAB\AWT_Zhe\2022-04-22_2D\' filename]);
% Close out program and clean up

disp(['    Data saved to ' filename]);
disp('    Calibration complete');
disp('END saving of results ---------------------------------------------')
disp('-------------------------------------------------------------------')
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM COMPLETED ---------------------------')
disp('-------------------------------------------------------------------')

