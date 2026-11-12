%% Setup for PIV - running at required Reynolds number. 
%optimized for quick start up ,  reducing number of required inputs

clear all;
close all;

driveName=pwd;
driveName=driveName(1);
addpath(genpath(strcat(driveName,':\ExCamp2\CalibrationData'))) % Add all relevant folders
%addpath(genpath(strcat(driveName,':\ExCamp2\ConfigurationData')))
addpath(genpath(strcat(driveName,':\ExCamp2\Subfunctions')))
addpath(genpath(strcat(driveName,':\ExCamp2\AWTcontrol')))
%addpath(genpath(strcat(driveName,':\ExCamp2\ValidationData\LinArray\Uinf')))


%% Setup
ReVec=[1.0]*10^6;

TempCelcOnline=  24;
PresKPascOnline= 101.8;

AoAvec = 4; %current AoA
AoAtype = 'geometric';
ShapeConfig = 'GS';
start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');

%% Baratron calibration
%BaratronChoice=input('Choose if offset correction of Baratron is necessary [Y/N]','s');
BaratronChoice='N';
if strcmp(BaratronChoice,'N')
    disp('Choose the calibration constant ...')
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

BaratronRange=100;

%% Initialize
c=0.3; % [m]

fs_Baratron=4000;
[T,~] = Meas_T_PS(fs_Baratron, 15);
P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(T, P_atm_mmHg);
nuAtm=muAtm/rhoAtm;
R=287; % J/kg/K


%% Turning on tunnel
AWT_Control_on
ReTarget=ReVec;
Utarget=ReTarget*nuAtm/c;
status=AWT_Control_Integrated_func(Utarget,PresKPascOnline,T,BaratronOffset.v_fs_offset,"Uinf");
status.time=datestr(now,'mm-dd-yyyy_HH-MM');
disp(strcat('Speed target: ',num2str(Utarget),'.'))
disp(strcat('Final speed: ',num2str(status.Ufinal),'.'))
disp(strcat('Temperature: ', num2str(status.T), '°C.'))


%% Turning off tunnel

ready = input('Are you ready to shut down tunnel [y/n]? ', 's');
if strcmp(ready, 'y') || strcmp(ready, 'Y')
    AWT_Control_off(status.Vcurrent);
end

%% saving data
oldPath=cd(strcat("F:\ExCamp2\Data\PIV"));
FileName=strcat('PIV_atRe=',num2str(ReTarget),'_', ShapeConfig,'_AoA=',num2str(AoAvec),'(',AoAtype,')_',start_date_time);
save(strcat(FileName,'.mat'))
disp('file saved!')
