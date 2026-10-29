function AWT_Control_setVref(voltage)

%---------------------------------------------------------------------------
% Function to set the motor controller voltage reference
% Description: Checks the requested voltage against the device limits
% (0 to 10 V), then outputs it on analog output channel ao0 of Dev5, which
% is the reference input to the Baldor motor controller. The value set is
% also saved to the base workspace as 'voltage'.
%
% INPUTS: voltage - desired reference voltage (V), between 0 and 10
% OUTPUTS: N/A (writes 'voltage' to the base workspace)
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

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

% Create session and analog output channel for the reference signal
s1 = daq.createSession('ni');
chans_Vref = addAnalogOutputChannel(s1,'Dev5','ao0','Voltage');

% set(chans_Vref,'OutputRange',[-vmax vmax]);
queueOutputData(s1,voltage);
startForeground(s1);

delete(s1)
clear s1

assignin('base', 'voltage',voltage)
