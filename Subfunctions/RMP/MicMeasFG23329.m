%% function [p_mic]=MicMeasFG23329(DAQname,DAQchannels,f_s)

% This function is for collecting the remote microphone measurements. 

% input
% - DAQname: Name of the DAQ to be specified in addAnalogInputChannel. eg. 'PXI1Slot2'
% - DAQchannels: Channel numbers to have the data collected from. eg. [0 1 2 3]
% - f_s: Requested sampling frequency
% - t_s: Required data in seconds
% - filterDelay: The additional duration to be measured to take in count
%   the filter delay. The actual sampling duration will be t_s+filterDelay.

% output

function [v_mic,p_mic,f_s_actual,time]=MicMeasFG23329(DAQname,DAQchannels,RMPSensitivityName,mode,PtapID,f_s,t_s,filterDelay)

% f_s = 2^16;
% t_samp = 30;

%% Data collection
disp('MicMeasFG23329.m. Connecting to DAQ')

% Open DAQ connection
warning('off')  
s = daq.createSession('ni'); % Open DAQ connection
s.addAnalogInputChannel(DAQname,DAQchannels,'Voltage'); % Add channels
s.Rate = f_s; % set sampling rate
s.DurationInSeconds = t_s + filterDelay; % add filter delay to sampling duration
f_s_actual = get(s, 'Rate'); % get actual sampling rate of data based on DAQ limits

disp('MicMeasFG23329.m. Collecting data.')
[v_mic,time] = startForeground(s); % Collect data

p_mic=NaN(size(v_mic));
if strcmp(mode,'measurement')
    for i=1:length(PtapID)
        p_mic(:,i)=v_mic(:,i)*RMPSensitivityName(PtapID(i));
    end
    disp('MicMeasFG23329.m. Data collection complete.')
end
end