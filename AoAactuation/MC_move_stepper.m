function MC_move_stepper(s_port, num_step, direction)

%---------------------------------------------------------------------------
% Function to move the stepper motor (standard speed)
% Description: Sets the speed parameters (first rate 30, max rate 50,
% slope 30), then sends the direction, the number of steps and the go
% command to the stepper motor controller. The speed is reset on every
% call. The function returns after sending the commands and does not wait
% for the move to finish. A motor must already be selected with
% MC_select_motor. For a slower move with gentler acceleration, use
% MC_move_stepper_med.
%
% INPUTS: 
%         s_port    - serial port information
%         num_step  - integer number of steps to rotate the traverse
%         direction - '+' or '-'. Required by the current code, since it is
%                     sent to the controller on every call.
% OUTPUTS: N/A
%
% HISTORY: 
%   Modified May 10, 2012 (Jason H.) - to reset speed on every command.
% 
%---------------------------------------------------------------------------
 
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
