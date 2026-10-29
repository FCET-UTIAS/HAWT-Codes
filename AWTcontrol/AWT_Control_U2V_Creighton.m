function [V] = AWT_Control_U2V_Creighton (U, Cal_1, Cal_2)

%---------------------------------------------------------------------------
% Function to convert tunnel speed to control voltage
% Description: Uses a linear calibration to convert a desired freestream 
% velocity into the voltage reference sent to the motor controller. A velocity
% of zero always returns 0 V (the offset is not applied at zero speed).
%
% INPUTS: 
%         U     - desired tunnel velocity (scalar or array)
%         Cal_1 - calibration slope (V per unit velocity)
%         Cal_2 - calibration intercept (V)
% OUTPUTS: 
%         V    - voltage reference (V), same size as U
%
% HISTORY: 
% 
%---------------------------------------------------------------------------

    V = (Cal_1 .* U + Cal_2);
    
    if U == 0
        V = 0;
    end
    
end
