function [outputFile] = oi2sensor(options)
%function [outputFile] = oi2sensor(oiFiles, sensorFile)
%OI2SENSOR Accept an OI and sensor and output the sensor image
% D. Cardinal, B. Wandell, Zhenyi Liu, Stanford University, 2022

%
% oiFiles is (for now) the data file(s) for an Optical Image
% sensorFile is (for now) the data file for the desired sensor
%

% Should test for oiFiles as some type of array here
arguments
    options.oiFiles = 'sampleoi.mat';
    options.sensorFile = 'ar0132atSensorRGB.mat';
end

load(options.oiFiles, 'oi');
sensor = sensorFromFile(options.sensorFile);

sensorImage = sensorCompute(sensor, oi);

ip = ipCreate();
ipImage = ipCompute(ip, sensorImage);

% ipWindow(ipImage);
outputFile = ipSaveImage(ipImage, 'sensorRGB.png');

% see if we can get time to look at output log
if isdeployed
    pause;
end
end

