function AWT_Control_on

%---------------------------------------------------------------------------
% Function to turn on Wind Tunnel
% Description: Creates a new NI DAQ session, enables the motor controller through 
% digital line 7 on Dev5 and sets reference voltage to 0 V, and then releases the 
% DAQ session.
%
% INPUTS: N/A
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

warning('off')
s = daq.createSession('ni');
addDigitalChannel(s, 'Dev5', 'port0/line7', 'OutputOnly');
outputSingleScan(s,1)

AWT_Control_setVref(0);
warning('on')
delete(s);
clear s
