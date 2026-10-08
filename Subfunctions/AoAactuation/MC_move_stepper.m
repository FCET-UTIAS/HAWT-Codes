function MC_move_stepper(s_port, num_step, direction)
%MC_move_stepper
%   This function can be used to set the commands to the stepper motor
%   controller to move a number of steps 'num_step' in a given direction.
%
%   INPUTS: 
%       s_port - serial port information
%       num_step - integer number of steps to rotate traverse
%       direction - (optional) should be '+' or '-'. If not specified motor
%           will move in previously given direction
%
%   OUTPUTS:
%       none
% 
% Modified May 10, 2012 (Jason H.) - to reset speed on every command.
% -------------------------------------------------------------------------
%% Main Code
% set speed paramters
fprintf(s_port, 'f 30');        % Set first rate 
fprintf(s_port, 'r 50');        % Set max rate
fprintf(s_port, 's 30');        % Set slope 

% move stepper
fprintf(s_port, direction)
fprintf(s_port, ['n ', int2str(num_step)])
fprintf(s_port, 'g')

end