%% Fish Video Cropping Script
% This script takes extremely large videos and crops them into 2 separate
% short videos. These are the pre-trap and post-trap sections used
% experimentally. User input is required to define the region that the
% video is cropped to.

% Please note that this script reads from a 'Fish Integration
% Mastersheet.xlsx'. If the data for the requested video is absent, then
% the script will throw an error.

%% Setup
clear; clc;% clears the workspace and console
% cd('D:\Fish Data') % Uncomment and change this to your fish data location
%% Parameters to tune
videoToRun = 1; %

% Read the mastersheet
% We assume Right camera is C1 and Left camera is C2
mastersheet = 'Fish Integration Mastersheet.xlsx'; % file name for the mastersheet
opts = detectImportOptions(mastersheet,'NumHeaderLines',0); % tells us what to read from the sheet
mainSheet = readtable(mastersheet,opts); % this is the data on the times we want to trim the file at

cd(mainSheet.Folder_Name{videoToRun})% go to our data folder

for cam = 2
    
    % Prepare to read our file
switch cam % choose which folder to look in
    case 1
        camFold = 'Right camera';
        timesOfInterest = mainSheet{videoToRun,2:4}; % pick the times we're clipping to
    case 2
        camFold = 'Left camera';
        timesOfInterest = mainSheet{videoToRun,5:7};
end
cd(camFold)
fileNameOptions = dir('GX*.mp4'); % Look for any MP4 files in the folder
fileName = fileNameOptions(1).name; % this is our file name
vr = VideoReader(fileName);

% Convert our time codes into seconds
tcode = timesOfInterest;
infmt = 'hh:mm:ss';
timeInDur = duration(tcode,'InputFormat',infmt);
timeInSec = seconds(timeInDur);

 % determine the number of frames per second
 framesPerSecond = get(vr,'FrameRate');
 % determine the number of frames
 numFrames = get(vr,'NumFrames');
 % find the points of the cuts
 cutPoints = round([timeInSec(1),timeInSec(2);timeInSec(3),timeInSec(3)+60]*framesPerSecond);
 % read all data from the first frame
 startFrame = read(vr,[timeInSec(1)]);
 [~,cropRect] = imcrop(startFrame);
 cropRect = round(cropRect);
 close all
 clearvars startFrame

 % now save the cropped video
 for vSection = 1:2
     switch vSection
         case 1
            vw = VideoWriter('pre-trap','MPEG-4');
         case 2
            vw = VideoWriter('post-trap','MPEG-4');
     end
     open(vw)
     for f = cutPoints(vSection,1):cutPoints(vSection,2)
         frame = read(vr,f); % read a frame from the original video
         frame = imcrop(frame,cropRect); % crop to the box we drew
         writeVideo(vw,frame);  % write this frame to the video
     end
     close(vw)
     save('MetadataFromClipping',"cutPoints","cropRect");
 end
end