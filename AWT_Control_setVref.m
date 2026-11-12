function AWT_Control_setVref(voltage)
% This program sets the voltage reference value used by the Baldor motor
% controller.

% device voltage limits
vmax = 10;
vmin = 0;
% ensure voltage is between device limits
if voltage < vmin || voltage > vmax
    display('Error: argument out of allowable range');
    return
end

% Direction reversal hardwired in motor driver box
%voltage = -voltage;

s1 = daq.createSession('ni');
chans_Vref = addAnalogOutputChannel(s1,'Dev1','ao0','Voltage');


% set(chans_Vref,'OutputRange',[-vmax vmax]);
queueOutputData(s1,voltage);
startForeground(s1);

delete(s1)
clear s1

assignin('base', 'voltage',voltage)
