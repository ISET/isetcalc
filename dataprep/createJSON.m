% Export objects to JSON for use in oi2sensor
%
% D. Cardinal, Stanford University, 2022
%
%% Set output folder
outputFolder = fullfile(piRootPath,'local','computed');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end

%% Export sensor(s)
sensorFiles = {'ar0132atSensorrgb.mat', 'MT9V024SensorRGB.mat'};

if ~isfolder(fullfile(outputFolder,'sensors'))
    mkdir(fullfile(outputFolder,'sensors'))
end
for ii = 1:numel(sensorFiles)
    load(sensorFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, fName, fSuffix] = fileparts(sensorFiles{ii});
    jsonwrite(fullfile(outputFolder,'sensors',[fName '.json']), sensor);
end

%% TBD Export Lenses

%% TBD Export Scenes

%% Export OIs
%% NOTE:
% They can include complex numbers that are not directly
% usable in JSON, so we need to encode or re-work somehow
imageArray = [];
metadataArray = [];

% For now we have the OI folder in our Matlab path
% As we add a large number we might want to enumerate a data folder
% Or even get them from a database
oiFiles = {'oi_001.mat', 'oi_002.mat', 'oi_fog.mat'};
for ii = 1:numel(oiFiles)
    load(oiFiles{ii}); % assume they are on our path
    % change suffix to json
    [~, fName, fSuffix] = fileparts(oiFiles{ii});

    % This is slow, and the files are too large for
    % direct use, so turned off by default
    % jsonwrite(fullfile(outputFolder,[fName '.json']), oi);

    % Now, pre-compute sensor images
    if ~isfolder(fullfile(outputFolder,'images'))
        mkdir(fullfile(outputFolder,'images'))
    end
    for iii = 1:numel(sensorFiles)
        load(sensorFiles{iii}); % assume they are on our path
        % change suffix to json
        [~, sName, fSuffix] = fileparts(sensorFiles{iii});

        % At least for now, scale sensor
        % to match the FOV
        hFOV = oiGet(oi,'hfov');
        sensor = sensorSetSizeToFOV(sensor,hFOV,oi);

        % Auto-Exposure breaks with oncoming headlights, etc.
        % NOTE: This is a patch, as it doesn't work for fog, for example.
        %       Need to decide best default for Exposure time calc
        aeMethod = 'mean';
        eTime  = autoExposure(oi,sensor,.5,aeMethod);
        sensor = sensorSet(sensor,'exp time',eTime);
        
        tic;
        sensor = sensorCompute(sensor,oi);
        toc;

        % append to our overall array
        imageArray = [imageArray sensor];

        % Here we save the preview images
        % We use the fullfile for local write
        % and just the filename for web use
        ipFileName = [fName '-' sName '.jpg'];
        ipThumbnailName = [fName '-' sName '-thumbnail.jpg'];

        ipLocalJPEG = fullfile(outputFolder,'images',ipFileName);
        ipLocalThumbnail = fullfile(outputFolder,'images',ipThumbnailName);

        ip = ipCreate('ourIP',sensor);
        ip = ipCompute(ip, sensor);

        % save using default IP as preview
        outputFile = ipSaveImage(ip, ipLocalJPEG);
        % we can save without an IP if we want
        %sensorSaveImage(sensor, sensorJPEG  ,'rgb');

        % It's late & I'm lazy so generating a thumbnail
        % by reading the jpeg back in, etc.
        thumbnail = imread(ipLocalJPEG);
        thumbnail = imresize(thumbnail, [128 128]);
        imwrite(thumbnail, ipLocalThumbnail);

        % we'd better have metadata by now!
        sensor.metadata.jpegName = ipFileName;
        sensor.metadata.thumbnailName = ipThumbnailName;

        % right now not-used, but of course it
        % makes a difference
        sensor.metadata.exposureTime = eTime;
        sensor.metadata.aeMethod = aeMethod;

        % We ONLY write out the metadata in the main .json
        % file to keep it of reasonable size
        metadataArray = [metadataArray sensor.metadata];
        jsonwrite(fullfile(outputFolder,'images', [fName '-' sName '.json']), sensor);

    end

    % NOTE: Full images are large,
    %       So look at metadata JSON array
    %       and separate images
    jsonwrite(fullfile(outputFolder,'images','images.json'), imageArray);
    jsonwrite(fullfile(outputFolder,'images','metadata.json'), metadataArray);


end