-- ui_win.e

include window.ew
include wee.exw



-- MenuItem constants
constant 
    File_New = 101,
    File_Open = 102,
    File_Save = 103,
    File_SaveAs = 104,
    File_Close = 105,
    File_PageSetup = 106,
    File_Print = 107,
    File_Exit = 108,
    File_Recent = 110,
    Edit_Undo = 201,
    Edit_Cut = 202,
    Edit_Copy = 203,
    Edit_Paste = 204,
    Edit_Clear = 205,
    Edit_SelectAll = 206,
    Edit_Wordwrap = 207,
    Search_Find = 301,
    Search_Replace = 302,
    View_Subs = 401,
    View_Error = 402,
    View_Font = 403,
    View_Completions = 404,
    View_Declaration = 405,
    View_GoBack = 406,
    View_SubArgs = 407,
    View_LineNumbers = 408,
    Run_Start = 501,
    Run_Intepreter = 502,
    Run_Intepreter_Default = 511,
    Run_Intepreter_EUIW = 512,
    Run_Intepreter_EUI = 513,
    Run_Intepreter_EXW = 514,
    Run_Intepreter_EX = 515,
    Options_Font = 601,
    Help_About = 701,
    Select_Tab = 801

constant file_filters = allocate_string(
	"Euphoria files (*.ex,*.exw,*.e,*.ew)"&0&"*.EX;*.EXW;*.E;*.EW;ex.err"&0&
	"Text or Document files (*.txt,*.doc)"&0&"*.TXT;*.DOC"&0&
	"All files (*.*)"&0&"*.*"&0&0)
    

atom hMainWnd, hFindDlg, class,
    hmenu, hfilemenu, heditmenu, hsearchmenu, hviewmenu, 
    hrunmenu, hoptionsmenu, hhelpmenu,
    hstatus, htabs, hcode, hedit,
    WM_FIND

sequence ui_hedits
ui_hedits = {}

class = 0
WM_FIND = 0
hMainWnd = 0  -- the main window
hFindDlg = 0
hedit = 0     -- the richedit control
hstatus = 0   -- the static control showing cursor position
htabs = 0     -- the tab control
hcode = 0     -- the listbox control for code completions
hedit = 0

constant tab_h = 24


x_pos = CW_USEDEFAULT
y_pos = CW_USEDEFAULT
x_size = CW_USEDEFAULT
y_size = CW_USEDEFAULT

constant 
    ansi_var_font = c_func(GetStockObject, {ANSI_VAR_FONT}),
    ansi_fixed_font = c_func(GetStockObject, {ANSI_FIXED_FONT})

atom captionFont, smCaptionFont, menuFont, statusFont, messageFont




global procedure ui_update_window_title(sequence file_name)
    atom result
    result = c_func(SendMessage, {hMainWnd, WM_SETTEXT, 0, 
        alloc_string(window_title&" [" & file_name & "]")})
    free_strings()
end procedure

global procedure ui_update_status(sequence status)
    atom txt, junk
    txt = allocate_string(status)
    junk = c_func(SendMessage, {hstatus, WM_SETTEXT, 0, txt})
    free(txt)
end procedure

global procedure ui_refresh_file_menu(sequence recent_files)
    atom junk, count
    count = c_func(GetMenuItemCount, {hfilemenu}) - 7
    if count = 0 and length(recent_files) > 0 then
      junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
    end if
    for i = 1 to length(recent_files) do
      if i >= count then
        junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED,
            File_Recent+i, alloc_string(recent_files[i])})
      else
        junk = c_func(ModifyMenu, {hfilemenu, i+7, MF_BYPOSITION + MF_STRING + MF_ENABLED,
            File_Recent+i, alloc_string(recent_files[i])})
      end if
    end for
    free_strings()
end procedure

global procedure ui_update_tab_name(integer tab, sequence name)
    atom junk, tcitem
    tcitem = allocate(4+4+4+4+4+4+4)
    poke4(tcitem, {TCIF_TEXT, 0, 0, alloc_string(name), 0, 0, 0})
    --tab = c_func(SendMessage, {htabs, TCM_GETCURSEL, 0, 0})
    junk = c_func(SendMessage, {htabs, TCM_SETITEMA, tab-1, tcitem})
    --junk = c_func(SendMessage, {htabs, TCM_HIGHLIGHTITEM, tab, modified})
    free(tcitem)
    free_strings()
end procedure


-- select the tab and show the hedit
global procedure ui_select_tab(integer tab)
    atom junk, rect
    integer w, h

    junk = c_func(SendMessage, {htabs, TCM_SETCURSEL, tab-1, 0})

    if hedit then
        -- hide the previous hedit
        c_proc(ShowWindow, {hedit, SW_HIDE})
    end if
  
    hedit = ui_hedits[tab]

    -- update the richedit control to the window size
    rect = allocate(16)
    c_proc(GetClientRect, {hMainWnd, rect})
    c_proc(MoveWindow, {hedit, 0, tab_h, peek4u(rect+8), peek4u(rect+12)-tab_h, 1})
    free(rect)
    c_proc(ShowWindow, {hedit, SW_SHOW})
    junk = c_func(SetFocus, {hedit})
end procedure

global function ui_new_tab(sequence name)
    atom junk, tcitem, tab, hedit
    tab = c_func(SendMessage, {htabs, TCM_GETITEMCOUNT, 0, 0})

    tcitem = allocate(4+4+4+4+4+4+4)
    poke4(tcitem, {TCIF_TEXT, 0, 0, alloc_string(name), 0, 0, 0})
    junk = c_func(SendMessage, {htabs, TCM_INSERTITEMA, tab+(tab!=0), tcitem})
    free(tcitem)
    free_strings()

    hedit = CreateWindow({
    	      0,
            "Scintilla",
            "",
            {WS_CHILD, WS_VISIBLE, WS_TABSTOP, WS_CLIPCHILDREN},
            0,0,0,0,  -- position and size set later by hMainWnd
            hMainWnd, NULL, 0, NULL})

    -- save the window handle
    ui_hedits = append(ui_hedits, hedit)
    return c_func(SendMessage, {hedit, SCI_GETDIRECTPOINTER, 0, 0})
end function

global procedure ui_close_tab(integer tab)
    atom junk
    
    --tab = c_func(SendMessage, {htabs, TCM_GETCURSEL, 0, 0})

    -- get the edit window handle and destroy it
    junk = c_func(DestroyWindow, {hedit})
    hedit = 0
    -- delete the tab
    junk = c_func(SendMessage, {htabs, TCM_DELETEITEM, tab-1, 0})
    -- remove the window handle
    ui_hedits = ui_hedits[1..tab-1] & ui_hedits[tab+1..$]
end procedure


integer current_filter
current_filter = 1

global function ui_get_open_file_name()
    sequence temp
    temp = GetOpenFileName({hMainWnd, 0, file_filters, current_filter, 
	    "", 0, 0, OFN_EXPLORER + OFN_PATHMUSTEXIST + OFN_FILEMUSTEXIST + OFN_HIDEREADONLY, 0})
    if length(temp) < 2 then return "" end if
    current_filter = temp[1]
    return temp[2]
end function

global function ui_get_save_file_name(sequence file_name)
    sequence temp
    temp = GetSaveFileName({hMainWnd, 0, file_filters, current_filter, 
	file_name, 0, 0, OFN_EXPLORER + OFN_PATHMUSTEXIST + OFN_HIDEREADONLY, 0})
    if length(temp) < 2 then return "" end if
	current_filter = temp[1]
    return temp[2]
end function


-- returns yes=1 no=0
global function ui_message_box_yes_no(sequence title, sequence message)
    atom result
    result = c_func(MessageBox, {hMainWnd, 
	  alloc_string(message),
	  alloc_string(title),
	  or_all({MB_APPLMODAL, MB_ICONINFORMATION, MB_YESNO})})
    free_strings()
    return result = IDYES
end function

-- returns yes=1 no=0 cancel=-1
global function ui_message_box_yes_no_cancel(sequence title, sequence message)
    atom result
    result = c_func(MessageBox, {hMainWnd, 
	  alloc_string(message),
	  alloc_string(title),
	  or_all({MB_APPLMODAL, MB_ICONINFORMATION, MB_YESNOCANCEL})})
    free_strings()
    return (result = IDYES) - (result = IDCANCEL)
end function

global function ui_message_box_error(sequence title, sequence message)
    atom result
    result = c_func(MessageBox, {hMainWnd, 
	  alloc_string(message),
	  alloc_string(title),
	  or_all({MB_APPLMODAL, MB_ICONSTOP, MB_OK})})
    free_strings()
    return result
end function



procedure about_box()
    atom result
    result = c_func(MessageBox, {hMainWnd, 
	alloc_string(window_title&"\n\nVersion "&version&"\n\nBy "&author),
	alloc_string("About "&window_title), 
	or_all({MB_APPLMODAL, MB_ICONINFORMATION, MB_OK})})
    free_strings()
end procedure

constant DialogListID = 1000
sequence subs

function SubsDialogProc(atom hdlg, atom iMsg, atom wParam, atom lParam)
    atom junk, hList, pos
    sequence text, word

    --? {hdlg, iMsg, wParam, HIWORD(lParam), LOWORD(lParam)}

    if iMsg = WM_INITDIALOG then
        junk = c_func(SendMessage, {c_func(GetDlgItem, {hdlg, IDOK}), 
                      WM_SETFONT, captionFont, 0})
        junk = c_func(SendMessage, {c_func(GetDlgItem, {hdlg, IDCANCEL}), 
                      WM_SETFONT, captionFont, 0})
        hList = c_func(GetDlgItem, {hdlg, DialogListID})
        junk = c_func(SendMessage, {hList, WM_SETFONT, messageFont, 0})
        text = get_edit_text()
        pos = get_pos()
        word = word_pos(text, pos)
        subs = get_subroutines(parse(text, file_name))
        
        for i = 1 to length(subs) by 2 do
            junk = c_func(SendMessage, {hList, LB_ADDSTRING, 0, alloc_string(subs[i])})
            if equal(word[1], subs[i]) then
                junk = c_func(SendMessage, {hList, LB_SETCURSEL, floor((i-1)/2), 0})
            end if
        end for
        free_strings()

    elsif iMsg = WM_COMMAND then
        if LOWORD(wParam) = IDOK then
            hList = c_func(GetDlgItem, {hdlg, DialogListID})
            pos = c_func(SendMessage, {hList, LB_GETCURSEL, 0, 0})*2+1
            if pos >= 1 and pos <= length(subs) then
              word = subs[pos]
              pos = subs[pos+1]-1
              --printf(1, "%s: pos=%d line=%d\n", {word, pos, 
              --    c_func(SendMessage, {hedit, SCI_LINEFROMPOSITION, pos, 0})})
              junk = c_func(SendMessage, {hedit, SCI_SETSEL, pos, pos+length(word)})
              set_top_line(-1) -- set the top visible line to the current line
            end if
            junk = c_func(EndDialog, {hdlg, 1})
            return 1
        elsif LOWORD(wParam) = IDCANCEL then
            junk = c_func(EndDialog, {hdlg, 0})
            return 1
        end if

    elsif iMsg = WM_CLOSE then --closing dialog
        junk = c_func(EndDialog, {hdlg, 0})
    end if

    return 0
end function

constant SubsDialogCallback = call_back(routine_id("SubsDialogProc"))

-- used for struct DLGITEMTEMPLATE
constant
    DIALOG_CLASS_BUTTON = #0080,
    DIALOG_CLASS_EDIT = #0081,
    DIALOG_CLASS_STATIC = #0082,
    DIALOG_CLASS_LIST = #0083,
    DIALOG_CLASS_SCROLLBAR = #0084,
    DIALOG_CLASS_COMBOBOX = #0085
         
procedure view_subroutines()
    atom junk
    junk = DialogBoxIndirectParam(c_func(GetModuleHandle, {NULL}), {
        --DLGTEMPLATE{style, exstyle, x, y, cx, cy, menu, wndclass, text}
	  {{WS_POPUP, WS_BORDER, WS_SYSMENU, DS_MODALFRAME, WS_CAPTION}, 0,
         10,10, 100,124, 0, 0, "Subroutines"},
        --DLGITEMTEMPLATE{style, exstyle, x, y, cx, cy, id, dlgclass, text}
        {{WS_CHILD, WS_VISIBLE, WS_VSCROLL}, WS_EX_CLIENTEDGE,
         4,4, 92,110, DialogListID, DIALOG_CLASS_LIST, "ListBox"},
        {{WS_CHILD, WS_VISIBLE, BS_PUSHBUTTON}, 0,
         4,108, 44,12, IDCANCEL, DIALOG_CLASS_BUTTON, "Cancel"},
        {{WS_CHILD, WS_VISIBLE, BS_DEFPUSHBUTTON}, 0,
         52,108, 44,12, IDOK, DIALOG_CLASS_BUTTON, "OK"}
        },
        hMainWnd, 
        SubsDialogCallback,
        0)
    subs = {}
end procedure


function CodeDialogProc(atom hdlg, atom iMsg, atom wParam, atom lParam)
    atom junk, hList, pos, len, item
    sequence word, text, decls, namespace

    --? {hdlg, iMsg, wParam, HIWORD(lParam), LOWORD(lParam)}

    if iMsg = WM_INITDIALOG then
        junk = c_func(SendMessage, {c_func(GetDlgItem, {hdlg, IDOK}), 
                      WM_SETFONT, captionFont, 0})
        junk = c_func(SendMessage, {c_func(GetDlgItem, {hdlg, IDCANCEL}), 
                      WM_SETFONT, captionFont, 0})
        hList = c_func(GetDlgItem, {hdlg, DialogListID})
        junk = c_func(SendMessage, {hList, WM_SETFONT, messageFont, 0})

        text = get_edit_text()
        pos = get_pos()
        word = word_pos(text, pos)
        if length(word) < 4 then 
            junk = c_func(EndDialog, {hdlg, 0})
            return 1
        end if
        junk = c_func(SendMessage, {hedit, SCI_SETSEL, word[3]-1, word[4]})
        namespace = word[2]
        word = word[1]

        decls = get_declarations(parse(text, file_name), pos, namespace)
        --if length(decls) = 0 then
            --puts(1, "no decls found for "&word&", suggesting includes...\n")
            decls &= suggest_includes(word, namespace)
        --end if

        if length(decls) = 0 then
            junk = c_func(EndDialog, {hdlg, 0})
            return 1
        end if

        for i = 1 to length(decls) by 2 do
            if length(decls[i]) >= length(word) and equal(decls[i][1..length(word)], word) then
              junk = c_func(SendMessage, {hList, LB_ADDSTRING, 0, alloc_string(decls[i])})
            end if
        end for
        junk = c_func(SendMessage, {hList, LB_SETCURSEL, 0, 0})

    elsif iMsg = WM_COMMAND then
        if LOWORD(wParam) = IDOK then
            hList = c_func(GetDlgItem, {hdlg, DialogListID})
            pos = c_func(SendMessage, {hList, LB_GETCURSEL, 0, 0})
            len = c_func(SendMessage, {hList, LB_GETTEXTLEN, pos, 0})
            if pos != -1 and len > 0 then
              item = allocate(len+1)
              junk = c_func(SendMessage, {hList, LB_GETTEXT, pos, item})
              junk = c_func(SendMessage, {hedit, SCI_REPLACESEL, 1, item})
              free(item)
            end if
            junk = c_func(EndDialog, {hdlg, 1})
            return 1
        elsif LOWORD(wParam) = IDCANCEL then
            junk = c_func(EndDialog, {hdlg, 0})
            return 1
        end if

    elsif iMsg = WM_CLOSE then --closing dialog
        junk = c_func(EndDialog, {hdlg, 0})
    end if

    return 0
end function

constant CodeDialogCallback = call_back(routine_id("CodeDialogProc"))

procedure ui_view_completions()
    atom junk
    sequence text, word, decls, namespace
    integer pos
if 0 then
    junk = DialogBoxIndirectParam(c_func(GetModuleHandle, {NULL}), {
--    hcode = CreateDialogIndirectParam(c_func(GetModuleHandle, {NULL}), {
        --DLGTEMPLATE{style, exstyle, x, y, cx, cy, menu, wndclass, text}
	  {{WS_POPUP, WS_BORDER, WS_SYSMENU, DS_MODALFRAME, WS_CAPTION}, 0,
         10,10, 100,124, 0, 0, "Completions"},
--	  {{WS_POPUP, WS_BORDER}, 0,
--         10,10, 100,124, 0, 0, "Completions"},
        --DLGITEMTEMPLATE{style, exstyle, x, y, cx, cy, id, dlgclass, text}
        {{WS_CHILD, WS_VISIBLE, WS_VSCROLL}, WS_EX_CLIENTEDGE,
         0,0, 100,108, DialogListID, DIALOG_CLASS_LIST, "ListBox"},
        {{WS_CHILD, WS_VISIBLE, BS_PUSHBUTTON}, 0,
         4,108, 44,12, IDCANCEL, DIALOG_CLASS_BUTTON, "Cancel"},
        {{WS_CHILD, WS_VISIBLE, BS_DEFPUSHBUTTON}, 0,
         52,108, 44,12, IDOK, DIALOG_CLASS_BUTTON, "OK"}
        },
        hMainWnd, 
        CodeDialogCallback,
        0)
    --c_proc(ShowWindow, {hcode, SW_SHOWNORMAL})
elsif 0 then
    -- use an overlapped window listbox
    hcode = CreateWindow({WS_EX_CLIENTEDGE,"LISTBOX", "code",
		    {WS_BORDER,WS_CHILD,WS_CLIPSIBLINGS,WS_OVERLAPPED,
                 WS_POPUP,WS_POPUPWINDOW,WS_SYSMENU,WS_VISIBLE,
                 WS_VSCROLL,LBS_NOTIFY},
		    100,100,200,200, -- set by resize
                hMainWnd,
                NULL,
                0,
                NULL})
    junk = c_func(SendMessage, {hcode, WM_SETFONT, messageFont, 0})

    text = get_edit_text()
    pos = get_pos()
    word = word_pos(text, pos)
    if length(word) = 0 then 
        return
    end if
    junk = c_func(SendMessage, {hedit, EM_SETSEL, word[3]-1, word[4]})
    namespace = word[2]
    word = word[1]

    decls = get_declarations(parse(text, file_name), pos, namespace)
    if length(decls) = 0 then
        return
    end if

    for i = 1 to length(decls) by 2 do
        if length(decls[i]) >= length(word) and equal(decls[i][1..length(word)], word) then
          junk = c_func(SendMessage, {hcode, LB_ADDSTRING, 0, alloc_string(decls[i])})
        end if
    end for
    junk = c_func(SendMessage, {hcode, LB_SETCURSEL, 0, 0})
    junk = c_func(SendMessage, {hMainWnd, WM_SETFOCUS, 0, 0})
end if
end procedure


sequence find_phrase
find_phrase = ""

procedure process_find(atom struc)
    atom flags, findtext, junk, result
    flags = GetFindFlags(struc)
    if and_bits(flags, FR_DIALOGTERM) then
        find_phrase = GetFindWhat(struc)
	hFindDlg = 0
    elsif and_bits(flags, FR_FINDNEXT) 
    or and_bits(flags, FR_REPLACE) 
    or and_bits(flags, FR_REPLACEALL) then
	findtext = allocate(20)
	poke4(findtext, {0,-1,peek4u(struc+16),0,-1})
	while 1 do
	
	    --junk = c_func(SendMessage, {hedit, SCI_GETSEL, findtext+12, findtext})
            poke4(findtext, c_func(SendMessage, {hedit, SCI_GETSELECTIONEND, 0, 0}))
            poke4(findtext+4, c_func(SendMessage, {hedit, SCI_GETTEXTLENGTH, 0, 0}))
        
	    if and_bits(flags, FR_REPLACE)
	    or and_bits(flags, FR_REPLACEALL) then
		if peek4s(findtext) > peek4s(findtext+12) then
		    junk = c_func(SendMessage, {hedit, SCI_REPLACESEL, 1, peek4u(struc+20)})
		end if
	    end if
	    junk = c_func(SendMessage, {hedit, SCI_FINDTEXT, 
		and_bits(flags, or_bits(FR_MATCHCASE, FR_WHOLEWORD)),
		findtext})
	    if junk != -1 then
		junk = c_func(SendMessage, {hedit, SCI_SETSEL}& peek4u({findtext + 12,2}))
		if and_bits(flags, FR_REPLACEALL) = 0 then
		    exit
		end if
	    else
		junk = c_func(MessageBox, {hFindDlg, 
		    alloc_string("Finished searching document.\n"
			&"Next search will start at the top of the document."),
		    alloc_string(window_title), 
		    or_all({MB_APPLMODAL, MB_ICONINFORMATION, MB_OK})})
		junk = c_func(SendMessage, {hedit, SCI_SETSEL, 0,0})
		exit
	    end if
	end while

	free(findtext)
    end if

end procedure


procedure run_start()
    atom result

    -- save, no confirm 
    if save_if_modified(0) = 0 or length(file_name) = 0 then 
      return -- cancelled, or no name
    end if
    
    run_file_name = file_name

    result = c_func(ShellExecute, {
	hMainWnd, NULL,
	alloc_string(run_file_name),
	NULL,
	NULL,
	1})
    free_strings()
end procedure

procedure get_window_size()
    atom rect
    rect = allocate(16)
    c_proc(GetWindowRect, {hMainWnd, rect})
    x_pos = peek4u(rect)
    y_pos = peek4u(rect+4)
    x_size = peek4u(rect+8) - x_pos
    y_size = peek4u(rect+12) - y_pos
    free(rect)
end procedure

function get_appdata_path()
    atom junk, path
    sequence appdata
    path = allocate(MAX_PATH)
    junk = c_func(SHGetFolderPath, {
        NULL,
        CSIDL_LOCAL_APPDATA + CSIDL_FLAG_CREATE,
        NULL,
        0,
        path})
    appdata = peek_string(path)
    free(path)
    return appdata
end function

constant wee_conf_filename = get_appdata_path() & "\\wee_conf.txt"


procedure init_fonts()
    atom junk, lf_facesize, lf_size, size, ncm, lf,
        lfCaptionFont, lfSmCaptionFont, lfMenuFont, lfStatusFont, lfMessageFont

    lf_facesize = 32
    lf_size = 4*5 + 8 + lf_facesize
    size = 4 + 4*5
    lfCaptionFont = size
    size += lf_size + 4*2
    lfSmCaptionFont = size
    size += lf_size + 4*2
    lfMenuFont = size
    size += lf_size
    lfStatusFont = size
    size += lf_size
    lfMessageFont = size
    size += lf_size
    ncm = allocate(size)
    
    poke4(ncm, size)
    poke4(ncm+lfCaptionFont, -1)
    poke4(ncm+lfSmCaptionFont, -1)
    poke4(ncm+lfMenuFont, -1)
    poke4(ncm+lfStatusFont, -1)
    poke4(ncm+lfMessageFont, -1)
   
    junk = c_func(SystemParametersInfo, {SPI_GETNONCLIENTMETRICS, size, ncm, 0})

    captionFont = c_func(CreateFontIndirect, {ncm+lfCaptionFont})
    smCaptionFont = c_func(CreateFontIndirect, {ncm+lfSmCaptionFont})
    menuFont = c_func(CreateFontIndirect, {ncm+lfMenuFont})
    statusFont = c_func(CreateFontIndirect, {ncm+lfStatusFont})
    messageFont = c_func(CreateFontIndirect, {ncm+lfMessageFont})
    free(ncm)
end procedure

procedure choose_font()
    atom junk, cf, lf, size, lf_facesize, lf_size, hedit

    lf_facesize = 32
    lf_size = 4*5 + 8 + lf_facesize
    lf = allocate(lf_size)
    poke4(lf, {-floor((font_height*96+36)/72),0,0,0,0,0,0})
    poke(lf+lf_size-lf_facesize, font_name&0)

    size = 4*15
    cf = allocate(size)
    poke4(cf,{ -- struct CHOOSEFONT
        size, -- DWORD lStructSize;
        hMainWnd, -- hwndOwner;
        NULL, -- HDC hDC;
        lf, -- LPLOGFONT lpLogFont;
        0, 
        CF_INITTOLOGFONTSTRUCT,
        0,
        0,
        NULL,
        NULL,
        NULL,
        0,
        0,
        0})
    junk = c_func(ChooseFont, {cf})
    if junk = 1 then
        font_name = peek_string(lf+lf_size-lf_facesize)
        font_height = floor(peek4u(cf+16) / 10)
        --? font_height
        --printf(1, "height=%d %d width=%d weight=%d facename=%s pointsize=%d\n", {
        --    peek4s(lf),
        --   -floor((font_height*96+36)/72),
        --    peek4u(lf+4),
        --    peek4u(lf+16),
        --    font_name,
        --    peek4u(cf+16)})
        
        -- update existing editor windows style
        reinit_all_edits()
    end if
    free(cf)
    free(lf)
end procedure

function crash_cleanup(object x)
  atom junk
  junk = c_func(MessageBox, {hMainWnd, 
		    alloc_string("Internal editor error occurred.\n"),
		    alloc_string(window_title), 
		    or_all({MB_APPLMODAL, MB_ICONINFORMATION, MB_OK})})
  if htabs then 
    junk = save_modified_tabs()
    save_wee_conf(wee_conf_filename)
  end if
  return 0
end function

crash_routine(routine_id("crash_cleanup"))

integer doing_setfocus_checks
doing_setfocus_checks = 0

global function WndProc(atom hwnd, atom iMsg, atom wParam, atom lParam)
-- callback routine to handle Window class
    atom junk, hwndFrom, code
    integer rc
    rc = 0
     
    if hwnd != hMainWnd then
        --? {hwnd, iMsg, wParam, lParam}
        return c_func(DefWindowProc, {hwnd, iMsg, wParam, lParam})
    end if
    if iMsg = WM_NOTIFY then
      -- lParam is pointer to NMHDR { HWND hwndFrom; UINT_PTR idFrom; UINT code; }
      hwndFrom = peek4u(lParam)
      code = peek4s(lParam+8)
--printf(1, "hwndFrom=%x idFrom=%x code=%x %x %x %x\n", peek4u({lParam,6}))

      if hwndFrom = hedit then
         sci_notify(c_func(SendMessage, {hedit, SCI_GETDIRECTPOINTER, 0, 0}), 0, lParam, 0)
         return rc

      elsif hwndFrom = htabs and code = TCN_SELCHANGE then
        select_tab(1 + c_func(SendMessage, {htabs, TCM_GETCURSEL, 0, 0}))

      else
        --? peek4u({lParam, 6})
        --printf(1, "hwndFrom=%x idFrom=%x code=%x %x %x %x\n", peek4u({lParam,6}))

      end if
    end if

    if iMsg = WM_CREATE then
	return rc
    elsif iMsg = WM_PAINT then
	
    elsif iMsg = WM_DESTROY then
	c_proc(PostQuitMessage, {0})

      get_window_size()
	return rc
    elsif iMsg = WM_SIZE then  --resize the rich edit control to fit the window
	c_proc(MoveWindow, {hedit, 0, tab_h, LOWORD(lParam), HIWORD(lParam)-tab_h, 1})
        c_proc(MoveWindow, {hstatus, LOWORD(lParam)-64, 2, 64, tab_h-4, 1})
        c_proc(MoveWindow, {htabs, 0, 0, LOWORD(lParam), tab_h, 1})

	return rc
    elsif iMsg = WM_CLOSE then --closing window
	if save_modified_tabs() then
	    junk = c_func(DestroyWindow, {hwnd})
	end if
	return rc
    elsif iMsg = WM_SETFOCUS then --always pass focus on to rich edit control
        if not doing_setfocus_checks then
            doing_setfocus_checks = 1
            check_ex_err()
            check_externally_modified_tabs()
	    junk = c_func(SetFocus, {hedit})
            doing_setfocus_checks = 0
        end if
	return rc
    elsif iMsg = WM_COMMAND then
	if lParam = 0 then
	    if wParam = File_New then
		new_file()
		return rc
	    elsif wParam = File_Open then
		open_file("", 0)
		return rc
	    elsif wParam = File_Save then
		save_if_modified(0) -- no confirm
		return rc
	    elsif wParam = File_SaveAs then
		junk = save_file_as()
		return rc
	    elsif wParam = File_Close then
                if save_if_modified(1) then
		    close_tab()
                end if
		return rc
	    elsif wParam = File_Exit then
		return c_func(SendMessage, {hwnd, WM_CLOSE, 0, 0})
	    elsif wParam = Edit_Undo then
		return c_func(SendMessage, {hedit, WM_UNDO, 0, 0})
	    elsif wParam = Edit_Cut then
		return c_func(SendMessage, {hedit, WM_CUT, 0, 0})
	    elsif wParam = Edit_Copy then
		return c_func(SendMessage, {hedit, WM_COPY, 0, 0})
	    elsif wParam = Edit_Paste then
		return c_func(SendMessage, {hedit, WM_PASTE, 0, 0})
	    elsif wParam = Edit_Clear then
		return c_func(SendMessage, {hedit, WM_CLEAR, 0, 0})
	    elsif wParam = Edit_SelectAll then
		return c_func(SendMessage, {hedit, EM_SETSEL, 0, -1})
	    elsif wParam = Search_Find then
		hFindDlg = FindText(hMainWnd,0,or_all({FR_HIDEUPDOWN}),find_phrase)
		return rc
	    elsif wParam = Search_Replace then
		hFindDlg = ReplaceText(hMainWnd,0,or_all({FR_HIDEUPDOWN}),"","")
		return rc
	    elsif wParam = View_Subs then
		view_subroutines()
		return rc
	    elsif wParam = View_Error then
		view_error()
		return rc
	    elsif wParam = View_Font then
		choose_font()
		return rc
	    elsif wParam = View_LineNumbers then
	        line_numbers = not line_numbers
	        reinit_all_edits()
	        return c_func(CheckMenuItem, {hviewmenu, View_LineNumbers, MF_CHECKED*line_numbers})
	    elsif wParam = View_Completions then
		view_completions()
		return rc
	    elsif wParam = View_Declaration then
                view_declaration()
		return rc
	    elsif wParam = View_SubArgs then
                view_subroutine_arguments()
		return rc
	    elsif wParam = Run_Start then
		run_start()
		return rc
	    elsif wParam = Help_About then
		about_box()
		return rc
            elsif wParam > File_Recent and wParam <= File_Recent + max_recent_files then
                open_recent(wParam - File_Recent)
            elsif wParam >= Select_Tab and wParam <= Select_Tab + 9 then
		select_tab(wParam - Select_Tab + 1)
	    else
	        printf(1, "%d %d\n", {wParam, lParam})
	    end if
	else
	    --printf(1, "HIWORD:%d LOWORD:%d LPARAM:%d\n", {HIWORD(wParam), LOWORD(wParam), lParam})
	end if
    elsif iMsg = WM_FIND then  -- find/replace dialog
	process_find(lParam)
    else
       --printf(1, "hwnd=%x iMsg=%d #%x wParam=%d lParam=%d\n", {hwnd, iMsg, iMsg, wParam, lParam})

    end if

    return c_func(DefWindowProc, {hwnd, iMsg, wParam, lParam})
end function

-- The scintilla edit control doesn't offer a way to hook accelerator keys
-- so we have to process messages in our message loop, and intercept and
-- rewrite them into WM_COMMAND messages for the main window handle.
procedure translate_editor_keys(atom msg)
  atom hwnd, iMsg, wParam, lParam

  hwnd = peek4u(msg)
  iMsg = peek4u(msg+4)
  wParam = peek4u(msg+8)
  lParam = peek4u(msg+12)
  if hwnd = hedit then
    if iMsg = WM_CHAR  then
      --printf(1, "%x %x %x %x\n", {hwnd, iMsg, wParam, lParam})
      if wParam = #13 then -- Ctrl-S
        poke4(msg, {hMainWnd, WM_COMMAND, File_Save, 0})
      elsif wParam = #6 then -- Ctrl-F
        poke4(msg, {hMainWnd, WM_COMMAND, Search_Find, 0})
      elsif wParam = VK_SPACE and and_bits(c_func(GetKeyState, {VK_CONTROL}), #8000) then
        poke4(msg, {hMainWnd, WM_COMMAND, View_Completions, 0})
      end if
    elsif iMsg = WM_KEYUP then
      if wParam = VK_F5 then
        poke4(msg, {hMainWnd, WM_COMMAND, Run_Start, 0})
      elsif wParam = VK_F4 then
        poke4(msg, {hMainWnd, WM_COMMAND, View_Error, 0})
      elsif wParam = VK_F3 then
        poke4(msg, {hMainWnd, WM_COMMAND, Search_Find, 0})
      elsif wParam = VK_F2 and and_bits(c_func(GetKeyState, {VK_CONTROL}), #8000) then
        poke4(msg, {hMainWnd, WM_COMMAND, View_Declaration, 0})
      elsif wParam = VK_F2 and and_bits(c_func(GetKeyState, {VK_SHIFT}), #8000) then
        poke4(msg, {hMainWnd, WM_COMMAND, View_SubArgs, 0})
      elsif wParam = VK_F2 then
        poke4(msg, {hMainWnd, WM_COMMAND, View_Subs, 0})
      end if
    elsif iMsg = WM_SYSCHAR then
      if wParam >= '1' and wParam <= '9' then
        poke4(msg, {hMainWnd, WM_COMMAND, wParam - '1' + Select_Tab, 0})
      end if
    end if
  end if  
end procedure


constant AppName = "WeeEditor"


procedure WinMain()
-- main routine 
    atom msg
    integer id
    atom junk, tcitem
    sequence cmdline
    
    cmdline = command_line()

    init_fonts()

    msg = allocate(SIZE_OF_MESSAGE)

    id = routine_id("WndProc")
    if id = -1 then
	puts(1, "routine_id failed!\n")
	abort(1)
    end if
    class = RegisterClass({
	or_bits(CS_HREDRAW, CS_VREDRAW),
	call_back(id), -- get 32-bit address for callback
	0,
	0,
	0,
	c_func(LoadIcon, {NULL, IDI_APPLICATION}),
	c_func(LoadCursor, {NULL, IDC_ARROW}),
	c_func(GetStockObject, {WHITE_BRUSH}),
	NULL,
	AppName,
	c_func(LoadIcon, {NULL, IDI_APPLICATION})})
    if class = 0 then
	puts(1, "Couldn't register class\n")
	abort(1)
    end if

    -- this is required for FindText,ReplaceText common dialogs to work
    WM_FIND = c_func(RegisterWindowMessage,{alloc_string(FINDMSGSTRING)})

-- menu creation
-- file menu
    hfilemenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_New, alloc_string("&New")})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_Open, alloc_string("&Open...")})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_Save, alloc_string("&Save")})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_SaveAs, alloc_string("Save &As...")})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_Close, alloc_string("&Close")})
--    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
--    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_GRAYED, 
--	File_Print, alloc_string("Print...")})
--    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_GRAYED, 
--	File_PageSetup, alloc_string("Page Setup...")})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
    junk = c_func(AppendMenu, {hfilemenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	File_Exit, alloc_string("E&xit\tAlt+F4")})
-- edit menu    
    heditmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_Undo, alloc_string("U&ndo\tCtrl+Z")})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_Cut, alloc_string("Cu&t\tCtrl+X")})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_Copy, alloc_string("&Copy\tCtrl+C")})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_Paste, alloc_string("&Paste\tCtrl+V")})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_Clear, alloc_string("Cl&ear\tDel")})
    junk = c_func(AppendMenu, {heditmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Edit_SelectAll, alloc_string("Select &All\tCtrl+A")})
-- search menu
    hsearchmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hsearchmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Search_Find, alloc_string("&Find...\tF3")})
    junk = c_func(AppendMenu, {hsearchmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Search_Replace, alloc_string("&Replace...")})
-- view menu
    hviewmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_Subs, alloc_string("&Subroutines...\tF2")})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_Declaration, alloc_string("&Declaration\tCtrl+F2")})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_SubArgs, alloc_string("Subroutine &Arguments...\tShift+F2")})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_Completions, alloc_string("&Completions...\tCtrl+Space")})
    --junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	--View_NavigateBack, alloc_string("&Navigate Back")})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_Error, alloc_string("Goto &Error\tF4")})
    --junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_SEPARATOR, 0, 0})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_Font, alloc_string("&Font...")})
    junk = c_func(AppendMenu, {hviewmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	View_LineNumbers, alloc_string("&Line Numbers")})
-- run menu
    hrunmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hrunmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Run_Start, alloc_string("&Start\tF5")})
-- options menu
--    hoptionsmenu = c_func(CreateMenu, {})
--    junk = c_func(AppendMenu, {hoptionsmenu, MF_BYPOSITION + MF_STRING + MF_GRAYED, 
--	Options_Font, alloc_string("&Font...")})
-- help menu
    hhelpmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hhelpmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED, 
	Help_About, alloc_string("&About...")})
-- main menu
    hmenu = c_func(CreateMenu, {})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	hfilemenu, alloc_string("&File")})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	heditmenu, alloc_string("&Edit")})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	hsearchmenu, alloc_string("&Search")})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	hviewmenu, alloc_string("&View")})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	hrunmenu, alloc_string("&Run")})
--    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
--	hoptionsmenu, alloc_string("&Options")})
    junk = c_func(AppendMenu, {hmenu, MF_BYPOSITION + MF_STRING + MF_ENABLED + MF_POPUP, 
	hhelpmenu, alloc_string("&Help")})
	
    free_strings() -- garbage collect menu strings

    load_wee_conf(wee_conf_filename)
    
    -- set the checkmark on the Line Numbers menu item
    c_func(CheckMenuItem, {hviewmenu, View_LineNumbers, MF_CHECKED*line_numbers}) 
    
-- window creation
    hMainWnd = CreateWindow({
		    0,                       -- extended style
		    AppName,               -- window class name
		    "",                -- window caption
		    WS_OVERLAPPEDWINDOW,     -- window style
		    x_pos,           -- initial x position
		    y_pos,           -- initial y position
		    x_size,           -- initial x size
		    y_size,           -- initial y size
		    NULL,                    -- parent window handle
		    hmenu,                   -- window menu handle
		    0 ,                 --hInstance // program instance handle
		    NULL})              -- creation parameters


    junk = c_func(LoadLibrary, {alloc_string("RICHED32.DLL")})  --needed for richedit

    hstatus = CreateWindow({0, "STATIC", "static", 
		    {WS_CHILD,WS_VISIBLE,SS_RIGHT},
		    0,0,0,0, -- set by resize
                hMainWnd,
                NULL,
                0,
                NULL})
    junk = c_func(SendMessage, {hstatus, WM_SETFONT, statusFont, 0})
    --update_status(0)

    htabs = CreateWindow({0,"SysTabControl32", "tabs",
		    {WS_CHILD,WS_VISIBLE,TCS_FOCUSNEVER},
		    0,0,200,20, -- set by resize
                hMainWnd,
                NULL,
                0,
                NULL})
    junk = c_func(SendMessage, {htabs, WM_SETFONT, statusFont, 0})

    if hMainWnd = 0 or hstatus = 0 or htabs = 0 then
	puts(1, "Couldn't CreateWindow\n")
	abort(1)
    end if

    
    if length(cmdline) > 2 then
	open_file(cmdline[3], 0)
    else
        new_file()
    end if

    --if SetThemeAppProperties != -1 then
    --    c_proc(SetThemeAppProperties, {STAP_ALLOW_NONCLIENT+STAP_ALLOW_CONTROLS})
    --    junk = c_func(SendMessage, {hMainWnd, WM_THEMECHANGED, 0, 0})
    --end if

    c_proc(ShowWindow, {hMainWnd, SW_SHOWNORMAL})
    c_proc(UpdateWindow, {hMainWnd})

    while c_func(GetMessage, {msg, NULL, 0, 0}) do
	if hFindDlg and c_func(IsDialogMessage,{hFindDlg,msg}) then
	  -- this message is handled by find dialog (thanks Jacques)
	  -- it makes the tab key work for find/replace dialogs
	else
          translate_editor_keys(msg)
          junk = c_func(TranslateMessage, {msg})
	  junk = c_func(DispatchMessage, {msg})
      end if
    end while

end procedure

wee_init()
WinMain()
save_wee_conf(wee_conf_filename)
