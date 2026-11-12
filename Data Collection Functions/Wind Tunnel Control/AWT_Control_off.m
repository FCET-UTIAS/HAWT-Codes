function AWT_Control_off(varargin)
warning('off')
disp('Shutting AWT off...');

if ~isempty(varargin)
    
    voltage = varargin{1};
    pause_time = 10;
    
    if voltage > 10
        disp('Error: Specified voltage is above maximum limit')
        AWT_Control_setVref(0);
    else
        
        % Slow down AWT before shutoff
        AWT_Control_setVref(0.75*voltage);
        pause(pause_time);
        AWT_Control_setVref(0.5*voltage);
        pause(pause_time);
        AWT_Control_setVref(0.25*voltage);
        pause(pause_time);
    end
    
end

AWT_Control_setVref(0);

s = daq.createSession('ni');
addDigitalChannel(s,'Dev5','port0/line7','OutputOnly');
outputSingleScan(s,0)

warning('on')

delete(s);
clear s
disp(['AWT has been turned off']);