function last_ang = rotaryEncoder_2(delta_angle_unsigned,sign) 

% desiredAngleAbsoluteValue = 3; 
% sign = '+';

if sign == '+'
    sign_real = '+'; %FOR FCET, NO NEED TO SWAP SIGNS, FOR VELMEX EFDR CONTROLLER, NEED SIGN SWAP 
else
    sign_real = '-';
end
load('premove.mat', 'premove'); 

disp(['Moving ', num2str(delta_angle_unsigned), ' degrees in the ', sign_real, 've AoA direction'])

s = daq("ni");

ch1 = addinput(s, 'Dev5', 'ctr1', 'Position');
ch1.EncoderType = 'X1';
s.Rate = 10000;
addinput(s, 'Dev5', 'ai0', 'Voltage');

%encoderPosition = inputSingleScan(s);
%encoderPositionDeg = encoderPosition * 360/encoderCPR;
% s.DurationInSeconds = 10;

% lh = s.addlistener('DataAvailable',@collectData);
% s.NotifyWhenDataAvailableExceeds = s.Rate*s.DurationInSeconds;
% s.startBackground();

s.ScansAvailableFcn = @(src, evt) acquireAllData(src, evt);
s.ScansAvailableFcnCount = s.Rate*10;
start(s, "Duration", seconds(2*delta_angle_unsigned +3));

% steps = ceil(delta_angle_unsigned*5000/2.664); 
% steps = ceil(2*delta_angle_unsigned*2000); %ADDED 2*2000 FACTOR FOR FCET MOTOR CONTROLLER W/ SLEW DRIVE 

%From Satoshi's code
res=1.8/40/44/4; % deg/steps
if premove==sign
    steps=delta_angle_unsigned/res;
else
    steps=(delta_angle_unsigned+0.784)/res;
end

turnSlewDrive_FCET(steps,sign,0);
pause(2*delta_angle_unsigned + 3)

%   while(s.IsDone)
%   end

[positionData, timestamps] = read(s,"all", 'OutputFormat','Matrix'); 

% figure
% plot(timestamps, positionData(:,1),'Linewidth',2)
% xlabel('Time (s)')
% ylabel('Counter Value')

encoderCPR = 5000; 
counterNBits = 32;
signedThreshold = 2^(counterNBits - 1);
signedData = positionData(:,1);
signedData(signedData > signedThreshold) = signedData(signedData > signedThreshold) - 2^counterNBits;
positionDataDeg = signedData * 360/encoderCPR;
last_ang = positionDataDeg(end); 

figure
plot(timestamps, positionDataDeg(:,1),'Linewidth',2)
xlabel('Time (s)')
ylabel('Angular Position (deg)')

premove=sign;
save('premove.mat','premove')


% function collectData(src,event)
%     %global data;
%     %global time
%     time = event.TimeStamps;
%     data = event.Data;
%     encoderCPR = 5000;
%     counterNBits = 32;
%     signedThreshold = 2^(counterNBits - 1);
%     signedData = data(:,1);
%     signedData(signedData > signedThreshold) = signedData(signedData > signedThreshold) - 2^counterNBits;
%     positionDataDeg = signedData * 360/encoderCPR;
%     save AoA.mat data time
%     plot(time, positionDataDeg(:,1),'Linewidth',2)
%     xlabel('Time (s)')
%     ylabel('Angular Position (deg)')
%     disp('Background acquisition completed')
%     last_ang = positionDataDeg(end); 
% end
 
% end

