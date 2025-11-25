%% Fish Video Tracking Script
% This script takes the pre- and post-trap videos and locates the fish in
% both. It will then build the detections of the fish into a trajectory.

cd('D:\1 Path Integration test - Ch1\4 Step 4 - Polarised light cue test - no move\2D.Polar1.Stable - Fish 10 - Trial 4 - 27.05.25\Left camera')

%% Setup
clear;  clc; % clears the workspace and console
fileNames = {'pre-trap.mp4';'post-trap.mp4'}; % these are both of the videos we will track

%% Parameters to tune
threshold= 50; % pixel difference from background expected to be a fish
visualise = 0; % watch your fish get tracked! (1 = on, 0 = off).
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

disp('finished reading')

%% Apply trajectory filtering
for fN = 1:2
traj = trajectories{fN};
traj_sm{fN} = resmoothFishTraj(traj,constant);
end

disp('finished filtering')

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

disp('finished figure')

%% Make trajectories tables and rename table columns

RawTrajectoryPre = array2table(trajectories{1});

RawTrajectoryPre.Properties.VariableNames{1} = 'X coord';
RawTrajectoryPre.Properties.VariableNames{2} = 'Y coord';

RawTrajectoryPost = array2table(trajectories{2});

RawTrajectoryPost.Properties.VariableNames{1} = 'X coord';
RawTrajectoryPost.Properties.VariableNames{2} = 'Y coord';

%% Add 5th column for 'time' ie frame numbers

vrPre = VideoReader(fileNames{1});  % read pre video
nfPre = (1:vrPre.numFrames)';       % obtain pre frame number, and make a column list from 1:frame number
RawTrajectoryPre.Frame = nfPre;     % add list as 5th column for 'time'

vrPost = VideoReader(fileNames{2});
nfPost = (1:vrPost.numFrames)';
RawTrajectoryPost.Frame = nfPost;

%% Plot raw trajectory points and smoothing line - to clear the tracks

figure; %plot x, pre
subplot(2,2,1);
scatter(RawTrajectoryPre{:,5}, RawTrajectoryPre{:,1}, 10, 'green');
hold on;
plot(RawTrajectoryPre{:,5},traj_sm{1}(:,1),'color','w');
title('X coord & smooth for Pre');

subplot(2,2,2); %plot y, pre
scatter(RawTrajectoryPre{:,5}, RawTrajectoryPre{:,2}, 10, 'green');
hold on;
plot(RawTrajectoryPre{:,5},traj_sm{1}(:,2),'color','w');
title('Y coord & smooth for Pre');

subplot(2,2,3); %plot x, post
scatter(RawTrajectoryPost{:,5}, RawTrajectoryPost{:,1}, 10, 'green');
hold on;
plot(RawTrajectoryPost{:,5},traj_sm{2}(:,1),'color','w');
title('X coord & smooth for Post');

subplot(2,2,4); %plot y, post
scatter(RawTrajectoryPost{:,5}, RawTrajectoryPost{:,2}, 10, 'green');
hold on;
plot(RawTrajectoryPost{:,5},traj_sm{2}(:,2),'color','w');
title('Y coord & smooth for Post');

%% Apply mask to filter out anomalous points - by considering the plot above

distance = 50; %distance to change - unsure what unit needed right now

for fN = 1:2 % If absolute difference between raw track and smoothed is less than 'distance' for both X and Y coords == TRUE
maskCorrections = abs(trajectories{fN}(:, 1) - traj_sm{fN}(:, 1)) < distance & abs(trajectories{fN}(:, 2) - traj_sm{fN}(:, 2)) < distance;
switch fN
    case (1) % Save 1's and 0's from mask to another column in table to then use for colour coding visualisation
        RawTrajectoryPre.mask = maskCorrections;
    case (2)
        RawTrajectoryPost.mask = maskCorrections;
end
end

%% ASK SAM HELP - Visualise the filtered points (red = masked out, green = correct) - view the points with video to check

% Change FALSE values from mask to Nan values

RawTrajectoryPre{:,1}(~RawTrajectoryPre.mask) = NaN; 
RawTrajectoryPre{:,2}(~RawTrajectoryPre.mask) = NaN; 
RawTrajectoryPost{:,1}(~RawTrajectoryPost.mask) = NaN; 
RawTrajectoryPost{:,2}(~RawTrajectoryPost.mask) = NaN;

%% Apply smoothing to filterred and tracked points (is transposing a problem here???)

SmoothPre = resmoothFishTraj(RawTrajectoryPre{:,[1,2]},constant);
SmoothPost = resmoothFishTraj(RawTrajectoryPost{:,[1,2]},constant);

%% Obtain raw track that is sampled 1 in 10 frames instead of in each

H1 = height(RawTrajectoryPre);
OneInTenPre = RawTrajectoryPre(1:10:H1);

H2 = height(RawTrajectoryPost);
OneInTenPost = RawTrajectoryPost(1:10:H2);

%% Plot filtered raw trajectory points, smoothing line, and 1 in 10 frame sampled track - to check smoothing parameter choice

figure; %plot x, pre
subplot(2,2,1);
scatter(RawTrajectoryPre{:,5}, RawTrajectoryPre{:,1}, 10, 'green');
hold on;
scatter(OneInTenPre{:,5}, OneInTenPre{:,1}, 10, 'red');
hold on;
plot(RawTrajectoryPre{:,5},SmoothPre{:,1},'color','w');
title('X coord & smooth for Pre');

subplot(2,2,1); %plot y, pre
scatter(RawTrajectoryPre{:,5}, RawTrajectoryPre{:,2}, 10, 'green');
hold on;
scatter(OneInTenPre{:,5}, OneInTenPre{:,2}, 10, 'red');
hold on;
plot(RawTrajectoryPre{:,5},SmoothPre{:,2},'color','w');
title('Y coord & smooth for Pre');

subplot(2,2,3); %plot x, post
scatter(RawTrajectoryPost{:,5}, RawTrajectoryPost{:,1}, 10, 'green');
hold on;
scatter(OneInTenPost{:,5}, OneInTenPost{:,1}, 10, 'red');
hold on;
plot(RawTrajectoryPost{:,5},SmoothPost{:,1},'color','w');
title('X coord & smooth for Post');

subplot(2,2,4); %plot y, post
scatter(RawTrajectoryPost{:,5}, RawTrajectoryPost{:,2}, 10, 'green');
hold on;
scatter(OneInTenPost{:,5}, OneInTenPost{:,2}, 10, 'red');
hold on;
plot(RawTrajectoryPost{:,5},SmoothPost{:,2},'color','w');
title('Y coord & smooth for Post');


%% ASK SAM HELP - there are missing points 'Nan' in the X and Y smooth line too - might be an issue for stats, any suggestions?

%% Save the filtered, smoothed data points = for stats use

writetable(SmoothPre,'smoothPre.csv');
writetable(SmoothPost,'smoothPost.csv');

%% ASK SAM HELP - Add corrections - lense distortion, refraction etc to points - to correct the final coords.

%% FOR LATER - How to combine both L and R cameras coords to one set only 
