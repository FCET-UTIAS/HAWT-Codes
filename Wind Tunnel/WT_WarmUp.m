function [] = WT_WarmUp(T_C)
global WT

WTSpeedSet_v0(17, 1, 1, 15, 0.1);

Tmeas_degC = 0;
while Tmeas_degC < T_C
    pause(60)
    Tmeas_degC = Meas_TC;
    fprintf('T = %f deg C\n', Tmeas_degC);
end
fprintf('Shutting down the wind tunnel\n')
WT_shutdown;
pause(30)