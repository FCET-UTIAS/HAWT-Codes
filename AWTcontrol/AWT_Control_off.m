function AWT_Control_off(voltage)

%---------------------------------------------------------------------------
% Function to gradually turn off Wind Tunnel
% Description: Ramps the motor controller voltage reference down in 2 V
% steps (pausing between steps), sets the reference to 0 V, then sends a 
% logic LOW on digital line 7 of Dev5 to disable the motor controller.
%
% INPUTS: voltage - current voltage reference (V), maximum 10
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

warning('off')
disp('Shutting AWT off...');

pause_time = 10;

if voltage > 10
    disp('Error: Specified voltage is above maximum limit')
    AWT_Control_setVref(10);
end

while voltage > 2
    % Slow down AWT before shutoff
    voltage = voltage - 2;
    AWT_Control_setVref(voltage);
    pause(pause_time);
end

AWT_Control_setVref(0);

s = daq.createSession('ni');
addDigitalChannel(s,'Dev5','port0/line7','OutputOnly');
outputSingleScan(s,0)

warning('on')

delete(s);
clear s
pause(10)
disp(['AWT has been turned off']);
