Re_list = [19 21 22 24 29 31 33.6 35.6 39 41 45 47 49 51]; %[350000:10000:900000]; 
caseNo_0 = 196; 
% 
% R_off_list = [4:4:15 17];  
% R_reinit_list = [1 5:4:15]; 

for R = 1:size(Re_list,2)


% addpath(genpath('H:\'));

set(groot, 'defaultAxesTickLabelInterpreter','latex'); 
set(groot, 'defaultLegendInterpreter','latex');

if 1%input('Clear? Type "1" if yes: ')
    clearvars -except on R caseNo_0 Re_list R_off_list R_reinit_list
    close all;
%     clc; 
    daqreset
end

%% Specify measurements to be done
CaseNo = caseNo_0+R; %196;

%Desired tunnel speed 
U_case = Re_list(R); %50; 
U_desired = U_case;%/cosd(30); %mps
U_fudge = 0; 
Re_desired = []; 
Re_fudge = 20000; 

micfilecompare = '70--BGAcoustic_50_mps_2025-07-11_10-08'; 
cpfilecompare = 'baratron_data_for_chord_and_span_slat_removed_0_deg_50.8655_mps_03-04-2023_15-00'; 

%speed measurement method 
pitot = 0; tunnel = 1;

Cp = 0; 
RMP = 0; 
Acoustic = 1;  
PMA = 0; 

off = 0; 


disp(['---------------Starting Case Number: ', char(string(CaseNo)), ' ---------------'])
AoA = nan; 
c_30P30N = 0.383;

% HW_X_locs = 295; 
% HW_Y_locs = [0.5:0.25:4.5 5:0.5:6 7:13 15:2:21 25 30]; % [0.5:0.75:5 6 7:2:15 20 25 30 35]; %
% summove = 0; 
f_s_HW = 2^15; 
t_s_HW = 60; 

f_s_mic = 2^16; 
t_s_mic = 90; 
n_rmp = 15; 

% if find(R == R_off_list)
%     off = 1; 
% else
%     off = 0; 
% end

%% Initialize
P_atm_kPa = 101.2; %input('    Atmospheric Pressure [kPa]: ');  % atmospheric pressure [kPa]
T_read(1) =  gimmeTemp; %input('   Temperature [deg]: ');
T0 = 273.15; 
P_atm_mmHg = (P_atm_kPa+2.7) * 7.50062;
gamma_air = 1.4;  % Ratio of thermal coeffs
R_air = 287;  % Gas constant for air [kJ/kg-K]

range = 100;
PT_gain = 133.322*range/10;
PT_f_s = 500;
PT_t_s = 30;
f_s = 40000;
time_per_sensor_in_a_loop = 0.01;
no_of_loops = 50;

%Load Tunnel Calibration Coefficients 
if pitot
    load('U_calib_pitot_tube_Empty_11-05-2025_18-16.mat','Cal_coef')
else
    load('U_calib_pressure_system_Empty_11-05-2025_21-56.mat', 'Cal_coef', 'AR'); 
end

f_s_HW = 2^16;
f_s_RMP = 200e3;
t_samp = 60;
filt_delay = 3;
n_RMP = 15;

Gain = [16];
Offset_V = [-(0.92+1.52)/2]; %, -(1.40+2.75)/2];  %Moving, Stationary  
% HW_WireT_degC_mov = 214; %Wire Temperature (Overtemp)
Overheat_ratio = 1.75; 
alpha0_sw1      = 0.0032;                                                       % value for tungsten
HW_RefT_degC = 29; %Reference temperature from StreamLine
HW_WireT_degC_mov   = (Overheat_ratio-1) / alpha0_sw1 + HW_RefT_degC;
t_samp_HW = 30; 
f_s_HW = 2^15; 

disp('END Program Initialization ----------------------------------------')
disp('-------------------------------------------------------------------')



%% Offset baratron
date_today = datestr(now, 'yyyy-mm-dd');
% offset_file_name = strcat('Baratron_scan_offset_',date_today,'.mat');

%Offset Pressure Scanning Baratron
% if exist(offset_file_name)==2
%     load(offset_file_name);
%     disp('offset has been taken today and has been loaded')
% else
%     [baratron_top_offset, baratron_bot_offset, raw_offset] = Offset_pressure_scanner;
%     save(strcat('H:\2025-07-00\Baratron Offsets\Baratron_scan_offset_',date_today,'.mat'), 'baratron_top_offset', 'baratron_bot_offset' )
% end

%Offset regular baratron            
offset_file_name = strcat('Baratron_offset_',date_today,'.mat');
if exist('P_offset_v') == 1
    v_fs_offset = P_offset_v;
elseif exist(offset_file_name) == 2
    load(offset_file_name);
    P_offset_v = v_fs_offset;
    disp('offset has been taken today and has been loaded')
else
    v_fs_offset = Baratron_offset(PT_f_s,PT_t_s);
    save(strcat('F:\2025-10-00\Offsets\Baratron_offset_',date_today,'.mat'), 'v_fs_offset' )
end
        
% if find(R == R_reinit_list)
%     do_settingsZOC = 1; 
% else
%     do_settingsZOC = 0; 
% end
do_settingsZOC = 0;% input('Re-initialize the Scanivalve ZOC units? 1 if yes, 0 if no: '); 
f_s_zoc = 40000;
if do_settingsZOC
    date_time = datestr(now, 'yymmdd_HH-MM');
%     input('Ensure ZOC ref ports are connected to the tunnel static pressure port line [Enter to continue]');
    [v_offset_zoc, serialnums,zoc_offset_status] = zoc_offset(f_s_zoc,time_per_sensor_in_a_loop,8);
    save latest_offset_zoc v_offset_zoc serialnums zoc_offset_status 
    save (['ZOC_offset',date_time], "v_offset_zoc", "serialnums", "zoc_offset_status")
else
    load latest_offset_zoc.mat v_offset_zoc serialnums zoc_offset_status 
end

% %% Non Looped Tunnel On
% input('Tunnel ready for on? [Enter to start tunnel]: ');
% if ~exist('on') || ~on 
%     AWT_Control_on 
% end
% U_test = U_desired + U_fudge;
% [rho_air, visc_air, ~, ~] = fluid_prop(gimmeTemp, P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity
%     
% disp(['Adjusting AWT to ' num2str(U_test, '%5.2f') ' m/s']);
% %     AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test, Cal_coef_10Torr(1), Cal_coef_10Torr(2)));
% AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test, Cal_coef(1), Cal_coef(2)));
% disp('    Allow tunnel to settle')
% pause(10);
% disp(' ')
% 
% % ------------
% %Contraction method
% disp('    Collecting Baratron measurement')
% % [~, e_PT] = Meas_T_PS(PT_f_s, 20); %measuring large Baratron (channel 7, Dev5) (small baratron is ch. 4) 
% [mean_p_1_kpa, mean_p_2_kpa, rawdata_mean_1, rawdata_mean_2, rawdata_module_1, rawdata_module_2] = pressure_scan(PT_f_s, 30, baratron_top_offset, baratron_bot_offset); %Measuring pressure scanner 
% disp('    Baratron measurement collected')
% 
% % PT_e = mean(e_PT);
% % delta_P = (PT_e - v_fs_offset) .* PT_gain'; %CHANGE THIS TO 1 FOR SMALL BARATRON, 2 FOR LARGE BARATRON
% T = gimmeTemp; T_Kelvin = T+T0;
% 
% if tunnel 
%     %tunnel method 
%     delta_P = abs(mean_p_1_kpa(2) - mean_p_2_kpa(31)); 
%     U_start = sqrt(2*abs(mean(delta_P))/( rho_air*(1-AR^2)));  % Measured wind tunnel velocity [m/s]
%     U_PT_mps = U_start; 
% elseif pitot
%     %if pitot tube method instead 
%     delta_P = abs(mean([mean_p_1_kpa(1) mean_p_2_kpa(32)])); 
%     u_p                         = (2 * abs(delta_P)./rho_air).^0.5 .* (delta_P ./ abs(delta_P));
%     U_start                       = mean(u_p); 
%     U_PT_mps = U_start;
% end
% 
% PT_P_Pa = 1/2*rho_air*(U_start).^2;  % Dynamic pressure [Pa]
% % Re = rho_air*U_start*c_0012/visc_air;  % Reynolds number
% a = sqrt(gamma_air*R_air*T_Kelvin);  % Speed of sound [m/s]
% Ma = U_start/a;  % Mach number
% 
% % Summary of the measurement
% disp('Current flow characteristics:')
% disp(['    T = ' num2str(gimmeTemp, '%10.2f') ' deg C']);
% disp([' P_pt = ' num2str(PT_P_Pa, '%10.2f') ' Pa']);
% disp([' U_pt = ' num2str(U_start, '%10.2f') ' m/s']);
% %     disp(['   Re = ' num2str(Re/10^6, '%10.2f') ' million']);
% % disp(['   Re = ' num2str(Re/10^3, '%10.2f') ' thousand']);

%% Loop Tunnel ON 
% if find(R == R_reinit_list)
%     on = 0; 
% else 
    on = 1; 
% end
% on = input('Is the tunnel already on? 1 if yes, 0 if no: '); 

% if on
%     speedchange = input('Will the speed be changing from the previous setting? 1 if yes, 0 if no: ');
% else
    speedchange = 1; 
% end

% if pitot
%     input('Is the baratron set to Pitot? [Enter to continue]: '); 
% else
%     input('Is the baratron set to tunnel? [Enter to continue]: ');
% end

if ~on
    AWT_Control_on
end

% IF SETTTING DESIRED SPEED 
if size(U_desired,1) && speedchange
    U_test = U_desired + U_fudge; 
    U_start = 0; 
    j = 0; 
    waittime = 20; 
while 1
    T = gimmeTemp; T_Kelvin = T+T0;
    [rho_air, visc_air, ~, ~] = fluid_prop(T, P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity
    
    disp(['Adjusting AWT to ' num2str(U_test, '%5.2f') ' m/s']);
    AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test, Cal_coef(1), Cal_coef(2)));
    disp('    Allow tunnel to settle')
    pause(waittime);
    disp(' ')

    % ------------
    %Contraction method
    disp('    Collecting Baratron measurement')
    [~, e_PT] = Meas_T_PS(PT_f_s, 30); %measuring large Baratron (channel 7, Dev5) (small baratron is ch. 4) 
    disp('    Baratron measurement collected')
    
    figure(); 
    plot((1:30*PT_f_s)./PT_f_s, e_PT); 
    PT_e = mean(e_PT);
    hold on ; yline(PT_e); hold off; 
    delta_P = (PT_e - v_fs_offset) .* PT_gain'; %CHANGE THIS TO 1 FOR SMALL BARATRON, 2 FOR LARGE BARATRON
    
    
    if tunnel 
        %tunnel method 
        U_start = sqrt(2*abs(mean(delta_P))/( rho_air*(1-AR^2)));  % Measured wind tunnel velocity [m/s]
    elseif pitot
        %if pitot tube method instead 
        u_p                         = (2 * abs(delta_P)./rho_air).^0.5 .* (delta_P ./ abs(delta_P));
        U_start                       = mean(u_p); 
    end
    
    PT_P_Pa = 1/2*rho_air*(U_start).^2;  % Dynamic pressure [Pa]
    Re = rho_air*U_start*c_30P30N*cosd(30)/visc_air;  % Reynolds number
    a = sqrt(gamma_air*R_air*T_Kelvin);  % Speed of sound [m/s]
    Ma = U_start/a;  % Mach number
    
    % Summary of the measurement
    disp('Current flow characteristics:')
    disp(['    T = ' num2str(gimmeTemp, '%10.2f') ' deg C']);
    disp([' P_pt = ' num2str(PT_P_Pa, '%10.2f') ' Pa']);
    disp([' U_pt = ' num2str(U_start, '%10.2f') ' m/s']);
    disp(['   Re = ' num2str(Re/10^6, '%10.2f') ' million']);
%     disp(['   Re = ' num2str(Re/10^3, '%10.2f') ' thousand']);
    
    diff = U_desired - U_start; 
    if j > 2
        disp(['Speed not reached after ',j,' attempts'])
        break
    end
     
    if abs(diff) > 0.01*U_desired
        j = j+1; 
        U_test = U_test + diff;
        waittime = 10; 
        if abs(diff) > 7
            disp('----------------!!!!!!!-------------------')
            disp('Warning: baratron reading likely incorrect')
            disp('!!!!!     Exiting speed set loop    !!!!!!')    
            disp('----------------!!!!!!!-------------------')
            check = input('Continue running the script? [Y/N]: ', 's');
            if upper(string(check)) == "N"
                return 
            else
                break
            end
        end
%         check = input("Change speed by "+diff+" m/s? [Enter to continue, 'n' to break]", 's');
    else
        break
    end

%     if upper(string(check)) == "N"
%         break
%     end

end
U_PT_mps = U_start; 

% IF SETTING DESIRED RE NUMBER 
elseif size(Re_desired,1) && speedchange
    Re_test = Re_desired + Re_fudge; 
    Re_start = 0; 
    j = 0; 
    waittime = 20; 
while 1
    [rho_air, visc_air, ~, ~] = fluid_prop(gimmeTemp, P_atm_mmHg);  % Determine air density [kg/m^3] and viscosity
    U_test = Re_test*visc_air / (rho_air*c_30P30N);

    disp(['Adjusting AWT to ' num2str(U_test, '%5.2f') ' m/s']);
    AWT_Control_setVref(AWT_Control_U2V_Creighton(U_test, Cal_coef(1), Cal_coef(2)));
    disp('    Allow tunnel to settle')
    pause(waittime);
    disp(' ')

    % ------------
    %Contraction method
    disp('    Collecting Baratron measurement')
    T_read(1) =  gimmeTemp; 
    [~, e_PT] = Meas_T_PS(PT_f_s, 30); %measuring large Baratron (channel 7, Dev5)
    disp('    Baratron measurement collected')
    
    T_read(2) = gimmeTemp;
    figure(); 
    plot((1:30*PT_f_s)./PT_f_s, e_PT); 
    PT_e = mean(e_PT);
    hold on ; yline(PT_e); hold off; 

    delta_P = (PT_e - v_fs_offset) .* PT_gain'; %CHANGE THIS TO 1 FOR SMALL BARATRON, 2 FOR LARGE BARATRON
    T = gimmeTemp; T_Kelvin = T+T0;
    
    if tunnel
    %tunnel method 
        U_PT_mps = sqrt(2*abs(mean(delta_P))/( rho_air*(1-AR^2)));  % Measured wind tunnel velocity [m/s]
    elseif pitot
    %if pitot tube method instead 
        u_p                         = (2 * abs(delta_P)./rho_air).^0.5 .* (delta_P ./ abs(delta_P));
        U_PT_mps                       = mean(u_p);
    end
    
    PT_P_Pa = 1/2*rho_air*(U_PT_mps).^2;  % Dynamic pressure [Pa]
    Re_start = rho_air*U_PT_mps*c_30P30N/visc_air;  % Reynolds number
    a = sqrt(gamma_air*R_air*T_Kelvin);  % Speed of sound [m/s]
    Ma = U_PT_mps/a;  % Mach number
    
    % Summary of the measurement
    disp('Current flow characteristics:')
    disp(['    T = ' num2str(gimmeTemp, '%10.2f') ' deg C']);
    disp([' P_pt = ' num2str(PT_P_Pa, '%10.2f') ' Pa']);
    disp([' U_pt = ' num2str(U_PT_mps, '%10.2f') ' m/s']);
%     disp(['   Re = ' num2str(Re_start/10^6, '%10.2f') ' million']);
    disp(['   Re = ' num2str(Re_start/10^3, '%10.2f') ' thousand']);

    
    diff = Re_desired - Re_start; 
    if j > 2
        disp(['Speed not reached after ',j,' attempts'])
        break
    end
    if abs(diff) > 0.008*Re_desired
        j = j+1; 
        Re_test = Re_test + diff;
        U_change = diff*visc_air / (rho_air*c_30P30N);
        waittime = 10; 
    else
        break
    end

end
end

if ~speedchange
    T = gimmeTemp; T_Kelvin = T+T0;
    %measure speed, but don't set/loop 
    %Contraction method
    [rho_air, visc_air, ~, ~] = fluid_prop(T, P_atm_mmHg);
    disp('    Collecting Baratron measurement')
    [~, e_PT] = Meas_T_PS(PT_f_s, 10); %measuring large Baratron (channel 7, Dev5) (small baratron is ch. 4) 
    disp('    Baratron measurement collected')

    PT_e = mean(e_PT);
    delta_P = (PT_e - v_fs_offset) .* PT_gain'; %CHANGE THIS TO 1 FOR SMALL BARATRON, 2 FOR LARGE BARATRON

    
    if tunnel 
        %tunnel method 
        U_PT_mps = sqrt(2*abs(mean(delta_P))/( rho_air*(1-AR^2)));  % Measured wind tunnel velocity [m/s]
    elseif pitot
        %if pitot tube method instead 
        u_p                         = (2 * abs(delta_P)./rho_air).^0.5 .* (delta_P ./ abs(delta_P));
        U_PT_mps                       = mean(u_p); 
    end

    PT_P_Pa = 1/2*rho_air*(U_PT_mps).^2;  % Dynamic pressure [Pa]
    Re = rho_air*U_PT_mps*c_30P30N/visc_air;  % Reynolds number
    a = sqrt(gamma_air*R_air*T_Kelvin);  % Speed of sound [m/s]
    Ma = U_PT_mps/a;  % Mach number
    
    % Summary of the measurement
    disp('Current flow characteristics:')
    disp(['    T = ' num2str(gimmeTemp, '%10.2f') ' deg C']);
    disp([' P_pt = ' num2str(PT_P_Pa, '%10.2f') ' Pa']);
    disp([' U_pt = ' num2str(U_PT_mps, '%10.2f') ' m/s']);
    disp(['   Re = ' num2str(Re/10^6, '%10.2f') ' million']);
%     disp(['   Re = ' num2str(Re/10^3, '%10.2f') ' thousand']);
end



%% Measure Cp
if Cp
[read_back, rawVoltage, t_stamp, v_mean, v_std, p_mean] = getZOC_pressure(f_s_zoc,time_per_sensor_in_a_loop,12,v_offset_zoc);

if pitot
M270_U = (2 * abs((p_mean(31,1)-p_mean(32,1)).*6894.76)./rho_air).^0.5 .* ((p_mean(31,1)-p_mean(32,1)).*6894.76 ./ abs((p_mean(31,1)-p_mean(32,1)).*6894.76));
M273_U = (2 * abs((p_mean(31,3)-p_mean(32,3)).*6894.76)./rho_air).^0.5 .* ((p_mean(31,3)-p_mean(32,3)).*6894.76 ./ abs((p_mean(31,3)-p_mean(32,3)).*6894.76));
M275_U = (2 * abs((p_mean(31,2)-p_mean(32,2)).*6894.76)./rho_air).^0.5 .* ((p_mean(31,2)-p_mean(32,2)).*6894.76 ./ abs((p_mean(31,2)-p_mean(32,2)).*6894.76));
end

if tunnel 
M270_U = sqrt(2*abs(p_mean(30, 1).*6894.76)/( rho_air*(1-AR^2)));
M273_U = sqrt(2*abs(p_mean(30, 3).*6894.76)/( rho_air*(1-AR^2))); 
M275_U = sqrt(2*abs(p_mean(30, 2).*6894.76)/( rho_air*(1-AR^2))); 
end

disp(['M270 U = ', char(string(M270_U)), ' m/s']); 
disp(['M273 U = ', char(string(M273_U)), ' m/s']); 
disp(['M275 U = ', char(string(M275_U)), ' m/s']); 

%% Plotting 

% Organize pressure data by tap
ME_idx_270 = [1:11 13:17 19:28]; 
ME_idx_273 = 1:4; 
FLAP_idx_275 = [1:10 12 14:17]; 

ME_SPAN_idx_273 = [5:10 11:17]; 
ME_SPAN_idx_270 = 2; 
FLAP_SPAN_idx_273 = [18:23 25:27];
FLAP_SPAN_idx_275 = 4; 

% Initialize 
ME_pmean = nan(33,1); ME_vmean = nan(33,1); 
FLAP_pmean = nan(17,1); FLAP_vmean = nan(17,1); 
ME_SPAN_pmean = nan(13,1); ME_SPAN_vmean = nan(13,1); 
FLAP_SPAN_pmean = nan(9,1); FLAP_SPAN_vmean = nan(9,1); 

% Assign pressure means to the correct tap positions
ME_pmean(2:27,1) = p_mean(ME_idx_270,1); 
ME_pmean([28 31:33],1) = p_mean(ME_idx_273,3); 
FLAP_pmean(FLAP_idx_275,1) = p_mean(FLAP_idx_275,2); 
ME_SPAN_pmean(:,1) = p_mean(ME_SPAN_idx_273,3); 
% ME_SPAN_pmean(7,1) = p_mean(ME_SPAN_idx_270,1); 
FLAP_SPAN_pmean([14:-1:9 6 5 3],1) = p_mean(FLAP_SPAN_idx_273,3); 
FLAP_SPAN_pmean(8,1) = p_mean(FLAP_SPAN_idx_275, 2); 

% Assign voltage means to the correct tap positions
ME_vmean(2:27,1) = v_mean(ME_idx_270,1); 
ME_vmean([28 31:33],1) = v_mean(ME_idx_273,3); 
FLAP_vmean(FLAP_idx_275,1) = v_mean(FLAP_idx_275,2); 
ME_SPAN_vmean([1:6 8:14],1) = v_mean(ME_SPAN_idx_273,3); 
ME_SPAN_vmean(7,1) = v_mean(ME_SPAN_idx_270,1); 
FLAP_SPAN_vmean([13:-1:8 6 5 3],1) = v_mean(FLAP_SPAN_idx_273,3); 

% Process to Cp
% U_PT_mps = U_zoc_check; 
ME_Cp = ((ME_pmean).*6894.76)./(0.5*rho_air*(U_PT_mps^2)*cosd(30)); %convert psi to pa
FLAP_Cp = ((FLAP_pmean).*6894.76)./(0.5*rho_air*(U_PT_mps^2)*cosd(30)); %convert psi to pa
ME_SPAN_Cp = ((ME_SPAN_pmean).*6894.76)./(0.5*rho_air*(M273_U^2)*cosd(30)); %convert psi to pa
FLAP_SPAN_Cp = ((FLAP_SPAN_pmean).*6894.76)./(0.5*rho_air*(M273_U^2)*cosd(30)); %convert psi to pa 

% Plot Cp
%import airfoil points
dir = 'E:\Awt_Raymond\30p30n_cp\P_tap_points\Pressure_taps';
[~, main, flap, main_span, flap_span] = import_P_tap_points_2015(dir);
c_inches = c_30P30N/0.0254; 
main_x_norm = main(1:end-1,2)./c_inches; 
flap_x_norm = flap.data(1:end-1,2)./c_inches; 

f3 = figure(); a3 = gca; 
% hold on 
scatter(main_x_norm, ME_Cp, 'red', 'MarkerFaceColor', 'white')
set(gca, 'YDir','reverse')
for n = 1:numel(main_x_norm) % Labels results with pressure tap number
    text(main_x_norm(n),ME_Cp(n),num2str(n))
end
hold on 
scatter(flap_x_norm, FLAP_Cp, 'blue', 'MarkerFaceColor', 'white'); 
hold off
for n = 1:numel(flap_x_norm) % Labels results with pressure tap number
    text(flap_x_norm(n),FLAP_Cp(n),num2str(n))
end
xlabel('$x/c$'); ylabel('$C_p$'); box on ; grid on ; ax = gca; ax.FontSize = 18; ax.LineWidth =1 ; 
%Plot Comparison Cp
load(cpfilecompare, 'flap_Cp', 'main_Cp'); 
hold(a3,'on'); 
scatter(main_x_norm, main_Cp, 'red', 'square', 'filled'); 
scatter(flap_x_norm, flap_Cp, 'blue', 'square', 'filled'); 
hold(a3, 'off'); 


main_span_norm = flipud(main_span.data(:,4)./(0.83/(0.0254*cosd(30)))); 
flap_span_norm = flap_span.data(:,4)./(0.83/(0.0254*cosd(30))); %NOTE: THIS WAS UPSIDE DOWN FOR FIRST PARTS OF DATA COLLECTION 
f4 = figure(); 
scatter(ME_SPAN_Cp, main_span_norm, 'red', 'MarkerFaceColor','white'); 
hold on 
scatter(FLAP_SPAN_Cp, flap_span_norm, 'blue', 'MarkerFaceColor', 'white'); 
hold off 
xlabel('$C_p$'); ylabel('$z/b$'); box on ; grid on ; ax = gca; ax.FontSize = 18; ax.LineWidth =1 ; 


% % dP_zoc_pitot = abs(p_mean_zoc(31,2) - p_mean_zoc(32,2)).*6894.76 
% % U_zoc_check = (2 * abs(dP_zoc_pitot)./rho_air).^0.5 .* (dP_zoc_pitot ./ abs(dP_zoc_pitot))
% %P_zoc_check = [p_mean_zoc(29,1), p_mean_zoc(30,2)].*6894.76 % Tunnel static pressure ZOC comparison
% if ~isempty('J_casecompare') && exist('J_casecompare')
%     loaddata = load(J_casecompare, 'naca0012_Cp'); 
%     hold on 
%     scatter(taps_x_normalized, loaddata.naca0012_Cp, 'cyan', 'MarkerFaceColor', 'white')
%     set(gca, 'YDir','reverse')
%     for n = 1:numel(taps_x_normalized) % Labels results with pressure tap number
%         text(taps_x_normalized(n),loaddata.naca0012_Cp(n),num2str(n))
% 
%     end
% end
end


%% Acoustic-RMP
if RMP
    [volt_RMP_table, RMP_actual_rate] = getVoltages_30P30N_RMP(f_s_mic, t_s_mic, filt_delay); 

%%
    % Import RMP Transfer functions
    d = "F:\2025-10-00\RMP\Calibrations\";
    Txy = readtable(strcat(d, 'Txy_RMP_30P30N_2LMNT_SWEPT_update.txt'));
    Txy_filt = readtable(strcat(d, 'TxyFiltered_RMP_30P30N_2LMNT_SWEPT_update.txt'));
    loaddata = load('0_AoA_trip_220_grit_8_percent_SS_16.5cm_PS_11-15-2023_16-52', 'data_table', 'f_s_RMP', 'Txy');
        
    for i = [2:5:12, n_rmp, n_rmp+1]
        figure(); 
        [all_PSD(:,i-1), ~, Gpp(:,i-1), p_mic(:,i-1)] = getSpectraRMP_2(volt_RMP_table{:,i}./(0.0112*3), f_s, Txy.F, table2array(Txy(:,i-1))); %./(0.0112*3)
        [all_PSD_filt(:,i-1), f, Gpp_filt(:,i-1), p_mic_filt(:,i-1)] = getSpectraRMP_2(volt_RMP_table{:,i}./(0.0112*3), f_s, Txy_filt.F, table2array(Txy_filt(:,i-1)));

        [~, f_comp, Gpp_compare(:,i-1), ~] = getSpectraRMP_2(loaddata.data_table{:,i}, loaddata.f_s_RMP, loaddata.Txy.F, loaddata.Txy{:,i-1}); %./(0.0112*3)

        semilogx(f, 10*log10(Gpp(:,i-1)./20e-6^2))
        hold on 
        semilogx(f, 10*log10(Gpp_filt(:,i-1)./20e-6^2)) 
        hold on 
        semilogx(f_comp, 10*log10(Gpp_compare(:,i-1)./20e-6^2)) 
        hold off
        title(char(Txy.Properties.VariableNames(i-1)))
        xlim([70 10000])
        drawnow; 
%         savefig(['\\HAK_THINKBOOK\Users\rhaks\OneDrive - University of Toronto\PhD\ExperimentCampaigns\October2025\RMP\TroubleshootingFigs\',char(Txy.Properties.VariableNames(i-1))]); 
    end
    clear p_mic p_mic_filt Gpp Gpp_filt all_PSD all_PSD_filt Txy Txy_filt
    
    % clear v_mics_RMP %To avoid saving 2x the size file 

    if Acoustic
    mic_sens_DATA = [0.0035529];  %0.003596012959434 (mic sens for RMP-FF 2025 Oct.) BE SURE TO CHECK THAT THIS LOADS AND WASN'T OVERWRITTEN IN SAVED DATA
    figure(); hold on 
    for i = 1
        [mic_PSD(:, i), f] = mic_SPL(volt_RMP_table{:, n_rmp+2+i}, f_s, mic_sens_DATA(i), 'SPL', 1);
        plotMicSPLours(f, mic_PSD(:, i))
    end
%     comparemic = load(micfilecompare, 'volt_RMP_table'); 
    comparemic = load(micfilecompare, 'volt_time_mic', 'mic_sens'); 
%     ffmic_compare = comparemic.volt_RMP_table.Ref; clear comparemic 
    ffmic_compare = comparemic.volt_time_mic.A; clear comparemic 
%     [mic_PSD_compare, f] = mic_SPL(ffmic_compare, f_s, mic_sens, 'SPL', 1);
    [mic_PSD_compare, f] = mic_SPL(ffmic_compare, f_s, mic_sens(1), 'SPL', 1);
    plotMicSPLours(f, mic_PSD_compare)
    legend('Top Stow', 'Full Deploy')
    xlim([160 20e3])
    drawnow
    hold off
    end

end

%% ACOUSTIC ONLY
if Acoustic
    [volt_acoustic_table, Acoustic_actual_rate] = getVoltages_30P30N_Acoustic(f_s_mic, t_s_mic, filt_delay); 
    mic_sens_DATA = [0.0035529];  %0.003596012959434 (mic sens for RMP-FF 2025 Oct.) BE SURE TO CHECK THAT THIS LOADS AND WASN'T OVERWRITTEN IN SAVED DATA
    figure(); hold on 
    for i = 1
        [mic_PSD(:, i), f] = mic_SPL(volt_acoustic_table.Ref, f_s, mic_sens_DATA(i), 'SPL', 1);
        plotMicSPLours(f, mic_PSD(:, i))
    end
%     comparemic = load(micfilecompare, 'volt_time_mic', 'mic_sens'); 
%     ffmic_compare = comparemic.volt_time_mic.A; 
%     [mic_PSD_compare, f] = mic_SPL(ffmic_compare, f_s, comparemic.mic_sens(1), 'SPL', 1);
%     plotMicSPLours(f, mic_PSD_compare)
%     legend('New', 'Old')
%     xlim([160 20e3])
%     drawnow
%     hold off
% clear comparemic 
end

%%
if PMA
    load('mic_sens.mat'); 
    Array_Data_Collect(f_s_mic, t_s_mic, 'run', AoA,U_PT_mps, Re, CaseNo, 0); %Note: files are saved in the function
end
 %% Turn off wind tunnel
if off
disp('BEGIN Shutdown Wind Tunnel ----------------------------------------')
disp('     Turn off Tunnel')
AWT_Control_off((round(U_PT_mps)/60)*10);


disp('END Shutdown Wind Tunnel ------------------------------------------')
disp('-------------------------------------------------------------------')
disp('Waiting to settle'); 
% pause(120); 
end
%% Save data
% input('Press Enter to close figures and save: '); 
% pause(5); 
% close all

disp('BEGIN Saving of Results -------------------------------------------')
date_time = datestr(now, 'yyyy-mm-dd_HH-MM');
filename = strcat(num2str(CaseNo),'--','30P30N_Swept_Re', char(num2str(round(Re,-3))), '_', num2str(round(U_PT_mps)),'_mps_', 'Alpha', num2str(AoA), '_', date_time, '.mat');
save(['F:\2025-10-00\Acoustic\Background\' filename]);
% Close out program and clean up
temp = clock;
disp(['    Data Saved to ' filename]);
disp('END Saving of Results ---------------------------------------------')
disp('-------------------------------------------------------------------')
disp('-------------------------------------------------------------------')
disp('--------------------- PROGRAM COMPLETED ---------------------------')
disp('-------------------------------------------------------------------')

end