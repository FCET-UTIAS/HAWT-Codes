function move_spanwise_dir(distance_in_mm, direction, verbose)
 
%---------------------------------------------------------------------------
% Function to move the traverse in the spanwise direction
% Description: Moves the spanwise axis (motor 1 on the motor control box)
% by the requested distance. The named direction is converted to a motor
% direction ('UP' = '-', 'DOWN' = '+') and the distance to steps at 800
% steps per mm. The function returns after sending the command and does
% not wait for the move to finish.
%
% INPUTS: distance_in_mm - distance to move (mm)
%         direction      - 'UP' or 'DOWN' (not case sensitive)
%         verbose        - (optional) nonzero to display progress messages,
%                          default 0
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

if upper(string(direction)) == "UP"
    sign = '-';
elseif upper(string(direction)) == "DOWN"
    sign = '+';
end

steps = distance_in_mm*800;
if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk; %('COM4');  % Use COM8 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 1, 1);  

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit;

disp(' ');
disp('Traverse movement completed');
