%% mainAOAcorrection

function AoApost=funcAoAcorrection(AoApre,type,loc) 
% Correct from the geometric aoa in the Kevlar wind tunnel to the effective
% angle of attack in the Kevlar wind tunnel
driveName=pwd;
driveName=driveName(1);
load(strcat(driveName,":\CalibrationData\AoAcorrection\AoAcorrectionCoef.mat"));

if strcmp(loc,"tip")
    CKg=CtipKg;
    CPIV=CtipPIV;
elseif strcmp(loc,"mid")
    CKg=CmidKg;
    CPIV=CmidPIV;
end

if strcmp(type,"findKg")
    AoApost=1/CKg(1)*(CPIV(1)*AoApre+CPIV(2)-CKg(2));

elseif strcmp(type,"findPIVg")
    AoApost=1/CPIV(1)*(CKg(1)*AoApre+CKg(2)-CPIV(2));
end