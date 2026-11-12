%% PIV_seederRakeTraverse.m


%% Input
xTraverse=input("Enter the amount to move the rake horizontally towards the door (cm)");
yTraverse=input("Enter the amount to move the rake vertically (cm)");

%% Execution
addpath(genpath('../CalibrationData'))
addpath(genpath('../ConfigurationData'))
addpath(genpath('../Subfunctions'))

disp('Moving the PIV seeder rake ...')

if xTraverse<0
    xdir='-';
    xTraverse=abs(xTraverse);
else 
    xdir='+';
end
if yTraverse<0
    ydir='-';
    yTraverse=abs(yTraverse);
else 
    ydir='+';
end

if xTraverse ~=0
    MCtravfunc(xTraverse*10,xdir,2) % dist: in mm
    disp('Moving in the x direction ...')
    pause(xTraverse*5+5)
else 
    disp('Not moving in the x direction ...')
end

if yTraverse ~=0
    MCtravfunc(yTraverse*10,ydir,3) % dist: in mm
    disp('Moving in the y direction ...')
    pause(yTraverse*5+5)
else 
    disp('Not moving in the y direction ...')
end
disp('The PIV seeder rake motion complete')


rmpath(genpath('../CalibrationData'))
rmpath(genpath('../ConfigurationData'))
rmpath(genpath('../Subfunctions'))

