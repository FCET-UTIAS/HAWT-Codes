function MCtravfunc(dist,dir,gain)

%---------------------------------------------------------------------------
% Function to move the traverse by a distance
% Description: Moves the traverse (motor 2 on the motor control box, COM3)
% by the requested distance in the requested direction. The distance is
% converted to motor steps using the step angle and screw pitch from the
% spec sheet (1.8/4 deg per pulse, 2 mm per revolution, which is 400 steps
% per mm), multiplied by a gain. The function returns after sending the
% command and does not wait for the move to finish.
%
% INPUTS: dist - distance to move (mm), from 0 to 200
%         dir  - direction, '+' or '-'
%         gain - scale factor applied to the number of steps (1 for the
%                nominal distance)
% OUTPUTS: N/A
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

if dist<0
    error
elseif dist>200
    error
end


% pause(10);
travstepangle=1.8/4; % deg/pulse, spec sheet
travscrewpitch=2/360; %mm/deg
travRes=travstepangle*travscrewpitch;

motorNum=2;

stepNum=dist/travRes*gain;

s_port = MC_open_traverse_talk('COM3');

disp('Connected')

MC_select_motor(s_port,motorNum,1);

disp('Motor Selected')
  
MC_move_stepper(s_port,stepNum,dir);
% dir: '+', '-'

disp('Command Sent')

MC_quit;

disp('Program Completion')
end
