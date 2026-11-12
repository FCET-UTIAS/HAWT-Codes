% Determines the height of the center of a wire off of a reflective surface
% using pixel measurement method. Note that probe height of zero cannot
% physically be achieved, since this is when the centre of the wire is at
% the plane of the wall.

wall_name = 'Wall_find_2020_09_13_1'; %file that will be saved to
%wall_name = 'image_cal';
im_loc = 'Images/20200913/1/'; %images for analysis

% Enter desired probe height
p_height = 0.125; % [mm]

% Traverse properties
h = 0.00125; % mm/step 

clear Itot

%Enter data as I = [probe pixel location, reflection pixel location,
%total steps moved]
% currently in 2D, maybe add additional functionality to do x,y
Itot(1,:,1) = [963, 950, 100];     % From image 1 (highest position) 
Itot(2,:,1) = [962, 951, 80];     
Itot(3,:,1) = [962, 952, 60]; 
Itot(4,:,1) = [961, 953, 40]; 
Itot(5,:,1) = [960, 952, 20]; 
Itot(6,:,1) = [960, 953, 0];  % From image 5 (lowest position)
% Itot(1,:,2) = [577, 606, 100];     % From image 1 (highest position)
% Itot(2,:,2) = [578, 604, 80];
% Itot(3,:,2) = [580, 602, 60]; 
% Itot(4,:,2) = [582, 601, 40];
% Itot(5,:,2) = [584, 599, 20];
% Itot(6,:,2) = [585, 597, 0];  % From image 5 (lowest position)
% %second rows are for second probe

szI = size(Itot);
n_probes = 1; %szI(3);

for i=1:n_probes
    
    clear D I L
    
    I = Itot(:,:,i);
    
    n = size(I,1);  % Number of images used
    
    % Convert pixels and steps to [mm]
    pixel_cal = h/((max(I(:,1))-min(I(:,1)))/max(abs(I(:,3)))); % [mm/pixel]
    D = I(:,3).*h; % [mm]
    
    probe = fit(D(:), I(:,1), 'poly1'); % Probe lin fit
    reflec = fit(D(:), I(:,2), 'poly1');    % Reflection lin fit
    
    % Find actual height of center of wire
    d2wall = fzero(@(x) reflec(x)-probe(x), 0);   % [mm]
    wall_pos = probe(d2wall); % [pixels]
    
    % Convert from pixel locations to wall height in [mm]
    L = (wall_pos-I(:,1:2)).*pixel_cal;
    F1 = @(x) (wall_pos-probe(x)).*pixel_cal;
    F2 = @(x) (wall_pos-reflec(x)).*pixel_cal;
    
    x_right = fzero(@(x) F1(x)-F2(x),0);
    
    x1 = linspace(x_right, 0.2);
    y1 = F1(x1);
    y2 = F2(x1);
    
    % Plot and display results
    figure()
    hold on
    plot(D, L(:,1), 'ro', D, L(:,2), 'ko');
    xlim([x_right, 0.2]);
    set(gca, 'Xdir', 'reverse')
    plot(x1, y1, 'r-');
    plot(x1, y2, 'k-');
    wall_line = refline(0,0);
    set(wall_line,'Color','k','Linestyle','--')
    p_line = refline(0,F1(D(n)));
    set(p_line,'Color','b','Linestyle','--')
    d_line = refline(0,p_height);
    set(d_line,'Color','g','Linestyle','--')
    
    title('Probe Height Determination');
    xlabel('Distance moved [mm]');
    ylabel('Probe height [mm]');
    legend('Probe data', 'Reflection data', 'Probe fit', 'Reflection fit', 'Wall', 'Current probe height', 'Desired probe height');
    
    %curr_hgt(i) = F1(D(n));
    curr_hgt(i) = F1(D(1));
    
    disp(['Current probe height is ' num2str(curr_hgt(i), '%1.3f') ' [mm]']);
    
    % Calculate steps to desired height
    meh = fzero(@(x) F1(x)-p_height,0);
    diff = F1(meh)-curr_hgt(i);
    steps2start = round(diff/h);
    
    if steps2start>0
        dir = 'up';
    else
        dir = 'down';
    end
    
    disp(['Move ' num2str(abs(steps2start)) ' steps ' dir ' to desired location']);
    
end

%save([im_loc,wall_name],'Itot','h','im_loc','curr_hgt')
save(['WallData/',wall_name],'Itot','h','im_loc','curr_hgt')
