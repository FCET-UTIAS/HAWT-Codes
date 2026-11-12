function [meanvelocity, time, voltagetimeseries, pressuretimeseries] = measurePitotTube(f_s, t_samp, P_atm_kPa)
    s1 = daq.createSession('ni');
    s1.Rate = f_s;
    s1.DurationInSeconds= t_samp;
    chans_PT = s1.addAnalogInputChannel('Dev5', 7, 'Voltage'); %Temperature compensated baratron in HAWT
    set(s1.Channels, 'TerminalConfig', 'Differential');


    load('U_calib_Both_hybrid10-28-2022_13-15.mat','Cal_coef_100Torr','Cal_coef_10Torr')
    range = 100; 
    PT_gain = 133.322*range/10;
    % Ambient properties
    P_atm_mmHg = P_atm_kPa * 7.50062;
    gamma_air = 1.4;  % Ratio of thermal coeffs
    R_air = 287;  % Gas constant for air [kJ/kg-K]
    % Other constants
    T0 = 273.15;  % Zero degrees C in Kelvin
    Temp = gimmeTemp(); 

    %% Perform offset
    do_zerobaratron = input('Re-zero the Baratrons? 1 if yes, 0 if no: ');
    if do_zerobaratron
        v_fs_offset = Baratron_offsetTwoBaratron(PT_f_s, PT_t_s);
        v_fs_offset_time = date_time;
        save latest_offset v_fs_offset v_fs_offset_time
    else
        load latest_offset.mat v_fs_offset v_fs_offset_time
    end



    disp('Measuring Pressure...')
    [voltagetimeseries, time] = startForeground(s1); %voltage time series of pressure data from Pitot tube


    
    pressuretimeseries = (voltagetimeseries - v_fs_offset(2)) .* PT_gain';
    [rho_air, ~, ~, ~] = fluid_prop(T, P_atm_mmHg); 

    U_timeseries = (2.*pressuretimeseries./rho_air).^0.5; 

    meanvelocity = mean(U_timeseries); 





end