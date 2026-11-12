% This script is called from within hotwiresurvey.m to perform the hot-wire
% measurements.  It is only separate to keep things tidy, so is not written
% as a function.
% Heather Clark
% April 21, 2014

% save temperature measurement before and after probe reading
T_read = zeros(2,1);
% measure the temperature
T_read(1) = TC_Omega_FCETdaq(1.5, 1000); % measure temperature

% take readings from wires
time = toc;
Date = clock;
[pt_e,er_sw1_1,er_sw1_2,~,ActualRate] = Meas_PT_2SW_Ve(f_s, t_samp, Nfft);

% save temperature
T_read(2) = TC_Omega_FCETdaq(1.5, 1000); % measure temperature

figure(1);
plot(er_sw1_1); ylabel('Voltage (V)'); title('Hot-wire 1 voltage');

figure(2);
plot(er_sw1_2); ylabel('Voltage (V)'); title('Hot-wire 2 voltage');

T = mean(T_read);
% Determine fluid properties
[rho_air,visc_air,~,~] = fluid_prop(T, P_atm_mmHg);

P   = (pt_e - P_offset_v) * P_gain;    % find pressure
Pm  = mean(P);                         % save mean pressure
ePm = mean(pt_e);                      % save electrical mean
up1 = (2 * abs(P)./rho_air).^0.5 .* (P ./ abs(P));
Up1  = mean(up1);  % just save mean Pitot tube velocity
figure(3);
plot(up1); ylabel('u [m/s]'); title('Pitot tube reading');
clear up1 pt_e;

% Correct hot wire voltages for changes in temperature
ecorr_sw1_1 = ( (Tw_sw1_1-T_ref_1)/(Tw_sw1_1-T) )^Tcorr_co_SW * er_sw1_1;
ecorr_sw1_2 = ( (Tw_sw1_2-T_ref_2)/(Tw_sw1_2-T) )^Tcorr_co_SW * er_sw1_2;

if (convertflag==1)  % convert to velocity if desired
    disp('hot-wire data conversion');
    u_sw1_1 = SW_data2vel(ecorr_sw1_1, CALIB_SW_1, type);
    u_sw1_2 = SW_data2vel(ecorr_sw1_2, CALIB_SW_2, type);
    
    U_SW_1(jx) = mean(u_sw1_1);   % this is just an estimate, based on what was converted
    figure(4);
    plot(U_SW_1(jx),xloc/inchtocm,'ro');
    xlabel('U (m/s)'); ylabel('x/d');
    
    U_SW_2(jx) = mean(u_sw1_2);   % this is just an estimate, based on what was converted
    figure(5);
    plot(U_SW_2(jx),xloc/inchtocm,'ro');
    xlabel('U (m/s)'); ylabel('x/d');
    
    % estimate variance
    usq_SW_1(jx) = mean((u_sw1_1 - U_SW_1(jx)).^2/U_SW_1(jx)^2);
    figure(6);
    plot(usq_SW_1(jx),xloc/inchtocm,'ms');
    xlabel('normalized variance'); ylabel('x/d');
    
    usq_SW_2(jx) = mean((u_sw1_2 - U_SW_2(jx)).^2/U_SW_2(jx)^2);
    figure(7);
    plot(usq_SW_2(jx),xloc/inchtocm,'ms');
    xlabel('normalized variance'); ylabel('x/d');
    
    uvar_SW_1(jx) = var(u_sw1_1);
    figure(8);
    plot(uvar_SW_1(jx),xloc/inchtocm,'ms');
    xlabel('variance'); ylabel('x/d');
    
    uvar_SW_2(jx) = var(u_sw1_2);
    figure(9);
    plot(uvar_SW_2(jx),xloc/inchtocm,'ms');
    xlabel('variance'); ylabel('x/d');
end

disp('CURRENT FLOW CHARACTERISTICS:')
disp(['    T = ' num2str(T, '%10.2f') ' deg C']);
disp([' U_pt = ' num2str(Up1, '%10.2f') ' m/s']);
disp([' U_sw_1 = ' num2str(U_SW_1(jx),  '%10.2f') ' m/s']);
disp([' U_sw_2 = ' num2str(U_SW_2(jx),  '%10.2f') ' m/s']);

% Save run
cd SWData
disp(['Saving data from run to: ' filename '_1_X' int2str(jx) '_Y' int2str(jy) '_Z' int2str(jz) '.mat']);
save([filename '_1_X' int2str(jx) '_Y' int2str(jy) '_Z' int2str(jz) '.mat'], ...
    'ecorr_sw1_1', 'er_sw1_1', ...
    'ActualRate', 'visc_air', 'rho_air', 'T', 'T_ref_1', 'P_atm_mmHg', ...
    'Up1', 'Pm', 'ePm', 'P_offset_v', 'xloc', 'yloc', 'zloc', 'Date', 'time');
disp(['Saving data from run to: ' filename '_2_X' int2str(jx) '_Y' int2str(jy) '_Z' int2str(jz) '.mat']);
save([filename '_2_X' int2str(jx) '_Y' int2str(jy) '_Z' int2str(jz) '.mat'], ...
    'ecorr_sw1_2', 'er_sw1_2', ...
    'ActualRate', 'visc_air', 'rho_air', 'T', 'T_ref_2', 'P_atm_mmHg', ...
    'Up1', 'Pm', 'ePm', 'P_offset_v', 'xloc', 'yloc', 'zloc', 'Date', 'time');
cd ..\