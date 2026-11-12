%NOTE: CHECK SPECTRUM/PSD METHOD BY SEEING IF THINGS INTEGRATE TO THE
%VARIANCE

function Tu = Turbulence_Intensity_Calc(caseNo, filetype)
    
    if upper(string(filetype)) == "CALIB"
%%       
        % Load voltage data
        % repairHWCalibration(caseNo)
        filename = find_file(caseNo, {'H:\2025-07-00\TurbulenceIntensity\HWCalibrations\'}); 
        load(filename, 'er_sw_orig_mov','T_ref','T','HW_WireT_degC_mov','Up_adj', 'CALIB_SW_MOV','f_s_HW', 'Tcorr_co_SW'); %'er_sw_orig_stat','HW_WireT_degC_stat', 'CALIB_SW_STAT', 
        
        % Convert HW data from voltage to velocity
        for i = 1:size(er_sw_orig_mov, 2)
            e_tempcompensated_mov{:,i} = (( (HW_WireT_degC_mov-T_ref)./(HW_WireT_degC_mov-T(i)) ).^Tcorr_co_SW) .* er_sw_orig_mov{i}';          % Temperature correction for HWdata
%             e_tempcompensated_stat{:,i} = (( (HW_WireT_degC_stat-T_ref)./(HW_WireT_degC_stat-T(i)) ).^Tcorr_co_SW) .* er_sw_orig_stat{i}';          % Temperature correction for HWdata
    
            u_timeseries_mov{:,i} = SW_data2vel(e_tempcompensated_mov{:,i},CALIB_SW_MOV,'king'); u_mov(i) = mean(u_timeseries_mov{:,i}); 
%             u_timeseries_stat{:,i} = SW_data2vel(e_tempcompensated_stat{:,i},CALIB_SW_STAT,'king'); u_stat(i) = mean(u_timeseries_stat{:,i}); 
        end
%%
        % Calculate Tu
        for i = 1:11
            LL = length(u_timeseries_mov{:,i}); 
            windowparam = 64; 
            % fidx = 1:LL; 

            % signalFFT_mov = abs(fft(u_timeseries_mov{:,i}-u_mov(i))) / LL; 
            % signalFFT_stat = abs(fft(u_timeseries_stat{:,i}-u_stat(i))) / LL; 
            % 
            % psd_mov = 2*(signalFFT_mov.*(signalFFT_mov/df)); 
            % psd_stat = 2*(signalFFT_stat.*(signalFFT_stat/df));

            [psd_mov{i}, f]         = pwelch(u_timeseries_mov{:,i}-u_mov(i), LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_HW);
%             [psd_stat{i}, ~]        = pwelch(u_timeseries_stat{:,i}-u_stat(i), LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_HW);

            df = mean(diff(f));  
            fmins = Up_adj./(2*3.56); 
            fmin = fmins(i); % minimum frequency for turbulent range, in Hz
            fmax = 10000; % maximum frequency for turbulent range, in Hz
            % fidx = find(round(f) == round(fmin)):find(round(f) == fmax); 

            fidx = find(df*(0:LL-1) >= fmin & df*(0:LL-1) <= fmax); % frequency indices in range


            rms_vel_fluct_mov(i) = sqrt(sum( psd_mov{i}(fidx) .* df )); % RMS velocity fluctuations
%             rms_vel_fluct_stat(i) = sqrt(sum( psd_stat{i}(fidx) .* df )); % RMS velocity fluctuations

            % rms_vel_fluct_mov(i) = sqrt(sum( psd_mov{i} .* df )); % RMS velocity fluctuations
            % rms_vel_fluct_stat(i) = sqrt(sum( psd_stat{i} .* df )); % RMS velocity fluctuations
            % rms_mov_check(i) = rms(u_timeseries_mov{:,i}-u_mov(i));
            % rms_stat_check(i) = rms(u_timeseries_stat{:,i}-u_stat(i));


            Tu_mov(i) = rms_vel_fluct_mov(i) / u_mov(i) * 100; % turbulence intensity as a percentage
%             Tu_stat(i) = rms_vel_fluct_stat(i) / u_stat(i) * 100; % turbulence intensity as a percentage
        
            Tu_mov2(i) = rms(u_timeseries_mov{:,i}-u_mov(i))/u_mov(i) * 100; 
%             Tu_stat2(i) = rms(u_timeseries_stat{:,i}-u_stat(i))/u_stat(i) * 100; 
        
        end

%%
        % Plot spectra (premultiplied and regular)
        for i = 1:11
            LL = length(u_timeseries_mov{:,i});
            [Gdat_mov, f]         = pwelch(u_timeseries_mov{:,i}-u_mov(i), LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_HW);
%             [Gdat_stat, f]        = pwelch(u_timeseries_stat{:,i}-u_stat(i), LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_HW);

            f1 = figure(1); 
            subplot(4,3,i)
            loglog(f,Gdat_mov, 'LineWidth',1)
%             hold on 
%             loglog(f,Gdat_stat,'LineWidth',1)
%             hold off
            legend(['Moving wire, $T_{u} =$ ', char(string(Tu_mov(i))), '%'],  'iterpreter', 'latex'); %['Stationary Wire, $T_{u} =$ ', char(string(Tu_stat(i))), '%'],
            xlabel('Frequency [Hz]', 'Interpreter','latex')
            ylabel('$S_{uu}$ [m$^{2}$/s]', 'Interpreter','latex')
            title(['$U_{\infty} =$ ', char(string(Up_adj(i))),'m/s'], 'Interpreter','latex')
            grid on 
            xlim([1,9000])

            f2 = figure(2); 
            subplot(4,3,i)
            semilogx(f,f.*Gdat_mov, 'LineWidth',1)
%             hold on 
%             semilogx(f,f.*Gdat_stat,'LineWidth',1)
%             hold off
            legend(['Moving wire, $T_{u} =$ ', char(string(Tu_mov(i))), '%'], 'iterpreter', 'latex'); %['Stationary Wire, $T_{u} =$ ', char(string(Tu_stat(i))), '%'], 
            xlabel('Frequency [Hz]', 'Interpreter','latex')
            ylabel('$f*S_{uu}$ [(m/s)$^{2}$]', 'Interpreter','latex')
            title(['$U_{\infty} =$ ', char(string(Up_adj(i))),'m/s'], 'Interpreter','latex')
            grid on 
            xlim([1,9000])

        end
%%
    elseif upper(string(filetype)) == "OLDDATA"
        %%
        filepath = 'E:\March-April 2023\Turbulence Intensity\230404 Data\Center of tunnel data\'; 
        speed = input('Which speed which you like to analyze (20/30/40/50/53 m/s)?: '); 
        filepattern = fullfile(filepath, '*.mat'); 
        filecell = dir(filepattern);
        for i = 1:size(filecell,1)
            split = strsplit(filecell(i).name, ' '); 
            if round(str2double(split{3})) == speed
                break
            end
        end

        filename = fullfile(filepath,filecell(i).name);
        load(filename, 'CALIB_SW','Gain','Offset_V','HW_V','T','HW_WireT_degC', 'Up', 'f_s', 'ActualRate', 't_samp');
        Offset_V = -1.76; 
        T_ref = 9.14;
        Tcorr_co_SW = 0.5; 
        er_sw_orig = HW_V./Gain - Offset_V;
        er_sw_tc = (( (HW_WireT_degC-T_ref)./(HW_WireT_degC-T) ).^Tcorr_co_SW) .* er_sw_orig';
        u_timeseries = SW_data2vel(er_sw_tc,CALIB_SW,'king'); u = mean(u_timeseries); 
        u_timeseries = u_timeseries(1:(t_samp*f_s));

        %Downsample from 200kHz to 2^15Hz       
        tvec_in = (1/f_s):(1/f_s):(t_samp); 
        f_s_out = 2^15; 
        tvec_out = (1/f_s_out):(1/f_s_out):t_samp; 
        u_timeseries = timeseries(u_timeseries,tvec_in); 
        u_timeseries = resample(u_timeseries, tvec_out); 
        u_timeseries = timeseries2timetable(u_timeseries);
        u_timeseries = u_timeseries.Data;  

        LL = length(u_timeseries); 
        windowparam = 64; 
        % fidx = 1:LL; 

        % signalFFT_mov = abs(fft(u_timeseries_mov{:,i}-u_mov(i))) / LL; 
        % signalFFT_stat = abs(fft(u_timeseries_stat{:,i}-u_stat(i))) / LL; 
        % 
        % psd_mov = 2*(signalFFT_mov.*(signalFFT_mov/df)); 
        % psd_stat = 2*(signalFFT_stat.*(signalFFT_stat/df));

        [psd, f]         = pwelch(u_timeseries-u, LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_out);
        
        df = mean(diff(f));  
        fmins = Up./(2*3.56); 
        fmin = fmins(2); % minimum frequency for turbulent range, in Hz
        fmax = 5000; % maximum frequency for turbulent range, in Hz
        % fidx = find(round(f) == round(fmin)):find(round(f) == fmax);
        fidx = find(df*(0:LL-1) >= fmin & df*(0:LL-1) <= fmax);

        rms_vel_fluct = sqrt(sum( psd(fidx) .* df )); % RMS velocity fluctuations
        Tu = rms_vel_fluct / u * 100; % turbulence intensity as a percentage
        Tu2 = rms(u_timeseries-u)/u * 100; 
        
        [Gdat, f_plot]         = pwelch(u_timeseries-u, LL/windowparam, round(0.75*LL/windowparam), LL/windowparam, f_s_out);
        f1 = figure(1); 
        loglog(f_plot,Gdat, 'LineWidth',1)
        legend(['Single Wire, $T_{u} =$ ', char(string(Tu)), '%'], 'Interpreter', 'latex')
        xlabel('Frequency [Hz]', 'Interpreter','latex')
        ylabel('$S_{uu}$ [m$^{2}$/s]', 'Interpreter','latex')
        title(['$U_{\infty} =$ ', char(string(Up(2))),'m/s'], 'Interpreter','latex')
        grid on 
        xlim([1,1000])

        f2 = figure(2);
        semilogx(f_plot,f_plot.*Gdat, 'LineWidth',1)
        legend(['Moving wire, $T_{u} =$ ', char(string(Tu)), '%'], 'Interpreter', 'latex')
        xlabel('Frequency [Hz]', 'Interpreter','latex')
        ylabel('$f*S_{uu}$ [(m/s)$^{2}$]', 'Interpreter','latex')
        title(['$U_{\infty} =$ ', char(string(Up(2))),'m/s'], 'Interpreter','latex')
        grid on 
        xlim([1,1000])
    end
    
    
    %     load('H:\March-April 2023\Turbulence Intensity\Testing\Hotwire Testing 54.2125 mps - 230403_12-33.mat', 'HW_V'); % for testing
    HW_WireT_degC = 261; %Wire Temperature (Overtemp)               %For Testing
    HW_RefT_degC = 31.7; %Reference temperature from StreamLine     %For Testing
    T = 31.5;                                                    %For Testing

%     load(filename, 'HW_V', 'HW_WireT_degC', 'HW_RefT_degC', 'T'); 
    
%     load('H:\March-April 2023\Turbulence Intensity\Testing\First Calibration\HWCalibration_230403_15-26.mat_CALIBSW.mat', 'Gain', 'Offset_V', 'Tcorr_co_SW', 'CALIB_SW', 'fs_hz'); 
%     load(calibrationfilename, 'Gain', 'Offset_V', 'HW_WireT_degC', 'HW_RefT_degC', 'Tcorr_co_SW', 'CALIB_SW', 'fs_hz'); 
    

    % Remvoe gain and offset from voltage
    er_sw_orig               =  HW_V./Gain - Offset_V;

    % Apply temperature compensation
    T_ref = HW_RefT_degC;
    e_tempcompensated = (( (HW_WireT_degC-T_ref)./(HW_WireT_degC-T) ).^Tcorr_co_SW) .* er_sw_orig';          % Temperature correction for HWdata
    

    u_timeseries = SW_data2vel(e_tempcompensated,CALIB_SW,'king'); 

% Calculate PSD of velocity data
    Fs = fs_hz; % sampling frequency in Hz, replace with your data sampling frequency
   
    LL = length(u_timeseries); 

%Suraj's code for PSD 
%     [psd, f]         = pwelch(u_timeseries-mean(u_timeseries), LL/16, round(0.75*LL/16), LL/16, Fs);
   

%Online source
%(https://www.mathworks.com/matlabcentral/answers/82182-rms-power-in-signal-time-series-vs-frequency-series-psd-rms-definition)
    signalFFT = abs(fft(u_timeseries-mean(u_timeseries))) / LL; 
    df = Fs/LL; 
    psd = 2*(signalFFT.*(signalFFT/df)); 
    f = Fs/2; 

%Hadar's Code: 
%     nfft = 2^nextpow2(LL); % number of points in FFT, should be power of 2 
%     psd = abs(fft(signal, nfft)).^2 / (Fs * nfft); % power spectral density - you can calculate it using fft function or pwelch function...

% Calculate RMS velocity fluctuations
    fmin = 10; % minimum frequency for turbulent range, in Hz
    fmax = 1000; % maximum frequency for turbulent range, in Hz
    df = Fs / LL; % frequency resolution
    fidx = find(df*(0:LL-1) >= fmin & df*(0:LL-1) <= fmax); % frequency indices in range
    rms_vel_fluct = sqrt(sum( psd(fidx) .* df )); % RMS velocity fluctuations

% Calculate mean velocity
    % mean_vel = sum(psd) * df; % mean velocity
%     mean_vel = mean(u_timeseries); 

% Calculate turbulence intensity
    Tu = rms_vel_fluct / mean_vel * 100; % turbulence intensity as a percentage

% Display turbulence intensity
    fprintf('Turbulence intensity: %.2f%%\n', Tu);

% end

loglog(f, psd)

%% Calculating using Full Signal
Vinf_mps_mean   = mean(u_timeseries);
Vprime_mps      = u_timeseries - Vinf_mps_mean;

sum1 = 0;
for i = 1:length(Vprime_mps)
    
    sum1 = sum1 + Vprime_mps(i)^2;
    
end

Vprime_mps_squaresum = sum1;

Vrms_mps = sqrt(Vprime_mps_squaresum/length(Vprime_mps));

Tupercent = Vrms_mps * 100 / Vinf_mps_mean