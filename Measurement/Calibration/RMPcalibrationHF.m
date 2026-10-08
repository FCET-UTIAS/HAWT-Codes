%% Script RMPcalibration.m
% This is the main code for calibrating the RMP. It instructs the user to
% position the reference mic and the speaker, collects measurements,
% calculates the sensitivity of the remote microhone and stores the results

% saved data:
% - RMPcalibration_XX_XX_XX: Contains all the data
%   - .vRMP: voltage from the RMP
%   - .vRef: voltage from the reference mic
%   - .sRef: sensitivity of the reference microphone
%   - .sRMP: sensitivity of all the RMPs


%% Initialize
clc;
clear all;
close all;

refMicDAQname="PXI1Slot3";
refMicDAQchannel=8;

t_sRMP=10;
f_sRMP=200000;
filterDelay=3;


addpath(genpath('CalibrationData'))
addpath(genpath('ConfigurationData'))
addpath(genpath('Subfunctions'))
addpath(genpath("AWTcontrol"))
Pref=20*1e-6;
T_thermocouple = USB_TC01_read();

%% Input
TempCelcOnline=input('Input the current temperature in Celcius.');
PresKPascOnline=input('Input the current atmospheric pressure in kPa.');


%% Define RMP configuration
RMPconfig = input('Select RMP configuration: (1,2,3,...,test) \n',"s");
CalibrationPortID=funcRMPconfigurationDefinition(RMPconfig);
disp(strcat('Configuration', RMPconfig,' selected. The ports are:'))
disp(strcat('A:',num2str(CalibrationPortID.A.tapID)))
disp(strcat('B:',num2str(CalibrationPortID.B.tapID)))
disp(strcat('C:',num2str(CalibrationPortID.C.tapID)))
disp(strcat('D:',num2str(CalibrationPortID.D.tapID)))
disp(strcat('E:',num2str(CalibrationPortID.E.tapID)))
disp(strcat('F:',num2str(CalibrationPortID.F.tapID)))
pause(2)

%% Measure the sensitivity of the reference microphone
disp('Choose the microphone sensitivity')
pause(0.5)
OldPath=cd('CalibrationData/GRASsensitivity');
load(uigetfile);
cd(OldPath)

%% Loop through the whole remote microphones
input('Turn on the signal conditioner at 600 mVpp and 50% amplifier setting.')
input('Set the f_min=1000 Hz, f_max=20 kHz, T=5 sec.')
input('Hit enter.')

Alphabet=["A","B","C","D","E","F"];
RMPnum=[length(CalibrationPortID.A.tapID)...
    length(CalibrationPortID.B.tapID)...
    length(CalibrationPortID.C.tapID)...
    length(CalibrationPortID.D.tapID)...
    length(CalibrationPortID.E.tapID)...
    length(CalibrationPortID.F.tapID)];

start_date_time = datestr(now,'yyyy-mm-dd_HH-MM');
oldPath=cd(strcat('CalibrationData/RMPsensitivity/Config',RMPconfig));
status=movefile(strcat('RMPcalibration_Config',RMPconfig,'_*.mat'), 'Legacy');
cd(oldPath);

Nwindow      = 2^14;

tic
for GroupID=1:6
    if RMPnum(GroupID)~=0
        figure(1) % Coherence
        figure(2) % RMP sensitivity
        figure(3) % Reconstruction
        disp(strcat('Calibrating Group ',Alphabet(GroupID)))
        tapID=1;
        while tapID<=RMPnum(GroupID)
            pause(0.5)
            TapCur=strcat(Alphabet(GroupID),num2str(CalibrationPortID.(Alphabet(GroupID)).tapID(tapID)));
            input(strcat('Align the mic at ',num2str(TapCur),'. Hit enter.'))
            %{
            if ~strcmp(CalibrationPortID.(Alphabet(GroupID)).DAQname(tapID),refMicDAQname)
                DAQname=[refMicDAQname CalibrationPortID.(Alphabet(GroupID)).DAQname(tapID)];
                DAQchannels.(DAQname(1))=refMicDAQchannel;
                DAQchannels.(DAQname(2))=CalibrationPortID.(Alphabet(GroupID)).DAQchannel(tapID);
            else
                DAQname=refMicDAQname;
                DAQchannels.(DAQname(1))=[refMicDAQchannel CalibrationPortID.(Alphabet(GroupID)).DAQchannel(tapID)];
            end
            %}
            DAQname=[CalibrationPortID.(Alphabet(GroupID)).DAQname(tapID), refMicDAQname];
            DAQchannels=[CalibrationPortID.(Alphabet(GroupID)).DAQchannel(tapID), refMicDAQchannel];
            disp(strcat('Starting measurement. Sampling time: ',num2str(t_sRMP),' sec'))
            [v_mic,f_s_actual,time]=DAQmeas(DAQname,DAQchannels,["Voltage","Voltage"],f_sRMP,t_sRMP,filterDelay); %DAQname,DAQchannels,MeasurementType,f_s,t_s,filterDelay
            v_mic=flip(v_mic,2);
            % coherence function
            [Coherence,F] = mscohere(v_mic(:,1),v_mic(:,2), [],[],[],f_sRMP);
            % transfer function
            [TransferFunc,F] = tfestimate(v_mic(:,1),v_mic(:,2),[],[],[],f_sRMP);
            % sensitivity
            sRMP=sensitivityMic./abs(TransferFunc);
            % BK - power spectrum density
            [PSDrefMic,F] = pwelch(v_mic(:,1),[],[],[],f_sRMP);
            % Mic. - power spectrum density
            [PSDRMP,F] = pwelch(v_mic(:,2),[],[],[],f_sRMP);

            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).channelDef="Channel 1: reference. Channel 2: RMP.";
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).v_mic=v_mic;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).f_s_actual=f_s_actual;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).time=time;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).refMicDAQname=refMicDAQname;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).RMPmicDAQname=CalibrationPortID.(Alphabet(GroupID)).DAQname(tapID);
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).refMicDAQchannel=refMicDAQchannel;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).RMPmicDAQchannel=CalibrationPortID.(Alphabet(GroupID)).DAQchannel(tapID);
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).Coherence=Coherence;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).TransferFunc=TransferFunc;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).PSDrefMic=PSDrefMic;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).PSDRMP=PSDRMP;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).sRMP=sRMP;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).F=F;
            RMPcalibrationData.(Alphabet(GroupID)).(strcat('tap',num2str(tapID))).CalibrationPortID=CalibrationPortID;
            oldPath=cd(strcat('CalibrationData/RMPsensitivity/Config',RMPconfig));
            save(strcat('RMPcalibrationHF_Config',RMPconfig,'_',start_date_time,'.mat'))
            cd(oldPath)

            close all
            mkdir(strcat('CalibrationData\RMPsensitivity\Config',RMPconfig,'\',start_date_time));
            oldPath=cd(strcat('CalibrationData\RMPsensitivity\Config',RMPconfig,'\',start_date_time));

            figure(1)
            semilogx(F,sRMP*1000)
            xlim([100 12000])
            title("RMP sensitivity","Interpreter","Latex")
            xlabel("Frequency (Hz)","Interpreter","Latex")
            ylabel("RMP sensitivity (mv/Pa)","Interpreter","Latex")
            savefig(strcat('SensitivityHF_',Alphabet(GroupID),num2str(CalibrationPortID.(Alphabet(GroupID)).tapID(tapID)),'.fig'))

            figure(2)
            semilogx(F,Coherence)
            xlim([100 12000])
            title("Coherence","Interpreter","Latex")
            xlabel("Frequency (Hz)","Interpreter","Latex")
            ylabel("Amplitude (dB)","Interpreter","Latex")
            savefig(strcat('CoherenceHF_',Alphabet(GroupID),num2str(CalibrationPortID.(Alphabet(GroupID)).tapID(tapID)),'.fig'))

            figure(3)
            semilogx(F,20*log10(sRMP.*sqrt(PSDRMP)/Pref))
            hold on
            semilogx(F,20*log10(sensitivityMic.*sqrt(PSDrefMic)/Pref),'k')
            xlim([100 12000])
            title("Pressure reconstruction","Interpreter","Latex")
            xlabel("Frequency (Hz)","Interpreter","Latex")
            ylabel("Reconstruction (dB)","Interpreter","Latex")
            legend('RMP reconstruction','Reference mic reconstruction')
            hold off
            savefig(strcat('PressureReconstructionHF_',Alphabet(GroupID),num2str(CalibrationPortID.(Alphabet(GroupID)).tapID(tapID)),'.fig'))
            cd(oldPath)
            
            saveOption=input("Save the result? [Y/N]",'s');
            if strcmp(saveOption,"Y")
                tapID=tapID+1;
            end
        end
    end

end

disp('============================')
disp('The calibration is complete.')
disp(strcat('Time:',num2str(floor(toc/60)),' minutes',num2str(toc-floor(toc/60)*60),'seconds'))
      
