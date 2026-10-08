%% mainZOC

clc;
clear all
close all
tic


%% Input
addpath(genpath('G:\ExCamp1\CalibrationData')) % Add all relevant folders
addpath(genpath('G:\ExCamp1\ConfigurationData'))
addpath(genpath('G:\ExCamp1\Subfunctions'))
addpath(genpath('G:\ExCamp1\AWTcontrol'))

ShapeConfig=input('Enter the ice shape configuration [C, GS, GR1, GR2, GR3]: ','s');
VelocityType=input('Choose from Uinf, Reynolds number or Mach number sweep (Uinf,Re,Ma)','s');
TempCelcOnline=input('Input the current temperature in Celcius.');
PresKPascOnline=input('Input the current atmospheric pressure in kPa.');
TripStatus="Trip220-4%";
AoAtype=input('Choose between geometric or effective AoA (geometric/effective)','s');

% Confirm the input
disp('Confirmation:')
disp(strcat('Tunnel Speed definition:',VelocityType))
disp(strcat('Atmospheric temperature:',num2str(TempCelcOnline),' c'))
disp(strcat('Atmospheric pressure:',num2str(PresKPascOnline),' kPa'))
disp(strcat('Trip status:',TripStatus))
disp(strcat('Angle of attack:',AoAtype))
pause(0.5)
input('Hit enter to continue.');
pause(0.5)
input('Confirm that the AoA is zero on the turn table. Run.')

% Baratron calibration
BaratronChoice=input('Choose if calibration of Baratron is necessary [Y/N]','s');
if strcmp(BaratronChoice,'N')
    disp('Choose the calibration constant ...')
    pause(0.5)
    OldPath=cd('G:\ExCamp1\CalibrationData\BaratronCalibration');
    BaratronCalibrationFileName=uigetfile;
    BaratronOffset=load(BaratronCalibrationFileName);
    cd(OldPath);
    clear OldPath
elseif strcmp(BaratronChoice,'Y')
    BaratronOffset=BaratronCalibration;
else
    disp('Invalid choice')
end

input("Confirm that the Baratron range is set to 100 torr");
BaratronRange=100;

%% Initialize
disp("Initializing...")
% Sweep parameters

AoAvec=[0 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7 7.5 8 8.5 9 9.5 10 11 12 13 14 15];

R=287; % J/kg/K
TempKelvinOnline=TempCelcOnline+273.16;

% Convert the speed to U_inf, if necessary
P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(TempCelcOnline, P_atm_mmHg);
nuAtm=muAtm/rhoAtm;
if strcmp(VelocityType,'Uinf')
    Utarget=[50];
elseif strcmp(VelocityType,'Re')
    ChordLength=12*0.0254;
    ReTarget=[1]*1e6;
    Utarget=ReTarget*nuAtm/ChordLength;
elseif strcmp(VelocityType,'Ma')
    fs_Baratron=4000;
    [T,~] = Meas_T_PS(fs_Baratron, 15);
    MaTarget=[0.077 0.1017 0.1275];
    gamma=1.4;
    Utarget=MaTarget*sqrt(gamma*R*(T+273.15));
end
    
% Convert the angle of attack from geometric to effective, if necessary.

if strcmp(AoAtype,'effective')
    AoAevec=AoAvec;
    AoAvec=funcAoAcorrection(AoAvec,'findKg','mid'); %generally AoAcorrection doesn't apply
end


        f_s=65536;
        t_s=60;


        %%
        
disp("Run the wind tunnel for 3 minutes")

AWT_Control_on % Turn on the wind tunnel control
AWT_Control_setVref(8)
pause(3*60)
AWT_Control_off(8)

%% Loop through the conditions
% Begin AoA loop
for AoAind=1:length(AoAvec)
    start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');

    if AoAind~=1
        % Change the AoA
        disp(strcat('Actuating the AoA to ',num2str(AoAvec(AoAind)),'deg'))
        MCslewfunc(AoAvec(AoAind)-AoAvec(AoAind-1),'+')
    elseif AoAvec(AoAind)~=0
        if AoAvec(AoAind)>0
            MCslewfunc(AoAvec(AoAind),'+')
        else
            MCslewfunc(abs(AoAvec(AoAind)),'-')
        end
    end

    % Begin velocity loop

    disp("Turning on the wind tunnel")
    AWT_Control_on % Turn on the wind tunnel control
    for Uind=1:length(MaTarget)
        status=AWT_Control_Integrated_func(MaTarget(Uind),PresKPascOnline,TempCelcOnline,BaratronOffset.v_fs_offset,VelocityType);
        disp(strcat('Speed target:',num2str(MaTarget(Uind)),'. Final speed: ',num2str(status.Ufinal),'. Begin measurement.'))
        %% Measure RMP and linear array
        disp(strcat('Measuring microphone array. Measurement time: ',num2str(t_s)));
        status_ZOC.UmeasBefore=status.Ufinal;
        status_ZOC.MaMeasBefore=status.MaFinal;
        status_ZOC.stdUmeasBefore=status.stdUfinal;
        status_ZOC.timeBefore=datestr(now,'mm-dd-yyyy_HH-MM');


        [data,PMAstatus]=Array_Data_Collect(f_s, t_s, 'run');

        
        
        [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(PresKPascOnline,BaratronOffset.v_fs_offset,BaratronRange);
        status_ZOC.UmeasAfter=Ufinal;
        status_ZOC.MaMeasAfter=MaFinal;
        status_ZOC.stdUmeasAfter=stdUfinal;
        status_ZOC.timeAfter=datestr(now,'mm-dd-yyyy_HH-MM');


   
        
        % Save the data
        if strcmp(VelocityType,'Uinf')
            OldPath=cd('..\..\Data\PMA\Uinf');
            if strcmp(AoAtype,'effective')
                FileName=strcat('PMA_',ShapeConfig,'_Uinf=',num2str(Utarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
            elseif strcmp(AoAtype,'geometric')
                FileName=strcat('PMA=',num2str(Utarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
            end
        elseif strcmp(VelocityType,'Re')
            OldPath=cd('Data\PMA\Re');
            if strcmp(AoAtype,'effective')
                FileName=strcat('PMA=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
            elseif strcmp(AoAtype,'geometric')
                FileName=strcat('PMA=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
            end
        elseif strcmp(VelocityType,'Ma')
            OldPath=cd('..\..\Data\PMA\Ma');
            if strcmp(AoAtype,'effective')
                FileName=strcat('PMA_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
            elseif strcmp(AoAtype,'geometric')
                FileName=strcat('PMA_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
            end
        end
        
        save(strcat(FileName,'.mat'))

         % Plot the data
        micInd=1;
        figure
        filterDelay=3;
        Nwindow      = 2^14;
        Noverlap = 2^13;
        Nfft=2^14;
        ENBW=f_s/Nfft*1.5;
        sensitivityFileNameVec=[];
        Pref=20e-6;
        for i=1
            [PSDMic,F] = pwelch(data(:,i),hanning(Nwindow),Noverlap,Nfft,f_s,'PSD');
            % Find sensitivity
            sensPath=cd("G:\ExCamp1\Subfunctions\PMA\Calibration");
            sensFile=load("MicSensitivity.mat");
            cd(sensPath)
            sensitivityMic=sensFile.sens_mat(i);
            semilogx(F,10*log10(PSDMic/sensitivityMic^2/Pref^2));
           % hold on
            cd(sensPath)
        end
        %hold off
        xlabel('Frequency (Hz)')
        ylabel('PSD (dB)')
        %legend("Mic P1","Mic S1")
        
        saveas(gcf, strcat(FileName,'.fig'))
        
        cd(OldPath)
        
        
    end % End velocity loop
    AWT_Control_off(1)
    
end % end AoA loop
toc