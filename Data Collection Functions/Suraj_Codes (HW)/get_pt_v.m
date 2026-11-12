function [Up, Pm, ePm, u_p] = get_pt_v(pt_e, P_offset_v, P_gain, rho_air)

%This function generates the mean velocity measured by a pitot tube.
% Inputs:
% pt_e: voltage from pitot tube
% P_offset_v: voltage when wind tunnel is at 0 m/s
% P_gain: conversion from pressure to velocity (depends on transducer)

  P      = (pt_e - P_offset_v) * P_gain;        % find pressure 
  Pm     = mean(P);                             % save mean pressure 
  ePm    = mean(pt_e);                          % save electrical mean upstream
  u_p    = (2 * abs(P)./rho_air).^0.5 .* (P ./ abs(P));
  Up     = mean(u_p);                           % Save Pitot tube velocity upstream
  
end