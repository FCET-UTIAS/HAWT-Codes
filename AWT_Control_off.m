function AWT_Control_off(voltage)
warning('off')
disp('Shutting AWT off...');

pause_time = 5;

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
addDigitalChannel(s,'Dev1','port1/line0','OutputOnly');
outputSingleScan(s,0)

warning('on')

delete(s);
clear s
pause(10)
disp(['AWT has been turned off']);