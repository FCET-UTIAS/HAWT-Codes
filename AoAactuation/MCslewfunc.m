function MCslewfunc(angle,dir)
% angle: in degree

%---------------------------------------------------------------------------
% Function to rotate the angle of attack (AoA) slew drive
% Description: Moves the AoA slew drive (motor 1 on the motor control box,
% COM3) by the requested angle in the requested direction. The direction of
% the previous move is stored in premove.mat; when the new direction differs,
% an extra 0.5 deg is added to take up backlash. Because the wire was
% flipped in February 2024, the direction given is reversed before it is
% sent. The function waits 3 s per degree for the move to finish, then
% saves the direction used to premove.mat for the next call. The angle is
% the amount to rotate, not an absolute position.
%
% INPUTS: angle - angle to rotate (deg), from 0 to 30
%         dir   - direction, '+' or '-' (reversed internally, see above)
% OUTPUTS: N/A (updates premove.mat in the AoAactuation folder)
%
% HISTORY: 
%   February 2024: The wire was flipped. Direction reversed in the code.
% 
%---------------------------------------------------------------------------

%% Load which direction the slew drive was moved. Correct for backlash if necessary
oldDir=cd("F:\ExCamp2\Subfunctions\AoAactuation");
structdir=load('premove.mat'); 
cd(oldDir)

premove=structdir.premove;
if angle<0
    error
elseif angle>30
    error
end

% February 2024: The wire was flipped. Reverse the direction

if strcmp(dir,'-')
    dir='+';
elseif strcmp(dir,'+')
    dir='-';
end



res=1.8/40/44/4; % deg/steps

if premove==dir
    stepNum=angle/res;

else %if previous direction does not match current direction
    stepNum=(angle+0.5)/res;
end

motorNum=1;

s_port = MC_open_traverse_talk('COM3');

disp('== AoA: Stepper motor controller connected')

MC_select_motor(s_port,motorNum,1);

disp('== AoA stepper motor selected')
  
MC_move_stepper(s_port,stepNum,dir);
% dir: '+', '-'

disp('== AoA stepper command sent')

MC_quit(s_port);

pause(angle*3)

disp('== Program completion')

premove=dir;

oldDir=cd("F:\ExCamp2\Subfunctions\AoAactuation");
save('premove.mat','premove')
cd(oldDir)
end
