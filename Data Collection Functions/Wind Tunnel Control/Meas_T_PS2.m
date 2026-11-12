function [T,PT_data] = Meas_T_PS2(channel, f_s,time, ind)
    

        % Configurate the data acquisition
        s1 = daq.createSession('ni');
        s1.Rate=f_s;
        s1.DurationInSeconds=time;
        chans_PT = s1.addAnalogInputChannel('Dev5',channel,'Voltage');
        set(s1.Channels,'TerminalConfig','SingleEnded');
                 
        % Start sampling
        PT_data=startForeground(s1);
        
         % Clear DAQ from system
        delete(s1);
        if ind ==1 
            T = USB_TC01_read();
        else
            T = 'NA';
        end
end

