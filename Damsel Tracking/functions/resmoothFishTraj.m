function traj_sm = resmoothFishTraj(traj,constant)
nf = length(traj);
smoothed = csaps(1:nf,traj(:,1:2)',0.1,1:nf)';
smoothDiff = vecnorm(smoothed-traj(:,1:2),2,2);
spurious = smoothDiff>10;
smoothed(spurious) = nan;
traj_sm = smoothed;
end