clc;
clear all;
close all;

%% Load my own results into workspace

% Import p_taps locations

d = "F:\Experimental Data 2023\30P30N_Baseline_Characterization\Cp\P_tap_points\Pressure_taps";
datFiles = dir(d);
N = length(datFiles); 

% loop for each file 
 P_taps = cell(N-2,1);

for i = 3:N
   thisFile = datFiles(i).name ; 
   filename = fullfile(d,thisFile);
   data = table2array(readtable(filename));
   P_taps{i-2} = data;
end
c = 15.748;


%%

% Import airfoil points locations

d = "F:\Experimental Data 2023\30P30N_Baseline_Characterization\Cp\P_tap_points\30P30N_points";
datFiles = dir(d);
N = length(datFiles); 

% loop for each file 
 points = cell(N-2,1);

for i = 3:N
   thisFile = datFiles(i).name ; 
   filename = fullfile(d,thisFile);
   data = table2array(readtable(filename));
   points{i-2} = data;
end

%%
[~, loc_l] = min(points{3}(:,1));
xl1 = ones(10,1)*points{3}(loc_l,1)/c;
yl1 = ones(10,1)*points{3}(loc_l,2)/c;
zl1 = linspace(-16.3,16.3,10)/c;

[~, loc_h] = max(points{3}(:,1));
xh1 = ones(10,1)*points{3}(loc_h,1)/c;
yh1 = ones(10,1)*points{3}(loc_h,2)/c;
zh1 = linspace(-16.3,16.3,10)/c;

loc_cove = 41;
xc1 = ones(10,1)*points{3}(loc_cove,1)/c;
yc1 = ones(10,1)*points{3}(loc_cove,2)/c;
zc1 = linspace(-16.3,16.3,10)/c;

[~, loc_l] = min(points{4}(:,1));
xs1 = ones(10,1)*points{4}(loc_l,1)/c;
ys1 = ones(10,1)*points{4}(loc_l,2)/c;
zs1 = linspace(-16.3,16.3,10)/c;

[~, loc_l] = max(points{4}(:,1));
xsh = ones(10,1)*points{4}(loc_l,1)/c;
ysh = ones(10,1)*points{4}(loc_l,2)/c;
zsh = linspace(-16.3,16.3,10)/c;

[~, loc_l] = min(points{1}(:,1));
xf1 = ones(10,1)*points{1}(loc_l,1)/c;
yf1 = ones(10,1)*points{1}(loc_l,2)/c;
zf1 = linspace(-16.3,16.3,10)/c;

[~, loc_l] = max(points{1}(:,1));
xfh = ones(10,1)*points{1}(loc_l,1)/c;
yfh = ones(10,1)*points{1}(loc_l,2)/c;
zfh = linspace(-16.3,16.3,10)/c;


loc_l = 109;
xcs = ones(10,1)*points{4}(loc_l,1)/c;
ycs = ones(10,1)*points{4}(loc_l,2)/c;
zcs = linspace(-16.3,16.3,10)/c;

scrsz = get(0,'ScreenSize');

figure('Position',[1 0.1*scrsz(4) 0.8*scrsz(3) 0.8*scrsz(4)]);
plot3(zl1,xl1,yl1,'k','Linewidth',1)
hold on
plot3(zh1,xh1,yh1,'k','Linewidth',1)
hold on
plot3(zc1,xc1,yc1,'k','Linewidth',1)
hold on
plot3(zf1,xf1,yf1,'k','Linewidth',1)
hold on
plot3(zfh,xfh,yfh,'k','Linewidth',1)
hold on
plot3((points{1}(:,3)-16.3)/c, points{1}(:,1)/c, points{1}(:,2)/c,'k','Linewidth',1)
hold on
plot3((points{3}(:,3)-16.3)/c, points{3}(:,1)/c, points{3}(:,2)/c,'k','Linewidth',1)
hold on
plot3((points{1}(:,3)+16.3)/c, points{1}(:,1)/c, points{1}(:,2)/c,'k','Linewidth',1)
hold on
plot3((points{3}(:,3)+16.3)/c, points{3}(:,1)/c, points{3}(:,2)/c,'k','Linewidth',1)
hold on
hold on
scatter3(P_taps{1}(:,4)/c, P_taps{1}(:,2)/c, P_taps{1}(:,3)/c, 'bo','Linewidth',2)
scatter3(P_taps{3}(:,4)/c, P_taps{3}(:,2)/c, P_taps{3}(:,3)/c, 'bo','Linewidth',2)
scatter3(zeros(size(P_taps{4}(:,2))), P_taps{4}(:,2)/c, P_taps{4}(:,3)/c,'bo','Linewidth',2)
scatter3(zeros(size(P_taps{2}(:,2))), P_taps{2}(:,2)/c, P_taps{2}(:,3)/c,'bo','Linewidth',2)
scatter3(zeros(size(P_taps{4}(2:4,2))), P_taps{4}(2:4,2)/c, P_taps{4}(2:4,3)/c,'ro','filled')
scatter3(zeros(size(P_taps{4}(28:29,2))), P_taps{4}(28:29,2)/c, P_taps{4}(28:29,3)/c,'ro','filled')
scatter3(zeros(size(P_taps{4}(31:32,2))), P_taps{4}(31:32,2)/c, P_taps{4}(31:32,3)/c,'ro','filled')
scatter3(zeros(size(P_taps{2}(1:2,2))), P_taps{2}(1:2,2)/c, P_taps{2}(1:2,3)/c,'ro','filled')
scatter3(zeros(size(P_taps{2}(5:6,2))), P_taps{2}(5:6,2)/c, P_taps{2}(5:6,3)/c,'ro','filled')
scatter3(zeros(size(P_taps{2}(8:10,2))), P_taps{2}(8:10,2)/c, P_taps{2}(8:10,3)/c,'ro','filled')
scatter3(P_taps{1}(6:10,4)/c, P_taps{1}(6:10,2)/c, P_taps{1}(6:10,3)/c,'ro','filled')
scatter3(P_taps{3}(6:9,4)/c, P_taps{3}(6:9,2)/c, P_taps{3}(6:9,3)/c,'ro','filled')
xlabel('x/c')
ylabel('y/c')
a = gca; b = gcf;
a.FontSize = 12;
a.PlotBoxAspectRatio = [14,4,1];
%ylim([-3/c 1.5/c])
%xlim([-2/c 19/c])
set(gca,'yticklabel',{[]})
set(gca,'xticklabel',{[]})
set(gca,'zticklabel',{[]})
set(gca,'XColor', 'none','YColor','none', 'ZColor','none')
%box on
%print -depsc freq_dependence

%%
[min_main, loc_l] = min(points{2}(:,1));
xl1 = ones(10,1)*min(points{2}(:,1))/c;
yl1 = ones(10,1)*points{2}(loc_l,2)/c;

zl1 = linspace(-16.3,16.3,10)/c;


scrsz = get(0,'ScreenSize');
figure('Position',[1 0.1*scrsz(4) 0.8*scrsz(3) 0.8*scrsz(4)]);

scatter3(P_taps{5}(:,2)/c, P_taps{5}(:,3)/c, P_taps{5}(:,4)/c, 200,'r.')
hold on
scatter3(P_taps{4}(:,2)/c, P_taps{4}(:,3)/c, P_taps{4}(:,4)/c,200 ,'r.')
hold on
scatter3(P_taps{2}(:,2)/c, P_taps{2}(:,3)/c, P_taps{2}(:,4)/c,200,'r.')
hold on
scatter3(P_taps{1}(:,2)/c, P_taps{1}(:,3)/c, P_taps{1}(:,4)/c, 200,'r.')
hold on
scatter3(P_taps{3}(:,2)/c, P_taps{3}(:,3)/c, P_taps{3}(:,4)/c,200 ,'r.')
hold on
% plot3(points{1}(:,1)/c, points{1}(:,2)/c, points{1}(:,3)/c,'k','Linewidth',2)
% hold on
% plot3(points{2}(:,1)/c, points{2}(:,2)/c,points{2}(:,3)/c,'k','Linewidth',2)
% hold on
% plot3(points{3}(:,1)/c, points{3}(:,2)/c,points{3}(:,3)/c,'k','Linewidth',2)
% hold on
plot3(points{1}(:,1)/c, points{1}(:,2)/c, (points{1}(:,3)-16.3)/c,'k','Linewidth',2)
hold on
plot3(points{2}(:,1)/c, points{2}(:,2)/c,(points{2}(:,3)-16.3)/c,'k','Linewidth',2)
hold on
plot3(points{3}(:,1)/c, points{3}(:,2)/c,(points{3}(:,3)-16.3)/c,'k','Linewidth',2)
hold on
plot3(points{1}(:,1)/c, points{1}(:,2)/c, (points{1}(:,3)+16.3)/c,'k','Linewidth',2)
hold on
plot3(points{2}(:,1)/c, points{2}(:,2)/c,(points{2}(:,3)+16.3)/c,'k','Linewidth',2)
hold on
plot3(points{3}(:,1)/c, points{3}(:,2)/c,(points{3}(:,3)+16.3)/c,'k','Linewidth',2)
hold on
plot3(xl1,yl1,zl1,'k','Linewidth',2)

% xlabel('x/c','FontSize',16)
% ylabel('y/c','FontSize',16)
% zlabel('z/c','FontSize',16)
a = gca; b = gcf;
a.FontSize = 14;
a.PlotBoxAspectRatio = [1,0.3,2];
grid on
ylim([-3/c 1.5/c])
xlim([-2/c 19/c])

set(gca,'xtick',[])
set(gca,'ytick',[])
set(gca,'ztick',[])
%print -depsc model3d

%%
scrsz = get(0,'ScreenSize');
figure('Position',[1 0.1*scrsz(4) 0.8*scrsz(3) 0.8*scrsz(4)]);
hold on
plot(points{1}(:,1)/c, points{1}(:,2)/c,'k','Linewidth',3)
plot(points{3}(:,1)/c, points{3}(:,2)/c,'k','Linewidth',3)
%plot(points{4}(:,1)/c, points{4}(:,2)/c,'k','Linewidth',3)
xlabel('x/c')
ylabel('y/c')
a = gca; b = gcf;
a.FontSize = 12;
a.PlotBoxAspectRatio = [4,1,1];
ylim([-3/c 1.5/c])
xlim([-2/c 19/c])
set(gca,'yticklabel',{[]})
set(gca,'xticklabel',{[]})
set(gca,'XColor', 'none','YColor','none')
%%
close all
scale  = -1.5/c:0.1/c:-1/c;

scrsz = get(0,'ScreenSize');
figure('Position',[1 0.1*scrsz(4) 0.8*scrsz(3) 0.8*scrsz(4)]);

hold on
plot(0.0439509+zeros(size(scale)), scale, 'k','Linewidth',2)
plot(ones(size(scale)), scale, 'k','Linewidth',2)
quiver(0.48, mean(scale), -0.485, 0, 'k','Linewidth',2)
quiver(0.52, mean(scale), 0.535, 0, 'k','Linewidth',2)
quiver(0.0439509+0, -0.012, 0.1, 0, 'k','Linewidth',2)
quiver(0.0439509+0, -0.012, 0, 0.07, 'k','Linewidth',2)
plot(points{2}(:,1)/c, points{2}(:,2)/c,'k','Linewidth',2)
plot(points{3}(:,1)/c, points{3}(:,2)/c,'k','Linewidth',2)
xlabel('$x$','Interpreter','Latex')
ylabel('$y$','Interpreter','Latex')
a = gca; b = gcf;
a.FontSize = 24;
a.PlotBoxAspectRatio = [3,1,1];
set(gca,'yticklabel',{[]})
set(gca,'xticklabel',{[]})
set(gca,'XColor', 'none','YColor','none')

text(0.041, 0.085, '$y$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(0.14, -0.0120, '$x$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(0.495, mean(scale), '$c$','Fontsize',24, 'Color','k','Interpreter','Latex')


lsy = linspace(-0.19706-0.1,-0.19706+0.015,10);
lfy = linspace(-0.1695-0.1,-0.1695+0.015,10);
[mm loc] = min(points{3}(:,1));
lm = linspace(-0.2,1.2,10);
dfx = linspace(0.775,1.199,10);
dfy = linspace(-0.183959+0.06,-0.384,10);

dsx = linspace(0.06,-0.12,10);
dsy = linspace(-0.146,-0.35,10);
d_alphax = linspace(0.044,-0.13,10);
d_alphay = linspace(-0.215,-0.35,10);

theta_alpha1 = deg2rad(185:190);
theta_s1 = deg2rad(180:190);
theta_f1 = deg2rad(330:340);
rs = 0.24;
rf = 0.28;
r_alpha = 0.12;

xr_alpha1 = r_alpha*cos(theta_alpha1)+0.1;
xrs1 = rs*cos(theta_s1)+0.1;
xrf1= rf*cos(theta_f1)+0.91;
yrf1 = 0.05+rf*sin(theta_f1)+points{3}(loc,2);
yrs1 = 0.05+rs*sin(theta_s1)+points{3}(loc,2);
yr_alpha1 = r_alpha*sin(theta_alpha1)-0.205;

theta_s2 = deg2rad(200:210);
theta_f2 = deg2rad(350:360);
theta_alpha2 = deg2rad(200:205);

xr_alpha2 = r_alpha*cos(theta_alpha2)+0.1;
xrs2 = rs*cos(theta_s2)+0.1;
xrf2= rf*cos(theta_f2)+0.91;
yrf2 = 0.05+rf*sin(theta_f2)+points{3}(loc,2);
yrs2 = 0.05+rs*sin(theta_s2)+points{3}(loc,2);
yr_alpha2 = r_alpha*sin(theta_alpha2)-0.205;

hold on
plot(xr_alpha1, yr_alpha1, 'k--','Linewidth',1)
plot(xrf1, yrf1, 'k--','Linewidth',1)
plot(xr_alpha2, yr_alpha2, 'k--','Linewidth',1)
plot(xrf2, yrf2, 'k--','Linewidth',1)
quiver(0.871557+0.035, -0.1695-0.08, -0.035, 0, 'k','Linewidth',2)
quiver(0.873978-0.035, -0.1695-0.08, 0.035, 0, 'k','Linewidth',2)
quiver(0.48, mean(scale)-0.25, -0.485, 0, 'k','Linewidth',2)
quiver(0.52, mean(scale)-0.25, 0.535, 0, 'k','Linewidth',2)
plot(d_alphax, d_alphay, 'k--','Linewidth',1)
plot(dfx, dfy, 'k--','Linewidth',1)
plot(zeros(size(lfy))+0.873978, lfy, 'k--','Linewidth',1)
plot(zeros(size(lfy))+0.871557, lfy, 'k--','Linewidth',1)


plot(lm, 0.05+zeros(size(lm))+points{3}(loc,2), 'k--','Linewidth',1)

plot(0.0439509+zeros(size(scale)), scale-0.25, 'k','Linewidth',2)
 plot(ones(size(scale)), scale-0.25, 'k','Linewidth',2)
plot(points{1}(:,1)/c, points{1}(:,2)/c-0.2,'k','Linewidth',2)
plot(points{3}(:,1)/c, points{3}(:,2)/c-0.2,'k','Linewidth',2)
xlabel('x/c')
ylabel('y/c')
a = gca; b = gcf;
a.FontSize = 12;
a.PlotBoxAspectRatio = [3,1,1];
%ylim([-3/c 1.5/c])
%xlim([-2/c 19/c])
set(gca,'yticklabel',{[]})
set(gca,'xticklabel',{[]})
set(gca,'XColor', 'none','YColor','none')
text(0.495, mean(scale)-0.25, '$c$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(0.78, -0.2495, '$o_f$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(1.16, -0.29, '$\delta_f$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(-0.03, -0.235, '$\alpha$','Fontsize',24, 'Color','k','Interpreter','Latex')
text(-0.18, -0.36, '$U_{\infty}$','Fontsize',24, 'Color','k','Interpreter','Latex')