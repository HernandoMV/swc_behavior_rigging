function HMV_JoystickHabituation_Bidirectional(t, events, parameters, visStim, inputs, outputs, audio)
% This is meant to help the mouse learn to control the joystick
% It is the second phase of learning. The animal needs to move the joystick
% left or right depending on where the stimulus appears, which also changes
% grating. A moving rectangle gives feedback on the joystick movement.When
% thresholds are reach either white noise appears if it is the wrong side,
% or reward is given and new trial is innitiated if joystick is in the
% center. The side is selected as a parameter.

%% Time, licks, joystick
% To monitor time
events.t = t;

% Lick detection
lick_raw = inputs.lick;
events.lick = lick_raw;

% Joystick, filtered to avoid flickering
joystick_raw = 10 * inputs.wheel;
joystick = joystick_raw.map(@floor).skipRepeats;
% make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
joystick_diff = joystick - zero_joystick;
% define a condition where the joystick is near the 0 position, in order
% not to move anything there, and as a condition to finish trial
joystick_zero_threshold = 2;
joystick_near_zero = abs(joystick_diff) < joystick_zero_threshold;

%% Define a target each trial, and the dependent variables
% test this differently
TrialSide = parameters.TrialSide;
events.TrialSide = TrialSide;

TrialTarget = cond(TrialSide==1, parameters.TargetDistance, ...
    TrialSide==-1, -parameters.TargetDistance, ...
    true, parameters.TargetDistance); % For first trial % CHECK IF THIS IS NEEDED
events.TrialTarget = TrialTarget;

TrialGrating = cond(TrialSide==1, parameters.GratingValue, ...
    TrialSide==-1, -parameters.GratingValue, ...
    true, parameters.GratingValue); % For first trial
events.TrialGrating = TrialGrating;

TrialAzimuth = cond(TrialSide==1, parameters.StimulusPosition, ...
    TrialSide==-1, -parameters.StimulusPosition, ...
    true, parameters.StimulusPosition); % For first trial
events.TrialAzimuth = TrialAzimuth;

%% Visual stimuli

% Helper stimuli
HelperStim_1 = vis.grating(t, 'square', 'gaussian');
HelperStim_1.azimuth = TrialAzimuth;
HelperStim_1.sigma = [20 20];
HelperStim_1.phase = TrialGrating;
HelperStim_1.show = true;
visStim.HelperStim_1 = HelperStim_1;

% Movable stimuli
MovingStim = vis.patch(t, 'rect');
% The joystick will not move at initial angles to avoid flickering
MovingStim_azimuth = - 4 * cond(...
    ~joystick_near_zero, joystick_diff - sign(joystick_diff) * joystick_zero_threshold, ... % to avoid a jump after threshold
    true, 0);
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.dims = [5,95];
MovingStim.show = true;
visStim.gaborStim = MovingStim;

%% Joystick target reached

Target_reached = cond(...
    TrialSide == 1, MovingStim_azimuth > TrialTarget, ...
    TrialSide == -1, MovingStim_azimuth < TrialTarget, ...
    true, 0); % This might not be needed

%% Wrong target reached

Wrong_reached = cond(...
    TrialSide == 1, MovingStim_azimuth < -TrialTarget, ...
    TrialSide == -1, MovingStim_azimuth > -TrialTarget, ...
    true, 0); % This might not be needed

%% Time to reward each trial
% Reasons for this same as with the joystick
Time_zero = cond(...
    skipRepeats(events.trialNum>1), t.at(events.newTrial),...
    true, 0);
Time_delta = t - Time_zero;
events.TimeDelta = Time_delta;

%% Reward
Condition_met = cond(Target_reached, true, ... % movement threshold reached
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

% Give feedback if wrong
% Define the sound
missNoiseDuration = 0.5;
missNoiseAmplitude = 0.02;
missNoiseSamples = missNoiseAmplitude*events.expStart.map(@(x) ...
    randn(2, audioSampleRate*missNoiseDuration));
% pass that into the audio handler:
audio.tone2 = missNoiseSamples.at(Wrong_reached);

%% End Trial
events.endTrial = events.newTrial.at(GiveReward.delay(parameters.IntertrialDelay)); %give time for sound

% TODO: Implement the condition that the joystick needs to be in the center
% again.

%% Define parameters
% Give the user the option to pass this as parameters
try
% parameters.useJoystick = true; %checkbox
parameters.rewardTime = 150; % How long to wait
parameters.rewardSize = 2; % Size of reward
parameters.IntertrialDelay = 2; % Delay between trials
parameters.TargetDistance = 8; % Distance of the target
parameters.GratingValue = 45;
parameters.StimulusPosition = 40;
parameters.TrialSide = 1; % 1 or -1 depending on the side
catch
end
    
end
