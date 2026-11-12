function [POLY] = fit_polynomial(U, E, n)

% This script fits a polynomial of order n to the hot-wire data provided by
% E and U.

% R. Jason Hearst
% September 16, 2011

% Create polynomial fit
POLY = polyfit(E, U, n);

% Plot fit for visual inspection
E_plot = linspace(min(E), max(E), 100);
U_plot = polyval(POLY, E_plot);

%close all;

figure;
plot(U, E, 'ob', U_plot, E_plot, '-r');
legend('data points', 'polynomial curve fit', 'Location', 'SouthEast');
xl = xlabel('$U_p$');
yl = ylabel('$E_{U,corr}$');
set(xl,'unit','character');
set(xl,'interpreter','latex');
set(yl,'unit','character');
set(yl,'interpreter','latex');