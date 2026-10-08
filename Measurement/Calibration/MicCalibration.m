%% Script MicCalibration.m
% This is the main code for calibrating the PCB mic. It instructs the user to
% position the pistonphone, collects measurements,
% calculates the sensitivity of the remote microhone and stores the results

% saved data:
% - RMPcalibration_XX_XX_XX: Contains all the data
%   - .vRMP: voltage from the RMP
%   - .vRef: voltage from the reference mic
%   - .sRef: sensitivity of the reference microphone
%   - .sRMP: sensitivity of all the RMPs

%% Initialize
clc;
close all;
clear all

micDAQname="PXI1Slot3";
addpath(genpath('I:\ExCamp1\CalibrationData'))
addpath(genpath('I:\ExCamp1\ConfigurationData'))
addpath(genpath('I:\ExCamp1\Subfunctions'))
Pref=20*1e-6;

GRASorPCB=input('GRAS or PCB [GRAS/PCB]','s');
MicName=input('Enter the mic serial number.','s');
micDAQchannels=input('Enter the DAQ channel number');

filterDelay=6;
num_bin = 100;
t_s=10; % This is confirmed to be enough. It results in 0.0028 dB difference for SPL=114 dB measurement

%% Measure the sensitivity of the reference microphone
disp('Place the mic in the pistonphone and turn it on.')
input('Press enter to start recording.')
disp('Start recording ... ()')
micNIsession = daq.createSession('ni'); % Open DAQ connection
%micNIsession.addAnalogInputChannel(micDAQname,micDAQchannels,'Voltage'); % Add channels
if strcmp(GRASorPCB,'GRAS')
    SignalType='Voltage';
    SpecSensitivity=3.6;
elseif strcmp(GRASorPCB,'PCB')
    SignalType='IEPE';
    SpecSensitivity=45;
end
micNIsession.addAnalogInputChannel(micDAQname,micDAQchannels,SignalType); % Add channels
micNIsession.Rate = 200000; % set sampling rate
micNIsession.DurationInSeconds = t_s+filterDelay; % add filter delay to sampling duration
mic_f_s_actual = get(micNIsession, 'Rate'); % get actual sampling rate of data based on DAQ limits
[v_mic,time_mic] = startForeground(micNIsession); % Collect data



v_mic=v_mic(mic_f_s_actual*filterDelay:end,:);
% Average the data and find the sensitivity
bin_size = floor((mic_f_s_actual*filterDelay)/num_bin);
v_rms = zeros(1, bin_size);
for i = 1:num_bin
    v_rms = v_rms + rms(v_mic(((i-1) * bin_size + 1):(i*bin_size))' - mean(v_mic(((i-1) * bin_size + 1):(i*bin_size))'));
end
v_rms = v_rms/num_bin;
% Calculate reference mic sensitivity
voltageMeanMic=mean(v_rms);
PpistonPhone= 10^(114/20)*Pref; % The pistonphone output. From the spec.
sensitivityMic=voltageMeanMic/PpistonPhone; % The sensitivity of the reference mic 
disp(strcat('Reference mic sensitivity: ',num2str(sensitivityMic*1000),' mv/Pa. Spec:',num2str(SpecSensitivity),' mv/Pa.'))

saveOption=input('Save? [Y/N]','s');
if strcmp(saveOption,'Y')
    date_time = datestr(now,'yyyy-mm-dd_HH-MM');
    if strcmp(GRASorPCB,'PCB')
        OldPath=cd('I:\ExCamp1\CalibrationData/PCBsensitivity');
        status=movefile(strcat('PCBsensitivity',MicName,'*.mat'), 'Legacy');
        fileName=strcat('PCBsensitivity',MicName,'_',date_time,'.mat');
        save(fileName)
        cd(OldPath)
    elseif strcmp(GRASorPCB,'GRAS')
        OldPath=cd('I:\ExCamp1\CalibrationData/GRASsensitivity');
        status=movefile(strcat('GRASsensitivity',MicName,'*.mat'), 'Legacy');
        fileName=strcat('GRASsensitivity',MicName,'_',date_time,'.mat');
        save(fileName)
        cd(OldPath)
    end
        
end


