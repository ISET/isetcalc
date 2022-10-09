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
sensorFiles = {'ar0132atSensorrgb.mat', 'MT9V024SensorRGB.mat'};

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
oiFiles = {'oi_001.mat', 'oi_002.mat', 'oi_fog.mat'};
for ii = 1:numel(oiFiles)
    load(oiFiles{ii}); % assume they are on our path

    [~, fName, fSuffix] = fileparts(oiFiles{ii});

    % Start with a copy of the Raw OI to the website
    if ~isfolder(fullfile(outputFolder,'oi'))
        mkdir(fullfile(outputFolder,'oi'))
    end
    oiDataFile = fullfile(outputFolder,'oi',[fName fSuffix]);
    copyfile(which(oiFiles{ii}), oiDataFile);

    % Pre-compute sensor images
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end
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
        eTime  = autoExposure(oi,sensor,aeMean,aeMethod);
        sensor = sensorSet(sensor,'exp time',eTime);
        
        % See how long this takes in case we want
        % to allow users to do it in real-time on our server
        tic;
        sensor = sensorCompute(sensor,oi);
        toc;

        % Here we save the preview images
        % We use the fullfile for local write
        % and just the filename for web use
        ipJPEGName = [fName '-' sName '.jpg'];
        ipThumbnailName = [fName '-' sName '-thumbnail.jpg'];

        % "Local" is our ISET filepath, not the website path
        ipLocalJPEG = fullfile(outputFolder,'images',ipJPEGName);
        ipLocalThumbnail = fullfile(outputFolder,'images',ipThumbnailName);

        % Create a default IP so we can see some baseline image
        % This could of course be tweaked
        ip = ipCreate('ourIP',sensor);
        ip = ipCompute(ip, sensor);

        % save an RGB JPEG using our default IP so we can show a preview
        outputFile = ipSaveImage(ip, ipLocalJPEG);
        
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
        sensor.metadata.oiFile = oiDataFile;

        % We ONLY write out the metadata in the main .json
        % file to keep it of reasonable size
        imageMetadataArray = [imageMetadataArray sensor.metadata];
        
        sensorDataFile = [fName '-' sName '.json'];
        sensor.metadata.sensorRawFile = sensorDataFile;
        jsonwrite(fullfile(outputFolder,'images', sensorDataFile), sensor);

    end

    % We can write metadata as one file -- but since it is only
    % read by our code, we place it in the code folder tree
    jsonwrite(fullfile(privateDataFolder,'metadata.json'), imageMetadataArray);

end