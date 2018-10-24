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
% events.lick = lick_raw;

% Joystick, filtered to avoid flickering
joystick_movement_ratio = 60;
joystick_raw = joystick_movement_ratio * inputs.wheel;
joystick = joystick_raw.map(@floor).skipRepeats;
% make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
joystick_diff = joystick - zero_joystick;
% define a condition where the joystick is near the 0 position, in order
% not to move anything there, and as a condition to finish trial
joystick_zero_threshold = joystick_movement_ratio / 10;
joystick_near_zero = abs(joystick_diff) < joystick_zero_threshold;

%% Define a target each trial, and the dependent variables
% Define it based on blocks
% The following variable is either 0 or 1
Block_Mod = mod(floor(events.trialNum/parameters.BlockSize), 2);
events.Block_Mod = Block_Mod.skipRepeats;
TrialSide = cond(Block_Mod == 1, 1, ...
    true, -1);

events.TrialSide = TrialSide;

TrialTarget = cond(TrialSide==1, parameters.TargetDistance, ...
    TrialSide==-1, -parameters.TargetDistance, ...
    true, parameters.TargetDistance); % For first trial % CHECK IF THIS IS NEEDED
% events.TrialTarget = TrialTarget;

TrialGrating = cond(TrialSide==1, parameters.GratingValue, ...
    TrialSide==-1, -parameters.GratingValue, ...
    true, parameters.GratingValue); % For first trial
% events.TrialGrating = TrialGrating;

TrialAzimuth = cond(TrialSide==1, parameters.StimulusPosition, ...
    TrialSide==-1, -parameters.StimulusPosition, ...
    true, parameters.StimulusPosition); % For first trial
% events.TrialAzimuth = TrialAzimuth;

%% Visual stimuli
GracePeriod1 = events.newTrial.to(events.newTrial.delay(1));
GracePeriod2 = events.newTrial.to(events.newTrial.delay(1.5));

% Helper stimuli
HelperStim_1 = vis.grating(t, 'square', 'gaussian');
HelperStim_1.azimuth = TrialAzimuth;
HelperStim_1.sigma = [20 20];
HelperStim_1.orientation = TrialGrating;
HelperStim_1.show = ~GracePeriod1;
visStim.HelperStim_1 = HelperStim_1;

% Movable stimuli
MovingStim = vis.patch(t, 'rect');
% The joystick will not move at initial angles to avoid flickering
MovingStim_azimuth = - 1 * cond(...
    GracePeriod2, 0, ...
    ~joystick_near_zero, joystick_diff - sign(joystick_diff) * joystick_zero_threshold, ... % to avoid a jump after threshold
    true, 0);
MovingStim.azimuth = MovingStim_azimuth;
MovingStim.dims = [5,95];
MovingStim.colour = [0 0 0];
MovingStim.show = ~GracePeriod1;
visStim.gaborStim = MovingStim;
events.MovingAzimuth = MovingStim_azimuth;

%% Joystick target reached

Target_reached = cond(...
    TrialSide == 1, MovingStim_azimuth > TrialTarget, ...
    TrialSide == -1, MovingStim_azimuth < TrialTarget, ...
    true, 0); % This might not be needed
events.TargetReached = Target_reached;

%% Wrong target reached

Wrong_reached = cond(...
    TrialSide == 1, MovingStim_azimuth < -TrialTarget, ...
    TrialSide == -1, MovingStim_azimuth > -TrialTarget, ...
    true, 0); % This might not be needed
events.WrongReached = Wrong_reached;

%make a signal that is true if the wrong side is reached
Wrong_reached_penalty = Wrong_reached.to(Wrong_reached.delay(2.5));
% events.WRP = Wrong_reached_penalty;
%% Time to reward each trial
% Reasons for this same as with the joystick
Time_zero = cond(...
    skipRepeats(events.trialNum>1), t.at(events.newTrial),...
    true, 0);
Time_delta = t - Time_zero;
events.TimeDelta = Time_delta;

%% Reward
Condition_met = cond(Wrong_reached_penalty, 0, ... %wrong movement
  Target_reached, true, ... % movement threshold reached
  Time_delta > parameters.rewardTime, true, ... % time reached
  true, 0);
 events.Condition_met = Condition_met;
% Give it only once per trial: THIS FAILS AS TRIALS DO NOT RESTART IF THE
% JOYSTICK IS KEPT FOR TOO LONG OVER THE TARGET
GiveReward_trigger = events.newTrial.setTrigger(Condition_met);
events.trigger = GiveReward_trigger;
GiveReward = GiveReward_trigger.to(events.newTrial); %skipRepeats does nothing
events.GiveReward = GiveReward;

% GiveReward = Condition_met.skipRepeats;

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
missNoiseDuration = 0.2;
missNoiseAmplitude = 0.02;
missNoiseSamples = missNoiseAmplitude*events.expStart.map(@(x) ...
    randn(2, audioSampleRate*missNoiseDuration));
% pass that into the audio handler:
audio.tone2 = missNoiseSamples.at(Wrong_reached);

%% End Trial
% events.endTrial = events.newTrial.at(GiveReward.delay(parameters.IntertrialDelay)); %give time for sound

% THIS MIGHT CONTAIN QUITE A LOT OF JUNK BUT I FOUND IT WORKED AFTER TRYING
% A BUNCH OF STUFF
% events.endTrial = events.newTrial.at(GiveReward.setTrigger(joystick_near_zero).delay(parameters.IntertrialDelay));
Task_Accomplished = GiveReward.to(events.newTrial);
% Task_Accomplished_delay = Task_Accomplished.delay(parameters.IntertrialDelay).to(events.newTrial);
% events.TAD = Task_Accomplished_delay;
JNZ = at(true,joystick_near_zero);
JNZ_cond = Task_Accomplished.to(JNZ.skipRepeats).skipRepeats;
% events.JNZ = JNZ.skipRepeats;
% events.JNZcond = JNZ_cond;
Ready_to_end = and(Task_Accomplished, JNZ_cond);
SR_Ready_to_end = Ready_to_end.skipRepeats;
% events.RTE = SR_Ready_to_end;

events.endTrial = events.GiveReward.at(SR_Ready_to_end.delay(parameters.IntertrialDelay));


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
parameters.BlockSize = 10; % number of trials each block
catch
end
    
end

