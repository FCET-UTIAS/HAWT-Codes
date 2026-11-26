%---------------------------------------------------------------------------
% mainZOCmeas - Script to measure Cp data with the ZOC pressure modules
% Description: Part of the AoA correction procedure (step 3: measure
% Kevlar-walled CL-alpha_g data at about 50 m/s). Asks for the ice shape
% configuration, AoA type, ZOC configuration and the current temperature and
% atmospheric pressure, sets up the Baratron offset, and zeroes the ZOC
% modules. Then turns the tunnel on and, for each angle of attack in AoAvec
% and each Reynolds number in ReVec, rotates the AoA slew drive, sets the
% tunnel speed, scans the ZOC pressure modules, re-measures the speed, groups
% the pressures by tap group (A, B, C), plots them, and saves the workspace
% and figures. The tunnel is turned off at the end. Step 4 (comparing the
% results to show the curves match) is not part of this script.
%
% Two plots are made for every condition. Figure 1 is normalized by the
% tunnel (contraction) dynamic pressure q, calculated from the speed measured
% after the ZOC scan. Figure 2 is normalized by the pitot tube total pressure
% read by each ZOC module (channel 31 of M270, channel 31 of M273, channel 32
% of M275), from the July 14, 2026 troubleshooting. The ZOC is zeroed once at
% the start, and a timer prints the time since the zero for every condition
% so that offset drift can be judged. The 95% precision uncertainty of each
% pressure is calculated and saved. Data are saved to the PMA_zeroFind
% folder.
%
% INPUTS: Prompted: ice shape configuration [C, GS, GR1, GR2, GR3], AoA type
%         (geometric/effective), ZOC configuration, temperature (deg C) and
%         atmospheric pressure (kPa) from Pearson, whether the Baratron
%         offset needs correcting (Y/N, and the calibration file if N),
%         confirmation that the AoA is zero, the pressure source is on and
%         the Baratron range is 100 torr. Set in the script: ReVec, AoAvec,
%         TripStatus.
% OUTPUTS: For each condition, a .mat file (whole workspace), a .fig file of
%          the tunnel q plot and a _pitot.fig file of the pitot plot, saved
%          to F:\ExCamp2\Data\Cp\PMA_zeroFind, named
%          ZOC=<Re>_<ShapeConfig>_AoA=<AoA>(<AoAtype>)_<CpConfig>_
%          <TripStatus>_<date_time>
%
% FUNCTIONS: (functions this script uses)
%   Called directly by the script:
%     BaratronCalibration         - measures the Baratron zero offset
%                                   (v_fs_offset) when "Y" is chosen
%     Meas_T_PS                   - reads the air temperature (T) with the
%                                   Baratron DAQ
%     fluid_prop                  - air density and viscosity from
%                                   temperature and pressure (mmHg)
%     funcAoAcorrection           - converts the AoA list between geometric
%                                   and effective angle ('findKg', 'tip')
%     funcZOCconfigurationDefinition - ZOC port groups (A, B, C) and tap x/c
%                                   locations for the chosen CpConfig
%     ZOC_quick_scan_2            - scans the ZOC modules (voltages, means,
%                                   standard deviations, serial numbers);
%                                   used once to zero and once per condition
%                                   to measure
%     AWT_Control_on              - turns the tunnel on
%     AWT_Control_Integrated_func - sets the target speed and corrects it
%                                   until it is on target
%     AWTspeedMeasurementFunc     - measures the speed and Mach number
%                                   after the Cp scan
%     MCslewfunc                  - rotates the AoA slew drive
%     AWT_Control_off             - shuts the tunnel off (called with 1, so
%                                   the ramp-down loop is skipped)
%   Called inside those functions:
%     AWT_Control_setVref         - sets the motor controller voltage
%                                   reference (used by AWT_Control_on,
%                                   AWT_Control_off and
%                                   AWT_Control_Integrated_func)
%     AWT_Control_U2V_Creighton   - converts speed to voltage (used by
%                                   AWT_Control_Integrated_func)
%     MC_open_traverse_talk, MC_init, MC_select_motor, MC_move_stepper,
%     MC_quit                     - motor control box communication and
%                                   motion (used by MCslewfunc)
%   Data files loaded:
%     M270_gain.mat, M273_gain.mat, M275_gain.mat - ZOC module
%                                   sensitivities (volts to psi)
%     Baratron calibration .mat   - chosen with uigetfile when "N" is chosen
%
% HISTORY: 
%   July 14, 2026 - troubleshooting snippet added (pressures normalized by
%                   the pitot total pressure of each ZOC module)
%   November 2026 - plots for both the tunnel dynamic pressure and the pitot
%                   pressure; timer printing the time since the ZOC was
%                   zeroed
% 
%---------------------------------------------------------------------------

%% mainAoAcorrection
% 3. Measures Kevlar-walled CL-alpha_g data at 50 m/s
% 4. Compare the result to show the curves match
clc;
clear all
%lose all

%%
driveName=pwd;
driveName=driveName(1);
addpath(genpath(strcat(driveName,':\ExCamp2\CalibrationData'))) % Add all relevant folders
addpath(genpath(strcat(driveName,':\ExCamp2\ConfigurationData')))
addpath(genpath(strcat(driveName,':\ExCamp2\Subfunctions')))
addpath(genpath(strcat(driveName,':\ExCamp2\AWTcontrol')))
%addpath(genpath(strcat(driveName,':\ExCamp2\ValidationData\LinArray\Uinf')))

ShapeConfig=input('Enter the ice shape configuration [C, GS, GR1, GR2, GR3]: ','s');

AoAtype=input('Choose between geometric or effective AoA (geometric/effective): ','s');
CpConfig=input('Choose the ZOC configuration [Standard]: ','s'); %Standard always? 

pause(1)

ReVec=[1]*10^6;
AoAvec= [0];

TempCelcOnline=input('Input the current temperature from Pearson in Celcius.');
PresKPascOnline=input('Input the current atmospheric pressure in kPa.');

% Confirm the input
disp('Confirmation:')
disp(strcat('Atmospheric temperature:',num2str(TempCelcOnline),' c'))
disp(strcat('Atmospheric pressure:',num2str(PresKPascOnline),' kPa'))
pause(0.5)
input('Hit enter to continue.');
pause(0.5)

TripStatus="Glaze";  %="Trip220-10%";

input('Confirm that the AoA is zero on the turn table.')
input('Confirm that the pressure source is on.')

% Baratron calibration
BaratronChoice=input('Choose if offset correction of Baratron is necessary [Y/N]','s');
if strcmp(BaratronChoice,'N')
    disp('Choose the calibration constant ...')
    pause(0.5)
    OldPath=cd(strcat(driveName,':\ExCamp2\CalibrationData\BaratronCalibration'));
    BaratronCalibrationFileName=uigetfile;
    BaratronOffset=load(BaratronCalibrationFileName);
    cd(OldPath);
    clear OldPath
elseif strcmp(BaratronChoice,'Y')
    [v_fs_offset,fs_Baratron,ts_Baratron,T,PT_e]=BaratronCalibration;
    BaratronOffset=v_fs_offset;
    disp('Done. Saving the result ...')
    OldPath=cd(strcat(driveName,':\ExCamp2\CalibrationData\BaratronCalibration'));
    data_time=datestr(now,'mm-dd-yyyy_HH-MM');
    save(strcat('BaratronCalibration_', data_time,".mat"),"date_time","");
    cd(OldPath);
    clear OldPath
else
    disp('Invalid choice')
end

input("Confirm that the Baratron range is set to 100 torr");
BaratronRange=100;

%% Initialize
c=12*0.0254; % chord= 12 in

fs_Baratron=4000;
[T,~] = Meas_T_PS(fs_Baratron, 15);
P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(T, P_atm_mmHg);
nuAtm=muAtm/rhoAtm;
R=287; % J/kg/K


% Convert the angle of attack from geometric to effective, if necessary.
AoAevec=AoAvec;
if strcmp(AoAtype,'effective')
    AoAvec=funcAoAcorrection(AoAvec,'findKg','tip');
end


% ZOC parameters
f_sZOC = 40000;
time_per_sensor_in_a_loop = 0.1;
no_of_loops = 5;

%% Define the ZOC
ZOCconfig=funcZOCconfigurationDefinition(CpConfig);

%% Zero the ZOC
disp("Zeroing the ZOC...")
[read_back_bias, Volt_bias, time_ZOC_bias, Volt_bias_mean, Volt_std_bias, serialnums] = ZOC_quick_scan_2(f_sZOC,time_per_sensor_in_a_loop,no_of_loops);
zeroTimer = tic;                                % start timer: time since the ZOC was zeroed
zero_time = datestr(now,'mm-dd-yyyy_HH-MM');    % clock time of the zero
Volt_bias_mean(:,1)=Volt_bias_mean(:,1);
Volt_bias_mean(:,2)=Volt_bias_mean(:,2);
Volt_bias_mean(:,3)=Volt_bias_mean(:,3);

addpath(strcat(driveName,":\ExCamp2\Subfunctions\ZOC\NRC_ZOCs_Cal_files\CAL_files_gains_only"));
load("M270_gain.mat");
load("M273_gain.mat");
load("M275_gain.mat");
ZOCsensitivity=[M270_gain, M273_gain M275_gain];
disp("Zeroing finished.")


%% Loop through the conditions
AWT_Control_on
start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');
for AoAind=1:length(AoAvec)
    start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');
    if AoAind~=1
        % Change the AoA
        disp(strcat('Actuating the AoA to ',num2str(AoAvec(AoAind)),'deg'))
        MCslewfunc(abs(AoAvec(AoAind))-abs(AoAvec(AoAind-1)),'-')
    elseif AoAvec(AoAind)~=0
        if AoAvec(AoAind)>0
            MCslewfunc(AoAvec(AoAind),'+')
        else
            MCslewfunc(abs(AoAvec(AoAind)),'-')
        end
    end
    disp(strcat('AoA is at',num2str(AoAvec(AoAind)),'deg'))


    for ReInd=1:length(ReVec)
        % Set target speed
        ReTarget=ReVec(ReInd);
        Utarget=ReTarget*nuAtm/c;
        status=AWT_Control_Integrated_func(Utarget,PresKPascOnline,T,BaratronOffset.v_fs_offset,"Uinf");
        disp(strcat('Speed target:',num2str(Utarget),'. Final speed: ',num2str(status.Ufinal),'. Begin measurement.'))
        
        %% Measure 
        disp(strcat('Measuring Cp'));
        status_LinArray.UmeasBefore=status.Ufinal;
        status_LinArray.MaMeasBefore=status.MaFinal;
        status_LinArray.stdUmeasBefore=status.stdUfinal;
        status_LinArray.timeBefore=datestr(now,'mm-dd-yyyy_HH-MM');
    

        %fileName=ZOCcalibration(TempCelcOnline,PresKPascOnline);
        N=no_of_loops*time_per_sensor_in_a_loop*f_sZOC;

        [read_back, Volt, time_ZOC, Volt_mean, Volt_std, serialnums] = ZOC_quick_scan_2(f_sZOC,time_per_sensor_in_a_loop,no_of_loops);

        % Time since the ZOC was zeroed, at the moment of this measurement
        t_since_zero_min = toc(zeroTimer)/60;   % minutes
        disp(['Time since the ZOC was zeroed: ' num2str(t_since_zero_min,'%.1f') ' min (zeroed at ' zero_time ')'])

        Volt_mean(:,1)=Volt_mean(:,1);
        Volt_mean(:,2)=Volt_mean(:,2);
        Volt_mean(:,3)=Volt_mean(:,3);
        Volt_std(:,1)=Volt_std(:,1);
        Volt_std(:,2)=Volt_std(:,2);
        Volt_std(:,3)=Volt_std(:,3);


        p_mean_psi=(Volt_mean-Volt_bias_mean).*ZOCsensitivity;

        PmeanPsiStdDev=(Volt_std+Volt_std_bias).*ZOCsensitivity; % Uncertainty in sensitivity is not taken in count. Should be.
        PrecisionUncertaintyPsi=1.96*PmeanPsiStdDev/sqrt(N);
    
        [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(PresKPascOnline,BaratronOffset.v_fs_offset,BaratronRange);
        status_LinArray.UmeasAfter=Ufinal;
        status_LinArray.MaMeasAfter=MaFinal;
        status_LinArray.stdUmeasAfter=stdUfinal;

        status_LinArray.timeAfter=datestr(now,'mm-dd-yyyy_HH-MM');


        p_mean_Pa_temp=p_mean_psi*6894.75729; % Convert psi to Pascal and re-shape it into a single vector.

        p_mean_Pa_temp=[p_mean_Pa_temp(:,1);p_mean_Pa_temp(:,2);p_mean_Pa_temp(:,3) ];
        PrecisionUncertaintyPa=PrecisionUncertaintyPsi*6894.75729;
        PrecisionUncertaintyPa=[PrecisionUncertaintyPa(:,1);PrecisionUncertaintyPa(:,2); PrecisionUncertaintyPa(:,3)];
        
        P_Pa.A.Pmean=p_mean_Pa_temp(ZOCconfig.A.PortID); % Rearrange the measured pressure based on the pressure tap groups
        P_Pa.B.Pmean=p_mean_Pa_temp(ZOCconfig.B.PortID);
        P_Pa.C.Pmean=p_mean_Pa_temp(ZOCconfig.C.PortID);
        P_Pa.A.PrecisionUncertainty=PrecisionUncertaintyPa(ZOCconfig.A.PortID);
        P_Pa.B.PrecisionUncertainty=PrecisionUncertaintyPa(ZOCconfig.B.PortID);
        P_Pa.C.PrecisionUncertainty=PrecisionUncertaintyPa(ZOCconfig.C.PortID);
        

        %% Pitot pressures - troubleshooting snippet - July 14, 2026
        
        q_270 = p_mean_Pa_temp(31); %Ptotal from pitot tube connected to channel 31 of Module 270 (C series)
        q_273 = p_mean_Pa_temp(31+32); %Ptotal from pitot tube connected to channel 31 of Module 273 (A series)
        q_275 = p_mean_Pa_temp(32+64); %Ptotal from pitot tube connected to channel 32 of Module 275 (B series)
        

           %% Plot the data
           close all
           q=1/2*rhoAtm*Ufinal^2;   % tunnel (contraction) dynamic pressure from the measured speed

           % Figure 1: normalized by the tunnel (contraction) dynamic pressure
           figure(1)
            hold on
            plot(ZOCconfig.A.x_c,(P_Pa.A.Pmean/q),'g-o', DisplayName='SS: 1-24');
            plot(ZOCconfig.B.x_c(1:5,:),P_Pa.B.Pmean(1:5,:)/q,'ro', DisplayName='TE: 25-29'); % and G1-G9');
            plot(ZOCconfig.C.x_c,(P_Pa.C.Pmean/q),'k-o', DisplayName='PS: 30-52');
            hold off
            legend('Interpreter', 'latex', 'FontSize', 12, 'Location', 'best');
            title(strcat('AoA=',num2str(AoAvec(AoAind)),', Re=', num2str(ReTarget),', tunnel q'));
            xlabel('$x/c$','Interpreter','latex'); ylabel('$p/q_{tunnel}$','Interpreter','latex');
            grid on;
            set(gca,'Ydir','reverse')

           % Figure 2: normalized by the pitot total pressure of each module
           figure(2)
            hold on
            plot(ZOCconfig.A.x_c,(P_Pa.A.Pmean/q_273),'g-o', DisplayName='SS: 1-24');
            plot(ZOCconfig.B.x_c(1:5,:),P_Pa.B.Pmean(1:5,:)/q_275,'ro', DisplayName='TE: 25-29'); % and G1-G9');
            plot(ZOCconfig.C.x_c,(P_Pa.C.Pmean/q_270 ),'k-o', DisplayName='PS: 30-52');
            hold off
            legend('Interpreter', 'latex', 'FontSize', 12, 'Location', 'best');
            title(strcat('AoA=',num2str(AoAvec(AoAind)),', Re=', num2str(ReTarget),', pitot'));
            xlabel('$x/c$','Interpreter','latex'); ylabel('$p/q_{pitot}$','Interpreter','latex');
            grid on;
            set(gca,'Ydir','reverse')
            drawnow
%%      
        
        % Save the data
        oldPath=cd(strcat("F:\ExCamp2\Data\Cp\PMA_zeroFind"));
        %FileName=strcat('ZOC=',num2str(ReTarget),'_', ShapeConfig,'_AoA=7ACTUALLY',num2str(AoAevec(AoAind)),'(',AoAtype,')_',CpConfig,'_',TripStatus,'_',start_date_time);
        FileName=strcat('ZOC=',num2str(ReTarget),'_', ShapeConfig,'_AoA=',num2str(AoAevec(AoAind)),'(',AoAtype,')_',CpConfig,'_',TripStatus,'_',start_date_time);
        %FileName=strcat('ZOC=',num2str(ReTarget),'_', ShapeConfig,'_AoA=-3.5g','(geom)_',CpConfig,'_',TripStatus,'_',start_date_time);
        save(strcat(FileName,'.mat'))
        figure(1)
        savefig(strcat(FileName,'.fig'))          % tunnel q plot
        figure(2)
        savefig(strcat(FileName,'_pitot.fig'))    % pitot plot
        cd(oldPath)
    end% End velocity loop
end
AWT_Control_off(1)
