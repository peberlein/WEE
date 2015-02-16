-- ui_gtk.e

-- fix intermittent hang on quit (found it, caused by putting the program in the
-- background using Ctrl-Z and "bg".  It blocks on doing something to console
-- before exiting, so need to do "fg" to unfreeze and exit normally.)

-- font seems to be ok on OSX now, 
-- needed to strip spaces and "bold", "italic", from the font name.

-- todo:
-- fix modifier keys not working on OS X (might be ok now using gtk accelerators)
--   menu accelerator labels show up as "-/-" on OS X
-- investigate if widgets need to be Destroy'd


public include std/machine.e
public include std/error.e
include scintilla.e
include EuGTK/GtkEngine.e
include wee.exw as wee



-- check to see if 64-bit callback arguments are broken
ifdef BITS64 then
function check_callback_func(atom x)
  if x = 0 then
    crash("You need a newer 64-bit Euphoria with callback bug fix")
  end if
  return 0
end function

c_proc(define_c_proc("",
		     call_back(routine_id("check_callback_func")),
		     {C_LONG}),
       {#100000000})
end ifdef



constant wee_conf_file = getenv("HOME") & "/.wee_conf"
constant cmdline = command_line()

--------------------------------------------------
sequence find_phrase, replace_phrase
find_phrase = ""
replace_phrase = ""

constant 
    GTK_RESPONSE_FIND = 1,
    GTK_RESPONSE_REPLACE = 2,
    GTK_RESPONSE_REPLACE_ALL = 3

procedure do_find(integer rep)
    atom dialog, content, row, vbox, hbox, lbl, hedit, find_entry, rep_entry, chk_word, chk_case
    integer flags, result, pos
-- Fi_nd What: __________________  [_Find Next]
-- [ ] Match _Whole Word Only      [  Cancel  ]
-- [ ] Match _Case

-- Fi_nd What: __________________   [_Find Next]
-- Re_place With: _______________   [_Replace ]
-- [ ] Match _Whole Word Only       [Replace _All ]
-- [ ] Match _Case                  [Cancel]

    dialog = create(GtkDialog)
    --set(dialog, "default size", 200, 200)
    set(dialog, "add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT)
    if rep then
	set(dialog, "add button", "Replace All", GTK_RESPONSE_REPLACE_ALL)
	set(dialog, "add button", "Replace", GTK_RESPONSE_REPLACE)
    end if
    set(dialog, "add button", "Find Next", GTK_RESPONSE_FIND)
    set(dialog, "transient for", win)
    set(dialog, "title", "Find")
    if rep then
	set(dialog, "default response", GTK_RESPONSE_REPLACE)
    else
	set(dialog, "default response", GTK_RESPONSE_FIND)
    end if
    set(dialog, "modal", TRUE)
    content = gtk:get(dialog, "content area")
    
    vbox = create(GtkBox, VERTICAL)
    add(content, vbox)
    
    hbox = create(GtkBox, HORIZONTAL)
    pack(vbox, hbox)
    pack(hbox, create(GtkLabel, "Find What:"))
    find_entry = create(GtkEntry)
    set(find_entry, "activates default", TRUE)
    set(find_entry, "text", find_phrase)
    pack(hbox, find_entry)
    --pack(hbox, -create(GtkButton, "Find Next", GTK_RESPONSE_OK))

    if rep then
        hbox = create(GtkBox, HORIZONTAL)
	pack(vbox, hbox)
	pack(hbox, create(GtkLabel, "Replace With:"))
	rep_entry = create(GtkEntry)
	set(rep_entry, "activates default", TRUE)
	set(rep_entry, "text", replace_phrase)
	pack(hbox, rep_entry)
    end if

    hbox = create(GtkBox, HORIZONTAL)
    pack(vbox, hbox)
    chk_word = create(GtkCheckButton, "Match Whole Word Only")
    pack(hbox, chk_word)
    --pack(hbox, -create(GtkButton, "Cancel", GTK_RESPONSE_DELETE_EVENT))
    
    hbox = create(GtkBox, HORIZONTAL)
    pack(vbox, hbox)
    chk_case = create(GtkCheckButton, "Match Case")
    pack(hbox, chk_case)

    show_all(dialog)
    hedit = tab_hedit()
    pos = -1
    
    result = set(dialog, "run")
    while result != GTK_RESPONSE_DELETE_EVENT do
	flags = 0
	if gtk:get(chk_word, "active") then
	    flags += SCFIND_WHOLEWORD
	end if
	if gtk:get(chk_case, "active") then
	    flags += SCFIND_MATCHCASE
	end if
	
	SSM(hedit, SCI_SETSEARCHFLAGS, flags)
	find_phrase = gtk:get(find_entry, "text")

	if result = GTK_RESPONSE_REPLACE_ALL then
	    pos = 0
	end if
	
	while 1 do
	    if pos = -1 then
		pos = SSM(hedit, SCI_GETCURRENTPOS)
	    elsif result != GTK_RESPONSE_FIND then
		-- replace or replace_all
		replace_phrase = gtk:get(rep_entry, "text")
		SSM(hedit, SCI_REPLACETARGET, length(replace_phrase), replace_phrase)
		pos += length(replace_phrase)
	    end if
	    
	    SSM(hedit, SCI_SETTARGETSTART, pos)
	    SSM(hedit, SCI_SETTARGETEND, SSM(hedit, SCI_GETTEXTLENGTH))
	    pos = SSM(hedit, SCI_SEARCHINTARGET, length(find_phrase), find_phrase)
	    if pos < 0 then
		SSM(hedit, SCI_GOTOPOS, 0)
	        pos = -1
	        exit
	    end if
	    if result != GTK_RESPONSE_REPLACE_ALL then
	        SSM(hedit, SCI_SETSEL, pos, pos+length(find_phrase))
	        pos += length(find_phrase)
	        exit
	    end if
	end while
	result = set(dialog, "run")
    end while
    hide(dialog)
    return
end procedure


--------------------------------------------------
-- functions called from menu items

function FileNew() new_file() return 0 end function
function FileOpen() open_file("", 0) return 0 end function
function FileSave() save_if_modified(0) return 0 end function
function FileSaveAs() save_file_as() return 0 end function
function FileClose() close_tab() return 0 end function
function FileQuit()
  if save_modified_tabs() then
    save_wee_conf(wee_conf_file)
    Quit()
  end if
  return 0
end function
function EditUndo() SSM(tab_hedit(), SCI_UNDO) return 0 end function
function EditRedo() SSM(tab_hedit(), SCI_REDO) return 0 end function
function EditCut() SSM(tab_hedit(), SCI_CUT) return 0 end function
function EditCopy() SSM(tab_hedit(), SCI_COPY) return 0 end function
function EditPaste() SSM(tab_hedit(), SCI_PASTE) return 0 end function
function EditClear() SSM(tab_hedit(), SCI_CLEAR) return 0 end function
function EditSelectAll() SSM(tab_hedit(), SCI_SELECTALL) return 0 end function
function SearchFind() do_find(0) return 0 end function
function SearchReplace() do_find(1) return 0 end function
function ViewDecl() view_declaration() return 0 end function
function ViewArgs() view_subroutine_arguments() return 0 end function
function ViewComp() view_completions() return 0 end function
function ViewError() ui_view_error() return 0 end function

function ViewSubs() 
    sequence text, word, subs
    integer pos, result
    atom dialog, scroll, list, content, row, lbl

    text = get_edit_text()
    pos = get_pos()
    word = word_pos(text, pos)
    subs = get_subroutines(parse(text, file_name))
    word = word[1]
    
    dialog = create(GtkDialog)
    set(dialog, "default size", 200, 400)
    set(dialog, "add button", "gtk-close", GTK_RESPONSE_CLOSE)
    set(dialog, "add button", "gtk-ok", GTK_RESPONSE_OK)
    set(dialog, "transient for", win)
    set(dialog, "title", "Subroutines")
    set(dialog, "default response", GTK_RESPONSE_OK)
    set(dialog, "modal", TRUE)

    content = gtk:get(dialog, "content area")
    scroll = create(GtkScrolledWindow)
    pack(content, scroll, TRUE, TRUE)

    list = create(GtkListBox)
    add(scroll, list)
    for i = 1 to length(subs) by 2 do
	lbl = create(GtkLabel, subs[i])
	set(lbl, "halign", GTK_ALIGN_START)
	set(list, "insert", lbl, -1)
	if equal(subs[i], word) then
	    row = gtk:get(list, "row at index", floor(i/2))
	    set(list, "select row", row)
	end if
    end for

    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	row = gtk:get(list, "selected row")
        --result = gtk:get(row, "index") -- doesn't work?
	for i = 1 to floor(length(subs) / 2)  do
	    if row = gtk:get(list, "row at index", i-1) then
		word = subs[i*2-1]
		pos = subs[i*2]-1
		SSM(tab_hedit(), SCI_SETSEL, pos, pos + length(word))
		set_top_line(-1)
		exit
	    end if
	end for
    end if
    hide(dialog)
    return 0
end function

function ViewFont()
  atom dialog
  sequence font, tmp

  dialog = create(GtkFontChooserDialog, "Font...", win)
  set(dialog, "font", sprintf("%s %d", {font_name, font_height}))
  if set(dialog, "run") = MB_OK then
    font = gtk:get(dialog, "font")
    for i = length(font) to 1 by -1 do
      if font[i] = ' ' then
	tmp = value(font[i+1..$])
	if tmp[1] = 0 then
	  font_height = tmp[2]
          font_name = font[1..i-1]
          --printf(1, "%s %d\n", {font_name, font_height})
	  reinit_all_edits()
	end if
	exit
      end if
    end for
  end if
  set(dialog, "hide")
    
  return 0 
end function

function RunStart() 
    if save_if_modified(0) = 0 or length(file_name) = 0 then
        return 0 -- cancelled, or no name
    end if
    
    run_file_name = file_name
    reset_ex_err()
    
    system(cmdline[1] & " " & run_file_name)
    check_ex_err()
    return 0 
end function

function HelpAbout()
  set(about_dialog, "run")
  set(about_dialog, "hide")
  return 0
end function

-- this gets called when window is moved or resized
function configure_event(atom w, atom s)
  -- s is struct GdkEventConfigure*
  -- skip over GdkEventType, GdkWindow *, gint8
  ifdef BITS64 then
    s += 20
  elsedef
    s += 12
  end ifdef
  x_pos = peek4u(s)
  y_pos = peek4u(s+4)
  x_size = peek4u(s+8)
  y_size = peek4u(s+12)
  --? {x_pos, y_pos, x_size, y_size}
  return 0
end function

-- called before window is closed, return TRUE to prevent close, otherwise FALSE
function delete_event()
  if save_modified_tabs() then
    save_wee_conf(wee_conf_file)
    return FALSE
  end if
  return TRUE
end function

function notebook_switch_page(atom nb, atom page, atom page_num)
    select_tab(page_num + 1)
    return 0
end function

function window_set_focus(atom widget)
    printf(1, "window set focus %d\n", {widget})
    check_externally_modified_tabs()
    check_ex_err()
    return 0
end function


-------------------------------------------------------------

constant 
  win = create(GtkWindow),
  group = create(GtkAccelGroup),
  panel = create(GtkBox, VERTICAL)

set(win, "border width", 0)
connect(win, "destroy", main_quit)
connect(win, "configure-event", call_back(routine_id("configure_event")))
connect(win, "delete-event", call_back(routine_id("delete_event")))
--connect(win, "set-focus", call_back(routine_id("window_set_focus")))
set(win, "add accel group", group)
add(win, panel)

constant
  about_dialog = create(GtkAboutDialog)
set(about_dialog, "transient for", win)
set(about_dialog, "program name", window_title)
set(about_dialog, "version", wee:version)
set(about_dialog, "authors", {author})

constant
  menubar = create(GtkMenuBar),
  menuFile = create(GtkMenuItem, "_File"),
  menuEdit = create(GtkMenuItem, "_Edit"),
  menuSearch = create(GtkMenuItem, "_Search"),
  menuView = create(GtkMenuItem, "_View"),
  menuRun = create(GtkMenuItem, "_Run"),
  menuHelp = create(GtkMenuItem, "_Help"),
  filemenu = create(GtkMenu),
  editmenu = create(GtkMenu),
  searchmenu = create(GtkMenu),
  viewmenu = create(GtkMenu),
  runmenu = create(GtkMenu),
  helpmenu = create(GtkMenu)
set(filemenu, "accel group", group)
set(editmenu, "accel group", group)
set(searchmenu, "accel group", group)
set(viewmenu, "accel group", group)
set(runmenu, "accel group", group)
set(helpmenu, "accel group", group)

-- create a menu item with "activate" signal connected to local routine
-- and add parsed accelerator key 
function createmenuitem(sequence text, object r, object key = 0, integer mod = 0)
  atom widget, x

  widget = create(GtkMenuItem, text)
  if sequence(r) then
    x = routine_id(r)
    if x <= 0 then
      crash(r &" is not a visible function")
    end if
    r = call_back(x)
  end if
  connect(widget, "activate", r)

  if sequence(key) then
      x = allocate(8)
      gtk_proc("gtk_accelerator_parse", {P,P,P}, {allocate_string(key, 1), x, x+4})
      key = peek4u(x)
      mod = peek4u(x+4)
      free(x)
  end if
  if key then
      set(widget, "add accelerator", "activate", group, key, mod, 1)
  end if
  return widget
end function

add(filemenu, {
  createmenuitem("_New", "FileNew", "<Control>N"),
  createmenuitem("_Open...", "FileOpen", "<Control>O"),
  createmenuitem("_Save", "FileSave", "<Control>S"),
  createmenuitem("Save _As...", "FileSaveAs"),
  createmenuitem("_Close", "FileClose"),
  create(GtkSeparatorMenuItem),
  createmenuitem("_Quit", "FileQuit", "<Control>Q")
  })
set(menuFile, "submenu", filemenu)

add(editmenu, {
  createmenuitem("_Undo", "EditUndo", "<Control>Z"),
  createmenuitem("_Redo", "EditRedo", "<Control><Shift>Z"),
  create(GtkSeparatorMenuItem),
  createmenuitem("_Cut", "EditCut", "<Control>X"),
  createmenuitem("C_opy", "EditCopy", "<Control>C"),
  createmenuitem("_Paste", "EditPaste", "<Control>V"),
  createmenuitem("Clear", "EditClear"),
  createmenuitem("Select _All", "EditSelectAll", "<Control>A")
  })
set(menuEdit, "submenu", editmenu)

add(searchmenu, {
  createmenuitem("Find...", "SearchFind", "F3"),
  createmenuitem("Replace...", "SearchReplace")
  })
set(menuSearch, "submenu", searchmenu)

add(viewmenu, {
  createmenuitem("Subroutines...", "ViewSubs", "F2"),
  createmenuitem("Declaration", "ViewDecl", "<Control>F2"),
  createmenuitem("Subroutine Arguments...", "ViewArgs", "<Shift>F2"),
  createmenuitem("Completions...", "ViewComp", "<Control>space"),
  createmenuitem("Goto Error", "ViewError", "F4"),
  create(GtkSeparatorMenuItem),
  createmenuitem("Font...", "ViewFont")
  })
set(menuView, "submenu", viewmenu)

add(runmenu, {
  createmenuitem("Start", "RunStart", "F5")
  })
set(menuRun, "submenu", runmenu)

add(helpmenu, {
  createmenuitem("About...", "HelpAbout")
  })
set(menuHelp, "submenu", helpmenu)

add(menubar, {menuFile, menuEdit, menuSearch, menuView, menuRun, menuHelp})
  
pack(panel, menubar)


constant
  notebook = create(GtkNotebook)

pack(panel, notebook, TRUE, TRUE)
connect(notebook, "switch-page", call_back(routine_id("notebook_switch_page")))

--------------------------------------------------

sequence ui_hedits
ui_hedits = {}

function tab_hedit()
  integer tab
  tab = gtk:get(notebook, "current page")
  return ui_hedits[tab+1]
end function 


--------------------------------------------------

global procedure ui_update_status(sequence status)
  -- no status label yet
end procedure


global procedure ui_refresh_file_menu(sequence items)
    integer count
--    count = gtk:get(filemenu, "")
--    if then
--	create(GtkSeparatorMenuItem),
--    end if
end procedure

global procedure ui_select_tab(integer tab)
  set(notebook, "current page", tab - 1)
  gtk_proc("gtk_widget_grab_focus", {P}, ui_hedits[tab])
end procedure

global procedure ui_update_window_title(sequence file_name)
  set(win, "title", window_title & " [" & file_name & "]")
end procedure

global procedure ui_update_tab_name(integer tab, sequence name)
  set(notebook, "tab_label_text", ui_hedits[tab], name)
end procedure

constant sci_notify_cb = call_back(routine_id("sci_notify"))

global function ui_new_tab(sequence name)
  atom editor, lbl

  lbl = create(GtkLabel)
  set(lbl, "text", name)
  show(lbl)

  editor = scintilla_new()
  ui_hedits &= editor
  init_edit(editor)
  gtk_proc("gtk_widget_show", {P}, editor)

  set(notebook, "append page", editor, lbl)
--  gtk_proc("gtk_widget_grab_focus", {P}, editor)

  connect(editor, "sci-notify", sci_notify_cb, 0)

  return editor
end function

global procedure ui_close_tab(integer tab)
--  printf(1, "close tab\n", {})
    set(notebook, "remove page", tab-1)

    -- remove the window handle
    ui_hedits = ui_hedits[1..tab-1] & ui_hedits[tab+1..$]
end procedure

global function ui_get_open_file_name()
  atom dialog
  sequence filename
  
  dialog = create(GtkFileChooserDialog, "Open...", win, GTK_FILE_CHOOSER_ACTION_OPEN)
  --set(dialog, "transient for", win)
  set(dialog, "select multiple", FALSE)
  set(dialog, "add button", "gtk-cancel", GTK_RESPONSE_CLOSE)
  set(dialog, "add button", "gtk-ok", GTK_RESPONSE_OK)
  set(dialog, "position", GTK_WIN_POS_MOUSE)
  if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
    filename = gtk:get(dialog, "filename")
  else
    filename = ""
  end if
  set(dialog, "hide")

  return filename
end function

global function ui_get_save_file_name(sequence filename)
  atom dialog
  
  dialog = create(GtkFileChooserDialog, "Save As...", win, GTK_FILE_CHOOSER_ACTION_SAVE)
  set(dialog, "select multiple", FALSE)
  set(dialog, "do overwrite confirmation", TRUE)
  set(dialog, "add button", "gtk-cancel", GTK_RESPONSE_CLOSE)
  set(dialog, "add button", "gtk-ok", GTK_RESPONSE_OK)
  set(dialog, "filename", filename)
  set(dialog, "position", GTK_WIN_POS_MOUSE)
  if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
    filename = gtk:get(dialog, "filename")
  else
    filename = ""
  end if
  set(dialog, "hide")
  
  return filename
end function

-- returns yes=1 no=0
global function ui_message_box_yes_no(sequence title, sequence message)
  integer result
  result = Question(win, title, "", message)
  return (result = MB_YES)
end function

-- returns yes=1 no=0 cancel=-1
global function ui_message_box_yes_no_cancel(sequence title, sequence message)
  atom dialog, result
  dialog = create(GtkMessageDialog, win, 2, 2, GTK_BUTTONS_NONE)
  set(dialog, "add button", "gtk-cancel", -1)
  set(dialog, "add button", "gtk-no", 0)
  set(dialog, "add button", "gtk-yes", 1)
  set(dialog, "transient for", win)
  set(dialog, "destroy with parent", TRUE)
  set(dialog, "title", title)
  set(dialog, "text", message)
  set(dialog, "position", GTK_WIN_POS_CENTER_ON_PARENT)
  
  result = gtk:get(dialog, "run")
  set(dialog, "hide")

  return result
end function

global function ui_message_box_error(sequence title, sequence message)
  integer result
  result = Error(win, title, "", message, , GTK_BUTTONS_OK)
  return 0
end function

global procedure ui_view_error()
    sequence err
    atom dialog, scroll, list, content, row, lbl
    integer result

    err = get_ex_err()
    if length(err) = 0 then return end if
    
    dialog = create(GtkDialog)
    set(dialog, "default size", 200, 400)
    set(dialog, "add button", "gtk-close", GTK_RESPONSE_CLOSE)
    set(dialog, "add button", "Open Ex.Err", GTK_RESPONSE_YES)
    set(dialog, "add button", "Goto Error", GTK_RESPONSE_OK)
    set(dialog, "transient for", win)
    set(dialog, "title", "View Error")
    set(dialog, "default response", GTK_RESPONSE_OK)
    set(dialog, "modal", TRUE)
    content = gtk:get(dialog, "content area")

    lbl = create(GtkLabel, err[2])
    pack(content, lbl)

    content = gtk:get(dialog, "content area")
    scroll = create(GtkScrolledWindow)
    pack(content, scroll, TRUE, TRUE)

    list = create(GtkListBox)
    add(scroll, list)
    for i = 3 to length(err) do
	lbl = create(GtkLabel, err[i])
	set(lbl, "halign", GTK_ALIGN_START)
	set(list, "insert", lbl, -1)
    end for

    show_all(dialog)
    result = set(dialog, "run")
    if result = GTK_RESPONSE_OK then
	row = gtk:get(list, "selected row")
        --result = gtk:get(row, "index") -- doesn't work?
	for i = 0 to length(err)-3 do
	    if row = gtk:get(list, "row at index", i) then
		goto_error(err, i+1)
		exit
	    end if
	end for
    elsif result = GTK_RESPONSE_YES then
        open_file(ex_err_name, 1)
    end if
    hide(dialog)
end procedure




--------------------------------------------------


wee_init()

x_pos = 100    y_pos = 50
x_size = 500 y_size = 600

load_wee_conf(wee_conf_file)
gtk_proc("gtk_window_move", {P,I,I}, {win, x_pos, y_pos-28}) -- something is moving the window 28 pixels down each time
--gtk_proc("gtk_window_resize", {P,I,I}, {win, x_size, y_size})
set(win, "default size", x_size, y_size)

if length(cmdline) > 2 then
  open_file(cmdline[3], 0)
else
  new_file()
end if


show_all(win)
main()


