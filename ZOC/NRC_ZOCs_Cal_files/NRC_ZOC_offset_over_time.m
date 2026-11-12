
load('offset_all_4_NRC_ZOCs_2023-05-12-13-11.mat')
v_offset_all_13_11 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-17.mat')
v_offset_all_13_17 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-23.mat')
v_offset_all_13_23 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-29.mat')
v_offset_all_13_29 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);

load('offset_all_4_NRC_ZOCs_2023-05-12-13-11.mat')
v_offset_all_12_37 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-17.mat')
v_offset_all_12_31 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-23.mat')
v_offset_all_12_24 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);
load('offset_all_4_NRC_ZOCs_2023-05-12-13-29.mat')
v_offset_all_12_18 = reshape(mean(Voltages),[num_sensors_per_ZOC,nzoc]);

% v_offset_all_M270 = [v_offset_all_12_18(:,1),v_offset_all_12_24(:,1),v_offset_all_12_31(:,1),v_offset_all_12_37(:,1)];
% v_offset_all_M276 = [v_offset_all_12_18(:,2),v_offset_all_12_24(:,2),v_offset_all_12_31(:,2),v_offset_all_12_37(:,2)];
% v_offset_all_M275 = [v_offset_all_12_18(:,3),v_offset_all_12_24(:,3),v_offset_all_12_31(:,3),v_offset_all_12_37(:,3)];
% v_offset_all_M267 = [v_offset_all_12_18(:,4),v_offset_all_12_24(:,4),v_offset_all_12_31(:,4),v_offset_all_12_37(:,4)];

v_offset_all_M270 = [v_offset_all_13_11(:,1),v_offset_all_13_17(:,1),v_offset_all_13_23(:,1),v_offset_all_13_29(:,1)];
v_offset_all_M276 = [v_offset_all_13_11(:,2),v_offset_all_13_17(:,2),v_offset_all_13_23(:,2),v_offset_all_13_29(:,2)];
v_offset_all_M275 = [v_offset_all_13_11(:,3),v_offset_all_13_17(:,3),v_offset_all_13_23(:,3),v_offset_all_13_29(:,3)];
v_offset_all_M267 = [v_offset_all_13_11(:,4),v_offset_all_13_17(:,4),v_offset_all_13_23(:,4),v_offset_all_13_29(:,4)];

%%
figure
bar(v_offset_all_M270)
ylabel('Voltage [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(v_offset_all_M276)
ylabel('Voltage [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(v_offset_all_M275)
ylabel('Voltage [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(v_offset_all_M267)
ylabel('Voltage [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

p_offset_all_M270 = v_offset_all_M270.*M270_poly.poly(:,1);
p_offset_all_M276 = v_offset_all_M276.*M276_poly.poly(:,1);
p_offset_all_M275 = v_offset_all_M275.*M275_poly.poly(:,1);
p_offset_all_M267 = v_offset_all_M267.*M267_poly.poly(:,1);

figure
bar(p_offset_all_M270)
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(p_offset_all_M276)
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(p_offset_all_M275)
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar(p_offset_all_M267)
ylabel('Pressure [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on


%%

figure
bar((v_offset_all_M270-v_offset_all_M270(:,1)))
ylabel('$\Delta V $ [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((v_offset_all_M276-v_offset_all_M276(:,1)))
ylabel('$\Delta V $ [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((v_offset_all_M275-v_offset_all_M275(:,1)))
ylabel('$\Delta V $ [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((v_offset_all_M267-v_offset_all_M267(:,1)))
ylabel('$\Delta V $ [V]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((p_offset_all_M270-p_offset_all_M270(:,1)))
ylabel('$\Delta P $ [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M270')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((p_offset_all_M276-p_offset_all_M276(:,1)))
ylabel('$\Delta P $ [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M276')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((p_offset_all_M275-p_offset_all_M275(:,1)))
ylabel('$\Delta P $ [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M275')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

figure
bar((p_offset_all_M267-p_offset_all_M267(:,1)))
ylabel('$\Delta P $ [psi]','Interpreter','Latex')
xlabel('Channel','Interpreter','Latex')
title('M267')
legend('12:18 pm','12:24 pm','12:31 pm','12:37 pm')
ax = gca;
ax.FontSize = 24;
box on

