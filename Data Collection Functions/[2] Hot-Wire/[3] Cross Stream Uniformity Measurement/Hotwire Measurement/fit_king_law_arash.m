function [king_coef] = fit_king_law_arash(Q, E);

% This function fits King's Law to a set of calibration data by allowing
% for a small error in the zero pressure of the measurements (of the order
% of a couple millivolts.

% Philippe Lavoie (23-01-2007)

% delta_e_p = [-0.015:0.00025:0.015];
% 
% [rho_air, visc_air, rho_w, g] = fluid_prop(T_atm, P_atm);  % Get property of fluids
% 
% 
% for i = 1:length(delta_e_p)
%     Q = sqrt(2* P_gain * (e_p + delta_e_p(i)) / rho_air);
%     if Q(1) < 0
%         Q(1) = 0;
%     end
% 
%     K_coef = nlinfit(Q, E, @king_law, [1 1 0.45]);
% 
%     Q_bla = ((E.^2 - K_coef(1))/K_coef(2)).^(1/K_coef(3));
%     error_rms(i) = mean(abs(Q - Q_bla)./Q*100);
% end
% 
% [min_err, I] = min(error_rms);
% 
% P_offset = delta_e_p(I);
% 
% Q = sqrt(2* P_gain * (e_p + P_offset) / rho_air);
% if Q(1) < 0
%     Q(1) = 0;
% end

king_coef = nlinfit(Q, E, @king_law, [1 1 0.45]);

% Plot fit for visual inspection
E_plot = linspace(min(E), max(E), 100);
U_plot = ((E_plot.^2 - king_coef(1))/king_coef(2)).^(1/king_coef(3));

%close all;
% hold on
% figure;
plot(Q, E, 'bs', U_plot, E_plot, '-r');
legend('data points', 'King law curve fit', 'Location', 'SouthEast');
xl = xlabel('$U_p$');
yl = ylabel('$E_{U,corr}$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');