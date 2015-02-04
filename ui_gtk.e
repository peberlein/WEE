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

constant chk_cb = define_c_proc("", call_back(routine_id("check_callback_func")), {C_LONG})
c_proc(chk_cb, {#100000000})
end ifdef



constant wee_conf_file = getenv("HOME") & "/.wee_conf"


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
function SearchFind() return 0 end function
function SearchReplace() return 0 end function
function ViewSubs() view_subroutines() return 0 end function
function ViewDecl() view_declaration() return 0 end function
function ViewArgs() view_subroutine_arguments() return 0 end function
function ViewComp() view_completions() return 0 end function
function ViewError() ui_view_error() return 0 end function

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
function RunStart() return 0 end function

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

pack(panel, notebook, 1, 1)
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
  set(dialog, "add button", "gtk-cancel", 0)
  set(dialog, "add button", "gtk-ok", 1)
  set(dialog, "position", GTK_WIN_POS_MOUSE)
  if gtk:get(dialog, "run") = 1 then
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
  set(dialog, "overwrite confirmation", TRUE)
  set(dialog, "add button", "gtk-cancel", 0)
  set(dialog, "add button", "gtk-ok", 1)
  set(dialog, "filename", filename)
  set(dialog, "position", GTK_WIN_POS_MOUSE)
  if gtk:get(dialog, "run") = 1 then
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

end procedure




--------------------------------------------------


wee_init()

x_pos = 100    y_pos = 50
x_size = 500 y_size = 600

load_wee_conf(wee_conf_file)
gtk_proc("gtk_window_move", {P,I,I}, {win, x_pos, y_pos-28}) -- something is moving the window 28 pixels down each time
--gtk_proc("gtk_window_resize", {P,I,I}, {win, x_size, y_size})
set(win, "default size", x_size, y_size)

constant cmdline = command_line()

if length(cmdline) > 2 then
  open_file(cmdline[3], 0)
else
  new_file()
end if


show_all(win)
main()


