function MC_init(s_port)

%---------------------------------------------------------------------------
% Function to initialize the motor control box
% Description: Turns all of the outputs (LEDs) on the control box off so
% that it starts from a known state. Enables communication between the
% computer and the controller, then steps through output bits Out 0 to
% Out 7 (addressed with bits 2, 3 and 4, with bit 1 as the data bit) as
% described in the inline comments, and finishes by setting bit 7 so the
% bits can change without turning anything on or off by accident.
%
% INPUTS: s_port - serial port that the motor control box is connected to
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------
 
%% Main Code
fprintf(s_port, '/b 0')     % set B0 = 0 (on)  - allows the computer to talk to the controller

fprintf(s_port, '/b 7')     % Write output port; Clear all outs
fprintf(s_port, 'b 1')      % Set data bit hi

fprintf(s_port, '/b 2')
fprintf(s_port, '/b 3')     % b2 b3 b4 Out bit
fprintf(s_port, '/b 4')     % 0  0  0  Out 0
fprintf(s_port, 'b 2')      % 1  0  0  Out 1

fprintf(s_port, '/b 2')     % 0
fprintf(s_port, 'b 3')      % 0  1  0  Out 2
fprintf(s_port, 'b 2')      % 1  1  0  Out 3
fprintf(s_port, '/b 2')     % 0

fprintf(s_port, '/b 3')     %    0
fprintf(s_port, 'b 4')      % 0  0  1  Out 4
fprintf(s_port, 'b 2')      % 1  0  1  Out 5
fprintf(s_port, '/b 2')     % 0

fprintf(s_port, 'b 3')      % 0  1  1  Out 6
fprintf(s_port, 'b 2')      % 1  1  1  Out 7

fprintf(s_port, 'b 7') % Allows bits to change without stuff turning on an off by accident.

