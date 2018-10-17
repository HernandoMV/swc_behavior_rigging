function HMV_JoystickHabituation(t, events, parameters, visStim, inputs, outputs, audio)
% This is meant to help the mouse learn to control the joystick
% Three visual stimuli appear:
% - One in the center, controlled by the joystick left and right
% - One in each side, indicating the targets
% The way to get reward is to move the first stimuli to either of the
% targets and hold it there for a brief period of time (avoid balistic).
% During that period of time a sound plays.



%% Time, licks, joystick
% To monitor time
events.t = t;

% Lick detection
lick_raw = inputs.lick;
events.lick = lick_raw;

% TODO: Implement an online thresholding to count licks, where the threshold
% is passed as an input in the parameters section.

% Joystick, filtered to avoid flickering
joystick_raw = 15 * inputs.wheel;
joystick = joystick_raw.map(@floor).skipRepeats;
% make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
% TODO: Implement a calibration for the joystick to define the zero
% position without the mouse in the setup

%% Visual stimuli
% Generate two rectangles that indicate the target to reach
TargetStim_1 = vis.patch(t, 'rect');
TargetStim_2 = vis.patch(t, 'rect');
TargetStim_1.azimuth = parameters.Distance_to_reach;
TargetStim_2.azimuth = - parameters.Distance_to_reach;
TargetStim_1.dims = [parameters.Target_range,95];
TargetStim_2.dims = [parameters.Target_range,95];
TargetStim_1.show = true;
TargetStim_2.show = true;
visStim.TargetStim_1 = TargetStim_1;
visStim.TargetStim_2 = TargetStim_2;

% Show a stimulus that can be controlled with the joystick
MovingStim = vis.grating(t, 'square', 'gaussian');
MovingStim_azimuth = 4 * -(joystick - zero_joystick); %negative because it goes the other way around
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.sigma = [5 5];
MovingStim.spatialFreq = 1/5;
MovingStim.show = true;
visStim.gaborStim = MovingStim;

%% Define the succesful trial condition
% Define the condition when the trial is successful. Do this when the
% grating is within a narrow range of the square.
% Joystick reaches the target
lower_limit = parameters.Distance_to_reach - parameters.Target_range/2;
joystick_reach = or(MovingStim_azimuth >= lower_limit, ...
    MovingStim_azimuth <= - lower_limit);
% Joystick has moved too much
upper_limit = parameters.Distance_to_reach + parameters.Target_range/2;
joystick_overshoot = or(MovingStim_azimuth >= upper_limit, ...
    MovingStim_azimuth <= - upper_limit);

joystick_condition_met = and(joystick_reach, ~joystick_overshoot);
joystick_in_range = joystick_condition_met.skipRepeats;
events.joystick_in_range = joystick_in_range;

%% Reward and end of trial
% Define when the task is accomplished
% This works as a counter:
Time_in_range = cond(...
    joystick_in_range, t - t.at(joystick_in_range), ...
    true, 0);
% Task accomplished:
Task_accomplished = Time_in_range >= parameters.Time_to_hold;
SR_Task_accomplished = Task_accomplished.skipRepeats;
events.Task_accomplished = SR_Task_accomplished;

% Give reward when task has been accomplished, only once per trial
GiveReward_trigger = events.newTrial.setTrigger(SR_Task_accomplished);
% events.GiveReward_trigger = GiveReward_trigger;
GiveReward = GiveReward_trigger.to(events.newTrial);
% events.GiveReward = GiveReward;
outputs.reward = parameters.Reward_size.at(GiveReward); % output reward

%% Sound stimuli
% Define the sound
audioSampleRate = 192e3;
toneAmplitude = 0.5;
toneFreq = 4000;
toneDuration = 0.1;
% Play a sound while the condition is met
toneSamples = toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate);
toneSamplesSignal = events.expStart.mapn(@(x) toneSamples);
% pass that into the audio handler:
audio.tone1 = toneSamplesSignal.at(GiveReward.delay(0));


%% End Trial
% end trial if task is successful and joystick is back to the center.
joystick_in_zero = joystick == zero_joystick;
events.Joystick_in_zero = joystick_in_zero.skipRepeats;

% PROBLEM: conditions to finish the trial are not reached 
% make a conditional signal that is true once the task is accomplished and
% false when a new trial starts.


% Mark that it was a success (the task)
Success = at(true,Task_accomplished);
% Mark that it was a success (the task)
events.success = Success;
% Make a variable that tracks success and is false at the beginning of
% trial
Ready_to_end = Success.to(events.Joystick_in_zero.delay(0.1));
events.Ready_to_end = Ready_to_end;
%end trial if both conditions are satisfied
% Task_accomplished is not true once the task has been accomplished and the
% joystick leaves the reward zone, so this End_Trial is never true:
End_Trial = and(events.Ready_to_end, events.Joystick_in_zero);
SR_End_Trial = at(true,End_Trial.skipRepeats);
% End_Trial_true = at(true,End_Trial); % THIS CAUSES PROBLEM
events.endTrial = SR_End_Trial.delay(0.1);
% events.endTrial = events.newTrial.delay(5);

%% Define parameters
% Give the user the option to pass this as parameters
try
parameters.Distance_to_reach = 30; % How far from the center
parameters.Target_range = 5; % How wide
parameters.Time_to_hold = 0.1; % For how long to keep the joystick in that position
parameters.Reward_size = 3; % Size of reward
catch
end
    
end
