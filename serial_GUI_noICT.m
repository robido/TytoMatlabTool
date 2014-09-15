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

% Last Modified by GUIDE v2.5 14-Sep-2014 16:30:52

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
persistent STATE last_cycle
if(isempty(last_cycle))
    last_cycle = now;
end

%Get handles structure
try
    handles = guidata(hObject.figure1);
catch
    handles = guidata(hObject);
end

%Update the state using serial comm and protocol functions
[STATE, CYCLE] = CORE_LOOP(handles.serConn,STATE);
    
if(CYCLE) %Only update after a full cycle
    %Get serial refresh rate
    current_time = now;
    serialTime = last_cycle-current_time;
    last_cycle = current_time;
    serial_delay = 24*3600*serialTime;
    serial_Hz = round(1/serial_delay);
    
    %Get results
    cycleTime = protocol_get_cycleTime(STATE);
    debug = protocol_get_debug(STATE); 
    
    %Display on graph
    OSCILLOSCOPE_update([cycleTime debug(1)]);
    
    %Display on GUI
    DISP_string = [];
    DISP_string = [DISP_string,'serialRate (Hz):',32,num2str(serial_Hz),10,13];
    DISP_string = [DISP_string,'cycleTime (us):',32,num2str(cycleTime),10,13];
    DISP_string = [DISP_string,'cycleTime (Hz):',32,num2str(round(1000000/cycleTime)),10,13];
    DISP_string = [DISP_string,'debug:',32,num2str(debug),10,13];
    set(handles.txt_test,'String',DISP_string);
    drawnow
end

% --- Executes just before serial_GUI_noICT is made visible.
function serial_GUI_noICT_OpeningFcn(hObject, eventdata, handles, varargin)

%Get the list of available ports
comPORTS = get_serial_ports();

% serialPorts = instrhwinfo('serial');
% nPorts = length(serialPorts.SerialPorts);
set(handles.portList, 'String', comPORTS);
set(handles.portList, 'Value', 1);   

GUItimer = timer('TimerFcn',{@GUI_update_timer,hObject},'StartDelay',0.5,'Period',0.001,'ExecutionMode','fixedRate');
handles.GUItimer = GUItimer;

handles.output = hObject;

OSCILLOSCOPE_init

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
    serPortn = get(handles.portList, 'Value');
    serList = get(handles.portList,'String');
    serPort = serList{serPortn};
    
    %Activate the serial connection
    serConn = serial_setup_open(serPort, str2num(get(handles.baudRateText, 'String')));
    if(serConn ~= 0)
        handles.serConn = serConn;
        guidata(hObject, handles);
        start(handles.GUItimer);
        set(hObject, 'String','Disconnect')
    end
else  
    set(hObject, 'String','Connect')
    stop(handles.GUItimer);
    serial_close(handles.serConn);
end
guidata(hObject, handles);

% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if isfield(handles, 'serConn')
    serial_close(handles.serConn);
end

% Hint: delete(hObject) closes the figure
delete(hObject);

try
stop(handles.GUItimer);
catch
end

OSCILLOSCOPE_close

% --- Executes during object creation, after setting all properties.
function figure1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
addpath(genpath(pwd));
