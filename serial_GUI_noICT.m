function varargout = serial_GUI_noICT(varargin)
% SERIAL_GUI_NOICT M-file for serial_GUI_noICT.fig
%      SERIAL_GUI_NOICT, by itself, creates a new SERIAL_GUI_NOICT or raises the existing
%      singleton*.
%
%      H = SERIAL_GUI_NOICT returns the handle to a new SERIAL_GUI_NOICT or the handle to
%      the existing singleton*.
%
%      SERIAL_GUI_NOICT('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SERIAL_GUI_NOICT.M with the given input arguments.
%
%      SERIAL_GUI_NOICT('Property','Value',...) creates a new SERIAL_GUI_NOICT or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before serial_GUI_noICT_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to serial_GUI_noICT_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help serial_GUI_noICT

% Last Modified by GUIDE v2.5 18-Nov-2014 20:26:49

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @serial_GUI_noICT_OpeningFcn, ...
                   'gui_OutputFcn',  @serial_GUI_noICT_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

function GUI_update_timer(~,~,hObject)
persistent STATE last_cycle refresh_delay averageSerialHz

if(isempty(last_cycle))
    last_cycle = now;
    refresh_delay = 0;
    STATE.OUTCOMMANDS = [];
end

%Get handles structure
try
    handles = guidata(hObject.figure1);
catch
    handles = guidata(hObject);
end

%Get the joystick readings
joy=jst;   
THROTTLE = joy(1);
YAW = joy(2);
PITCH = joy(3);
ROLL = joy(4)-0.5;

%Display joystick
set(handles.left_joy_plot,'XData',YAW,'YData',THROTTLE);
set(handles.right_joy_plot,'XData',ROLL,'YData',PITCH);

%Manual Control
if( get(handles.chk_manual_rc,'Value') )
    ROLL = 1400 + 100*ROLL;
    PITCH = 1500 + 500*PITCH;
    YAW = 1500 + 500*YAW;
    THROTTLE = 1500 + 500*THROTTLE;
    AUX1 = 1500;
    AUX2 = 1500;
    AUX3 = 1500;
    AUX4 = 1500;
    RC_VALS = [ROLL PITCH YAW THROTTLE AUX1 AUX2 AUX3 AUX4];
    [r,c]=find(RC_VALS>2000);
    RC_VALS(sub2ind(size(RC_VALS),r,c)) = 2000;
    [r,c]=find(RC_VALS<1000);
    RC_VALS(sub2ind(size(RC_VALS),r,c)) = 1000;

    STATE.MSP_SET_RAW_RC = RC_VALS;
    STATE.OUTCOMMANDS = [STATE.OUTCOMMANDS 200]; %Request this command to be sent.
else
    if( get(handles.chkTrustTest,'Value') ) 
    else
        if( get(handles.chkTailTest,'Value') )
        else
            STATE.OUTCOMMANDS = STATE.OUTCOMMANDS(STATE.OUTCOMMANDS~=200); %Remove all commands related to manual control
        end
    end
end
STATE.OUTCOMMANDS = unique(STATE.OUTCOMMANDS);

%Get the list of commands to be refreshed
M_Selections = get(handles.list_M_data,'Value');
Plot_Selections = get(handles.list_plot,'Value');
size_psel = size(Plot_Selections,2);
if(size_psel>3)
    Plot_Selections(4:size_psel)=[]; %Limit selection to 3 
    set(handles.list_plot,'Value',Plot_Selections);
end
List_of_commands = protocol_find_simple_list(M_Selections,Plot_Selections,STATE.OUTCOMMANDS);
Delay_comp = round(str2double(get(handles.txt_delay_comp,'String')));

%Update the state using serial comm and protocol functions
[STATE, CYCLE] = CORE_LOOP(handles.serConn, handles.captureFile ,STATE,List_of_commands,Delay_comp);
    
if(CYCLE) %Only update after a full cycle
    %Get serial refresh rate
    current_time = now;
    serialTime = current_time-last_cycle;
    last_cycle = current_time;
    serial_delay = 24*3600*serialTime;
    serial_Hz = 1/serial_delay;
    averageSerialHz = [averageSerialHz serial_Hz];
    STATE.SERIAL.rate = serial_Hz;

    %Display on PLOT
    plot_values = protocol_get_plot_values(STATE,Plot_Selections);
    OSCILLOSCOPE_update(plot_values);
    
    refresh_delay = refresh_delay + 1;
    if(refresh_delay>0) %This value controls how often the text is refreshed.
        %Display on GUI
        set(handles.txt_serial_Hz,'String',num2str(round(mean(averageSerialHz))));
        averageSerialHz = [];
        
        %Display plot text
        plot_names = protocol_get_plot_names(STATE,Plot_Selections);
        set(handles.txt_plot_1,'String',strcat(plot_names{1},':',32,num2str(plot_values(1))));
        set(handles.txt_plot_2,'String',strcat(plot_names{2},':',32,num2str(plot_values(2))));
        set(handles.txt_plot_3,'String',strcat(plot_names{3},':',32,num2str(plot_values(3))));
        
        if(~isempty(M_Selections))
            List_to_display = protocol_find_simple_list(M_Selections,[],[]);
        else
            List_to_display = [];
        end
        DISP_string = protocol_get_M_display(STATE,List_to_display); 
        if (get(handles.txt_test,'Value')>size(DISP_string,2) )
            set(handles.txt_test,'Value',size(DISP_string,2));
        end
        set(handles.txt_test,'String',DISP_string);
        refresh_delay = 0;
    end
end
drawnow

% --- Executes just before serial_GUI_noICT is made visible.
function serial_GUI_noICT_OpeningFcn(hObject, eventdata, handles, varargin)

GUItimer = timer('TimerFcn',{@GUI_update_timer,hObject},'StartDelay',0.5,'Period',0.001,'ExecutionMode','fixedRate','BusyMode','queue');
handles.GUItimer = GUItimer;

handles.output = hObject;

OSCILLOSCOPE_init

%Fill the heli data box
protocol_import_DEF(1); %Refresh the imported data
M_DATA = protocol_get_list_M_data();
size_data = size(M_DATA,2);
content = {};
counter = 1;
for i=1:size_data
    content{i}=M_DATA{i}.NAME;
end
set(handles.list_M_data,'String',content);

set(handles.txt_test,'BackgroundColor',get(handles.figure1,'Color'));

%Fill the list to plot
P_LIST = protocol_get_plot_list();
size_data = size(P_LIST,2);
content = {};
for(i=1:size_data)
    content{i}=P_LIST{i}.NAME;
end
set(handles.list_plot,'String',content);

%Make the joystick plots
handles.left_joy_plot = plot(handles.axes_joy_left,0,0,'ro','MarkerFaceColor','r');
xlabel(handles.axes_joy_left,'Yaw');
ylabel(handles.axes_joy_left,'Throttle');
xlim(handles.axes_joy_left,'manual');
xlim(handles.axes_joy_left,[-1 1]);
ylim(handles.axes_joy_left,'manual');
ylim(handles.axes_joy_left,[-1 1]);
set(handles.axes_joy_left,'YTickLabel',[]);
set(handles.axes_joy_left,'XTickLabel',[]);

handles.right_joy_plot = plot(handles.axes_joy_right,0,0,'ro','MarkerFaceColor','r');
xlabel(handles.axes_joy_right,'Roll');
ylabel(handles.axes_joy_right,'Pitch');
xlim(handles.axes_joy_right,'manual');
xlim(handles.axes_joy_right,[-1 1]);
ylim(handles.axes_joy_right,'manual');
ylim(handles.axes_joy_right,[-1 1]);
set(handles.axes_joy_right,'YTickLabel',[]);
set(handles.axes_joy_right,'XTickLabel',[]);

%Load essential GUI data if any
try
load('GUI_DATA','GUI_DATA');
set(handles.txt_COM,'String',GUI_DATA.com);
set(handles.baudRateText,'String',GUI_DATA.baud);
catch
end

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes serial_GUI_noICT wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = serial_GUI_noICT_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on selection change in portList.
function portList_Callback(hObject, eventdata, handles)
% hObject    handle to portList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns portList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from portList


% --- Executes during object creation, after setting all properties.
function portList_CreateFcn(hObject, eventdata, handles)
% hObject    handle to portList (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function history_box_Callback(hObject, eventdata, handles)
% hObject    handle to history_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of history_box as text
%        str2double(get(hObject,'String')) returns contents of history_box as a double


% --- Executes during object creation, after setting all properties.
function history_box_CreateFcn(hObject, eventdata, handles)
% hObject    handle to history_box (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function baudRateText_Callback(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of baudRateText as text
%        str2double(get(hObject,'String')) returns contents of baudRateText as a double


% --- Executes during object creation, after setting all properties.
function baudRateText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to baudRateText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in connectButton.
function connectButton_Callback(hObject, eventdata, handles)    
if strcmp(get(hObject,'String'),'Connect') % currently disconnected
    serPort = get(handles.txt_COM,'String');
    
    %Activate the serial connection
    [serConn serFile] = serial_setup_open(serPort, str2num(get(handles.baudRateText, 'String')));
    if(serConn ~= 0)
        handles.serConn = serConn;
        handles.captureFile = serFile;
        guidata(hObject, handles);
        start(handles.GUItimer);
        set(hObject, 'String','Disconnect')
        set(handles.txt_COM,'Enable','off');
        set(handles.baudRateText,'Enable','off');
        set(handles.txt_delay_comp,'Enable','off');
    end
else  
    set(hObject, 'String','Connect')
    stop(handles.GUItimer);
    serial_close(handles.serConn,handles.captureFile);
    set(handles.txt_COM,'Enable','on');
    set(handles.baudRateText,'Enable','on');
    set(handles.txt_delay_comp,'Enable','on');
end
guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.connectButton,'String'),'Disconnect')
    msgbox('Please disconnect first.');
else
    %Stop what can be stopped
    stop(handles.GUItimer);
    try
    serial_close(handles.serConn,handles.captureFile);
    catch
    end

    OSCILLOSCOPE_close;
    
    %Save essential GUI data
    GUI_DATA.com = get(handles.txt_COM,'String');
    GUI_DATA.baud = get(handles.baudRateText,'String');
    save('GUI_DATA','GUI_DATA');
    
    % Hint: delete(hObject) closes the figure
    delete(hObject);
end


% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
addpath(genpath(pwd));


% --- Executes on selection change in list_plot.
function list_plot_Callback(hObject, eventdata, handles)
% hObject    handle to list_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_plot contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_plot


% --- Executes during object creation, after setting all properties.
function list_plot_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_plot (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in list_M_data.
function list_M_data_Callback(hObject, eventdata, handles)
% hObject    handle to list_M_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns list_M_data contents as cell array
%        contents{get(hObject,'Value')} returns selected item from list_M_data


% --- Executes during object creation, after setting all properties.
function list_M_data_CreateFcn(hObject, eventdata, handles)
% hObject    handle to list_M_data (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_delay_comp_Callback(hObject, eventdata, handles)
% hObject    handle to txt_delay_comp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_delay_comp as text
%        str2double(get(hObject,'String')) returns contents of txt_delay_comp as a double


% --- Executes during object creation, after setting all properties.
function txt_delay_comp_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_delay_comp (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chk_manual_rc.
function chk_manual_rc_Callback(hObject, eventdata, handles)
% hObject    handle to chk_manual_rc (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chk_manual_rc
if(get(hObject,'Value'))
    set(handles.chkTrustTest,'Value',0);
    set(handles.chkTailTest,'Value',0);
    set(handles.chkTrustTest,'Enable','off');
    set(handles.chkTailTest,'Enable','off');
else
    set(handles.chkTrustTest,'Enable','on');
    set(handles.chkTailTest,'Enable','on');
end

% --- Executes on button press in right_joy_pos.
function right_joy_pos_Callback(hObject, eventdata, handles)
% hObject    handle to right_joy_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of right_joy_pos


% --- Executes on button press in left_joy_pos.
function left_joy_pos_Callback(hObject, eventdata, handles)
% hObject    handle to left_joy_pos (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of left_joy_pos



function txt_test_Callback(hObject, eventdata, handles)
% hObject    handle to txt_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_test as text
%        str2double(get(hObject,'String')) returns contents of txt_test as a double


% --- Executes during object creation, after setting all properties.
function txt_test_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_test (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function txt_COM_Callback(hObject, eventdata, handles)
% hObject    handle to txt_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of txt_COM as text
%        str2double(get(hObject,'String')) returns contents of txt_COM as a double
persistent VAL
if(isempty(VAL))
    VAL = 1;
end
try
    temp_val = round(str2double(get(hObject,'String')));
    VAL = temp_val;
catch
end
set(hObject,'String',num2str(VAL));

% --- Executes during object creation, after setting all properties.
function txt_COM_CreateFcn(hObject, eventdata, handles)
% hObject    handle to txt_COM (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in chkTrustTest.
function chkTrustTest_Callback(hObject, eventdata, handles)
% hObject    handle to chkTrustTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkTrustTest
if(get(hObject,'Value'))
    set(handles.chk_manual_rc,'Value',0);
    set(handles.chkTailTest,'Value',0);
    set(handles.chk_manual_rc,'Enable','off');
    set(handles.chkTailTest,'Enable','off');
else
    set(handles.chk_manual_rc,'Enable','on');
    set(handles.chkTailTest,'Enable','on');
end

% --- Executes on button press in chkTailTest.
function chkTailTest_Callback(hObject, eventdata, handles)
% hObject    handle to chkTailTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of chkTailTest
if(get(hObject,'Value'))
    set(handles.chk_manual_rc,'Value',0);
    set(handles.chkTrustTest,'Value',0);
    set(handles.chk_manual_rc,'Enable','off');
    set(handles.chkTrustTest,'Enable','off');
else
    set(handles.chk_manual_rc,'Enable','on');
    set(handles.chkTrustTest,'Enable','on');
end