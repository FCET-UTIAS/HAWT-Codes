.%% 
% Measure Cp for 60 sec. See how the error bar converges. Use the equation
% from AER303 to calculate the convergence.


% Process:
% 1: Measure the signal for 60 seconds at 4000 Hz
% 2: Calculate integral time scale. The sampling rate should be more than
%    double the time scale
% 3: 



%% Input
clc;

TempCelcOnline=input('Input the current temperature in Celcius.','s');
PresPascOnline=input('Input the current atmospheric pressure in Pascal.','s');

% Confirm the input
disp('Confirmation:')
disp(strcat('Tunnel Speed definition: Uinf'))
disp(strcat('Atmospheric temperature:',num2str(TempCelcOnline),' c'))
disp(strcat('Atmospheric pressure:',num2str(PresPascOnline),' c'))
disp(strcat('Trip status: No trip????'))
disp(strcat('Angle of attack: 10 deg geometric'))
pause(0.5)
input('Hit enter to continue.');
pause(0.5)
input('Confirm that the AoA is 10 degrees on the turn table. Run.')

% Baratron calibration
BaratronChoice=input('Choose if calibration of Baratron is necessary [Y/N]','s');
if strcmp(BaratronChoice,'N')
    disp('Choose the calibration constant ...')
    pause(0.5)
    OldPath=cd('F:/ExCamp1/CalibrationData/BaratronCalibration');
    uigetfile;
    cd(OldPath);
    clear OldPath
elseif strcmp(BaratronChoice,'Y')
    BaratronOffsetVolt=BaratronCalibration;
else
    disp('Invalid choice')
end

%% Initialize: Run f_s=4000 Hz and t_s=60 sec
% Sweep parameters
AoAvec=[0 10];
Utarget=[50];
R=287; % J/kg/K
TempKelvinOnline=TempCelcOnline+273.16;
f_sZOC=4000;
t_sZOC=60;
N=t_sZOC*f_sZOC;

%% Loop through the conditions

% Begin AoA loop
for AoAind=1:length(AoAvec)
    if AoAind~=1
        % Change the AoA
        disp(strcat('Actuating the AoA to ',num2str(AoAvec(AoAind)),'deg'))
        AoAactuation(AoAvec(AoAind-1),AoAvec(AoAind),PreviousMotionDir)
    end
    
    % Begin velocity loop
    AWT_Control_on % Turn on the wind tunnel control
    for Uind=1:length(Utarget)
        status=AWT_Control_Integrated_func(Utarget(Uind),PresPascOnline,TempCelcOnline,BaratronOffsetVolt,tunnelOn);
        [ZOCraw, ~, ZOCstddev]=SupercriticalZOCmeas(f_sZOC,t_sZOC);
        
        [~,TapNum]=size(ZOCraw);
        for i=1:TapNum
            [Bxx,lags] = autocorr(ZOCraw(:,i));
            tau=lags/f_s;
        end
        IntTimeScale=trapz(tau,Bxx);
        IntTimeScale2=IntTimeScale*2;
        
        P=1.96*ZOCstddev/sqrt(N);
        
        disp(strcat('The minimum integral time scale is ',num2str(min(IntTimeScale)),' sec.'))
        disp(strcat('The maximum integral time scale is ',num2str(max(IntTimeScale)),' sec.'))
        disp(strcat('The minimal sampling frequency is ',num2str(1/(2*min(IntTimeScale))),' sec.'))
        disp('This will provide statistical independence of each sample.')
        disp('----------------------------')
        disp(strcat('The measured mean is within ',num2str(P),' of the actual mean with 95% confidence'))
        
        % Plot the result
        figure(AoAind)
        TapGroup1=["A","B"];
        TapGroup2=["C","D","E"];
        TapNum1=-1*ones(length(TapGroup1),1);
        TapNum2=-1*ones(length(TapGroup2),1);
        ZOCportID1=funcZOCconfigurationDefinition(TapGroup1,TapNum1);
        ZOCportID2=funcZOCconfigurationDefinition(TapGroup2,TapNum2);
        xTapPos1=[];
        xTapPos2=[];
        xType='x/c';
        for i=1:length(TapGroup1)
            xTapPosTemp1=load(strcat('TapLoc',TapGroup1(i),'.mat'));
            xTapPos1=[xTapPos1;xTapPosTemp1.TapLocxc];
        end
        for i=1:length(TapGroup2)
            xTapPosTemp2=load(strcat('TapLoc',TapGroup2(i),'.mat'));
            xTapPos1=[xTapPos2;xTapPosTemp2.TapLocxc];
        end
        figure(1)
        plot(xTapPos1,ZOCraw(ZOCportID1))
        figure(2)
        plot(xTapPos2,ZOCraw(ZOCportID2))
        title(strcat(VelocityType,' sweep, AoA=',num2str(AoAvec(AoAind)),'deg'))
        legendVec=[];
        for i=1:length(VelocityVec)
            legendVec=[legendVec strcat('$U_\infty=',num2str(Velocity(i)),'$ m/s')];
        end
        xlim([-0.1 1.1]);
        legend(legendVec)
        
        % Save the data
        date_time = datestr(now,'mm-dd-yyyy_HH-MM');
        OldPath=cd('F:/ExCamp1/Data/ZOC/Uinf');
        save(strcat('CpUncertaintyMeas_U=',num2str(ReTarget(Uind)),'_AoA=',num2str(AoAvec(AoAind)),'(geometric)_',date_time,'.mat'))
        cd('OldPath')
    end % End velocity loop
    AWT_Control_off(1)
    figure(AoAind)
    % Plot CFD data
    legendVec=[legendVec "CFD"];
    legend(legendVec)
    
end % end AoA loop