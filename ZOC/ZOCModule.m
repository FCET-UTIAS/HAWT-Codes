classdef ZOCModule
    properties
        serialnumber char
        modelname char
        range uint32
        banks double
        transducers double
        working double
        calibration double
    end

    methods
        function zoc = ZOCModule(serial, model, range, bank, trans, calib)
            if nargin == 6
                zoc.serialnumber = serial; 
                zoc.modelname = model; 
                zoc.range = range; 
                zoc.banks = bank; 
                zoc.transducers = trans; 
                zoc.calibration = calib; 
            end
        end
        function newzoc = update(zoc, serial)
            run("zoc_data_NRC.m")
            zoctable = load("ZOC_Database", 'zocs').zocs; 
            newzoc = []; 
                for i = 1:width(zoctable)
                    if serial == string(zoctable.(i).serialnumber)
                        newzoc = zoctable.(i);
                        break
                    else
                        continue 
                    end
                end
            
                if string(class(newzoc)) == "ZOCModule"
                    disp('Updating zoc...')
                else
                    disp("Couldn't load zoc module, please try again")
                end
            end

        end
    end

