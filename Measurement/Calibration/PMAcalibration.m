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

addpath("G:\ExperimentalCampaign4\Subfunctions\PMA\Calibration\Legacy")
load("MicSensitivity.mat")

addpath(genpath('CalibrationData'))
addpath(genpath('ConfigurationData'))
addpath(genpath('Subfunctions'))
Pref=20*1e-6;

filterDelay=6;
num_bin = 100;
t_s=10; % This is confirmed to be enough. It results in 0.0028 dB difference for SPL=114 dB measurement

%% Measure the sensitivity of the reference microphone
for micInd=38
    disp(strcat('Place mic ',num2str(micInd),' in the pistonphone and turn it on.'))
    input('Press enter to start recording.')
    disp('Start recording ... ()')
    micNIsession = daq.createSession('ni'); % Open DAQ connection
    %micNIsession.addAnalogInputChannel(micDAQname,micDAQchannels,'Voltage'); % Add channels
    SignalType='IEPE';
    micNIsession.addAnalogInputChannel(mic_PXIcard{micInd},micInd-1-floor((micInd-1)/16)*16,SignalType); % Add channels
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
    disp(strcat('Reference mic sensitivity: ',num2str(sensitivityMic*1000),' mv/Pa.'))
    
    %sens_mat(micInd)=sensitivityMic;
        

end
%%
date_time = datestr(now,'yyyy-mm-dd_HH-MM');
oldPath=cd("G:\ExperimentalCampaign4\Subfunctions\PMA\Calibration");
save("MicSensitivity.mat")
cd(oldPath)