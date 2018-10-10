function HMV_JoystickHabituation(t, events, parameters, visStim, inputs, outputs, audio)
% This is meant to help the mouse learn to control the joystick
% Three visual stimuli appear:
% - One in the center, controlled by the joystick left and right
% - One in each side, indicating the targets
% The way to get reward is to move the first stimuli to either of the
% targets and hold it there for a brief period of time (avoid balistic).
% During that period of time a sound plays.

%% Define parameters
% Give the user the option to pass this as parameters
DistToReach = parameters.Distance_to_reach; % How far from the center
TargetRange = parameters.Target_range; % How wide
TimeToHold = parameters.Time_to_hold; % For how long to keep the joystick in that position

%% Time, licks, joystick
% To monitor time
events.t = t;

% Lick detection
lick_raw = inputs.lick;
events.lick = lick_raw;

% TODO: Implement an online thresholding to count licks, where the threshold
% is passed as an input in the parameters section

% Joystick, filtered to avoid flickering
joystick_raw = 25*inputs.wheel;
joystick = joystick_raw.map(@floor).skipRepeats;
% make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
% TODO: Implement a calibration for the joystick to define the zero
% position without the mouse in the setup

%% Visual stimuli
% Generate two rectangles that indicate the target to reach
TargetStim_1 = vis.patch(t, 'rect');
TargetStim_2 = vis.patch(t, 'rect');
TargetStim_1.azimuth = DistToReach;
TargetStim_2.azimuth = - DistToReach;
TargetStim_1.dims = [TargetRange,95];
TargetStim_2.dims = [TargetRange,95];
TargetStim_1.show = true;
TargetStim_2.show = true;
visStim.TargetStim_1 = TargetStim_1;
visStim.TargetStim_2 = TargetStim_2;

% Show a stimulus that can be controlled with the joystick
MovingStim = vis.grating(t, 'square', 'gaussian');
MovingStim_azimuth = 2 * -(joystick - zero_joystick); %negative because it goes the other way around
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.sigma = [5 5];
MovingStim.spatialFreq = 1/5;
MovingStim.show = true;
visStim.gaborStim = MovingStim;

%% Define the succesful trial condition
% TODO: Implement the 'hold for some time' condition

% Define the condition when the trial is successful. Do this when the
% grating is within a narrow range of the square.
% Joystick reaches the target
joystick_reach = or(MovingStim_azimuth >= (DistToReach - TargetRange/2), ...
    MovingStim_azimuth <= (-DistToReach + TargetRange/2));

% Joystick has moved too much
joystick_overshoot = or(MovingStim_azimuth >= (DistToReach - TargetRange/2), ...
    MovingStim_azimuth <= (-DistToReach + TargetRange/2));
joystick_left_to_target = or(MovingStim_azimuth <= (DistToReach + TargetRange/2), ...
    MovingStim_azimuth <= (-DistToReach + TargetRange/2));
joystick_condition_met = and(joystick_right_to_target, joystick_left_to_target);
events.joystick_condition_met = joystick_condition_met; %do I need this?

%% Sound stimuli
% Define the sound
audioSampleRate = 192e3;
toneAmplitude = 0.5;
toneFreq = 500;
toneDuration = 0.1;
% Define when to start the sound
soundTrigger = events.joystick_condition_met.delay(0);
% Play a sound while the condition is met
toneSamples = toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate);
toneSamplesSignal = events.expStart.mapn(@(x) toneSamples);
% pass that into the audio handler:
audio.tone1 = toneSamplesSignal.at(soundTrigger);

% 
% % TODO: make this dependent on accomplishment of the task, with a delay
% % endTrial = events.newTrial.delay(1); % could also write delay(events.newTrial,1)
% % Whatever parameter passed to events, will get displayed
% % events.endTrial = endTrial;
% % When the hit happens, end the trial: This is too fast and new trials are
% % initiated all the time. It should be fixed once the hit condition is
% % better.
% % endTrial = events.joystick_condition_met.delay(0.2);
% events.endTrial = at(true,joystick_condition_met);
% %events.endTrial = joystick_condition_met.at(true); %This doesn't do it
% 
% 
% TODO: start a new trial when joystick in the center?

%% End Trial
events.endTrial = events.newTrial.delay(10);
end
