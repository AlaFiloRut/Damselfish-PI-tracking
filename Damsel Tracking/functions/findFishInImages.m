function [trajectory,mask] = findFishInImages(vr,backgroundIm,STDIm,threshold,visualise)
trajectory = nan(vr.NumFrames,4);
mask = backgroundIm>175;
mask = imdilate(mask,strel('disk',30));

if visualise==1
    frame = rgb2gray(read(vr,1));
    figure(111);
    imshown = imshow(frame);
    hold on
    imsc = scatter(0,0,'r','filled');
end

for f = 1:vr.NumFrames

% Open the image and subtract the baground, then binarise into a mask
    frame = rgb2gray(read(vr,f));
    frame_diff = backgroundIm-double(frame);
    frame_diff_std = frame_diff./STDIm; % STD processing doesn't help much
    frame_bin = frame_diff>threshold;
        % apply our mask
    frame_bin(mask) = 0;
    frame_dil = imdilate(frame_bin,strel('disk',3));

    % Find the fish in the mask
    regs = regionprops(frame_dil,'centroid','area','BoundingBox','image');
    % Filter our tine spots
    tooSmall = [regs.Area]<50;
    regs(tooSmall) = [];
    if isempty(regs)
        continue
    end

    [regs.localIntensity] = deal(nan);
    % Find the brightness of each region
    for r = 1:length(regs)
        bbox = regs(r).BoundingBox;
        localIm = imcrop(frame,bbox);
        localIntensity = mean(localIm(regs(r).Image),'all');
        regs(r).localIntensity = localIntensity;
    end

    % we'll use the largest detected blob as our animal
    [maxSz,maxID] = max([regs.Area]);
    if maxSz>50
        trajectory(f,:) = [regs(maxID).Centroid,regs(maxID).Area,regs(maxID).localIntensity];
    end

    if visualise==1
        imshown.CData = frame;
        imsc.XData = trajectory(f,1);
        imsc.YData = trajectory(f,2);
        drawnow
    end

end
end