function HMV_JoystickHabituation_Move(t, events, parameters, visStim, inputs, outputs, audio)
% This is meant to help the mouse learn to control the joystick
% It is the first phase of learning. Whenever the mouse moves the joystick,
% it gets a big reward, a tone sounds, and trial ends.
% Trial ends also with reward if certain time elapses.
% A visual stimulus moves with the joystick

%% Time, licks, joystick
% To monitor time
events.t = t;

% Lick detection
lick_raw = inputs.lick;
events.lick = lick_raw;

% TODO: Implement an online thresholding to count licks, where the threshold
% is passed as an input in the parameters section.

% Joystick, filtered to avoid flickering
joystick_raw = 10 * inputs.wheel;
joystick = joystick_raw.map(@floor).skipRepeats;
% make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
joystick_diff = joystick - zero_joystick;
% define a condition where the joystick is near the 0 position, in order
% not to move anything there, and as a condition to finish trial
joystick_zero_threshold = 3;
joystick_near_zero = abs(joystick_diff) < joystick_zero_threshold;

% TODO: Implement a calibration for the joystick to define the zero
% position without the mouse in the setup

%% Visual stimuli
% Show a stimulus that can be controlled with the joystick
MovingStim = vis.grating(t, 'square', 'none');
% The joystick will not move at initial angles to avoid flickering
MovingStim_azimuth = - 4 * cond(...
    ~joystick_near_zero, joystick_diff - sign(joystick_diff) * joystick_zero_threshold, ... % to avoid a jump after threshold
    true, 0);
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.sigma = [5 5];
MovingStim.spatialFreq = 1/25;
MovingStim.show = true;
visStim.gaborStim = MovingStim;

%% Joystick movement each trial
% starting point of the joystick/azimuth each trial, which is not
% initialized in the first trial and therefore needs a 'cond'
MovingStim_start = cond(...
    skipRepeats(events.trialNum>1), MovingStim_azimuth.at(events.newTrial),...
    true, 0);
MovingStim_delta = MovingStim_azimuth - MovingStim_start;
events.MovementDelta = MovingStim_delta;

%% Time to reward each trial
% Reasons for this same as with the joystick
Time_zero = cond(...
    skipRepeats(events.trialNum>1), t.at(events.newTrial),...
    true, 0);
Time_delta = t - Time_zero;
events.TimeDelta = Time_delta;

%% Reward
Condition_met = cond(abs(MovingStim_delta) > parameters.movementThreshold, true, ... % movement threshold reached
  Time_delta > parameters.rewardTime, true, ... % time reached
  true, 0);
 events.Condition_met = Condition_met;
% Give it only once per trial
GiveReward_trigger = events.newTrial.setTrigger(Condition_met);
GiveReward = GiveReward_trigger.to(events.newTrial); %skipRepeats does nothing
outputs.reward = parameters.rewardSize.at(GiveReward);

%% Sound stimuli
% Define the sound
audioSampleRate = 192e3;
toneAmplitude = 0.5;
toneFreq = 4000;
toneDuration = 0.1;
% Play a sound when the condition is met
toneSamples = toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate);
toneSamplesSignal = events.expStart.mapn(@(x) toneSamples);
% pass that into the audio handler:
audio.tone1 = toneSamplesSignal.at(GiveReward);

%% End Trial
events.endTrial = events.newTrial.at(GiveReward.delay(parameters.IntertrialDelay)); %give time for sound

%% Define parameters
% Give the user the option to pass this as parameters
try
% parameters.useJoystick = true; %checkbox
parameters.movementThreshold = 15; % How much to move the joystick
parameters.rewardTime = 30; % How long to wait
parameters.rewardSize = 2; % Size of reward
parameters.IntertrialDelay = 2; % Delay between trials
catch
end
    
end
