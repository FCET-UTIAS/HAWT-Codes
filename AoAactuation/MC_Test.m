%---------------------------------------------------------------------------
% Script to test the traverse motor connection
% Description: Opens the serial connection to the motor control box on COM1,
% selects motor 1, sends a 1000 step move in the '-' direction, then closes
% the connection. Used to check that the MC motor is connected and
% functioning. The variables steps_to_mm and inverse_motor_speed are defined
% but not used by this script.
%
% INPUTS: N/A
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

steps_to_mm = 800;
inverse_motor_speed = 2.3/10;

s_port = MC_open_traverse_talk('COM1');

disp('Connected')

MC_select_motor(s_port,1,1);

disp('Motor Selected')

MC_move_stepper(s_port,1000,'-');

disp('Command Sent')

MC_quit;

disp('Program Completion')
