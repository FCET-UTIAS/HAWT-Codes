

%% Input
AoA=10;
gearBoxGain=10;
channel=4;
c=12*25.4;
load("planeLoc.mat")
disp(strcat("The plane is currently at ",num2str(planeLoc*c)," from the leading edge"))
disp("in the chordwise location")
XlocXC_c=input("Enter the plane to move to (x/c): ");

load("planeLoc.mat")

Xtraversemm_s=(XlocXC_c-planeLoc)*c*cosd(AoA);
motorNum=2;

%% Execution
disp('Moving the PIV optical table')
addpath("F:\ExperimentalCampaign3\Subfunctions\AoAactuation")
if Xtraversemm_s<0
    dir='-';
    Xtraversemm_s=abs(Xtraversemm_s);
else 
    dir='+';
end

disp('Moving in the y direction ...')
MCtravTablefunc(Xtraversemm_s*gearBoxGain,dir,motorNum) % dist: in mm
pause(Xtraversemm_s*5+5)
disp('Motion complete')

planeLoc=XlocXC_c;
    
save("planeLoc.mat","planeLoc")

