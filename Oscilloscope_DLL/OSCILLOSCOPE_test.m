OSCILLOSCOPE_init;

% run graph
cnt=1;
%tic
while (cnt<500)
    cnt = cnt+1;
    OSCILLOSCOPE_update([100* sin(cnt*2*pi / 1000+rand(1) ),100*cos(cnt*2*pi / 1000 ),-100*sin(2*cnt*2*pi / 1000 )  ]);
    pause(0.001);
    %drawnow;
end

OSCILLOSCOPE_close;