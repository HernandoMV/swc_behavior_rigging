function HMV_JoystickHabituation_Discriminate(t, events, parameters, visStim, inputs, outputs, audio)
% This is meant to help the mouse learn to control the joystick
% It is the second phase of learning. The animal needs to move the joystick
% left or right depending on the orientation of the gratings, that are
% shown in three different stimuli: Two big ones, one on each side, and one
% in the middle, which moves with the joystick to provide visual feedback
% on the movement. There is another stimuli that appears to indicate the
% target to reach, which will be left or right dependent on the stimuli.
% The opacity of this target can be specified in the parameters.

% There are no wrong trials for now


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
joystick_zero_threshold = 3;
joystick_near_zero = abs(joystick_diff) < joystick_zero_threshold;

% TODO: Implement a calibration for the joystick to define the zero
% position without the mouse in the setup

%% Define a target each trial, and the dependent variables
% test this differently
TrialSide = events.newTrial.scan(@(~, ~)...
    (randsample([-1,1],1)), 1); % CHECK IF THIS IS NEEDE
events.TrialSide = TrialSide;

TrialTarget = cond(TrialSide==1, parameters.TargetDistance, ...
    TrialSide==-1, -parameters.TargetDistance, ...
    true, parameters.TargetDistance); % For first trial % CHECK IF THIS IS NEEDED
events.TrialTarget = TrialTarget;

TrialGrating = cond(TrialSide==1, parameters.GratingValue, ...
    TrialSide==-1, -parameters.GratingValue, ...
    true, parameters.GratingValue); % For first trial
events.TrialGrating = TrialGrating;

%% Visual stimuli
%TODO: The stimuli display should be from the start of the trial to the
%end, and dissapear on the resting period.

% Target stimuli
TargetStim = vis.patch(t, 'rect');
TargetStim.azimuth = TrialTarget; % Target to reach
TargetStim.dims = [5,95];
TargetStim.show = true;
visStim.TargetStim = TargetStim;

% Helper stimuli
HelperStim_1 = vis.grating(t, 'square', 'gaussian');
HelperStim_2 = vis.grating(t, 'square', 'gaussian');
HelperStim_1.azimuth = 120;
HelperStim_2.azimuth = - 120;
HelperStim_1.sigma = [20 20];
HelperStim_2.sigma = [20 20];
HelperStim_1.phase = TrialGrating;
HelperStim_2.phase = TrialGrating;
HelperStim_1.show = true;
HelperStim_2.show = true;
visStim.HelperStim_1 = HelperStim_1;
visStim.HelperStim_2 = HelperStim_2;

% Movable stimuli
MovingStim = vis.grating(t, 'square', 'gaussian');
% The joystick will not move at initial angles to avoid flickering
MovingStim_azimuth = - 4 * cond(...
    ~joystick_near_zero, joystick_diff - sign(joystick_diff) * joystick_zero_threshold, ... % to avoid a jump after threshold
    true, 0);
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.sigma = [5 5];
MovingStim.phase = TrialGrating;
MovingStim.spatialFreq = 1/25;
MovingStim.show = true;
visStim.gaborStim = MovingStim;

%% Joystick target reached

Target_reached = cond(...
    TrialSide == 1, MovingStim_azimuth > TrialTarget, ...
    TrialSide == -1, MovingStim_azimuth < TrialTarget, ...
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

%% End Trial
events.endTrial = events.newTrial.at(GiveReward.delay(parameters.IntertrialDelay)); %give time for sound

% TODO: Implement the condition that the joystick needs to be in the center
% again.

%% Define parameters
% Give the user the option to pass this as parameters
try
% parameters.useJoystick = true; %checkbox
parameters.rewardTime = 30; % How long to wait
parameters.rewardSize = 2; % Size of reward
parameters.IntertrialDelay = 2; % Delay between trials
parameters.TargetDistance = 15; % Distance of the target
parameters.GratingValue = 45;
catch
end
    
end
