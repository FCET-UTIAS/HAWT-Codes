% function threeTraverse_HWRake(steps, sign)
% For the 1.3m traverse:
%   800 steps = 1 mm
%   "+" = left; "-" = right

% Type in 1 for horizontal, 2 for vertical
dist_mm = 300;
% Port 2 is the bottom traverse, '+' is to the left
% Port 3 is the second vertical traverse, '+' is going up
% Port 4 is the first vertical traverse, '+' is going down
sign = '+';  % '+' for left and '+' for up
test_case = 2;  % 1 for horizontal, 2 for vertical

steps_per_mm = 800;
steps = dist_mm * steps_per_mm;

s_port = MC_open_traverse_talk;  % Use COM8 on the anechoic WT computer | COM4 on CCD computer
disp('Motor Connected')

if test_case == 1  % Horizontal
    
    MC_select_motor(s_port, 2, 1);
    disp('Motor Selected')
    MC_move_stepper(s_port, steps, sign);
    disp('Command Sent')
    
elseif test_case == 2  % Vertical
    % Split steps between the two vertical traverses
    stepshalf = steps/2;
    % Swap the signs b/c the traverses have opposite directions
    sign1 = sign;
    if sign == '+'
        sign2 = '-';
    elseif sign == '-'
        sign2 = '+';
    end
    
    MC_select_motor(s_port, 3, 1);
    disp('Motor 1 Selected')
    MC_move_stepper(s_port, stepshalf, sign1);
    disp('Command 1/2 Sent')
    MC_quit;
    pause(3)
    s_port = MC_open_traverse_talk;
    MC_select_motor(s_port, 4, 1);
    disp('Motor 2 Selected')
    MC_move_stepper(s_port, stepshalf, sign2);
    disp('Command 2/2 Sent')
end

MC_quit;
disp('Program Completion')
