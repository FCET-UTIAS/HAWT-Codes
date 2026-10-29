function [s_port] = open_traverse_talk

%---------------------------------------------------------------------------
% Function to open communication with the traverse (fixed port)
% Description: Near-identical copy of MC_open_traverse_talk. The only
% difference is that the port is fixed to COM5 in the code instead of being
% passed in. Opens the serial port to the motor control box (CR terminator,
% 9600 baud), clears the command string, enables the mode command, and
% calls MC_init so that everything starts off. Then sets the initial speed
% and motion parameters (first rate 40, max rate 80, slope 40). The
% returned port should be closed with MC_quit.
%
% WHY IT EXISTS: move_spanwise_dir, move_streamwise_dir and
% move_wall_normal_dir open the connection with no input, which only works
% with a fixed-port opener like this one. NOTE: those functions currently
% call MC_open_traverse_talk, which requires a port input, so as written
% this function is not called by them. Either point them at this function,
% or give MC_open_traverse_talk a default port, after which this function
% is redundant.
%
% INPUTS: N/A (the port is fixed to COM5 in the code)
% OUTPUTS: s_port - serial port object for the motor control box
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

    s_port = serial('COM5');            % Choose motor port
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
