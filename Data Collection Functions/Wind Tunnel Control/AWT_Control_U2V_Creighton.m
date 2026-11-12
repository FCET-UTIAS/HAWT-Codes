function [V] = AWT_Control_U2V_Creighton (U, Cal_1, Cal_2)

    V = (Cal_1 .* U + Cal_2);
    
    if U == 0
        V = 0;
    end
    
end