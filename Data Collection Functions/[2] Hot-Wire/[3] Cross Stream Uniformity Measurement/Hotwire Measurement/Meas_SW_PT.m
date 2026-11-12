function [HW_e,pt_e,ActualRate] = Meas_SW_PT(t_samp, f_s, channels)

% This script acquires data from 2 channels.

% R. Jason Hearst
% July 8, 2014

% Select channels
% NC = [2,6,7,8,9,10]; % 1st channel is for Pitot Tube, 2nd channel for Hot Wire
NC = channels;
device = 'Dev1';

% Select voltage ranges
V_PT = 10;  % pitot tube / pressure transducer
V_HW = 10;  % hot-wires

ai = daq.createSession('ni');
ai.Rate = f_s;
ai.DurationInSeconds = t_samp;
ActualRate = ai.Rate;
ai.addAnalogInputChannel(device,NC,'Voltage'); % add channels
set(ai.Channels,'TerminalConfig','SingleEnded');
warning('off')

% ai.Channels(1).Range = [-V_HW V_HW];
% ai.Channels(2).Range = [-V_PT V_PT];

data = ai.startForeground();

% Clear DAQ from system
delete(ai);
clear ai

% Seperate output in variables
HW_e = data(:, 2:end);
pt_e = data(:, 1);

clear data      % Don't need anymore

% --- END OF CODE ---
