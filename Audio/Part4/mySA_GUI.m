function [] = mySA_GUI()
%mySA_GUI Creates the GUI for the Speech and Audio labs
%
% Syntax:  mySA_GUI()
%
% Inputs:
%
% Outputs:
%
%
% Example: 
%
% Other m-files required: mySA_GUI_graphics, all_callbacks, create_rirs, simroommex
% Subfunctions: none
% MAT-files required: none
% Version 1.1
% MATLAB version: R2016a
%
% See also: 
%
% Authors: Giuliano Bernardi, Alexander Bertrand
% KU Leuven, Department of Electrical Engineering (ESAT/SCD)
% email: giuliano.bernardi@esat.kuleuven.be
% Website: http://homes.esat.kuleuven.be/~gbernard/index.html
% Created: 17-October-2013; Last revision: 10-November-2016


%------------- BEGIN CODE --------------
% The handle 100 is assigned to the GUI
clear; clc;
if ishandle(100)
    close(100);
end

% Version
S.myVer = '1.11';

% ------------------------ VARIABLES ---------------------------         
% Default room dimension
S.rdim = 5;
% Default sampling frequency
S.fs = 44.1e3;
% Default rev time
S.reverb = 0;
% Default RIR length
S.lRIR = 0.5*S.fs;

% Initialize pushed_btn to null
S.pushed_btn = 0;
% This holds the handles to the points relative to audios, noise and mics.
S.hpc_audio = [];  
S.hpc_noise = [];  
S.hpc_mic = [];
% This holds the points relative to audios, noise and mics.
S.pc_audio = [];  
S.pc_noise = [];  
S.pc_mic = [];
% Number of components (initialized to zero)
S.L_audio = 0;
S.L_noise = 0;  
S.L_mic = 0;
% Handles with the components' labels
S.txt_audio = [];
S.txt_noise = [];
% Number of mic in the array and their distance
S.nmic = 0;
S.dmic = 0;
% Boolean flags checking content of the editboxes
S.flag_nmic = false;
S.flag_dmic = false;
S.flag_rdim = true;
S.flag_reverb = true;
S.flag_lRIR = true;
% Other handles
S.hDOAs_est = [];
S.hDOAs_true = [];

% if ~verLessThan('matlab','8.4')
    % Default Linewidth of the markers
    S.mlw = 1.5;
% end

% Load all the graphic objects
mySA_GUI_graphics;


% ------------------------------------------------------------
% ------------- Functions calls
% ------------------------------------------------------------
all_callbacks_fcn(S);

% End main function
% ------------------------------------------------------------
% ------------------------------------------------------------
% ------------------------------------------------------------


% -------------------- DRAW COMPONENTS -------------------------------------------------------------
function [] = ax_bdfcn(varargin)
    % Serves as the buttondownfcn for the axes.
    S = varargin{3};  % Get the structure.
    p = get(S.ax, 'currentpoint'); % Get the position of the mouse.

    % Check whether we are within the axis (otherwise a few pixel outside would be allowed)
    if (abs(p(1)) > S.rdim) || (abs(p(2)) > S.rdim)
        return
    end

    switch S.pushed_btn
        case S.pb_audio
            % If I enter here I'm sure the mic's already been placed
            xmic = get(S.hpc_mic(1),'Xdata'); 
            if p(1) <= xmic
                % Get current number of audio sources
                S.L_audio = length(S.hpc_audio);
                % Place at most 20 audio sources
                if S.L_audio < 20
                    S.L_audio = S.L_audio +1;
                    S.pc_audio(S.L_audio,:) = [p(1) p(3)];
                    S.hpc_audio(S.L_audio) = line(p(1),p(3),...
                        'Color','r','Marker','x','Linewidth',S.mlw);  % Make our plot.
                    S.txt_audio(S.L_audio) = text(p(1),p(3)+S.rdim*0.075,['a',num2str(length(S.hpc_audio))],'Fontsize',12,...
                        'FontWeight','Bold');

                    % Update the number of the audio sources
                    currNumber = str2double(get(S.text_audio,'String'));
                    set(S.text_audio,'String',num2str(currNumber + 1));
                else
                    wd = warndlg('20 is the maximum number of audio sources!','Warning');
                    set(wd, 'WindowStyle', 'modal');
                    uiwait(wd); 
                end
            else
                ed = errordlg('Audio sources must be on the left of the mic. array!','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);  
            end
        case S.pb_noise
            % If I enter here I'm sure the mic's already been placed
            xmic = get(S.hpc_mic(1),'Xdata'); 
            if p(1) <= xmic
                % Get current number of noise sources
                S.L_noise = length(S.hpc_noise);
                if S.L_noise < 5          
                    S.L_noise = S.L_noise + 1;
                    S.pc_noise(S.L_noise,:) = [p(1) p(3)];
                    S.hpc_noise(S.L_noise) = line(p(1),p(3),...
                        'Color','k','Marker','s','Linewidth',S.mlw);  % Make our plot.
                    S.txt_noise(S.L_noise) = text(p(1),p(3)+S.rdim*0.075,['n',num2str(length(S.hpc_noise))],'Fontsize',12,...
                        'FontWeight','Bold');

                    % Update the number of the noise sources
                    currNumber = str2double(get(S.text_noise,'String'));
                    set(S.text_noise,'String',num2str(currNumber + 1));
                else
                    wd = warndlg('5 is the maximum number of noise sources!','Warning');
                    set(wd, 'WindowStyle', 'modal');
                    uiwait(wd); 
                end       
            else
                ed = errordlg('Noise sources must be on the left of the mic. array!','Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);  
            end                
        case S.pb_mic
            % Number of mics (zero only if nothing has been placed)
            S.L_mic  = length(S.hpc_mic);        
            if S.L_mic == 0
                if (p(3) + (S.nmic-1)*S.dmic/100) <= S.rdim
                    for k = 1:S.nmic
                        S.pc_mic(S.L_mic + k,:) = [p(1), p(3) + (k-1)*S.dmic/100];
                        S.hpc_mic(S.L_mic + k) = line(p(1),p(3) + (k-1)*S.dmic/100,...
                            'Color','b','Marker','o','Linewidth',S.mlw);  % Make our plot.
                    end
                    S.L_mic = k;
                    % Update to 1 the number of the mics
                    set(S.text_mic,'String',num2str(S.nmic));
                    % Disable mic button and editboxes
                    set(S.pb_mic,'Enable','off');
                    set(S.ed_rdim,'Enable','off');
                    set(S.ed_nmics,'Enable','off');
                    set(S.ed_dmics,'Enable','off');
                    set(S.pb_audio,'Enable','on');
                    set(S.pb_noise,'Enable','on');   
                    set(S.pb_DOA,'Enable','on');                
                else
                    wd = warndlg('The array exceeds room dimensions!','Warning');
                    set(wd, 'WindowStyle', 'modal');
                    uiwait(wd);
                end
            end
        otherwise
            wd = warndlg('Select one of the items first!','Warning');
            set(wd, 'WindowStyle', 'modal');
            uiwait(wd);
    end
    % ------------- CALLBACKS
    all_callbacks_fcn(S);
    

% -------------------- ADD COMPONENT BUTTONS -------------------------------------------------------
function [] = pb_call(varargin)
    % Callback for pb
    S = varargin{3};  % Get the structure.
    S.pushed_btn = varargin{1};
    % ------------- CALLBACKS
    all_callbacks_fcn(S);

% -------------------- CREATE RIRs BUTTONS--------------------------------------------------------------------
function [] = pb_create_RIRs(varargin)
    % Callback for pb create RIRs
    S = varargin{3};  % Get the structure.
    
    % Check whether all the parameters are correctly inserted
    if S.L_audio > 0 && S.L_mic > 0 && S.flag_rdim && S.flag_reverb && S.flag_lRIR
        xy_mic = zeros(S.L_mic,2);
        xy_audio = zeros(S.L_audio,2);
        

        for k = 1:S.nmic
            xy_mic (k,:) = [get(S.hpc_mic(k),'Xdata') get(S.hpc_mic(k),'Ydata')];
        end

        for k = 1:S.L_audio
            xy_audio (k,:) = [get(S.hpc_audio(k),'Xdata') get(S.hpc_audio(k),'Ydata')];
        end

        if S.L_noise > 0
            xy_noise = zeros(S.L_noise,2);
            for k = 1:S.L_noise
                xy_noise (k,:) = [get(S.hpc_noise(k),'Xdata') get(S.hpc_noise(k),'Ydata')];
            end
        else
            xy_noise = [];
        end

        create_rirs(xy_mic,xy_audio,xy_noise,S.rdim*[1 1],S.reverb,S.fs,S.lRIR);
        ed = msgbox('RIRs created and stored in Computed_RIRs.mat!');
        uiwait(ed);        
    else
        ed = errordlg({'Some parameters are missing! Please check that:',... 
            '1. At least 1 audio source has been included', ...
            '2. At least 1 microphone has been included', ...
            '3. Dimensions, T60 and Length RIR have been included', ...
            },'Error');
        set(ed, 'WindowStyle', 'modal');
        uiwait(ed);        
    end

    % ------------- CALLBACKS
    all_callbacks_fcn(S);

% -------------------- ADDCOMPONENTS EDITBOXES -----------------------------------------------------
function ed_kpfcn(varargin)
    % Callback for ed in the Add component panel
    S = varargin{3};  % Get the structure.
    calling_h = varargin{1}; % Get the handle of the calling object

    % Get the data within the editbox
    data = str2double(get(calling_h,'String'));
    
    
    % Handle the Number Editbox
    if isequal(calling_h,S.ed_nmics) 
        if (isnan(data) || (data > 5) || (data < 1))
            ed = errordlg('Please provide an integer NUMBER between 1 and 5!','Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
            % Reset the string to zero
            set(S.ed_nmics,'String','')
            S.flag_nmic = false;
        else
            S.flag_nmic = true;
            S.nmic = data;
        end
    end
    % Handle the Distance Editbox    
    if isequal(calling_h,S.ed_dmics) 
        if (isnan(data) || (data > 100) || (data < 1))
            ed = errordlg('Please provide an integer NUMBER between 1 and 100!','Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
            % Reset the string to zero
            set(S.ed_dmics,'String','')
            S.flag_dmic = false;
        else
            S.flag_dmic = true;
            S.dmic = data;
        end
    end 
    
    % Return the mic flag (if 1 the array can be placed)
    if S.flag_nmic && S.flag_dmic
        set(S.pb_mic,'Enable','On')
    end
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);

% -------------------- PARAMETERS EDITBOXES -----------------------------------------------------
function ed_par_kpfcn(varargin)
    % Callback for ed in the Parameters panel
    S = varargin{3};  % Get the structure.
    calling_h = varargin{1}; % Get the handle of the calling object

    % Get the data within the editbox
    data = str2double(get(calling_h,'String'));
    
    % Handle the Room dimension Editbox
    if isequal(calling_h,S.ed_rdim) 
        if (isnan(data) || (data > 10) || (data < 5))
            ed = errordlg('Please provide an integer NUMBER between 5 and 10!','Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
            % Reset the string to zero
            set(S.ed_nmics,'String','')
            S.flag_rdim = false;
        else
            S.flag_rdim = true;
            S.rdim = data;
            set(S.ax,'Xlim',[0 data]);
            set(S.ax,'Ylim',[0 data]);
        end
    end
    % Handle the Reverb Editbox    
    if isequal(calling_h,S.ed_reverb) 
        if (isnan(data) || (data > 3) || (data < 0))
            ed = errordlg('Please provide a real NUMBER between 0 and 3!','Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
            % Reset the string to zero
            set(S.ed_reverb,'String','')
            S.flag_reverb = false;
        else
            S.flag_reverb = true;
            S.reverb = data;
        end
    end 
    
    % Handle the lRIR
    if isequal(calling_h,S.ed_lRIR) 
        if (isnan(data) || (data > S.fs*5) || (data < S.fs*0.2))
            ed = errordlg(['Please provide a real NUMBER between ',num2str(S.fs*0.2),...
                ' (0.2*fs) and ',num2str(S.fs*5),' (5*fs)!'],'Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
            % Reset the string to zero
            set(S.ed_lRIR,'String','')
            S.flag_lRIR = false;
        else
            S.flag_lRIR = true;
            S.lRIR = data;
        end
    end     
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);    

% -------------------- DRAW DOA BUTTON --------------------------------------------------------------------
function [] = pb_draw_DOA(varargin)
    % Callback for pb create RIRs
    S = varargin{3};  % Get the structure.
    
    % Check if DOA_est exists
    if ~(exist('DOA_est.mat', 'file') == 2)
        ed = errordlg('File DOA_est.mat not found in the working directory!','Error');
        set(ed, 'WindowStyle', 'modal');
        uiwait(ed);
        
    else
        load 'DOA_est';
        
        % Read the estimated DOAs
        S.DOAs = DOA_est;
        % Get the length
        lDOAs_est = length(S.DOAs);

        if lDOAs_est == S.L_audio

            % Get the central y-coordinate of the mic array
            y_mic_avg = 0;
            for l = 1:length(S.hpc_mic)
                y_mic_avg = y_mic_avg + get(S.hpc_mic(l),'Ydata');
            end
            y_mic_avg = y_mic_avg/length(S.hpc_mic);
            x_mic_avg = get(S.hpc_mic(1),'Xdata');    

            for k = 1:S.L_audio
                % Get the real DOA for the current audio
                x_audio = get(S.hpc_audio(k),'Xdata');
                y_audio = get(S.hpc_audio(k),'Ydata');
                S.DOA_true(k) = atan2d((-(x_audio-x_mic_avg)),(y_audio-y_mic_avg));

                x_vector = 0:0.1:x_mic_avg;

                hold on;
                if S.DOAs(k) == 0
                    S.hDOAs_est(k) = line([x_mic_avg x_mic_avg],[y_mic_avg S.rdim],...
                        'Color','k','Linestyle','--','Linewidth',2);
                elseif S.DOAs(k) == 180
                    S.hDOAs_est(k) = line([x_mic_avg x_mic_avg],[y_mic_avg -S.rdim],...
                        'Color','k','Linestyle','--','Linewidth',2);
                else
                    y_vector_est = sin((S.DOAs(k)+90)/180*pi)/cos((S.DOAs(k)+90)/180*pi)*(x_vector-x_mic_avg)...
                               + y_mic_avg;
                    y_vector_est(end) = y_mic_avg;
                    S.hDOAs_est(k) = plot(x_vector,y_vector_est,'--k','Linewidth',2);
                end
                
                y_vector_true = sin((S.DOA_true(k)+90)/180*pi)/cos((S.DOA_true(k)+90)/180*pi)*(x_vector-x_mic_avg)...
                           + y_mic_avg;       
                y_vector_true(end) = y_mic_avg;   
                S.hDOAs_true(k) = plot(x_vector,y_vector_true,'r','Linewidth',1.5);
                
%                 % Calculate the errors
% %                 [minerr,S.ind_minerr]=min(abs(S.DOAs(k) - S.DOA_true));
% %                 S.DOA_error(k) = S.DOAs(k) - S.DOA_true(ind_minerr);
%                 S.DOA_error(k) = S.DOAs(k) - S.DOA_true(k);
%                 tmpstr{k} = ['a',num2str(k),': ',num2str(S.DOA_error(k))];
            end
            
            % Calculate the errors (each error is found as the minimum distance between each one of
            % the estimated DOAs and the vector of real DOAs; the element of the real DOAs vector
            % selected at each iteration is then removed so that the next error will be calculated
            % on a reduced real DOAs vector)
            [minerr,ind_minerr]=min(abs(S.DOAs(1) - S.DOA_true));
            S.DOA_error(1) = S.DOAs(1) - S.DOA_true(ind_minerr);
            DOAs_reduced = S.DOA_true(setxor(1:length(S.DOA_true),ind_minerr));
            tmpstr{1} = ['a',num2str(1),': ',num2str(S.DOA_error(1))];
            
            for k = 2:S.L_audio
                [minerr,ind_minerr]=min(abs(S.DOAs(k) - DOAs_reduced));
                S.DOA_error(k) = S.DOAs(k) - DOAs_reduced(ind_minerr);
                DOAs_reduced = DOAs_reduced(setxor(1:length(DOAs_reduced),ind_minerr));
                tmpstr{k} = ['a',num2str(k),': ',num2str(S.DOA_error(k))];
            end


            % Enable the reset DOAs button
            set(S.pb_reset_DOA,'Enable','on');
            % Disable the draw DOAs button (otherwise one could draw the DOAs on top of each other)
            set(S.pb_DOA,'Enable','off');
            % Update the string and make the list of Error DOAs visible
            set(S.ls_error_DOAs,'String',tmpstr);      
        else
            ed = errordlg({'The number of estimated DOAs you provided';'does not match the number of audio sources!'},'Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
        end
    end
    % ------------- CALLBACKS
    all_callbacks_fcn(S);
    

% -------------------- DELETE SINGLE COMPONENT BUTTON ----------------------------------------------
function [] = pb_del_single_cmp(varargin)
    % Callback for pb delete single component
    S = varargin{3};  % Get the structure.
    calling_h = varargin{1}; % Get the handle of the calling object

    % Handle is delete audio
    if isequal(calling_h,S.pb_audio_rm) 
        if S.L_audio > 0
            delete(S.hpc_audio(S.L_audio));
            delete(S.txt_audio(S.L_audio));
            S.pc_audio(S.L_audio,:) = [];            
            S.hpc_audio(S.L_audio) = [];          
            S.txt_audio(S.L_audio) = [];
            S.L_audio = S.L_audio - 1;
            set(S.text_audio,'String',num2str(S.L_audio));
        end
    end
    
    % Handle is delete audio
    if isequal(calling_h,S.pb_noise_rm) 
        if S.L_noise > 0
            delete(S.hpc_noise(S.L_noise));
            delete(S.txt_noise(S.L_noise));
            S.pc_noise(S.L_noise,:) = [];            
            S.hpc_noise(S.L_noise) = [];          
            S.txt_noise(S.L_noise) = [];
            S.L_noise = S.L_noise - 1;
            set(S.text_noise,'String',num2str(S.L_noise));
        end
    end
    
    % Handle is delete mic
    if isequal(calling_h,S.pb_mic_rm) 
        if S.L_mic > 0
            if (S.L_audio == 0) && (S.L_noise == 0)
                delete(S.hpc_mic(1:S.L_mic));
                S.pc_mic(1:S.L_mic,:) = [];          
                S.hpc_mic(1:S.L_mic) = [];                
                S.L_mic = 0;
                set(S.text_mic,'String',num2str(S.L_mic));
                set(S.pb_mic,'Enable','on');
                set(S.pb_audio,'Enable','off');
                set(S.pb_noise,'Enable','off');   
            else
                ed = errordlg({'You can remove the mic. array ONLY if no'...
                    ;'other component has been placed'},'Error');
                set(ed, 'WindowStyle', 'modal');
                uiwait(ed);
            end
        end
    end
    
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);       
    
    
% -------------------- RESET COMPONENTS BUTTON --------------------------------------------------------------------
function [] = pb_reset_cmp(varargin)
    % Callback for pb reset components
    S = varargin{3};  % Get the structure.
    
    % Reset the DOAS (if any)
    pb_reset_DOAs([],[],S);
    
    % Delete all audio sources
    if S.L_audio > 0
        delete(S.hpc_audio);
        delete(S.txt_audio);
        S.pc_audio = [];
        S.hpc_audio = [];          
        S.L_audio = 0;
        S.txt_audio = [];
    end
    
    % Delete all noises
    if S.L_noise > 0
        delete(S.hpc_noise);
        delete(S.txt_noise);
        S.pc_noise = [];        
        S.hpc_noise = [];          
        S.L_noise = 0;
        S.txt_noise = [];
    end
    
    % Delete all mics
    if S.L_mic > 0
        delete(S.hpc_mic);
        S.pc_mic = [];
        S.hpc_mic = [];          
        S.L_mic = 0;
        % Restore default nmic and dmic and their flags
        S.nmic = 0;
        S.dmic = 0;
        S.flag_nmic = false;
        S.flag_dmic = false;
    end
    
    
    % Disable audio and noise buttons
    set(S.pb_audio,'Enable','off');
    set(S.pb_noise,'Enable','off');

    % Set numbers of each component to zero
    set(S.text_audio,'String','0');
    set(S.text_noise,'String','0');
    set(S.text_mic,'String','0');
    % Enable nmics and dmics editboxes
    set(S.ed_nmics,'Enable','on','String','');
    set(S.ed_dmics,'Enable','on','String','');
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);    

% -------------------- RESET DOAs BUTTON --------------------------------------------------------------------
function [] = pb_reset_DOAs(varargin)
    % Callback for pb create RIRs
    S = varargin{3};  % Get the structure.
    
    % Delete DOAs
    for k = 1:length(S.hDOAs_est)
        delete(S.hDOAs_est);
        delete(S.hDOAs_true);
        S.hDOAs_est = [];
        S.hDOAs_true = [];
    end
    
    % Disable reset button
    set(S.pb_reset_DOA,'Enable','off');
    % Enable the draw DOAs button
    set(S.pb_DOA,'Enable','on');
    % Update the string and make the list of Error DOAs invisible
    set(S.ls_error_DOAs,'String','');      
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);
    
    
% -------------------- GET FS --------------------------------------------------------------------
function [] = pp_get_fs(varargin)
    % Callback for the pop up menu with the sampling frequencies
    S = varargin{3};  % Get the structure.
    
    % Get the chosen fs
    ind = get(S.pp_fs,'val');
    fss = get(S.pp_fs,'string');
    fs = 1e3*str2double(fss(ind));
    
    % Save it on the global variable
    S.fs = fs;
    
    % Reset the length of the RIR
    % Get the data within the editbox
    data = str2double(get(S.ed_lRIR,'String'));
    
    % Reminder to change lRIR
    if ~isnan(data) && (S.lRIR ~= 0.5*S.fs)
        wd = warndlg({'The sampling frequency has been changed.';...
            'You must re-enter the length of the RIR'},'Warning');
        set(wd, 'WindowStyle', 'modal');
        uiwait(wd);
        set(S.ed_lRIR,'String','');
    end

    % ------------- CALLBACKS
    all_callbacks_fcn(S);    

% -------------------- SAVE SESSION --------------------------------------------------------------------
function [] = mh_save_session(varargin)
    % Callback for the menu to save the session
    S = varargin{3};  % Get the structure.
    
    % Open dialog box and save
    [filename,pathname] = uiputfile('*.mat','Save session as');
    if ischar(filename) && ischar(pathname)
        save(fullfile(pathname,filename),'S');
    end
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);        

% -------------------- SAVE SESSION --------------------------------------------------------------------
function [] = mh_load_session(varargin)
    % Callback for the menu to load the session
    S = varargin{3};  % Get the structure.        

    % Open dialog box and load file
    [filename,pathname] = uigetfile('*.mat','Select the session file');
    if ischar(filename) && ischar(pathname)
        if verLessThan('matlab','8.4')
            saved_S = load(fullfile(pathname,filename));
        else
    %         set(S.fh, 'DefaultFigureRenderer', 'zbuffer');
            saved_S = load(fullfile(pathname,filename),'-mat');
            figure(S.fh); %close(saved_S.fh);
        end
        figure(S.fh); %close(saved_S.fh);
        if isfield(saved_S,'S')
            saved_S = saved_S.S;

            % Assign saved values
            S.rdim = saved_S.rdim;
            set(S.ed_rdim,'String',num2str(S.rdim));
            axis([0 S.rdim 0 S.rdim]);

            S.fs = saved_S.fs;
            switch S.fs 
                case 8000
                    set(S.pp_fs,'Val',3);
                case 16000
                    set(S.pp_fs,'Val',2);
                case 44100
                    set(S.pp_fs,'Val',1);   
            end
            S.reverb = saved_S.reverb;
            set(S.ed_reverb,'String',num2str(S.reverb));
            S.lRIR = saved_S.lRIR;
            set(S.ed_lRIR,'String',num2str(S.lRIR));  

            S.nmic = saved_S.nmic;
            S.dmic = saved_S.dmic;

            S.flag_nmic = saved_S.flag_nmic;
            S.flag_dmic = saved_S.flag_dmic;
            S.flag_rdim = saved_S.flag_rdim;
            S.flag_reverb = saved_S.flag_reverb;
            S.flag_lRIR = saved_S.flag_lRIR;      

            %------ Redraw components
            cla;
            S.hpc_audio = [];  
            S.hpc_noise = [];  
            S.hpc_mic = [];  
            S.txt_audio = [];  
            S.txt_noise = [];  
            S.txt_mic = [];  

            S.L_audio = saved_S.L_audio;
            S.L_noise = saved_S.L_noise;  
            S.L_mic = saved_S.L_mic;

            if S.L_mic == 0
                set(S.ed_nmics,'String','0','Enable','on');  
                set(S.ed_dmics,'String','0','Enable','on'); 
                set(S.pb_DOA,'Enable','off');
            else
                set(S.ed_nmics,'String',num2str(S.nmic),'Enable','off');  
                set(S.ed_dmics,'String',num2str(S.dmic),'Enable','off');  
                set(S.pb_audio,'Enable','on');
                set(S.pb_noise,'Enable','on');
                set(S.pb_mic,'Enable','off');
                set(S.pb_DOA,'Enable','on');
            end

            S.pc_audio = saved_S.pc_audio;  
            S.pc_noise = saved_S.pc_noise;  
            S.pc_mic = saved_S.pc_mic;  

            % Redraw components
            for k = 1:S.L_audio
                S.hpc_audio(k) = line(S.pc_audio(k,1),S.pc_audio(k,2),...
                    'Color','r','Marker','x','Linewidth',S.mlw);  % Make our plot.
                S.txt_audio(k) = text(S.pc_audio(k,1),S.pc_audio(k,2)...
                    +S.rdim*0.075,['a',num2str(length(S.hpc_audio))],'Fontsize',12,...
                    'FontWeight','Bold');
            end
            set(S.text_audio,'String',num2str(S.L_audio));

            for k = 1:S.L_noise
                S.hpc_noise(k) = line(S.pc_noise(k,1),S.pc_noise(k,2),...
                    'Color','k','Marker','s','Linewidth',S.mlw);  % Make our plot.
                S.txt_noise(k) = text(S.pc_noise(k,1),S.pc_noise(k,2)...
                    +S.rdim*0.075,['n',num2str(length(S.hpc_noise))],'Fontsize',12,...
                    'FontWeight','Bold');
            end
            set(S.text_noise,'String',num2str(S.L_noise));

            for k = 1:S.L_mic
                S.hpc_mic(k) = line(S.pc_mic(k,1),S.pc_mic(k,2),...
                    'Color','b','Marker','o','Linewidth',S.mlw);  % Make our plot.
            end
            set(S.text_mic,'String',num2str(S.L_mic));

            set(S.pb_reset_DOA,'Enable','off');
            set(S.ls_error_DOAs,'String','');
        else
             ed = errordlg('You did not provide a proper session file!','Error');
            set(ed, 'WindowStyle', 'modal');
            uiwait(ed);
        end
        if ~verLessThan('matlab','8.4')
            close(saved_S.fh)
        end
    end
    
    % ------------- CALLBACKS
    all_callbacks_fcn(S);    
    

% -------------------- HELP and ABOUT --------------------------------------------------------------
function [] = mh_help_about(varargin)
    % Callback for the menu help and about
    S = varargin{3};  % Get the structure.
    calling_h = varargin{1}; % Get the handle of the calling object

    % Handle is delete audio
    if isequal(calling_h,S.eh_help) 
        mb = msgbox('Please refer to the session1.pdf file provided in the first lab',...
            'Help','help');
        uiwait(mb);      
    else
        mb = msgbox({['Speech and Audio GUI v. ',S.myVer];...
            'Authors: Randall Ali, Giuliano Bernardi, Alexander Bertrand';...
            'November 10, 2016'},'About S&A GUI','help');
        uiwait(mb);      
    end
    
    
% -------------------- RESET ALL ------------------------------------------------------------------
function [] = pb_reset(varargin)
    mySA_GUI;    
    
% -------------------- ALL CALLBACKS --------------------------------------------------------------
function [] = all_callbacks_fcn(varargin)   
% Serves as the buttondownfcn for the axes.
S = varargin{1};  % Get the structure.
    
set(S.ax,'ButtonDownFcn',{@ax_bdfcn,S});
set(S.pb_audio,'callback',{@pb_call,S});  
set(S.pb_audio_rm,'callback',{@pb_del_single_cmp,S});  
set(S.pb_noise,'callback',{@pb_call,S});
set(S.pb_noise_rm,'callback',{@pb_del_single_cmp,S});  
set(S.pb_mic,'callback',{@pb_call,S});
set(S.pb_mic_rm,'callback',{@pb_del_single_cmp,S});  
set(S.pb_reset,'callback',{@pb_reset,S});
set(S.pb_create_RIRs,'callback',{@pb_create_RIRs,S});
set(S.ed_nmics,'callback',{@ed_kpfcn,S});
set(S.ed_dmics,'callback',{@ed_kpfcn,S});
set(S.ed_rdim,'callback',{@ed_par_kpfcn,S});
set(S.ed_reverb,'callback',{@ed_par_kpfcn,S});
set(S.ed_lRIR,'callback',{@ed_par_kpfcn,S});
set(S.pb_DOA,'callback',{@pb_draw_DOA,S});
set(S.pb_reset_DOA,'callback',{@pb_reset_DOAs,S});
set(S.pb_reset_cmp,'callback',{@pb_reset_cmp,S});
set(S.pp_fs,'callback',{@pp_get_fs,S});
set(S.eh_save,'callback',{@mh_save_session,S});
set(S.eh_load,'callback',{@mh_load_session,S});
set(S.eh_help,'callback',{@mh_help_about,S});
set(S.eh_about,'callback',{@mh_help_about,S});


%------------- END CODE --------------    