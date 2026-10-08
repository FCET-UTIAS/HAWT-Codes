%% mainRMP_LinArray


% This script is used to measure the Cp, far-field noise and the remote
% mic. The script sweeps through the AoA and velocity.
% The script first runs ZOC, then the far-field mic and RMP simultaneously.



%% Input
clc;
clear all
close all

addpath(genpath('F:\ExCamp1\CalibrationData')) % Add all relevant folders
addpath(genpath('F:\ExCamp1\ConfigurationData'))
addpath(genpath('F:\ExCamp1\Subfunctions'))
addpath(genpath('F:\ExCamp1\AWTcontrol'))

ShapeConfig=input('Enter the ice shape configuration [C, GS, GR1, GR2, GR3]: ','s');

VelocityType=input('Choose from Uinf, Reynolds number or Mach number sweep (Uinf,Re,Ma)','s');
TempCelcOnline=input('Input the current temperature in Celcius.');
PresKPascOnline=input('Input the current atmospheric pressure in kPascal.');
TripStatus=input('Enter the trip condition (NoTrip,Trip220Grid)','s');
AoAtype=input('Choose between geometric or effective AoA (geometric/effective)','s');

RMPconfig=input('Choose the RMP configuration: [1/2/3/.../6/test]','s');
disp('Choose the RMP sensitivity data')
pause(0.3);
OldPath=cd(strcat('F:\ExCamp1\CalibrationData\RMPsensitivity\Config',RMPconfig));
RMPcalibrationFileName=uigetfile;
cd('../../../')
RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);

% Confirm the input
disp('Confirmation:')
disp(strcat('Tunnel Speed definition:',VelocityType))
disp(strcat('Atmospheric temperature:',num2str(TempCelcOnline),' c'))
disp(strcat('Atmospheric pressure:',num2str(PresKPascOnline),' Pa'))
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
    OldPath=cd('CalibrationData/BaratronCalibration');
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
% Sweep parameters
AoAvec=[6.5];
R=287; % J/kg/K
TempKelvinOnline=TempCelcOnline+273.16;
f_s=200000;
t_s=60;
filterDelay=3;
Pref=20e-6;

fs_Baratron=4000;
[T,~] = Meas_T_PS(fs_Baratron, 15);
P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(T, P_atm_mmHg);

% Convert the speed to U_inf, if necessary
nuAtm=muAtm/rhoAtm;
if strcmp(VelocityType,'Uinf')
    Utarget=20:5:55;
elseif strcmp(VelocityType,'Re')
    ChordLength=12*0.0254;
    ReTarget=[1]*1e6;
    %ReTarget=[652656 902914 1127782];
    Utarget=ReTarget*nuAtm/ChordLength;
elseif strcmp(VelocityType,'Ma')
    MaTarget=0.06:0.01:0.16;
    Utarget=MaTarget*sqrt(gamma*R*TempKelvinOnline);
end
    
% Convert the angle of attack from geometric to effective, if necessary.
if strcmp(AoAtype,'effective')
    AoAevec=AoAvec;
    AoAvec=funcAoAcorrection(AoAvec,'findKg','tip');
end

Alphabet=["A","B","C", "D", "E"];

%% Define the DAQ setting. 
%{
ZOC_DAQ_ID=funcZOCconfigurationDefinition(TapGroup,TapNum);
RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);
MicDAQ_ID=funcLinearMicArrayConfigDefinition;
%}


%% Loop through the conditions
    
    % Begin velocity loop
    AWT_Control_on % Turn on the wind tunnel control
start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');
% Begin AoA loop
for AoAind=1:length(AoAvec)
    close all
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
    disp(strcat('AoA is at',num2str(AoAvec(AoAind)),'deg'))

    for Uind=1:length(Utarget)
        status=AWT_Control_Integrated_func(Utarget(Uind),PresKPascOnline,TempCelcOnline,BaratronOffset.v_fs_offset);
        disp(strcat('Speed target:',num2str(Utarget(Uind)),'. Final speed: ',num2str(status.Ufinal),'. Begin measurement.'))
        
        %% Measure RMP and linear array
        disp(strcat('Measuring RMP and linear microphone array. Measurement time: ',num2str(t_s)));
        status_RMP_LinArray.UmeasBefore=status.Ufinal;
        status_RMP_LinArray.MaMeasBefore=status.MaFinal;
        status_RMP_LinArray.stdUmeasBefore=status.stdUfinal;
        status_RMP_LinArray.timeBefore=datestr(now,'mm-dd-yyyy_HH-MM');
        

        RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);
        DAQname=[RMP_DAQ_ID.A.DAQname RMP_DAQ_ID.B.DAQname RMP_DAQ_ID.C.DAQname RMP_DAQ_ID.D.DAQname RMP_DAQ_ID.E.DAQname];
        DAQchannels=[RMP_DAQ_ID.A.DAQchannel RMP_DAQ_ID.B.DAQchannel RMP_DAQ_ID.C.DAQchannel RMP_DAQ_ID.D.DAQchannel RMP_DAQ_ID.E.DAQchannel];
        DAQmeasurementType=[RMP_DAQ_ID.A.MeasurementType RMP_DAQ_ID.B.MeasurementType RMP_DAQ_ID.C.MeasurementType RMP_DAQ_ID.D.MeasurementType RMP_DAQ_ID.E.MeasurementType];

        [vMic,f_s_actual,time]=DAQmeas(DAQname,DAQchannels,DAQmeasurementType,f_s,t_s,filterDelay); % Take a measurement of all the ports
        disp('Acoustic measurement complete.');
        
        [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(PresKPascOnline,BaratronOffset.v_fs_offset,BaratronRange);
        status_ZOC.UmeasAfter=Ufinal;
        status_ZOC.MaMeasAfter=MaFinal;
        status_ZOC.stdUmeasAfter=stdUfinal;
        status_ZOC.timeAfter=datestr(now,'mm-dd-yyyy_HH-MM');
        
        %vMicRMP=vMic(:,1:23);
        %vMicLinearArray=vMic(:,1:8);
        %{
        CurID=1;
        for groupInd=1:length(Alphabet)
            for tapInd=1:length(RMP_DAQ_ID.(Alphabet(groupInd)).tapID)
                RMPmeasData.(Alphabet(groupInd)).(strcat('tap',num2str(RMP_DAQ_ID.(Alphabet(groupInd)).tapID(tapInd)))).vMicRMP=vMicRMP(:,CurID);
                CurID=CurID+1;
            end
        end
        CurID=1;
        for MicInd=1:7
            LinArrayMeasData.(strcat('PressureSide',num2str(MicInd))).vMicLinearArray=vMicLinearArray(:,CurID);
            CurID=CurID+1;
        end
        LinArrayMeasData.SuctionSide1.vMicLinearArray=vMicLinearArray(:,8);
        %}

            filterDelay=3;
            Nwindow= 2^14;
            Noverlap = 2^13;
            Nfft=2^14;
            ENBW=f_s/Nfft*1.5;
            figure(1)
            [PSDMic,F] = pwelch(vMic,hanning(Nwindow),Noverlap,Nfft,f_s,'PSD');
            % Find sensitivity
            semilogx(F,10*log10(PSDMic/0.0036^2/Pref^2));
            hold on
            xlabel('Frequency (Hz)')
            ylabel('PSD (dB)')
            
        
        % Save the data
        if strcmp(VelocityType,'Uinf')
            OldPath=cd('Data\RMP\Uinf');
            if strcmp(AoAtype,'effective')
                save(strcat('RMPconfig',RMPconfig, '_',ShapeConfig,'_Uinf=',num2str(UinfTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            elseif strcmp(AoAtype,'geometric')
                save(strcat('RMPconfig',RMPconfig,'_',ShapeConfig,'_Uinf=',num2str(UinfTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            end
        elseif strcmp(VelocityType,'Re')
            OldPath=cd('F:\ExCamp1\Data\RMP');
            if strcmp(AoAtype,'effective')
                save(strcat('RMPconfig',RMPconfig,'_',ShapeConfig,'_Re=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            elseif strcmp(AoAtype,'geometric')
                save(strcat('RMPconfig',RMPconfig,'_',ShapeConfig,'_Re=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            end
        elseif strcmp(VelocityType,'Ma')
            OldPath=cd('Data\RMP\Ma');
            if strcmp(AoAtype,'effective')
                save(strcat('RMPconfig',RMPconfig,'_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            elseif strcmp(AoAtype,'geometric')
                save(strcat('RMPconfig',RMPconfig,'_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_Glass_',TripStatus,'_',start_date_time,'.mat'))
            end
        end
        cd(OldPath)
        
        
    end % End velocity loop
end % end AoA loop
    AWT_Control_off(1)