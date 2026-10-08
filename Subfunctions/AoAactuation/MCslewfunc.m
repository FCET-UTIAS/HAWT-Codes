function MCslewfunc(angle,dir)
% angle: in degree
% Test MC motor if it is connected and functioning

%% Load which direction the slew drive was moved. Correct for backlash if necessary
oldDir=cd("I:\ExCamp1\Subfunctions\AoAactuation");
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


% pause(10);
res=1.8/40/44/4; % deg/steps

if premove==dir
    stepNum=angle/res;
else
    %stepNum=(angle+0.376)/res; May 2023
    %stepNum=(angle+0.75)/res;
    stepNum=(angle+1.25)/res;
%{
elseif premove=='-'
    stepNum=(angle+0.16)/res;
    %stepNum=(angle+0.376)/res;
    %stepNum=(angle+0)/res;
elseif premove=='+'
    stepNum=(angle+0.16)/res;
    stepNum=(angle-0.16)/res;
    %stepNum=(angle-0.376)/res;
    %stepNum=(angle-0)/res;
%}
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

oldDir=cd("I:\ExCamp1\Subfunctions\AoAactuation");
save('premove.mat','premove')
cd(oldDir)
end
