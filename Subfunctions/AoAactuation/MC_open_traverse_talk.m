function [s_port] = MC_open_traverse_talk(comport)
%MC_open_traverse_talk
%   Opens communication with the traverse.
%   Sets speed and motion parameters for skewdrive. 
%
%   INPUTS: 
%       comport (motor port connection)
%
%   OUTPUTS:
%       s_port 
%
%--------------------------------------------------------------------------
%% Main Code

    s_port = serial(comport);            % Choose motor port
    fopen(s_port);                      % Open the port
    set(s_port, 'Terminator', 'CR');    % Autodetect port settings
    pause(0.5);
    set(s_port, 'Terminator', 'CR');    % Do it twice (i dunno, but seems important)
    pause(0.5)
    set(s_port,'BaudRate',9600);        % Set Baudrate (not really needed)
    pause(0.2)
    
    % Initalize (make sure everything is off)
    fprintf(s_port, '\n')               % Clears the command string
    fprintf(s_port, 'o 0a0h')           % Enable the mode command
    MC_init(s_port);            
    pause(0.3)
    
% Set inital rates and slopes    
% Rates and slope
fprintf(s_port, 'f 40');        % Set first rate 
fprintf(s_port, 'r 80');        % Set max rate
fprintf(s_port, 's 40');        % Set slope 

end