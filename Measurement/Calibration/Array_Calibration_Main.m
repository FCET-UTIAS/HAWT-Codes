%% Array Calibration
% This code is used to perform a calibration on the acoustic array. The
% prerequisites for this code are the Beamforming_Settings and collection
% of calibration data. The calibration data should include an array called
% 'cal_data' and 'cal_refMic'.
% The output of the calibration is saved in the calibration folder and this
% output filename should be interted back into the Beamforming_Settings
% prior to running Beamformer_Main.
%
% This code is adapted from the phased array calibration codes used at the
% University of Notre Dame and is based on the calibration principles
% detailed in Aeroacoustic Measurements, by Mueller (2002).
% Written by P.McCarthy (2018)


%% Load and check calibration data file.

% Load Data
CalData = load([Path.CalPath,Path.CalData]);

% Determine number of mics used from data file and perform check against
% expected number
NumMics = size(CalData.cal_data,2);

% Check to ensure data is suitable for processing by comparing the number
% of mics in data and stated value.
if NumMics ~= CalSettings.NumMics
    disp('Data does not match number of microphones, could not perform calibration')
else
    
    %% Main function - this is only performed if the current data size is loaded.
    
    % Convert reference microphone voltage into pressure.
    refMicP = CalData.cal_refMic / CalSettings.refMic_sens;
    %     refMicP = CalData.cal_data(:,1) / CalSettings.refMic_sens;
    
    %% Check for any bad channels and remove them from the channel lists
    % Set initial number of mics used
    MicsUsed = 1:NumMics;
    
    % compute autospectral density for each channel. The output is plot on
    % screen
    [Gxx, ~, ~, Gxx_ref] = ArrayASD(CalData.cal_data,refMicP,Spec.Fs,Spec.Nfft,Spec.SpectralOverlap,NumMics);
    
    % peform check to ensure there are no bad microphones.
    bm = [];                % index of bad mics.
    load('ChampionsLeagueSample');
    sound(ChampionsY,ChampionsFs);
    clear ChampionsY; clear ChampionsFs;
%     answer = input('\n\nAre there bad microphones? (y/n) ','s');
    answer = 'n';
    
    % loop the question of bad mics until all bad mics are removed (figures are not changed).
    while (strcmp(answer,'y'))
        cont=1;
        while (cont > 0)
            bm(cont) = input ('Enter Bad Microphone (enter -1 if all bad microphones have been entered): ');
            if (bm(cont) == -1)
                bm(cont) = [];
                cont=-1;
            elseif (bm(cont) > NumMics || bm(cont) < -1 || bm(cont) == 0)
                fprintf('Bad Input, please re-enter.\n');
                cont=cont-1;
                
            else
            end
            cont=cont+1;
        end
        
        %If user identifies bad microphones, they are removed from the array before rerunning ArrayASD
        printf('Removing Bad Microphones, ')
        
        % sort bad mic channel number in ascending order
        bm = sort(bm);
        
        % determine which mics need to be kept
        MicsUsed = setdiff(1:NumMics,bm);
        
        % extract data to keep for subsequenct processing
        CalData.cal_data = CalData.cal_data(:,MicsUsed);
        
        % determine how many microphones are still being used
        NumMics = size(CalData.cal_data,2);
        
        %recompute the autospectral density for each channel and display. This should be a final check.
        [Gxx, ~, ~, Gxx_ref] = ArrayASD(CalData.cal_data,refMicP,Spec.Fs,Spec.Nfft,Spec.SpectralOverlap,NumMics,Path.CalPath);
        
        % check to make sure all bad channels/mics are removed.
        answer = input('\n\nAre there still bad microphones? (y/n) ','s');
        
        
    end
    
    % remove the coordinates of the bad microphones/channels
    XYZm = CalSettings.XYZm(MicsUsed,:);
    Xm = XYZm(:,1);
    Ym = XYZm(:,2);
    Zm = XYZm(:,3);
    
    %% Calculate distance from microphones to calibration source
    
    % distance from all microphones to calibration source
    rm = ((Xm - CalSettings.X_cal).^2 + (Ym - CalSettings.Y_cal).^2 + (Zm - CalSettings.Z_cal).^2).^(1/2);
    
    % distance from reference microphone to calibration source
    rcal = ((CalSettings.Xm_cal - CalSettings.X_cal).^2 + (CalSettings.Ym_cal - CalSettings.Y_cal).^2 + (CalSettings.Zm_cal - CalSettings.Z_cal).^2).^(1/2);
    
    %% Calculate the cross spectral density matrix for the calibration data.
    disp('Computing array CSM');
    
    % Perform Cross Spectral Density Matrix (CSM) calculation
    [Gxy, Fk, ENBW] = CSDcalc(CalData.cal_data,Spec.Fs,Spec.Nfft,Spec.SpectralOverlap);
    
    disp('Calculated CSD for array');
    
    %% Calculate the mic gain factor.
    % This is used to normalise the differences between each microphone.
    % That is to deal with the difference of sensitivity between different
    % mics in the array.
    
    kGF = ArrayGainFact(CalData.cal_data,refMicP,rm,rcal,NumMics);
    
    %% Determine the complex correction factor
    % This uses the Eigenvalue decomposition to determine complex corrections and
    % overall array sensitivity. This step does two main things, the first
    % one of which is to obtain the correction for the theoretical steering
    % vectors (and also for the CSM) and the second is to obtain the
    % average correction for the signal level of the array mics based on
    % the signal level of the ref mic that is considered as the correct
    % level.
    kGF = 1;            % Temp
    [Dcorr,Kavg] = ArrayEigCal(Gxy,Gxx_ref,Fk,ENBW,Spec.F_lim_ind,Spec.Nfft,NumMics,AtmProp.pref,rm,rcal,kGF,AtmProp.c);
    
    %% Calculate array beamwith
    % If desired, the beamwidth of the array can be computed.
    if strcmp(CalSettings.compBeamwidth,'Y');
        BeamWidth = ArrayBeamwidth(Fk,Spec.F_lim_ind,CalSettings.BWdist,Xm,Ym,Zm,CalSettings.BW_SVmethod,AtmProp.c,CalSettings.BWguess,CalSettings.BWfrac,CalSettings.BWmulti);
    end
    
    %% Clean Up Variables Specific Only to this code
    NewCalSettings.Spec.Fk = Fk;
    NewCalSettings.Spec.ENBW = ENBW;
    NewCalSettings.CalSettings.XYZm = XYZm;
    NewCalSettings.CalSettings.NumMics = NumMics;
    NewCalSettings.CalSettings.MicsUsed = MicsUsed;
    NewCalSettings.BFsettings.XYZm = XYZm;
    NewCalSettings.BFsettings.NumMics = NumMics;
    
    %% Save calibration file
    if strcmp(CalSettings.compBeamwidth,'Y');
        save([Path.CalPath,Path.CalFile],'Gxx','Gxx_ref','Gxy','kGF','Kavg','Dcorr','NewCalSettings','BeamWidth');
    else
        save([Path.CalPath,Path.CalFile],'Gxx','Gxx_ref','Gxy','kGF','Kavg','Dcorr','NewCalSettings');
    end
    
    disp('Calibration Complete')
    disp(['File saved as: ',Path.CalPath,Path.CalFile])
    clearvars -except AtmProp BFsettings CalSettings Path Spec
end

