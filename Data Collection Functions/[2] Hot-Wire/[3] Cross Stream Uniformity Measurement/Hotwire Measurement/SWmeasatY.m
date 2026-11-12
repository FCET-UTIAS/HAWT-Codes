% This script is called from within hotwiresurvey.m to perform the hot-wire
% measurements.  It is only separate to keep things tidy, so is not written
% as a function.
% Heather Clark
% April 21, 2014

% Save temperature measurement before and after probe reading
T_read = zeros(2,1);
T_read(1) = Meas_T(); % measure initial temperature

% take readings from wires
try
    time = toc;
    Date = clock;
    [sw_e,pt_e,ActualRate] = Meas_SW_PT(t_samp, f_s);
catch
    try
        disp('Error taking velocity measurements.  Trying again...');
        pause(1);
        time = toc;
        Date = clock;
        [sw_e,pt_e,ActualRate] = Meas_SW_PT(t_samp, f_s);
    catch
        try
            disp('Error taking velocity measurements again.  Trying again...');
            pause(10);
            daqreset;
            pause(5);
            time = toc;
            Date = clock;
            [sw_e,pt_e,ActualRate] = Meas_SW_PT(t_samp, f_s);
        catch
            disp('THREE ERRORS READING VELOCITY.  Please check system.');
            disp('Run terminating.');
        end
    end
end

% save temperature
T_read(2) = Meas_T(); % measure final temperature
    
figure(1);
plot(sw_e);
ylabel('Voltage (V)');
title('Hot-wire voltage');

% Determine fluid properties
T = mean(T_read);
[rho_air,visc_air,~,~] = fluid_prop(T, P_atm_mmHg);

P   = (pt_e - P_offset_v) * P_gain;    % find pressure
Pm  = mean(P);                         % save mean pressure
ePm = mean(pt_e);                      % save electrical mean
up1 = (2 * abs(P)./rho_air).^0.5 .* (P ./ abs(P));
Up1  = mean(up1);  % just save mean Pitot tube velocity

figure(2);
plot(up1);
ylabel('u [m/s]');
title('Pitot tube reading');
clear up1 pt_e;

% Correct hot wire voltages for changes in temperature
ecorr_sw = ( (Tw_sw1-T_ref)/(Tw_sw1-T) )^Tcorr_co_SW * sw_e;

if (convertflag==1)  % convert to velocity if desired
    disp('hot-wire data conversion');
    u_sw = SW_data2vel(ecorr_sw, CALIB_SW, type);
    
    U_SW(jy) = mean(u_sw);   % this is just an estimate, based on what was converted
    figure(3);
    plot(U_SW(jy),yloc,'ro');
    xlabel('U (m/s)');
    ylabel('y-position [mm]');
    title(['Velocity Profile @ ' num2str(speed) 'm/s']);
    
    % estimate variance
    usq_SW(jy) = mean((u_sw - U_SW(jy)).^2/U_SW(jy)^2);
    figure(4);
    plot(usq_SW(jy),yloc,'ms');
    xlabel('normalized variance');
    ylabel('y-position [mm]');
    title(['Variance @ ' num2str(speed) 'm/s']);
    
end

disp('CURRENT FLOW CHARACTERISTICS:')
disp(['    T = ' num2str(T, '%10.2f') ' deg C']);
disp([' U_pt = ' num2str(Up1, '%10.2f') ' m/s']);
disp([' U_sw = ' num2str(U_SW(jy),  '%10.2f') ' m/s']);

% Save run
% cd SWData
% disp(['Saving data from run to: ' filename '_Y' int2str(jy) '.mat']);
% save([filename '_Y' int2str(jy) '.mat'], ...
%     'ecorr_sw1', 'sw_e', ...
%     'ActualRate', 'visc_air', 'rho_air', 'T', 'T_ref', 'P_atm_mmHg', ...
%     'Up1', 'Pm', 'ePm', 'P_offset_v', 'yloc', 'Date', 'time');
% cd ../

BL_Data.(fieldname).HW_correction=ecorr_sw;
BL_Data.(fieldname).HW_voltage=sw_e;
BL_Data.(fieldname).U_SW=U_SW(jy);
BL_Data.(fieldname).Actual_Rate=ActualRate;
BL_Data.(fieldname).visc_air=visc_air;
BL_Data.(fieldname).rho_air=rho_air;
BL_Data.(fieldname).T_mean=T;
BL_Data.(fieldname).T_ref=T_ref;
BL_Data.(fieldname).P_atm_mmHg=P_atm_mmHg;
BL_Data.(fieldname).U_mean_pitot=Up1;
BL_Data.(fieldname).P_meam=Pm;
BL_Data.(fieldname).PT_e_mean=ePm;
BL_Data.(fieldname).P_offset_v=P_offset_v;
BL_Data.(fieldname).yloc=yloc;
BL_Data.(fieldname).Steps_from_home=y_sfh;
BL_Data.(fieldname).Date=Date;
BL_Data.(fieldname).time=time;