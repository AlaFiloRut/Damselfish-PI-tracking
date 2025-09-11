function [backgroundIm,STDIm] = fishBackgroundSubtract(vr,frameNumbers)
% This function gets both the background image and the S.T.D. in pixel
% values
frameStack = uint8(zeros(vr.Height,vr.Width,numel(frameNumbers)));
for f_ind = 1:numel(frameNumbers)
    f = frameNumbers(f_ind);
    frame =rgb2gray(read(vr,f));
    frameStack(:,:,f_ind) = frame;
end
backgroundIm = mean(frameStack,3);
STDIm = std(single(frameStack),[],3);
STDIm(STDIm<1)=1;
end