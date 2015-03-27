-- ui_gtk.e

-- A huge thanks to Irv Mullins for making EuGTK, which made the Linux 
-- and OSX GTK ports painless.  Thanks to Irv for:
--  * focus-in-event for checking modified tabs
--  * current folder for load and save dialogs
--  * window placement taking window theme into account 
--  * file dialog filters
--  * menu accelerator appearance
--  * new subs dialog

-- Changes:
-- fix intermittent hang on quit (found it, caused by putting the program in the
-- background using Ctrl-Z and "bg".  It blocks on doing something to console
-- before exiting, so need to do "fg" to unfreeze and exit normally.)

-- font seems to be ok on OSX now, 
-- needed to strip spaces and "bold", "italic", from the font name.

-- Todo:
-- fix modifier keys not working on OS X (might be ok now using gtk accelerators)
--   menu accelerator labels show up as "-/-" on OS X
-- investigate if widgets need to be Destroy'd


public include std/machine.e
public include std/error.e
include std/regex.e
include std/sort.e
include scintilla.e
include EuGTK/GtkEngine.e
include EuGTK/events.e
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



constant cmdline = command_line()

wee_init() -- initialize global variables

x_pos = 100    y_pos = 50
x_size = 500 y_size = 600

constant wee_conf_file = getenv("HOME") & "/.wee_conf"
load_wee_conf(wee_conf_file)


-- helper function for setting multiple properties at once
function sets(atom handle, sequence properties)
    sequence p
    for i = 1 to length(properties) do
	p = properties[i]
	if length(p) = 2 then
	   set(handle, p[1], p[2])
	elsif length(p) = 3 then
	   set(handle, p[1], p[2], p[3])
	elsif length(p) = 4 then
	   set(handle, p[1], p[2], p[3], p[4])
	elsif length(p) = 5 then
	   set(handle, p[1], p[2], p[3], p[4], p[5])
	elsif length(p) = 6 then
	   set(handle, p[1], p[2], p[3], p[4], p[5], p[6])
	else
	    crash("unhandled property length")
	end if
    end for
    return handle
end function


--------------------------------------------------
-- Find dialog

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

function OldViewSubs() 
    sequence text, word, subs, tmp
    integer pos, result
    atom dialog, scroll, list, content, row, lbl

    text = get_edit_text()
    pos = get_pos()
    word = word_pos(text, pos)
    tmp = get_subroutines(parse(text, file_name))
    word = word[1]
    
    subs = repeat(0, floor(length(tmp)/2))
    for i = 1 to length(subs) do
        subs[i] = {tmp[i*2-1], tmp[i*2]}
    end for
    if sorted_subs then
        subs = sort(subs)
    end if
    
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
    for i = 1 to length(subs) do
	lbl = create(GtkLabel, subs[i][1])
	set(lbl, "halign", GTK_ALIGN_START)
	set(list, "insert", lbl, -1)
	if equal(subs[i][1], word) then
	    row = gtk:get(list, "row at index", i-1)
	    set(list, "select row", row)
	end if
    end for

    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	row = gtk:get(list, "selected row")
        --result = gtk:get(row, "index") -- doesn't work?
	for i = 1 to length(subs) do
	    if row = gtk:get(list, "row at index", i-1) then
		word = subs[i][1]
		pos = subs[i][2]
		goto_pos(pos, length(word))
		exit
	    end if
	end for
    end if
    hide(dialog)
    return 0
end function

function RowActivated(atom ctl, atom path, atom col, atom dialog)
    set(dialog, "response", GTK_RESPONSE_OK)
    return 0
end function
constant row_activated = call_back(routine_id("RowActivated"))

-- contributed by Irv
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

    object routines = {}, data
    for i = 1 to length(subs) by 2 do
	routines = append(routines,{subs[i],subs[i+1]})
    end for
    if sorted_subs then
        routines = sort(routines)
    end if

    list = create(GtkTreeView)
    add(scroll, list)
    object store = create(GtkListStore,{gSTR,gINT})
    set(list,"model",store)
    object col1 = create(GtkTreeViewColumn)
    object rend1 = create(GtkCellRendererText)
    add(col1,rend1)
    set(col1,"add attribute",rend1,"text",1)
    set(col1,"sort indicator",TRUE)
    set(col1,"max width",100)
    set(col1,"title","Routine Name")
    set(list,"append columns",col1)

    object col2 = create(GtkTreeViewColumn)
    object rend2 = create(GtkCellRendererText)
    add(col2,rend2)
    set(col2,"add attribute",rend2,"text",2)
    set(list,"append columns",col2)
    set(store,"data",routines)
    
    object selection = gtk:get(list,"selection")
    set(selection,"mode",GTK_SELECTION_SINGLE)
    set(col2,"visible",FALSE)

    set(col1,"sort column id",1)
    connect(list, "row-activated", row_activated, dialog)

    show_all(dialog)
    if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
	row = gtk:get(selection,"selected row")
	data = gtk:get(store,"row data",row)
	word = data[1]
	pos = data[2]
	goto_pos(pos, length(word))
    end if
    hide(dialog)

    return 0
end function

function OptionsFont()
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

function RunColorDialog(integer color)
    object ccd = create(GtkColorChooserDialog, "Select a color", win)
    set(ccd, "use alpha", FALSE)
    set(ccd, "rgba", sprintf("#%02x%02x%02x", 
	and_bits(floor(color/{1,#100,#10000}),#FF)))
    if gtk:get(ccd, "run") = MB_OK then
	color = gtk:get(ccd, "rgba", 2)
	color = floor(and_bits(color, #FF0000) / #10000) +
	    and_bits(color, #FF00) + and_bits(color, #FF) * #10000
    end if
    set(ccd, "hide")
    return color
end function

function ColorButton(atom ctl, atom w)
    if w = 1 then
	normal_color = RunColorDialog(normal_color)
    elsif w = 2 then
	background_color = RunColorDialog(background_color)
    elsif w = 3 then
	comment_color = RunColorDialog(comment_color)
    elsif w = 4 then
	string_color = RunColorDialog(string_color)
    elsif w = 5 then
	keyword_color = RunColorDialog(keyword_color)
    elsif w = 6 then
	builtin_color = RunColorDialog(builtin_color)
    elsif w = 7 then
	number_color = RunColorDialog(number_color)
    elsif w = 8 then
	bracelight_color = RunColorDialog(bracelight_color)
    elsif w = 9 then
	linenumber_color = RunColorDialog(linenumber_color)
    end if
    reinit_all_edits()
    return 0
end function

constant color_button = call_back(routine_id("ColorButton"))

function OptionsColors()
    atom dialog, vbox
    
    dialog = create(GtkDialog)
    set(dialog, "default size", 200, 300)
    set(dialog, "add button", "gtk-close", GTK_RESPONSE_CLOSE)
    set(dialog, "transient for", win)
    set(dialog, "title", "Colors")
    set(dialog, "default response", GTK_RESPONSE_OK)
    set(dialog, "modal", TRUE)
    
    vbox = create(GtkBox, VERTICAL)
    add(gtk:get(dialog, "content area"), vbox)
    
    pack(vbox, create(GtkButton, "Normal", color_button, 1))
    pack(vbox, create(GtkButton, "Background", color_button, 2))
    pack(vbox, create(GtkButton, "Comment", color_button, 3))
    pack(vbox, create(GtkButton, "String", color_button, 4))
    pack(vbox, create(GtkButton, "Keyword", color_button, 5))
    pack(vbox, create(GtkButton, "Built-in", color_button, 6))
    pack(vbox, create(GtkButton, "Number", color_button, 7))
    pack(vbox, create(GtkButton, "Brace Highlight", color_button, 8))
    pack(vbox, create(GtkButton, "Line Number", color_button, 9))
    
    show_all(dialog)
    set(dialog, "run")
    set(dialog, "hide")
    return 0
end function

function OptionsLineNumbers(atom handle)
    line_numbers = gtk:get(handle, "active")
    reinit_all_edits()
    return 0
end function

function OptionsSortedSubs(atom handle)
    sorted_subs = gtk:get(handle, "active")
    return 0
end function


function RunStart() 
    if save_if_modified(0) = 0 or length(file_name) = 0 then
        return 0 -- cancelled, or no name
    end if
    
    run_file_name = file_name
    reset_ex_err()
    -- TODO: make configurable
    chdir(dirname(run_file_name))
    system("eui " & run_file_name)
    --system(cmdline[1] & " " & run_file_name)
    check_ex_err()
    return 0
end function

function RunStartWithArguments()
    if save_if_modified(0) = 0 or length(file_name) = 0 then
        return 0 -- cancelled, or no name
    end if
    if length(get_tab_arguments()) = 0 then
        RunSetArguments()
    end if
    
    run_file_name = file_name
    reset_ex_err()
    -- TODO: make configurable
    chdir(dirname(run_file_name))
    system("eui " & run_file_name & " " & get_tab_arguments())
    --system(cmdline[1] & " " & run_file_name)
    check_ex_err()
    return 0
end function

function RunSetArguments()
    atom dialog, content, text_entry
    
    dialog = create(GtkDialog)
    --set(dialog, "default size", 200, 200)
    set(dialog, "add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT)
    set(dialog, "add button", "gtk-ok", GTK_RESPONSE_OK)
    set(dialog, "transient for", win)
    set(dialog, "title", "Arguments")
    set(dialog, "default response", GTK_RESPONSE_OK)
    set(dialog, "modal", TRUE)
    content = gtk:get(dialog, "content area")
    
    text_entry = create(GtkEntry)
    add(content, text_entry)
    set(text_entry, "activates default", TRUE)
    set(text_entry, "text", get_tab_arguments())

    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	set_tab_arguments(gtk:get(text_entry, "text"))
    end if
    hide(dialog)
    return 0
end function

function RunConvert(atom ctl)
    object lbl = gtk:get(ctl, "label")

    if save_if_modified(0) = 0 or length(file_name) = 0 then
        return 0 -- cancelled, or no name
    end if
    
    chdir(dirname(file_name))
    if equal(lbl, "Bind") then
	system("eubind " & file_name)
    elsif equal(lbl, "Shroud") then
	system("eushroud " & file_name)
    elsif equal(lbl, "Translate") then
	system("euc " & file_name)
    end if
    return 0
end function

function HelpAbout()
  set(about_dialog, "run")
  set(about_dialog, "hide")
  return 0
end function

function HelpTutorial()
  open_tutorial()
  return 0
end function

function HelpHelp()
  context_help()
  return 0
end function

--------------------------------------
-- functions called from window events

-- this gets called when window is moved or resized
function configure_event(atom w, atom s)
  atom left_margin, top_margin -- not used, just for show
  {left_margin, top_margin, x_size, y_size} =
    gtk:get(gtk:get(w, "window"), "geometry")
  {x_pos, y_pos} = gtk:get(w, "position")
  --? {x_pos, y_pos, x_size, y_size, left_margin, top_margin}
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
    --? {nb, page, page_num}
    select_tab(page_num + 1)
    return 0
end function

function window_set_focus(atom widget)
    --printf(1, "window set focus %d\n", {widget})
    check_externally_modified_tabs()
    check_ex_err()
    return 0
end function


function accelerator_parse(sequence key)
  atom x
  x = allocate(8)
  gtk_proc("gtk_accelerator_parse", {P,P,P}, {allocate_string(key, 1), x, x+4})
  key = peek4u({x,2})
  free(x)
  return key
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
connect(win, "focus-in-event", call_back(routine_id("window_set_focus")))
set(win, "add accel group", group)
add(win, panel)

set(win, "default size", x_size, y_size)
set(win, "move", x_pos, y_pos)

constant
  about_dialog = sets(create(GtkAboutDialog), {
    {"transient for", win},
    {"program name", window_title},
    {"comments", "A small editor for Euphoria programming."},
    {"version", wee:version},
    {"authors", {author, "Powered by EuGTK http://sites.google.com/site/euphoriagtk/Home/"}},
    {"website", "https://github.com/peberlein/WEE/"},
    {"website label", "Wee on GitHub"}
  })

constant
  menubar = create(GtkMenuBar),
  menuFile = create(GtkMenuItem, "_File"),
  menuEdit = create(GtkMenuItem, "_Edit"),
  menuSearch = create(GtkMenuItem, "_Search"),
  menuView = create(GtkMenuItem, "_View"),
  menuRun = create(GtkMenuItem, "_Run"),
  menuOptions = create(GtkMenuItem, "_Options"),
  menuHelp = create(GtkMenuItem, "_Help"),
  filemenu = sets(create(GtkMenu), {{"accel group", group}}),
  editmenu = sets(create(GtkMenu), {{"accel group", group}}),
  searchmenu = sets(create(GtkMenu), {{"accel group", group}}),
  viewmenu = sets(create(GtkMenu), {{"accel group", group}}),
  runmenu = sets(create(GtkMenu), {{"accel group", group}}),
  optionsmenu = sets(create(GtkMenu), {{"accel group", group}}),
  helpmenu = sets(create(GtkMenu), {{"accel group", group}}),
  tabmenu = create(GtkMenu)

-- create a menu item with "activate" signal connected to local routine
-- and add parsed accelerator key 
function createmenuitem(sequence text, object r, object key = 0, integer check = -1)
  atom widget, x
  if check = -1 then
    if sequence(key) then
      widget = create(GtkMenuItem, text, 0, 0, {group, key})
    else
      widget = create(GtkMenuItem, text)
    end if
  else
    widget = create(GtkCheckMenuItem, text)
    set(widget, "active", check)
  end if
  if sequence(r) then
    x = routine_id(r)
    if x <= 0 then
      crash(r &" is not a visible function")
    end if
    r = call_back(x)
  end if
  connect(widget, "activate", r)
  return widget
end function

add(filemenu, {
  createmenuitem("_New", "FileNew", "<Control>N"),
  createmenuitem("_Open...", "FileOpen", "<Control>O"),
  createmenuitem("_Save", "FileSave", "<Control>S"),
  createmenuitem("Save _As...", "FileSaveAs", "<Control><Shift>S"),
  createmenuitem("_Close", "FileClose", "<Control>W"),
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
  sets(createmenuitem("Find...", "SearchFind", "F3"), {
    {"add accelerator", "activate", group} & 
    accelerator_parse("<Control>F") & {GTK_ACCEL_VISIBLE}
    }),
  createmenuitem("Replace...", "SearchReplace")
  })
set(menuSearch, "submenu", searchmenu)

add(viewmenu, {
  createmenuitem("Subroutines...", "ViewSubs", "F2"),
  createmenuitem("Declaration", "ViewDecl", "<Control>F2"),
  createmenuitem("Subroutine Arguments...", "ViewArgs", "<Shift>F2"),
  createmenuitem("Completions...", "ViewComp", "<Control>space"),
  createmenuitem("Goto Error", "ViewError", "F4")
  })
set(menuView, "submenu", viewmenu)

add(runmenu, {
  createmenuitem("Start", "RunStart", "F5"),
  createmenuitem("Start with Arguments", "RunStartWithArguments", "<Shift>F5"),
  createmenuitem("Set Arguments...", "RunSetArguments"),
  create(GtkSeparatorMenuItem),
  createmenuitem("Bind", "RunConvert"),
  createmenuitem("Shroud", "RunConvert"),
  createmenuitem("Translate", "RunConvert")
  })
set(menuRun, "submenu", runmenu)

add(optionsmenu, {
  createmenuitem("Font...", "OptionsFont"),
  createmenuitem("Line Numbers", "OptionsLineNumbers", 0, line_numbers),
  createmenuitem("Sort View Subroutines", "OptionsSortedSubs", 0, sorted_subs),
  createmenuitem("Colors...", "OptionsColors")
  })
set(menuOptions, "submenu", optionsmenu)

add(helpmenu, {
  createmenuitem("About...", "HelpAbout"),
  createmenuitem("Tutorial", "HelpTutorial"),
  createmenuitem("Help", "HelpHelp", "F1")
  })
set(menuHelp, "submenu", helpmenu)

-- popup menu for tab controls
add(tabmenu, {
  createmenuitem("Save", "FileSave"),
  createmenuitem("Save As...", "FileSaveAs"),
  createmenuitem("Close", "FileClose")
})
show_all(tabmenu)

add(menubar, {
    menuFile,
    menuEdit,
    menuSearch,
    menuView,
    menuRun,
    menuOptions,
    menuHelp})


pack(panel, menubar)

-------------------------------------------------
function PopupTabMenu(atom nb, atom event)

  if events:button(event) = 3 then
    atom x, y, lx, ly, lw, lh
    {x,y} = events:xy(event) -- get mouse coordinates
    atom allocation = allocate(4*4)
    for i = 0 to gtk:get(nb, "n_pages")-1 do
      atom pg = gtk:get(nb, "nth_page", i)
      atom lbl = gtk:get(nb, "tab_label", pg)

      gtk_func("gtk_widget_get_allocation", {P,P}, {lbl, allocation})
      {lx, ly, lw, lh} = peek4u({allocation, 4}) -- get label rect

      if x >= lx-10 and x <= lx+lw+10 then
        select_tab(i+1)
        set(tabmenu, "popup", NULL, NULL, NULL, NULL, 0, events:time(event))
        exit
      end if
    end for
    free(allocation)
  end if

  return 0
end function

constant
  notebook = create(GtkNotebook),
  status_label = create(GtkLabel, "status")

pack(panel, notebook, TRUE, TRUE)

connect(notebook, "switch-page", call_back(routine_id("notebook_switch_page")))
connect(notebook, "button-press-event", call_back(routine_id("PopupTabMenu")))

show(status_label)
set(notebook, "action widget", status_label, GTK_PACK_END)


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
  set(status_label, "text", status)
end procedure

function file_open_recent(atom handle, integer idx)
    open_recent(idx)
    return 0
end function

sequence filemenu_items = {}

global procedure ui_refresh_file_menu(sequence items)
    atom widget
    if length(filemenu_items) = 0 then
	filemenu_items &= create(GtkSeparatorMenuItem)
	add(filemenu, filemenu_items[1])
    end if
    for i = 1 to length(items) do
        if i + 1 > length(filemenu_items) then
	    widget = create(GtkMenuItem, items[i])
	    filemenu_items &= widget
	    add(filemenu, widget)
	    connect(widget, "activate", call_back(routine_id("file_open_recent")), i)
	else
	    set(filemenu_items[i+1], "label", items[i])
        end if
    end for
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
  atom editor

  editor = scintilla_new()
  ui_hedits &= editor
  init_edit(editor)
  gtk_proc("gtk_widget_show", {P}, editor)

  set(notebook, "append page", editor, create(GtkLabel, name))

  connect(editor, "sci-notify", sci_notify_cb, 0)

  return editor
end function

global procedure ui_close_tab(integer tab)
--  printf(1, "close tab\n", {})
    set(notebook, "remove page", tab-1)

    -- remove the window handle
    ui_hedits = ui_hedits[1..tab-1] & ui_hedits[tab+1..$]
end procedure


constant filter1 = sets(create(GtkFileFilter), {
    {"name", "Euphoria files"},
    {"add pattern", "*.e"},
    {"add pattern", "*.ex"},
    {"add pattern", "*.exw"}
    })

constant filter2 = sets(create(GtkFileFilter), {
    {"name", "Text files"},
    {"add mime type", "text/*"}
    })

constant filter3 = sets(create(GtkFileFilter), {
    {"name", "All files"},
    {"add pattern", "*"}
    })

global function ui_get_open_file_name()
  atom dialog
  sequence filename
  
  dialog = create(GtkFileChooserDialog, "Open...", win, GTK_FILE_CHOOSER_ACTION_OPEN)
  set(dialog, "select multiple", TRUE)
  set(dialog, "add button", "gtk-cancel", GTK_RESPONSE_CLOSE)
  set(dialog, "add button", "gtk-ok", GTK_RESPONSE_OK)
  set(dialog, "position", GTK_WIN_POS_MOUSE)
  set(dialog, "current folder", pathname(canonical_path(file_name)))
  add(dialog, {filter1, filter2, filter3})
  if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
    filename = gtk:get(dialog, "filenames")
    if length(filename) = 1 then
	-- single filename selected
        filename = filename[1]
    end if
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
  set(dialog, "current folder", pathname(canonical_path(file_name)))
  add(dialog, {filter1, filter2, filter3})
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
  Error(win, title, "", message, , GTK_BUTTONS_OK)
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
-- help window

constant helpwin = create(GtkWindow)
    set(helpwin, "transient for", win)
    set(helpwin,"title","Help")
    set(helpwin,"default size",400,400)
    set(helpwin,"border width",10)
    set(helpwin,"deletable",FALSE) --!
    set(helpwin,"resizable",FALSE)
    connect(helpwin, "delete-event", call_back(routine_id("Hide")))

constant helplbl = create(GtkLabel)
    add(helpwin,helplbl)
    connect(helplbl, "activate-link", call_back(routine_id("HelpActivateLink")))

function HelpActivateLink(atom handle, atom uri, atom userdata)
    puts(1, peek_string(uri)&"\n")
    return 1
end function

function Hide(atom handle)
    set(handle,"visible",FALSE)
    return 1
end function

function re(sequence txt, sequence rx, sequence rep)
    return regex:find_replace(regex:new(rx), txt, rep)
end function

-- FIXME this doesn't work very well
function html_to_markup(sequence html)
    html = re(html, `<a name="[A-Za-z0-9_]+">([A-Za-z0-9. ]*)</a>`, `\1`)
    html = re(html, `<p> ?`, ``)
    html = re(html, `</p>`, ``)
    html = re(html, `<font`, `<span`)
    html = re(html, `</font>`, `</span>`)
    html = re(html, `<pre class="[A-Za-z0-9_]+">`, `<tt>`)
    html = re(html, `</pre>`, `</tt>`)
    html = re(html, `<h5>`, `<big>`)
    html = re(html, `</h5>`, `</big>`)
    html = re(html, `<ol>`, `\n`)
    html = re(html, `</ol>`, ``)
    html = re(html, `<li>`, `  1. `)
    html = re(html, `</li>`, `\n`)
    html = re(html, `<ul>`, `\n`)
    html = re(html, `</ul>`, ``)
    html = re(html, `\n\n+`, `\n\n`)
    puts(1, html)
    return html
end function

global function ui_show_help(sequence html)
    set(helplbl,"markup",html_to_markup(html))
    show_all(helpwin)
    return 0
end function

global procedure ui_show_uri(sequence uri)
    --puts(1, uri & "\n")
    show_uri(uri)
end procedure

--------------------------------------------------

ui_refresh_file_menu(recent_files)

-- open files on command line
if length(cmdline) > 2 then
  for i = 3 to length(cmdline) do
    open_file(cmdline[i], 0)
  end for
else
  new_file()
end if

show_all(win)
main()
