function [v_mic, T, ActualRate] = AWT_Meas_mic_T(t_samp, f_s, chan);
    
warning('off')
s1 = daq.createSession('ni');
%s1.addAnalogInputChannel('PXI1Slot2',[5 6 7],'IEPE');
 s1.addAnalogInputChannel('Dev1', 2,'Voltage');
 set(s1.Channels,'TerminalConfig','SingleEnded');
% data = zeros(5,1);
s1.Rate = f_s;
s1.DurationInSeconds = t_samp;
ActualRate = get(s1, 'Rate');

%         % Configurate the data acquisition
%         ai = analoginput('nidaq','PXI1Slot2');
        
%         chans_temp = addchannel(ai,[0,1]);
%         chans_MIC = addchannel(ai,chan);
        
%         set(ai,'SampleRate', );
%         set(ai,'InputType','Differential');
%                                      %Actual sampling rate not always was is asked for!!
%         set(ai, 'TriggerType', 'Manual', 'bufferingmode', 'auto');      %This way it waits for your command
%         set(ai,'SamplesPerTrigger', fix(t_samp*ActualRate));

        
%         trange = 10;
%         mrange = 10;
%         set(chans_temp,'SensorRange',[-trange trange],'InputRange',[-trange trange],'UnitsRange',[-trange trange],'Units','Volts')
%         set(chans_MIC,'SensorRange',[-mrange mrange],'InputRange',[-mrange mrange],'UnitsRange',[-mrange mrange],'Units','Volts')       
% 
%         
        % Start sampling
%         start(ai);
%         trigger(ai);
%         data = getdata(ai);
    [data,time] = startForeground(s1);
    plot(time,data);

        % Clear DAQ from system
        delete(s1);
        clear s1;

        % Separate output in variables
        
%         [T] = TC_CJC(data(:,2),data(:,1),'BNC-2120','T');

%         v_mic = data(:,3:(3+length(chan)-1));

% T = 26.92;
T = USB_TC01_read();
v_mic = data;
% v_mic = data(:,chan-4);
              
%         clear data      % Don't need anymore
end
