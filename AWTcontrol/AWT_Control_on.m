% Function to turn on Wind Tunnel - currently just copied straight from Code 1 AWTcontrol

function AWT_Control_on
% 
warning('off')
s = daq.createSession('ni');
addDigitalChannel(s, 'Dev5', 'port0/line7', 'OutputOnly');
outputSingleScan(s,1)

AWT_Control_setVref(0);
warning('on')
delete(s);
clear s
