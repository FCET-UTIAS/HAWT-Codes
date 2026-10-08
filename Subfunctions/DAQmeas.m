function [v_mic,f_s_actual,time]=DAQmeas(DAQname,DAQchannels,MeasurementType,f_s,t_s,filterDelay)

%% Data collection
% Open DAQ connection
warning('off')  
DAQlist=["PXI1Slot3","PXI1Slot4","PXI1Slot5"];



s = daq.createSession('ni'); % Open DAQ connection
for i=1:length(DAQname)
    s.addAnalogInputChannel(DAQname(i),DAQchannels(i),MeasurementType(i)); % Add channels
end

s.Rate = f_s; % set sampling rate
s.DurationInSeconds = t_s + filterDelay; % add filter delay to sampling duration
f_s_actual = get(s, 'Rate'); % get actual sampling rate of data based on DAQ limits

[a]=ismember(DAQlist,DAQname);
if sum(a)>1
    for i=1:(sum(a)-1)
        addTriggerConnection(s,strcat(DAQlist(1),"/PXI_Trig0"),strcat(DAQlist(i+1),"/PXI_Trig0"),"StartTrigger");
    end
end


    %addTriggerConnection(s,"PXI1Slot2/PXI_Trig0","PXI1Slot3/PXI_Trig0","StartTrigger");
    %addTriggerConnection(s,"PXI1Slot2/PXI_Trig0","PXI1Slot4/PXI_Trig0","StartTrigger");
    
[v_mic,time] = startForeground(s); % Collect data

%{
s = daq.createSession('ni'); % Open DAQ connection
for i=1:length(DAQname)
    s.addAnalogInputChannel(DAQname,DAQchannels.(DAQname(i)),'Voltage'); % Add channels
end

if length(DAQname)>1
    for i=2:length(DAQname)
        addTriggerConnection(s,strcat(DAQname(1),"/PXI_Trig0"),strcat(DAQname(i),"/PXI_Trig0"),"StartTrigger");
    end
    
end
s.Rate = f_s; % set sampling rate
s.DurationInSeconds = t_s + filterDelay; % add filter delay to sampling duration
f_s_actual = get(s, 'Rate'); % get actual sampling rate of data based on DAQ limits
[v_mic,time] = startForeground(s); % Collect data
%}
end