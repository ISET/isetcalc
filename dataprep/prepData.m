% Render & Export objects for use in oi2sensor
%
% D. Cardinal, Stanford University, 2022
%
%% Set output folder
% I'm not sure where we want the data to go ultimately.
% As it will wind up in the website and/or a db
% We don't want it in our path or github (it wouldn't fit)
%
outputFolder = fullfile(calcRootPath,'camsim','public');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
privateDataFolder = fullfile(calcRootPath,'camsim','src','data');

%% Export sensor(s)
% Provide data for the sensors used so people can work with it on their own
sensorFiles = {'ar0132atSensorrgb.mat', 'MT9V024SensorRGB.mat', ...
    'ar0132atSensorRGBW.mat', 'imx363.mat'};

if ~isfolder(fullfile(outputFolder,'sensors'))
    mkdir(fullfile(outputFolder,'sensors'))
end

% Write data for each sensor as a separate JSON file
for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, sName, fSuffix] = fileparts(sensorFiles{ii});
    jsonwrite(fullfile(outputFolder,'sensors',[sName '.json']), sensor);
end

%% TBD Export Lenses
% When we have the definitions of lenses we use,
% we should export them so others can replicate/etc.

%% TBD Export "Scenes"
% Our scenes won't typically be ISET scenes.
% Instead they will be recipes usable by the
% Vistalab version of PBRT and by ISET3d.

%% ... Eventually see if we can modify illumination ...

%% Export OIs
%  OIs include complex numbers, which are not directly-accessible
%  in standard JSON. They also become extremely large as JSON (or BSON)
%  files. So for now, seems best to simply export the .mat files.

% Create an array to store images recorded by our sensors
sensorImageArray = [];

% The Metadata Array is the non-image portion of those, which
% is small enough to be kept in a single file & used for filtering
imageMetadataArray = [];

% For now we have the OI folder in our Matlab path
% As we add a large number we might want to enumerate a data folder
% Or even get them from a database
% Original set
%oiFiles = {'oi_001.mat', 'oi_002.mat', 'oi_fog.mat'};
oiFiles = {'oi_003.mat', 'oi_004.mat', 'oi_005.mat', 'oi_006.mat'};
for ii = 1:numel(oiFiles)
    load(oiFiles{ii}); % assume they are on our path

    [~, fName, fSuffix] = fileparts(oiFiles{ii});

    % Start with a copy of the Raw OI to the website
    if ~isfolder(fullfile(outputFolder,'oi'))
        mkdir(fullfile(outputFolder,'oi'))
    end
    oiDataFile = fullfile(outputFolder,'oi',[fName fSuffix]);
    copyfile(which(oiFiles{ii}), oiDataFile);

    % Total hack to prototype lighting
    illumination = 'unknown';
    switch(fName)
        case 'oi_001'
            illumination = 'daylight';
        case 'oi_002'
            illumination = 'night';
        case 'oi_fog'
            illumination = 'fog';
    end
    % Pre-compute sensor images
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end

    % Loop through our sensors:
    for iii = 1:numel(sensorFiles)
        load(sensorFiles{iii}); % assume they are on our path
        % prep for changing suffix to json
        [~, sName, ~] = fileparts(sensorFiles{iii});

        % At least for now, scale sensor
        % to match the FOV
        hFOV = oiGet(oi,'hfov');
        sensor = sensorSetSizeToFOV(sensor,hFOV,oi);

        % Auto-Exposure breaks with oncoming headlights, etc.
        % NOTE: This is a patch, as it doesn't work for fog, for example.
        %       Need to decide best default for Exposure time calc
        aeMethod = 'mean';
        aeMean = .5;
        aeTime  = autoExposure(oi,sensor,aeMean,aeMethod);

        % Now derive bracket & burst times:
        % These are hacked for now to get things working.
        % Then we can wire them up more elegantly
        numFrames = 3; % should we allow for 3 or 5?
        burstTimes = repelem(aeTime/3, 3);

        bracketStops = 2; % for now
        bracketTimes = [aeTime/(2*bracketStops), ...
            aeTime, aeTime * (2*bracketStops)];

        sensor_ae = sensorSet(sensor,'exp time',aeTime);
        sensor_burst = sensorSet(sensor,'exp time',burstTimes);
        sensor_bracket = sensorSet(sensor,'exp time',bracketTimes);

        % See how long this takes in case we want
        % to allow users to do it in real-time on our server
        tic;
        sensor_ae = sensorCompute(sensor_ae,oi);
        sensor_burst = sensorCompute(sensor_burst,oi);
        sensor_bracket = sensorCompute(sensor_bracket,oi);
        toc;

        % Here we save the preview images
        % We use the fullfile for local write
        % and just the filename for web use
        ipJPEGName = [fName '-' sName '.jpg'];
        ipJPEGName_burst = [fName '-' sName '-burst.jpg'];
        ipJPEGName_bracket = [fName '-' sName '-bracket.jpg'];
        ipThumbnailName = [fName '-' sName '-thumbnail.jpg'];

        % "Local" is our ISET filepath, not the website path
        ipLocalJPEG = fullfile(outputFolder,'images',ipJPEGName);
        ipLocalJPEG_burst = fullfile(outputFolder,'images',ipJPEGName_burst);
        ipLocalJPEG_bracket = fullfile(outputFolder,'images',ipJPEGName_bracket);
        ipLocalThumbnail = fullfile(outputFolder,'images',ipThumbnailName);

        % Create a default IP so we can see some baseline image
        % This could of course be tweaked
        ip_ae = ipCreate('ourIP',sensor_ae);
        ip_ae = ipCompute(ip_ae, sensor_ae);

        ip_burst = ipCreate('ourIP',sensor_burst);
        ip_burst = ipCompute(ip_burst, sensor_burst);

        ip_bracket = ipCreate('ourIP',sensor_bracket);
        ip_bracket = ipCompute(ip_bracket, sensor_bracket);

        % save an RGB JPEG using our default IP so we can show a preview
        outputFile = ipSaveImage(ip_ae, ipLocalJPEG);
        burstFile = ipSaveImage(ip_burst, ipLocalJPEG_burst);
        bracketFile = ipSaveImage(ip_bracket, ipLocalJPEG_bracket);
        
        % we could also save without an IP if we want
        %sensorSaveImage(sensor, sensorJPEG  ,'rgb');

        % Generate a quick thumbnail
        thumbnail = imread(ipLocalJPEG);
        thumbnail = imresize(thumbnail, [128 128]);
        imwrite(thumbnail, ipLocalThumbnail);

        % We need to save the relative paths for the website to use
        sensor.metadata.jpegName = ipJPEGName;
        sensor.metadata.thumbnailName = ipThumbnailName;

        % Stash exposure time for reference
        sensor.metadata.exposureTime = eTime;
        sensor.metadata.aeMethod = aeMethod;

        % Save OI & Raw sensor file locations
        sensor.metadata.oiFile = [fName fSuffix];

        % WE ALSO WANT ILLUMINATION FROM THE OI
        % FOR NOW We've stuck in some simple examples
        sensor.metadata.illumination = illumination;

        % We don't want the full lensfile path
        if isfield(sensor.metadata,'opticsname')
            [~, lName, ~] = fileparts(sensor.metadata.opticsname);
            sensor.metadata.opticsname = lName;
        end

        % Write out the 'raw' voltage file
        sensorDataFile = [fName '-' sName '.json'];
        sensor.metadata.sensorRawFile = sensorDataFile;
        jsonwrite(fullfile(outputFolder,'images', sensorDataFile), sensor);

        % We ONLY write out the metadata in the main .json
        % file to keep it of reasonable size
        % NOTE: Currently we re-write the entire file
        % Each time so dataPrep needs to run a complete batch
        % We might want to add an "Update" option that only
        % adds and updates?
        imageMetadataArray = [imageMetadataArray sensor.metadata];
        
    end

    % We can write metadata as one file -- but since it is only
    % read by our code, we place it in the code folder tree
    jsonwrite(fullfile(privateDataFolder,'metadata.json'), imageMetadataArray);

end