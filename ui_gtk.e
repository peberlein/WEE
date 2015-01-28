-- ui_gtk.e


public include std/machine.e
public include scintilla.e
include EuGTK/GtkEngine.e
include wee.exw


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




--------------------------------------------------

constant 
  win = create(GtkWindow)

connect(win, "destroy", main_quit)
set(win, "border width", 0)


constant
  panel = create(GtkBox, VERTICAL)

add(win, panel)

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

global function FileNew()
  new_file()
  return 0
end function
global function FileOpen()
  open_file("", 1)
  return 0
end function
global function FileSave()
  save_if_modified(0)
  return 0
end function
global function FileSaveAs()
  save_file_as()
  return 0
end function
global function FileClose()
  close_tab()
  return 0
end function


function act(atom widget, object x, object y=0, object z=0)
  connect(widget, "activate", x, y, z)
  return widget
end function

add(filemenu, {
  act(create(GtkMenuItem, "New"), "FileNew"),
  act(create(GtkMenuItem, "Open..."), "FileOpen"),
  act(create(GtkMenuItem, "Save"), "FileSave"),
  act(create(GtkMenuItem, "Save As..."), "FileSaveAs"),
  act(create(GtkMenuItem, "Close"), "FileClose"),
  create(GtkSeparatorMenuItem),
  act(create(GtkMenuItem, "Quit"), main_quit)
  })
set(menuFile, "submenu", filemenu)

add(editmenu, {
  create(GtkMenuItem, "Undo\tCtrl+Z", 0, 0),
  create(GtkSeparatorMenuItem),
  create(GtkMenuItem, "Cut\tCtrl+X", 0, 0),
  create(GtkMenuItem, "Copy\tCtrl+C", 0, 0),
  create(GtkMenuItem, "Paste\tCtrl+V", 0, 0),
  create(GtkMenuItem, "Clear\tDel", 0, 0),
  create(GtkMenuItem, "Select All\tCtrl+A", 0, 0)
  })
set(menuEdit, "submenu", editmenu)

add(searchmenu, {
  create(GtkMenuItem, "Find...\tF3", 0, 0),
  create(GtkMenuItem, "Replace...", 0, 0)
  })
set(menuSearch, "submenu", searchmenu)

add(viewmenu, {
  create(GtkMenuItem, "Subroutines...\tF2", 0, 0),
  create(GtkMenuItem, "Declaration\tCtrl+F2", 0, 0),
  create(GtkMenuItem, "Subroutine Arguments...\tShift+F2", 0, 0),
  create(GtkMenuItem, "Completions...\tCtrl+Space", 0, 0),
  create(GtkMenuItem, "Goto Error\tF4", 0, 0),
  create(GtkSeparatorMenuItem),
  create(GtkMenuItem, "Font...", 0, 0)
  })
set(menuView, "submenu", viewmenu)

add(runmenu, {
  create(GtkMenuItem, "Start\tF5", 0, 0)
  })
set(menuRun, "submenu", runmenu)

add(helpmenu, {
  create(GtkMenuItem, "About...", 0, 0)
  })
set(menuHelp, "submenu", helpmenu)

add(menubar, {menuFile, menuEdit, menuSearch, menuView, menuRun, menuHelp})
  
pack(panel, menubar)



constant
  notebook = create(GtkNotebook)

pack(panel, notebook, 1, 1)


--------------------------------------------------

sequence tab_labels, tab_hedits
tab_labels = {}
tab_hedits = {}


--------------------------------------------------

global procedure ui_update_status(sequence status)
  -- no status label yet
end procedure


global procedure ui_refresh_file_menu(sequence items)

end procedure

global procedure ui_select_tab(integer tab)

end procedure

global procedure ui_update_window_title(sequence file_name)
  set(win, "title", window_title & " [" & file_name & "]")
end procedure

global procedure ui_update_tab_name(integer tab, sequence name)
  set(tab_labels[tab], "text", name)
end procedure

constant sci_notify_cb = call_back(routine_id("sci_notify"))

global function ui_new_tab(sequence name)
  atom editor, lbl

  lbl = create(GtkLabel)
  tab_labels &= lbl
  set(lbl, "text", make_tab_name())

  editor = scintilla_new()
  tab_hedits &= editor
  init_edit(editor)
  connect(editor, "sci-notify", sci_notify_cb, 0)

  set(notebook, "append page", editor, lbl)
--  gtk_proc("gtk_widget_grab_focus", {P}, editor)

  return editor
end function

global procedure ui_close_tab()
  printf(1, "close tab\n", {})
end procedure

global function ui_get_open_file_name()
  atom dialog
  sequence filename
  
  dialog = create(GtkFileChooserDialog, "Open...", win, GTK_FILE_CHOOSER_ACTION_OPEN)
  set(dialog, "add button", "gtk-cancel", 0)
  set(dialog, "add button", "gtk-ok", 1)
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
  set(dialog, "add button", "gtk-cancel", 0)
  set(dialog, "add button", "gtk-ok", 1)
  set(dialog, "filename", filename)
  if gtk:get(dialog, "run") = 1 then
    filename = gtk:get(dialog, "filename")
  else
    filename = ""
  end if
  set(dialog, "hide")
  
  return filename
end function

global function ui_message_box_yes_no(sequence title, sequence message)
  return 0
end function

global function ui_message_box_yes_no_cancel(sequence title, sequence message)
  return 0
end function

global function ui_message_box_error(sequence title, sequence message)
  return 0
end function






--------------------------------------------------

constant wee_conf_file = getenv("HOME") & "/.wee_conf"

wee_init()

x_size = 500 y_size = 600

load_wee_conf(wee_conf_file)


gtk_proc("gtk_window_resize", {P,I,I}, {win, x_size, y_size})



constant cmdline = command_line()

if length(cmdline) > 2 then
  open_file(cmdline[3], 0)
else
  new_file()
end if


show_all(win)
main()

save_wee_conf(wee_conf_file)


