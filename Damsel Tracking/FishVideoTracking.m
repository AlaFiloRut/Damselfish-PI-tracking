%% Fish Video Tracking Script
% This script takes the pre- and post-trap videos and locates the fish in
% both. It will then build the detections of the fish into a trajectory.

%% Setup
clear;  clc; % clears the workspace and console
fileNames = {'pre-trap.mp4';'post-trap.mp4'}; % these are both of the videos we will track

%% Parameters to tune
threshold= 50; % pixel difference from background expected to be a fish
visualise = 1; % watch your fish get tracked! (1 = on, 0 = off).
constant = 0.1; % smoothing constant for our filter (smaller is smoother)

%% Main loop for reading frames
for fN = 1:2
fileName = fileNames{fN};
vr = VideoReader(fileName);
nf = vr.numFrames;
frameNumbers = 1:100:nf;
[backgroundIm,STDIm] = fishBackgroundSubtract(vr,frameNumbers);
[trajectory,mask] = findFishInImages(vr,backgroundIm,STDIm,threshold,visualise);
trajectories{fN} = trajectory;
staticImages{fN} = uint8(backgroundIm);
masks{fN} = mask;
end


%% Apply trajectory filtering
for fN = 1:2
traj = trajectories{fN};
traj_sm{fN} = resmoothFishTraj(traj,constant);
end

%% Make our figure
figure;
hold on
for fN = 1:2
    subplot(1,2,fN)
    
imshow(staticImages{fN})
hold on
scatter(trajectories{fN}(:,1),trajectories{fN}(:,2),10,'k')
plot(traj_sm{fN}(:,1),traj_sm{fN}(:,2),'color','w')
switch fN
        case(1)
            title('Pre-Trapping')
        case(2)
            title('Post-Trapping')
end
end
set(gcf,'color','w')
