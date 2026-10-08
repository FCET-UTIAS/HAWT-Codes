%% mainLinArrayMeas

% clc;
% clear all
% close all
% 

%% Input
addpath(genpath('I:\ExCamp1\CalibrationData')) % Add all relevant folders
addpath(genpath('I:\ExCamp1\Calibration'))
addpath(genpath('I:\ExCamp1\ConfigurationData'))
addpath(genpath('I:\ExCamp1\Subfunctions'))
addpath(genpath('I:\ExCamp1\AWTcontrol'))

ShapeConfig=input('Enter the ice shape configuration [BG, C, GS, GR1, GR2, GR3]: ','s');

VelocityType=input('Choose from Uinf, Reynolds number or Mach number sweep (Uinf,Re,Ma)','s');
TempCelcOnline=input('Input the current temperature in Celcius.');
PresKPascOnline=input('Input the current atmospheric pressure in kPa.');
BGorModel=input("Choose from model or background noise [Model/BG]","s");
if strcmp(BGorModel,"Model")
    TripStatus="Trip220-10%";
    AoAtype=input('Choose between geometric or effective AoA (geometric/effective)','s');
    if strcmp(AoAtype,'effective')
        disp('Choose the input file ...')
        pause(1)
        OldPath=cd('I:\ExCamp1\CalibrationData\AoAcorrection');
        uigetfile;
        cd(OldPath);
        clear OldPath
    elseif strcmp(AoAtype,'geometric')

    else
        disp('Error at AoA input definition')
    end
end

LinearMicInfo=funcLinearMicArrayConfigDefinition;
disp("Confirm that the mic serial numbers are as follows:")
disp(strcat("Pressure 1: ",LinearMicInfo.serialNum(1)))
disp(strcat("Suction 1: ",LinearMicInfo.serialNum(2)))
input("Press enter to confirm.")



% Confirm the input
disp('Confirmation:')
disp(strcat('Tunnel Speed definition:',VelocityType))
disp(strcat('Atmospheric temperature:',num2str(TempCelcOnline),' c'))
disp(strcat('Atmospheric pressure:',num2str(PresKPascOnline),' kPa'))
if strcmp(BGorModel,'Model')
    disp(strcat('Trip status:',TripStatus))
    disp(strcat('Angle of attack:',AoAtype))
end
pause(0.5)
input('Hit enter to continue.');
pause(0.5)
if strcmp(BGorModel,'Model')
    input('Confirm that the AoA is zero on the turn table. Run.')
end

% Baratron calibration
BaratronChoice=input('Choose if calibration of Baratron is necessary [Y/N]','s');
if strcmp(BaratronChoice,'N')
    disp('Choose the calibration constant ...')
    %pause(0.5)
    OldPath=cd('I:\ExCamp1\CalibrationData\BaratronCalibration');
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
if strcmp(BGorModel,'Model')
    AoAvec=[0 1 1.5 2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7 7.5 8 8.5 9 9.5 10 11 12 13 14 15];
else
    AoAvec=0;
end
R=287; % J/kg/K
TempKelvinOnline=TempCelcOnline+273.16;
f_s=200000;
t_s=30;
filterDelay=3;
Pref=20e-6;


P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(TempCelcOnline, P_atm_mmHg);
nuAtm=muAtm/rhoAtm;
if strcmp(VelocityType,'Uinf')
    Utarget=[48.5];
elseif strcmp(VelocityType,'Re')
    ChordLength=12*0.0254; % Chord length is 12 inches

    ReTarget=[1.043544]*10^6;
    Utarget=ReTarget; %*nuAtm/ChordLength;
elseif strcmp(VelocityType,'Ma')
    fs_Baratron=4000;
    [T,~] = Meas_T_PS(fs_Baratron, 15);
    MaTarget=[0.08746 0.116618 0.14577];
    gamma=1.4;
    Utarget=MaTarget; %*sqrt(gamma*R*(T+273.15));
end
    
% Convert the angle of attack from geometric to effective, if necessary.
if strcmp(BGorModel,'Model')
    if strcmp(AoAtype,'effective')
        AoAevec=AoAvec;
        AoAvec=funcAoAcorrection(AoAvec,'findKg','tip');
    end

end


Alphabet=["A","B","C","D","E","F"];

%% Define the DAQ setting. 
%{
ZOC_DAQ_ID=funcZOCconfigurationDefinition(TapGroup,TapNum);
RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);
MicDAQ_ID=funcLinearMicArrayConfigDefinition;
%}
disp("Run the wind tunnel for 3 minutes")
AWT_Control_on % Turn on the wind tunnel control
AWT_Control_setVref(8)
pause(150)
AWT_Control_off(8)

%% Loop through the conditions
% Begin AoA loop
for AoAind=1:length(AoAvec)
    start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');

    if strcmp(BGorModel,'Model')
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
        disp(strcat("AoA is ",num2str(AoAvec(AoAind))," degree"))
    end
    % Begin velocity loop
    disp("Turning on the wind tunnel")
    AWT_Control_on % Turn on the wind tunnel control
    for Uind=1:length(Utarget)
        
        if strcmp(VelocityType,'Uinf')
            status=AWT_Control_Integrated_func(Utarget(Uind),PresKPascOnline,TempCelcOnline,BaratronOffset.v_fs_offset,VelocityType);
        elseif strcmp(VelocityType,'Re')
            status=AWT_Control_Integrated_func(ReTarget(Uind),PresKPascOnline,TempCelcOnline,BaratronOffset.v_fs_offset,VelocityType);
            Utarget=ReTarget*nuAtm/ChordLength;
        elseif strcmp(VelocityType,'Ma')
            status=AWT_Control_Integrated_func(MaTarget(Uind),PresKPascOnline,TempCelcOnline,BaratronOffset.v_fs_offset,VelocityType);
            Utarget=MaTarget*sqrt(gamma*R*(T+273.15));
        end

        disp(strcat('Speed target:',num2str(Utarget(Uind)),'. Final speed: ',num2str(status.Ufinal),'. Begin measurement.'))
        %% Measure linear array
        disp(strcat('Measuring linear microphone array. Measurement time: ',num2str(t_s)));
        status_LinArray.UmeasBefore=status.Ufinal;
        status_LinArray.MaMeasBefore=status.MaFinal;
        status_LinArray.stdUmeasBefore=status.stdUfinal;
        status_LinArray.timeBefore=datestr(now,'mm-dd-yyyy_HH-MM');

        MicDAQ_ID=funcLinearMicArrayConfigDefinition;
        [vMic,f_s_actual,time]=DAQmeas(MicDAQ_ID.DAQname,MicDAQ_ID.DAQchannels,MicDAQ_ID.MeasurementType,f_s,t_s,filterDelay); % Take a measurement of all the ports
        disp('Acoustic measurement complete.');

        [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(PresKPascOnline,BaratronOffset.v_fs_offset,BaratronRange);
        status_LinArray.UmeasAfter=Ufinal;
        status_LinArray.MaMeasAfter=MaFinal;
        status_LinArray.stdUmeasAfter=stdUfinal;
        status_LinArray.timeAfter=datestr(now,'mm-dd-yyyy_HH-MM');
        vMicLinearArray=vMic(1:8);
        
        % Organize the measured linear mic array data into a data structure
        LinArrayMeasData.PressureSide1.vMicLinearArray=vMicLinearArray(:,1);
        LinArrayMeasData.SuctionSide1.vMicLinearArray=vMicLinearArray(:,8);
        
        % Plot the data
        figure(1)
        filterDelay=3;
        Nwindow      = 2^14;
        Noverlap = 2^13;
        Nfft=2^14;
        ENBW=f_s/Nfft*1.5;
        sensitivityFileNameVec=[];
        for i=1:2
            [PSDMic,F] = pwelch(vMic(:,i),hanning(Nwindow),Noverlap,Nfft,f_s,'PSD');
            % Find sensitivity
            serialNum=LinearMicInfo.serialNum(i);
            micType=LinearMicInfo.type(i);
            oldPath=cd(strcat("I:\ExCamp1\CalibrationData\",micType,"sensitivity"));
            sensitivityFileName=ls(strcat(micType,"sensitivity",serialNum,"*.mat")); % The directory should only contain one file that matches this wild card.
            sensitivityMic=load(sensitivityFileName).sensitivityMic;
            sensitivityFileNameVec=[sensitivityFileNameVec, string(sensitivityFileName)];
            semilogx(F,10*log10(PSDMic/sensitivityMic^2/Pref^2));
            hold on
            cd(oldPath)
        end
        hold off
        xlabel('Frequency (Hz)')
        ylabel('PSD (dB)')
        legend("Mic P1","Mic S1")
        
        
        % Save the data
        if strcmp(BGorModel,"Model")
            if strcmp(VelocityType,'Uinf')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Uinf');
                if strcmp(AoAtype,'effective')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Uinf=',num2str(Utarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
                elseif strcmp(AoAtype,'geometric')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Uinf=',num2str(Utarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
                end
            elseif strcmp(VelocityType,'Re')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Re');
                if strcmp(AoAtype,'effective')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Re=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
                elseif strcmp(AoAtype,'geometric')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Re=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
                end
            elseif strcmp(VelocityType,'Ma')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Ma');
                if strcmp(AoAtype,'effective')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAevec(AoAind)),'(effective)_',TripStatus,'_',start_date_time);
                elseif strcmp(AoAtype,'geometric')
                    FileName=strcat('LinMicArray_',ShapeConfig,'_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time);
                end
            end
        elseif strcmp(BGorModel,"BG")
            if strcmp(VelocityType,'Uinf')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Uinf');
                FileName=strcat('LinMicArray_Uinf=',num2str(Utarget(Uind)),'_Background',start_date_time);
            elseif strcmp(VelocityType,'Re')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Re');
                FileName=strcat('LinMicArray_Re=',num2str(ReTarget(Uind)),'_Background',start_date_time);
            elseif strcmp(VelocityType,'Ma')
                OldPath=cd('I:\ExCamp1\Data\LinArray\Ma');
                FileName=strcat('LinMicArray_Ma=',num2str(MaTarget(Uind)),'_Background',start_date_time);
            end
        end
        save(strcat(FileName,'.mat'))
        figure(1)
        title(FileName)
        savefig(strcat(FileName,'.fig'))
        cd(OldPath)
        
        
    end % End velocity loop
    AWT_Control_off(1)
    
end % end AoA loop