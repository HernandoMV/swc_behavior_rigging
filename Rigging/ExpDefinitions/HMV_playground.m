function HMV_playground(t, events, parameters, visStim, inputs, outputs, audio)
% Definition of when the trial will end, dependent on time delay to
% newTrial

% To monitor time
events.t = t;

% Lick detection
lick_raw = inputs.lick;
events.lick = lick_raw;


% Show a stimulus that can be controlled with the joystick
% The wheel is commonly set up as a signal with skipRepeats, though this
% may not be necessary
joystick_raw = 25*inputs.wheel;
%filter to avoid flickering
joystick = joystick_raw.map(@floor).skipRepeats;

% We will define a visual stimulus
% stim = vis.grating(t, 'sinusoid', 'gaussian');
stim = vis.grating(t, 'square', 'none');

% TODO: make the azimuth 0 when joystick in center
zero_joystick = joystick.at(events.expStart.delay(0));
stim_azimuth = 2 * -(joystick - zero_joystick); %negative because it goes the other way around
% we will set the azimuth to be controlled by the wheel signal
% stim_azimuth = cond(...
%     joystick, joystick_pos, ...
%     true, 0); %this is to initialize the azimuth to 0 so it does not crash
stim.azimuth = stim_azimuth;
stim.show = true;

visStim.gaborStim = stim;

% Every trial, plot a random square to reach by moving the joystick
sqStim = vis.patch(t, 'rect');
%make the azimuth random between a range
%the scan function requires an initial value, otherwise it doesn't work
randomAzimuth = events.newTrial.scan(@(~, ~) (rand() - 0.5) * 100, 0);
%randomAzimuth = 90;
sqStim_azimuth = cond(randomAzimuth, randomAzimuth, true, 0);
% sqStim_azimuth = randomAzimuth;
sqStim.azimuth = sqStim_azimuth;
sqStim.altitude = 0;
sqStim.show = true;
visStim.sqStim = sqStim;

% TODO: Define the condition when the trial is successful. Do this when the
% grating is within a narrow range of the square.
%somehow this condition cannot be defined dependent on sqStim.azimuth for
%example... I don't know why
% joystick_target = 45; %randomAzimuth
% if joystick_target >= 0
%    joystick_condition_met = joystick_pos > joystick_target;
% else
%    joystick_condition_met = joystick_pos < joystick_target;
% end
% events.joystick_condition_met = joystick_condition_met;

%TODO: Clean this shit!
 range_val = 5;
% joystick_condition_met = (joystick_pos >= (sqStim_azimuth - range_val) ...
%     && joystick_pos <= (sqStim_azimuth + range_val));
hit_target1 = sqStim_azimuth - range_val;
joystick_condition_met_1 = stim_azimuth >= hit_target1;
hit_target2 = sqStim_azimuth + range_val;
joystick_condition_met_2 = stim_azimuth <= hit_target2;

%joystick_condition_met = joystick_condition_met_1;
% this fails: 
joystick_condition_met = and(joystick_condition_met_1, joystick_condition_met_2);
%%%%%%%%%%%%
% % TODO: play a very short sound when the joystick reaches the square. This
% % should be fine if trials are reinitiated every time condition is met
% % Define when to start the sound
events.joystick_condition_met = joystick_condition_met; %do I need this?
% soundTrigger = events.joystick_condition_met.delay(0);
% % Define necessary parameters of the sound
% audioSampleRate = 192e3;
% toneAmplitude = 0.5;
% toneFreq = 500;
% toneDuration = 0.1;
% % Make the waveform of the tone (this uses a function in burgbox: try
% % running this code outside of signals and make sure to see that it's just
% % a vector that defines a sine wave)
% toneSamples = toneAmplitude*aud.pureTone(toneFreq, toneDuration, audioSampleRate);
% toneSamplesSignal = events.expStart.mapn(@(x) toneSamples);
% % Finally, we will trigger our waveform signal whenever soundTrigger
% % updates, and pass that into the audio handler.
% audio.default = toneSamplesSignal.at(soundTrigger);
%%%%%%%%%%%%%%%

% TODO: make this dependent on accomplishment of the task, with a delay
% endTrial = events.newTrial.delay(1); % could also write delay(events.newTrial,1)
% Whatever parameter passed to events, will get displayed
% events.endTrial = endTrial;
% When the hit happens, end the trial: This is too fast and new trials are
% initiated all the time. It should be fixed once the hit condition is
% better.
% endTrial = events.joystick_condition_met.delay(0.2);
events.endTrial = at(true,joystick_condition_met);
%events.endTrial = joystick_condition_met.at(true); %This doesn't do it


% TODO: start a new trial when joystick in the center?

end
