s = daq.createSession('ni');
[ch, idx] = s.addAnalogInputChannel('Dev1', 'ai8', 'Voltage');
ch.TerminalConfig = 'SingleEnded';
while true
    values = inputSingleScan(s);
    x = values(idx);
    disp(x);
    pause(0.1);
end