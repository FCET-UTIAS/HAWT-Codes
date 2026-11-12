function E = HW_king_law(A,Q)
% HW_king_law
%   The King's Law function for hot-wire response to velocity changes.
%
%   INPUTS: 
%       A - inputs for coefficents for King's Law
%       Q - velcoity input to King's Law 
%  
%   OUTPUTS:
%       E - voltage output from King's Law relation
%
% Philippe Lavoie (18-01-2007)
%--------------------------------------------------------------------------
E = sqrt(A(1)+A(2)*Q.^A(3));

