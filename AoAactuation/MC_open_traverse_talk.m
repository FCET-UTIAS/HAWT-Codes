function [s_port] = MC_open_traverse_talk(comport)

%---------------------------------------------------------------------------
% Function to open communication with the traverse
% Description: Opens the serial port to the motor control box (CR
% terminator, 9600 baud), clears the command string, enables the mode
% command, and calls MC_init so that everything starts off. Then sets the
% initial speed and motion parameters for the skewdrive (first rate 40,
% max rate 80, slope 40). The returned port is used by the other MC_
% functions and should be closed with MC_quit.
%
% INPUTS: comport - motor port connection, e.g. 'COM1'
% OUTPUTS: s_port - serial port object for the motor control box
%
% HISTORY: 
% 
%---------------------------------------------------------------------------
 
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
