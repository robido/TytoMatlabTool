%
% Test joystick dll's (up to 2 joysticks)
%
figure(1);
fprintf('\n Type ctrl-C to stop\n')
done=0;
clf
while done==0; 
    joy1=jst;
    joy1(5)=[]
    %joy2=jst2;
    plot(joy1(2),-joy1(1),'b+');
    axis([-1 1 -1 1]);
    drawnow
    pause(.1);
end