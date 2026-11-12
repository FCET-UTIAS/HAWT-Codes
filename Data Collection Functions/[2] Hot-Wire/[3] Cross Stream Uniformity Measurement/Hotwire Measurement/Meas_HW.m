function [hw_v,ActualRate] = Meas_HW(f_s, t_samp)

% This script acquires data from 2 channels.

% Select channels
chan = 1; % channel is for HW
device = 'Dev1';


ai = daq.createSession('ni');
ai.Rate = f_s;
ai.DurationInSeconds = t_samp;
ActualRate = ai.Rate;
ai.addAnalogInputChannel(device,chan,'Voltage'); % add channels
set(ai.Channels,'TerminalConfig','SingleEnded');
warning('off')


data = ai.startForeground();

% Clear DAQ from system
delete(ai);
clear ai

% Seperate output in variables
hw_v = data(:,1);

clear data     
