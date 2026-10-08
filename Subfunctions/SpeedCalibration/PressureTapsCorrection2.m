%%

OldPath=cd('G:\ExCamp1\CalibrationData\TunnelSpeedCalibration');

load("U_calib_pressure_system_03-07-2026_10-46.mat");
mean_u_fs_offset_weighted_pretaps = mean_u_fs;
dP = mean(q_fs);
load('U_calib_pitot_tube_03-07-2026_10-34.mat');
mean_u_fs_offset_weighted_pitot = mean_u_fs;
%dP = mean_u_fs_offset_weighted_pretaps.^2.*rho_air*(1 - AR^2)/2;

%%
AR_new = 0.52;

% AR_nozzle = (0.874/0.6)^2;
AR_nozzle = 1; % This is for the open-jet nozzle (second contraction)
v_expected_new = (dP*2./rho_air/(1 - AR_new^2)).^0.5*AR_nozzle;
InvCal_coef_taps = polyfit(V_test(1:9),v_expected_new(1:9),1);
InvCal_coef_pitot = polyfit(V_test(1:9),mean_u_fs_offset_weighted_pitot(1:9),1);
figure;
plot(V_test,mean_u_fs_offset_weighted_pitot,'o',V_test,v_expected_new,'s','LineWidth',2);
hold on
plot(0:1:10, InvCal_coef_taps(1)*(0:1:10) + InvCal_coef_taps(2),'color',[0.8500 0.3250 0.0980])
hold off
hold on
plot(0:1:10, InvCal_coef_pitot(1)*(0:1:10) + InvCal_coef_pitot(2),'color',[0 0.4470 0.7410])
hold off
xlabel('Voltage input [V]');
ylabel('Velocity [m/s]');
legend('Pitot tube measurement','Pressure taps measurement');


%{
pause(1)
saveOption=input("Save? [Y/N]","s")
if strcmp(saveOption,"Y")
    status=movefile(strcat('CalculatedAR_*.mat'), 'Legacy');
    save(strcat("CalculatedAR_" ,date_time,".mat"))
    disp('Completed and saved');
end
cd(OldPath)
%}
% %%
% b = gcf;
% 
% mean_u_fs = mean(u_fs);
% mean_v_expected = mean(v_expected);
% plot(V_test,mean_u_fs,'o--',V_test,mean_v_expected,'s--','LineWidth',2);