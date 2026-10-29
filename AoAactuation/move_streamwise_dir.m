function move_streamwise_dir(distance_in_mm, direction, verbose)

%---------------------------------------------------------------------------
% Function to move the traverse in the streamwise direction
% Description: Moves the streamwise axis (motor 2 on the motor control box)
% by the requested distance. The named direction is converted to a motor
% direction ('UPSTREAM' = '+', 'DOWNSTREAM' = '-') and the distance to
% steps at 800 steps per mm (1.3 m traverse). The function returns after
% sending the command and does not wait for the move to finish.
%
% INPUTS: distance_in_mm - distance to move (mm)
%         direction      - 'UPSTREAM' or 'DOWNSTREAM' (not case sensitive)
%         verbose        - (optional) nonzero to display progress messages,
%                          default 0
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

% For the 1.3m traverse:
%   800 steps = 1 mm
%   "+" = inside; "-" = outside

if upper(string(direction)) == "UPSTREAM"
    sign = '+';
elseif upper(string(direction)) == "DOWNSTREAM"
    sign = '-';
end

steps = distance_in_mm*800;
if exist('verbose') == 0
    verbose = 0;
end

s_port = MC_open_traverse_talk;  % Use COM8 on the anechoic WT computer

if verbose ~= 0; disp('Motor connected'); end

MC_select_motor(s_port, 2, 1);  

if verbose ~= 0; disp('Motor selected'); end
  
MC_move_stepper(s_port, steps, sign);

if verbose ~= 0; disp('Command sent'); end

MC_quit(s_port);


disp(' ');
disp('Traverse movement completed');
