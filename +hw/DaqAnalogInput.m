classdef DaqAnalogInput < hw.PositionSensor
  %HW.DAQANALOGINPUT Tracks analog input from a DAQ
  %TODO update documentation
  %   Communicates with rotary encoder via a DAQ. Will configure a DAQ
  %   session counter channel for you, log position and times every time you
  %   call readPosition, and allows 'zeroing' at the current position. Also
  %   takes care of the DAQ counter overflow when ticking over backwards.
  %
  %   e.g. use:
  %     session = daq.createSession('ni')
  %     enc = RotaryEncoder  % I think this line should say: enc = hw.DaqRotaryEncoder % NS 2014-10-28
  %     enc.DaqSession = session
  %     enc.DaqId = 'Dev1'
  %     enc.createDaqChannel
  %     [x, time] = enc.readPosition
  %     enc.zero
  %     [x, time] = enc.readPosition
  %     X = enc.Positions
  %     T = enc.PositionTimes
  %
  % Part of Rigbox
  
  properties
    DaqSession = [] %DAQ session for input (see session-based interface docs)
    DaqId = 'Dev1' %DAQ's device ID, e.g. 'Dev1'
    DaqChannelId = 'ai8' %DAQ's ID for the analog input channel. e.g. 'ai8'
  end
  
  properties (Access = protected)
    %Created when listenForAvailableData is called, allowing logging of
    %positions during DAQ background acquision
    DaqListener
    DaqInputChannelIdx %Index into acquired input data matrices for our channel
  end
  
  properties (Dependent)
    DaqChannelIdx % index into DaqSession's channels for our data
  end
  
  methods
    function value = get.DaqChannelIdx(obj)
      inputs = find(strcmpi('input', io.daqSessionChannelDirections(obj.DaqSession)));
      value = inputs(obj.DaqInputChannelIdx);
    end
    
    function set.DaqChannelIdx(obj, value)
      % get directions of all channels on this session
      dirs = io.daqSessionChannelDirections(obj.DaqSession);
      % logical array flagging all input channels
      inputsUptoChannel = strcmp(dirs(1:value), 'Input');
      % ensure the channel we're setting is an input
      assert(inputsUptoChannel(value), 'Channel %i is not an input', value);
      % find channel number counting inputs only
      obj.DaqInputChannelIdx = sum(inputsUptoChannel);
    end
    
    function createDaqChannel(obj)
      [ch, idx] = obj.DaqSession.addAnalogInputChannel(obj.DaqId, obj.DaqChannelId, 'Voltage');
      ch.TerminalConfig = 'SingleEnded';
      obj.DaqChannelIdx = idx; % record the index of the channel
    end

%     function listenForAvailableData(obj)
%       disp('### listenForAvailableData ###')  % TODO remove
%       % adds a listener to the DAQ session that will receive and process
%       % data when the DAQ is acquiring data in the background (i.e.
%       % startBackground() has been called on the session).
%       deleteListeners(obj);
%       obj.DaqListener = obj.DaqSession.addlistener('DataAvailable', ...
%         @(src, event) daqListener(obj, src, event));
%     end
    
%     function delete(obj)
%       deleteListeners(obj);
%     end
    
%     function deleteListeners(obj)
%       if ~isempty(obj.DaqListener)
%         delete(obj.DaqListener);
%       end
%     end
  end
  
  methods %(Access = protected)
    function [x, time] = readAbsolutePosition(obj)
      if obj.DaqSession.IsRunning
        disp('waiting for session');
        obj.DaqSession.wait;
        disp('done waiting');
      end
      preTime = obj.Clock.now;
      daqVal = inputSingleScan(obj.DaqSession);
      x = daqVal(obj.DaqInputChannelIdx);
      postTime = obj.Clock.now;
      time = 0.5*(preTime + postTime); % time is mean of before & after
    end
  end
  
%   methods (Access = protected)
%     function daqListener(obj, ~, event)
%       disp('### daqListener ###')  % TODO remove
%       acqStartTime = obj.Clock.fromMatlab(event.TriggerTime);
%       values = decode(obj, event.Data(:,obj.DaqInputChannelIdx)) - obj.ZeroOffset;
%       times = acqStartTime + event.TimeStamps(:,obj.DaqInputChannelIdx);
%       logSamples(obj, values, times);
%     end
%   end
end