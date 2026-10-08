%%
dP = mean_u_fs_offset_weighted_pretap.^2.*rho_air*(1 - AR^2)/2;
AR_new = 0.838^2;
% AR_nozzle = (0.874/0.6)^2;
AR_nozzle = 1;
v_expected_new = (dP*2./rho_air/(1 - AR_new^2)).^0.5*AR_nozzle;
Cal_coef_taps = polyfit(V_test,v_expected_new,1);
Cal_coef_pitot = polyfit(V_test,mean_u_fs_offset_weighted_pitot,1);
figure;
plot(V_test,mean_u_fs_offset_weighted_pitot,'o',V_test,v_expected_new,'s','LineWidth',2);
hold on
plot(0:1:10, Cal_coef_taps(1)*(0:1:10) + Cal_coef_taps(2),'color',[0.8500 0.3250 0.0980])
hold off
hold on
plot(0:1:10, Cal_coef_pitot(1)*(0:1:10) + Cal_coef_pitot(2),'color',[0 0.4470 0.7410])
hold off
xlabel('Voltage input [V]');
ylabel('Velocity [m/s]');
legend('Pitot tube measurement','Pressure taps measurement');
% %%
% b = gcf;
% 
% mean_u_fs = mean(u_fs);
% mean_v_expected = mean(v_expected);
% plot(V_test,mean_u_fs,'o--',V_test,mean_v_expected,'s--','LineWidth',2);