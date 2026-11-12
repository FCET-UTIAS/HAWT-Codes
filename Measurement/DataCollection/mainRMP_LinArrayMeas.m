%% mainRMP_LinArray


% This script is used to measure the Cp, far-field noise and the remote
% mic. The script sweeps through the AoA and velocity.
% The script first runs ZOC, then the far-field mic and RMP simultaneously.



%% Input
clc;
clear all
close all

addpath(genpath('F:\ExCamp2\CalibrationData')) % Add all relevant folders
addpath(genpath('F:\ExCamp2\ConfigurationData'))
addpath(genpath('F:\ExCamp2\Subfunctions'))
addpath(genpath('F:\ExCamp2\AWTcontrol'))

VelocityType=input('Choose from Uinf, Reynolds number or Mach number sweep (Uinf,Re,Ma)','s');
PresKPascOnline=input('Input the current atmospheric pressure in kPascal.');
TripStatus=input('Enter the trip condition (NoTrip,Trip220Grit, GS, GR)','s');


LinearMicInfo=funcLinearMicArrayConfigDefinition;
disp("Confirm that the mic serial numbers are as follows:")
disp(strcat("Suction: ",LinearMicInfo.serialNum(2)))
disp(strcat("Pressure: ",LinearMicInfo.serialNum(1)))
input("Press enter to confirm.")

RMPconfig=input('Choose the RMP configuration: [Clean-ALL, Glaze-ALL]: ','s');
disp('Choose the RMP sensitivity data')
pause(0.3);
OldPath=cd(strcat('F:\ExCamp2\CalibrationData\RMPsensitivity\Config',RMPconfig));
RMPcalibrationFileName=uigetfile;
cd('../../../')
RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);

% Confirm the input
disp('Confirmation:')
disp(strcat('Tunnel Speed definition:',VelocityType))
disp(strcat('Atmospheric pressure:',num2str(PresKPascOnline),' Pa'))
disp(strcat('Trip status:',TripStatus))
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

BaratronRange=100;

%% Initialize
% Sweep parameters
AoAvec=[6];
AoAtype='geometric';
R=287; % J/kg/K
f_s=200000;
t_s=60;
filterDelay=3;
Pref=20e-6;

fs_Baratron=4000;
T =gimmetemp;
P_atm_mmHg = PresKPascOnline*1e3*0.0075;   % [from kPa to mmHg]
[rhoAtm, muAtm, ~, ~] = fluid_prop(T, P_atm_mmHg);

% Convert the speed to U_inf, if necessary
nuAtm=muAtm/rhoAtm;
if strcmp(VelocityType,'Uinf')

    Utarget=40:5:50;
elseif strcmp(VelocityType,'Re')
    ChordLength=0.3;

    ReTarget=[1.043544]*1e6;
    Utarget=ReTarget;
elseif strcmp(VelocityType,'Ma')

    MaTarget=[0.08746, 0.116618, 0.14577];
    Utarget=MaTarget;
end
    

%%  Convert the angle of attack from geometric to effective, if necessary.
% if strcmp(AoAtype,'effective')
%     AoAevec=AoAvec;
%     AoAvec=funcAoAcorrection(AoAvec,'findKg','tip');
% end
%% Loop through the conditions
    
    % Begin velocity loop
AWT_Control_on()
start_date_time = datestr(now,'mm-dd-yyyy_HH-MM');

%Begin AoA loop
% for AoAind=1:length(AoAvec)
%     close all
%     if AoAind~=1
%         % Change the AoA
%         disp(strcat('Actuating the AoA to ',num2str(AoAvec(AoAind)),'deg'))
%         MCslewfunc(AoAvec(AoAind)-AoAvec(AoAind-1),'+')
%     elseif AoAvec(AoAind)~=0
%         if AoAvec(AoAind)>0
%             MCslewfunc(AoAvec(AoAind),'+')
%         else
%             MCslewfunc(abs(AoAvec(AoAind)),'-')
%         end
%     end
%    disp(strcat('AoA is at',num2str(AoAvec(AoAind)),'deg (AoAe=',num2str(AoAvec(AoAind)),')'))

    for Uind=1:length(Utarget)
        status=AWT_Control_Integrated_func(Utarget(Uind),PresKPascOnline,T,BaratronOffset.v_fs_offset,VelocityType);
        disp(strcat('Speed target:',num2str(Utarget(Uind)),'. Final speed: ',num2str(status.Ufinal),'. Begin measurement.'))
        
        % Measure RMP and linear array
        disp(strcat('Measuring RMP and linear microphone array. Measurement time: ',num2str(t_s)));
        status_RMP_LinArray.UmeasBefore=status.Ufinal;
        status_RMP_LinArray.MaMeasBefore=status.MaFinal;
        status_RMP_LinArray.stdUmeasBefore=status.stdUfinal;
        status_RMP_LinArray.timeBefore=datestr(now,'mm-dd-yyyy_HH-MM');
        

        MicDAQ_ID=funcLinearMicArrayConfigDefinition;
        RMP_DAQ_ID=funcRMPconfigurationDefinition(RMPconfig);
        DAQname=[RMP_DAQ_ID.A.DAQname RMP_DAQ_ID.B.DAQname RMP_DAQ_ID.C.DAQname RMP_DAQ_ID.D.DAQname RMP_DAQ_ID.E.DAQname MicDAQ_ID.DAQname];
        DAQchannels=[RMP_DAQ_ID.A.DAQchannel RMP_DAQ_ID.B.DAQchannel RMP_DAQ_ID.C.DAQchannel RMP_DAQ_ID.D.DAQchannel RMP_DAQ_ID.E.DAQchannel MicDAQ_ID.DAQchannels];
        DAQmeasurementType=[RMP_DAQ_ID.A.MeasurementType RMP_DAQ_ID.B.MeasurementType RMP_DAQ_ID.C.MeasurementType RMP_DAQ_ID.D.MeasurementType RMP_DAQ_ID.E.MeasurementType MicDAQ_ID.MeasurementType];

        [vMic,f_s_actual,time]=DAQmeas(DAQname,DAQchannels,DAQmeasurementType,f_s,t_s,filterDelay); % Take a measurement of all the ports
        disp('Acoustic measurement complete.');
        
        [Ufinal,MaFinal,stdUfinal]=AWTspeedMeasurementFunc(PresKPascOnline,BaratronOffset.v_fs_offset,BaratronRange);
        status_post.UmeasAfter=Ufinal;
        status_post.MaMeasAfter=MaFinal;
        status_post.stdUmeasAfter=stdUfinal;
        status_post.timeAfter=datestr(now,'mm-dd-yyyy_HH-MM');
        
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
        %% FFT & Plotting
            filterDelay=3;
            Nwindow= 2^14;
            Noverlap = 2^13;
            Nfft=2^14;
            ENBW=f_s/Nfft*1.5;
            figure(2)
            subplot(1,2,1)
            title('farfield mic (SS, PS)')
            [PSDMic,F] = pwelch(vMic(:,14:15),hanning(Nwindow),Noverlap,Nfft,f_s,'PSD');
            % Find sensitivity
            semilogx(F,10*log10(PSDMic/0.0036^2/Pref^2), LineWidth=2.5);
            hold on
            grid on
            xlabel('Frequency (Hz)')
            ylabel('PSD (dB)')
            xlim([1e2, 2.5e4]);

            subplot(1,2,2)
            title('RMP mic')
            [PSDMic,F] = pwelch(vMic(:,1:13),hanning(Nwindow),Noverlap,Nfft,f_s,'PSD');
            % Find sensitivity
            semilogx(F,10*log10(PSDMic/0.0036^2/Pref^2), LineWidth=2.5);
            hold on
            grid on
            xlabel('Frequency (Hz)')
            ylabel('PSD (dB)')
            xlim([1e2, 2.5e4]);
                    
        %% Save the data
        if strcmp(VelocityType,'Uinf')
            OldPath=cd('F:\ExCamp2\Data\RMP_LinArray\Uinf');
                save(strcat('RMPconfig',RMPconfig,'_LinMicArray_Uinf=',num2str(Utarget(Uind)),'_AoA=',num2str(AoAvec),'(geometric)_',TripStatus,'_',start_date_time,'.mat'))
       elseif strcmp(VelocityType,'Re')
            save(strcat('RMPconfig',RMPconfig,'_LinMicArray_Re=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time,'.mat'))
        elseif strcmp(VelocityType,'Ma')
            OldPath=cd('F:\ExCamp2\Data\RMP_LinArray\Ma');
            save(strcat('RMPconfig',RMPconfig,'_LinMicArray_Ma=',num2str(MaTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',TripStatus,'_',start_date_time,'.mat'))
        end
        
        cd(OldPath) 
        input('does the plots look good? if no, CTRL+C now.');
        
    end % End velocity loop

%end % end AoA loop

disp('Run complete - data saved & shutting down tunnel')    
off = input('turn off tunnel? [1=yes, 0=no]: ');
if off==1
    AWT_Control_off((round(Ufinal)/60)*10);
else 
    disp('program complete, ready to run next case.')
    return 
end


    