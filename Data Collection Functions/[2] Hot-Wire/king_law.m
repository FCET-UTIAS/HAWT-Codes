function E = king_law(A,Q)

% function E = King_Law(A,Q);
%
% The King's Law function for hot-wire response to velocity changes.

% Philippe Lavoie (18-01-2007)

E = sqrt(A(1)+A(2)*Q.^A(3));

