[Pu_sw1_u,f] = estpsd2(u_sw1_u-mean(u_sw1_u),2^10,2^10,false,ActualRate);
loglog(f,Pu_sw1_u)