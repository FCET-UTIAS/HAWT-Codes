function status = AWT_Control_Integrated_func(speed_target, P_atm_in, T, v_fs_offset_initial, VelocityType)

%---------------------------------------------------------------------------
% Function to set and verify the Wind Tunnel speed
% Description: Converts the requested target (velocity, chord Reynolds
% number or Mach number) to a tunnel velocity, sets the motor controller
% voltage from the speed calibration, then measures the speed with the
% Baratron and corrects the voltage until the measured speed is within
% tolerance of the target. Corrections are damped (decreasing gain) to avoid
% oscillation. The loop ends when:
%   - the speed is within tolerance (converged),
%   - the speed error exceeds the abort limit (likely a bad Baratron
%     reading; the voltage is left unchanged), or
%   - the maximum number of measurements is reached (a warning is issued).
%
% INPUTS: 
%         speed_target        - target value, units set by VelocityType
%         P_atm_in            - atmospheric pressure (kPa)
%         T                   - air temperature (deg C), used for the
%                               initial voltage estimate only
%         v_fs_offset_initial - Baratron zero offset voltage (V)
%         VelocityType        - 'Uinf' (m/s), 'Re' (chord Reynolds number)
%                               or 'Ma' (Mach number)
% OUTPUTS: 
%            status - struct with fields:
%            Utarget, Ufinal, stdUfinal (m/s), MaFinal, Refinal, T (deg C),
%            Vcurrent (V), Qactual (Pa), V_baratron (V),
%            Converged, Aborted (logical), Iterations
%
% HISTORY:
%   Created  - Zhe Lu (2022-06)
%   Modified - Satoshi Baba (2022-08)
%   Modified - Arshia Singh (2026-10): added convergence check and abort guard, cleanup
%---------------------------------------------------------------------------

%% Settings
fs_Baratron = 4000;          % Baratron sampling rate (Hz)
t_settle_init = 30;          % settle time after the first voltage set (s)
t_settle = 15;               % settle time after each correction (s)
t_meas = 15;                 % Baratron measurement time (s)

gain = [1 0.5 0.25];         % damping gain for each correction
maxIter = numel(gain) + 1;   % max measurements = one per correction + final check
tol = 0.01;                  % converged when |error| <= tol * target
abortLimit = 7;              % abort if |error| (m/s) exceeds this (bad reading)

ChordLength = 12*0.0254;     % chord length, 12 inches (m)
gamma = 1.4;                 % ratio of specific heats for air
R = 287;                     % gas constant for air (J/kg-K)

calFile = 'I:\ExCamp1\CalibrationData\TunnelSpeedCalibration\CalculatedAR_03-07-2026_10-34.mat';
% Previous calibration: CalculatedAR_05-15-2026_21-47.mat

%% Load tunnel calibration
load(calFile, 'Cal_coef', 'AR_new');
AR = AR_new;                         % contraction area ratio used in the speed equation

%% Fixed parameters
P_atm = P_atm_in*1e3*0.0075;         % atmospheric pressure, kPa to mmHg
range = 100;                         % Baratron range (torr), 10 or 100
P_gain_fs = 133.322*range/10;        % MKS 120AD gain: volts to Pa for the chosen range

%% Initial voltage from calibration
[rho_air, muAtm, ~, ~] = fluid_prop(T, P_atm);
nuAtm = muAtm/rho_air;
U_target = target_velocity(speed_target, VelocityType, nuAtm, T, ChordLength, gamma, R);

V_target = AWT_Control_U2V_Creighton(U_target, Cal_coef(1), Cal_coef(2));
AWT_Control_setVref(V_target);

disp('Initial voltage set, waiting for the flow to settle...')
pause(t_settle_init);

%% Measure, check, and correct
converged = false;
aborted = false;

for i = 1:maxIter
    disp(['Wait for the flow to settle (' num2str(t_settle) ' sec)'])
    pause(t_settle);
    disp(['Speed measurement (' num2str(t_meas) ' sec)'])

    [T, PT_e] = Meas_T_PS(fs_Baratron, t_meas);
    [rho_air, muAtm, ~, ~] = fluid_prop(T, P_atm);   % update air properties
    nuAtm = muAtm/rho_air;

    % Re and Ma targets depend on temperature, so recompute the target
    U_target = target_velocity(speed_target, VelocityType, nuAtm, T, ChordLength, gamma, R);

    % Speed from the contraction pressure drop (sign() avoids 0/0 = NaN)
    Qactual = (PT_e - v_fs_offset_initial)*P_gain_fs;
    UactualTime = sqrt(abs(2*Qactual/(rho_air*(1 - AR^2)))).*sign(Qactual);
    Uactual = mean(UactualTime);
    stdUactual = std(UactualTime);
    err = U_target - Uactual;

    disp(['Iteration ' num2str(i) ': V=' num2str(V_target) ', U=' num2str(Uactual) ...
          ' m/s, target=' num2str(U_target) ' m/s, error=' num2str(err) ' m/s'])

    % Abort if the error is implausibly large (likely a bad Baratron reading)
    if abs(err) > abortLimit
        aborted = true;
        warning('AWT_Control_Integrated_func:Aborted', ...
            ['Speed error of %.2f m/s exceeds the %.1f m/s limit. Baratron reading likely ' ...
             'incorrect; voltage left at %.3f V.'], err, abortLimit, V_target);
        break
    end

    % Stop once the speed is within tolerance
    if abs(err) <= tol*U_target
        converged = true;
        break
    end

    % Out of measurements: keep the voltage so the final data matches V_target
    if i == maxIter
        break
    end

    % Damped, multiplicative correction (assumes V is linear in U)
    V_target = V_target*(1 + (err/U_target)*gain(i));
    AWT_Control_setVref(V_target);   % voltage limits are enforced inside setVref
end

if ~converged && ~aborted
    warning('AWT_Control_Integrated_func:NotConverged', ...
        'Speed not within %.1f%% of target after %d measurements (error = %.2f m/s).', ...
        tol*100, i, err);
end

ReActual = Uactual*ChordLength/nuAtm;
disp(['Final speed: V=' num2str(V_target) ', U=' num2str(Uactual) ' m/s'])

%% Output
status.Utarget = U_target;
status.Ufinal = Uactual;
status.stdUfinal = stdUactual;
status.MaFinal = Uactual/sqrt(gamma*R*(T + 273.15));
status.Refinal = ReActual;
status.Vcurrent = V_target;
status.Qactual = Qactual;
status.T = T;
status.V_baratron = PT_e;
status.Converged = converged;
status.Aborted = aborted;
status.Iterations = i;
if strcmp(VelocityType, 'Ma')
    status.MaTarget = speed_target;
end

end

%% Local function
function U_target = target_velocity(speed_target, VelocityType, nuAtm, T, ChordLength, gamma, R)
% Converts the requested target (Uinf, Re or Ma) to a velocity in m/s
    switch VelocityType
        case 'Uinf'
            U_target = speed_target;
        case 'Re'
            U_target = speed_target*nuAtm/ChordLength;
        case 'Ma'
            U_target = speed_target*sqrt(gamma*R*(T + 273.15));
        otherwise
            error('Unknown VelocityType "%s". Use ''Uinf'', ''Re'' or ''Ma''.', VelocityType);
    end
end
