function status=AWT_Control_Integrated_func(speed_target,P_atm_in,T,v_fs_offset_initial,VelocityType)

%AWT_Control_Integrated allows you to specify and change the wind tunnel
%velocity and saves the flow information
%   INPUTS:
%       
%
%   OUTPUTS: 
%       
%        
%
%   HISTORY:
%       Created - Zhe Lu (2022-06)
%       Modified - Satoshi Baba (2022-08)
% -------------------------------------------------------------------------%   

%%
%% Parameter Input
fs_Baratron = 4000;
ts_Baratron = 30;
%load('I:\ExCamp1\CalibrationData\TunnelSpeedCalibration\CalculatedAR_05-15-2026_21-47.mat',"Cal_coef","AR_new")
load('I:\ExCamp1\CalibrationData\TunnelSpeedCalibration\CalculatedAR_03-07-2026_10-34.mat',"Cal_coef","AR_new")
AR=AR_new;
%% Fixed Parameters
%AR = 0.845^2;
P_atm = P_atm_in*1e3*0.0075;   % [from kPa to mmHg]

range = 100;                      % range of pressure transducer, 10 or 100 torr
P_gain_fs = 133.322*range/10;    % for MKS 120AD on desired torr range, 10V range

%% Initial offset measurement

% if exist('v_fs_offset_initial') == 0
%     disp('Please ZERO the two Baratrons for initial offset measurement and press any key to continue...');
%     pause;
%     disp('BEGIN Pressure Transducer Offset ----------------------------------')
%     [~, PT_e] = Meas_T_PS(2, fs_Baratron, ts_Baratron, 0);
%     tic;        % Starting time of the Baratron offset
%     v_fs_offset_initial = mean(PT_e);
%     disp(['    Initial offset voltage is: ' num2str(v_fs_offset_initial,'%10.5f') ' V']);
%     disp('END Pressure Trasnsducer Offset -----------------------------------')
%     disp('-------------------------------------------------------------------')
%     disp('Restore the two Baratrons and press any key to continue...')
%     load('ChampionsLeagueSample.mat');
%     sound(ChampionsY, ChampionsFs);
%     pause;
% end

%% Velocity Control
                                                           % VFD initialization
[rho_air, muAtm, ~, ~] = fluid_prop(T, P_atm);                           % Target dynamic pressure calculation
nuAtm=muAtm/rho_air;
gamma=1.4;
R=287;

if strcmp(VelocityType,'Uinf')
    U_target=speed_target;
   
elseif strcmp(VelocityType,'Re')
    ChordLength=12*0.0254; % Chord length is 12 inches
    U_target=speed_target*nuAtm/ChordLength;
elseif strcmp(VelocityType,'Ma')
    U_target=speed_target*sqrt(gamma*R*(T+273.15));
end

[V] = AWT_Control_U2V_Creighton(U_target, Cal_coef(1), Cal_coef(2));        % Start the tunnel using Cal_coef
AWT_Control_setVref(V);
pause(30);

disp('Target velocity reached initially, starting correction...');
SpeedControlGain=[1 0.5 0.25];
V_target=V;
for i = 1:2
    disp("Wait for the flow to settle (15 sec)")
    pause(15);
    disp("Speed measurement (15 sec)")

    [T,PT_e] = Meas_T_PS(fs_Baratron, 10);
    [rho_air, muAtm, ~, ~] = fluid_prop(T, P_atm);   % update air density
    nuAtm=muAtm/rho_air;

    if strcmp(VelocityType,'Uinf')
        U_target=speed_target;
        %Utarget=[30 40 50];
    elseif strcmp(VelocityType,'Re')
        ChordLength=12*0.0254; % Chord length is 12 inches
        U_target=speed_target*nuAtm/ChordLength;
    elseif strcmp(VelocityType,'Ma')
        U_target=speed_target*sqrt(gamma*R*(T+273.15));
        status.MaTarget=speed_target;
    end

    Qactual = (PT_e - v_fs_offset_initial)* P_gain_fs;
    UactualTime=sqrt(abs(2*Qactual/(rho_air*(1 - AR^2)))).*(Qactual./abs(Qactual));
    Uactual = mean(UactualTime);
    stdUactual=std(UactualTime);
    disp(strcat("Iteration ",num2str(i),": V=",num2str(V_target),", U=",num2str(Uactual)," m/s"))
    V_target = V_target*(1+(1-Uactual/U_target)*SpeedControlGain(i));             % correct the input voltage based on linear assumption for the V-U curve
    AWT_Control_setVref(V_target);
end

disp(strcat("Final iteration. V=",num2str(V_target),", U=",num2str(Uactual)," m/s"))
disp("Wait for the flow to settle (15 sec)")
pause(15);
disp("Speed measurement (15 sec)")
[T,PT_e] = Meas_T_PS(fs_Baratron, 15);
[rho_air, muAtm,  ~, ~] = fluid_prop(T, P_atm);   % update air density
nuAtm=muAtm/rho_air;
Qactual = (PT_e - v_fs_offset_initial)* P_gain_fs;

UactualTime=sqrt(abs(2*Qactual/(rho_air*(1 - AR^2)))).*(Qactual./abs(Qactual));
Uactual = mean(UactualTime);
stdUactual=std(UactualTime);
ReActual=Uactual*0.3048/nuAtm;
disp(strcat("Final speed: V=",num2str(V_target),", U=",num2str(Uactual)," m/s"))



status.Utarget=U_target;
status.MaFinal=Uactual/sqrt(1.4*287*(T+273.15));
status.Ufinal=Uactual;
status.Refinal=ReActual;
status.stdUfinal=stdUactual;
status.Vcurrent=V_target;
status.Qactual=Qactual;
status.T=T;
status.V_baratron=PT_e;

end
