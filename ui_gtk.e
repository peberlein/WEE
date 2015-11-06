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
include std/get.e
include std/regex.e
include std/sort.e
include scintilla.e
include EuGTK/GtkEngine.e
include EuGTK/GtkEvents.e
include wee.exw as wee
include weeicon.e

-- nifty shortcut, thanks Greg Haberek
function callback(sequence name, atom rid = routine_id(name))
    if rid = -1 then
        crash("routine '"&name&"' is not visible")
    end if
    return call_back(rid)
end function

-- check to see if 64-bit callback arguments are broken
ifdef BITS64 then
function check_callback_func(atom x)
  if x = 0 then
    crash("You need a newer 64-bit Euphoria with callback bug fix: 4.1.0 Beta 2 or later")
  end if
  return 0
end function

c_proc(define_c_proc("", callback("check_callback_func"), {C_LONG}),
       {#100000000})
end ifdef



wee_init() -- initialize global variables

x_pos = 100    y_pos = 50
x_size = 500 y_size = 600

constant wee_conf_file = getenv("HOME") & "/.wee_conf"
load_wee_conf(wee_conf_file)

-- bind the icon so it won't have to be found at runtime;
constant wee_icon = gtk_func("gdk_pixbuf_new_from_xpm_data", {P},
        {allocate_string_pointer_array(wee_xpm)})

--------------------------------------------------
-- Find dialog

constant 
    GTK_RESPONSE_FIND = 1,
    GTK_RESPONSE_REPLACE = 2,
    GTK_RESPONSE_REPLACE_ALL = 3

integer find_backward = 0

procedure find_dialog(integer replace_flag)
    atom dialog, content, row, vbox, hbox, lbl, hedit,
	find_entry, rep_entry, chk_word, chk_case, chk_backward
    integer flags, result, pos
    sequence text

    text = get_selection()
    if length(text) then
	find_phrase = text
    end if

    dialog = create(GtkDialog, {
	{"border width", 5},
	{"transient for", win},
	{"title", "Find"},
	{"modal", TRUE},
	{"add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT}})
    if replace_flag then
	set(dialog, "add button", "Replace All", GTK_RESPONSE_REPLACE_ALL)
	set(dialog, "add button", "Replace", GTK_RESPONSE_REPLACE)
    end if
    set(dialog, "add button", "Find Next", GTK_RESPONSE_FIND)
    set(dialog, "default response", GTK_RESPONSE_FIND)

    content = gtk:get(dialog, "content area")
    
    vbox = create(GtkBox, VERTICAL, 5)
    set(vbox, "margin bottom", 5)
    add(content, vbox)
    
    hbox = create(GtkBox, HORIZONTAL, 5)
    pack(vbox, hbox)
    pack(hbox, create(GtkLabel, "Find What:"))
    find_entry = create(GtkEntry, {
	{"activates default", TRUE},
	{"text", find_phrase}})
    pack(hbox, find_entry, TRUE, TRUE)

    hedit = tab_hedit()

    if replace_flag then
	set(dialog, "default response", GTK_RESPONSE_REPLACE)
        hbox = create(GtkBox, HORIZONTAL, 5)
	pack(vbox, hbox)
	pack(hbox, create(GtkLabel, "Replace With:"))
	rep_entry = create(GtkEntry, {
	    {"activates default", TRUE},
	    {"text", replace_phrase}})
	pack(hbox, rep_entry, TRUE, TRUE)
	
	-- clear the target so that first replace won't reuse old one
	SSM(hedit, SCI_SETTARGETSTART, 0)
	SSM(hedit, SCI_SETTARGETEND, 0)
    end if
    
    flags = SSM(hedit, SCI_GETSEARCHFLAGS)

    chk_word = create(GtkCheckButton, {
	{"label", "Match whole word only"},
	{"active", 0 != and_bits(flags, SCFIND_WHOLEWORD)}})
    pack(vbox, chk_word)
    
    chk_case = create(GtkCheckButton, {
	{"label", "Match case"},
	{"active", 0 != and_bits(flags, SCFIND_MATCHCASE)}})
    pack(vbox, chk_case)

    chk_backward = create(GtkCheckButton, {
	{"label", "Search backward"},
	{"active", find_backward}})
    pack(vbox, chk_backward)

    show_all(dialog)
    
    result = set(dialog, "run")
    while result != GTK_RESPONSE_DELETE_EVENT do
	flags = 0
	if gtk:get(chk_word, "active") then
	    flags += SCFIND_WHOLEWORD
	end if
	if gtk:get(chk_case, "active") then
	    flags += SCFIND_MATCHCASE
	end if
	find_backward = gtk:get(chk_backward, "active")
	
	SSM(hedit, SCI_SETSEARCHFLAGS, flags)
	find_phrase = gtk:get(find_entry, "text")

	if result = GTK_RESPONSE_FIND then
	    if search_find(find_phrase, find_backward) = 0 then
		Info(dialog, "Find", "Unable to find a match.")
	    end if
	else
	    replace_phrase = gtk:get(rep_entry, "text")
	    if result = GTK_RESPONSE_REPLACE_ALL then
		result = search_replace_all(find_phrase, replace_phrase)
		if result then
		    Info(dialog, "Replace All", sprintf("%d replacements.", {result}))
		else
		    Info(dialog, "Replace All", "Unable to find a match.")
		end if
	    else
	        result = search_replace(replace_phrase)
	        if search_find(find_phrase, find_backward) = 0 and result = 0 then
	           Info(dialog, "Replace", "Unable to find a match.") 
	        end if
	    end if
	end if
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
function EditToggleComment() toggle_comment() return 0 end function
function SearchFind() find_dialog(0) return 0 end function
function SearchFindNext() 
    if length(find_phrase) = 0 then
        return SearchFind()
    end if
    search_find(find_phrase, 0)
    return 0 
end function
function SearchFindPrevious() search_find(find_phrase, 1) return 0 end function
function SearchReplace() find_dialog(1) return 0 end function
function ViewDecl() view_declaration() return 0 end function
function ViewArgs() view_subroutine_arguments() return 0 end function
function ViewComp() view_completions() return 0 end function
function ViewError() ui_view_error() return 0 end function
function GoBack() go_back() return 0 end function

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
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"default size", 200, 400},
	{"add button", "gtk-close", GTK_RESPONSE_CLOSE},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Subroutines"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})

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
    --? {ctl, path, col, dialog}
    set(dialog, "response", GTK_RESPONSE_OK)
    return 0
end function
constant row_activated = callback("RowActivated")

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

    dialog = create(GtkDialog, {
	{"border width", 5},
	{"default size", 200, 400},
	{"add button", "gtk-close", GTK_RESPONSE_CLOSE},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Subroutines"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})

    content = gtk:get(dialog, "content area")
    scroll = create(GtkScrolledWindow)
    pack(content, scroll, TRUE, TRUE)

    object routines = subs, data
    if sorted_subs then
        routines = sort(routines)
    end if

    list = create(GtkTreeView)
    add(scroll, list)
    object store = create(GtkListStore, {gSTR, gINT})
    set(list, "model", store)
    object col1 = create(GtkTreeViewColumn)
    object rend1 = create(GtkCellRendererText)
    add(col1, rend1)
    set(col1, "add attribute", rend1, "text", 1)
    set(col1, "sort indicator", TRUE)
    set(col1, "max width", 100)
    set(col1, "title", "Routine Name")
    set(list, "append columns", col1)

    object col2 = create(GtkTreeViewColumn)
    object rend2 = create(GtkCellRendererText)
    add(col2, rend2)
    set(col2, "add attribute", rend2, "text", 2)
    set(list, "append columns", col2)
    set(store, "data", routines)
    
    object selection = gtk:get(list,"selection")
    set(selection, "mode", GTK_SELECTION_SINGLE)
    set(col2, "visible", FALSE)

    set(col1, "sort column id", 1)
    connect(list, "row-activated", row_activated, dialog)

    show_all(dialog)
    if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
	row = gtk:get(selection, "selected row")
	data = gtk:get(store, "row data", row)
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
    object ccd = create(GtkColorChooserDialog, {
	{"title", "Select a color"},
	{"transient for", win},
	{"use alpha", FALSE},
	{"rgba", sprintf("#%02x%02x%02x", 
	and_bits(floor(color/{1,#100,#10000}),#FF))}})
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

function BoldToggle(atom ctl, atom flag)
    if gtk:get(ctl, "active") then
	bold_flags = or_bits(bold_flags, flag)
    else
	bold_flags = and_bits(bold_flags, not_bits(flag))
    end if
    reinit_all_edits()
    return 0
end function

constant color_button = callback("ColorButton")
constant bold_toggle = callback("BoldToggle")

function OptionsColors()
    atom dialog, grid
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"default size", 200, 300},
	{"add button", "gtk-close", GTK_RESPONSE_CLOSE},
	{"transient for", win},
	{"title", "Colors"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})
    
    grid = create(GtkGrid, VERTICAL)
    set(grid, "margin bottom", 5)
    add(gtk:get(dialog, "content area"), grid)
    
    set(grid, {
	{"row spacing", 2},
	{"column spacing", 2},
	{"attach", create(GtkButton, "Normal", color_button, 1), 1, 2, 1, 1},
	{"attach", create(GtkButton, "Background", color_button, 2), 1, 3, 1, 1},
	{"attach", create(GtkButton, "Comment", color_button, 3), 1, 4, 1, 1},
	{"attach", create(GtkButton, "String", color_button, 4), 1, 5, 1, 1},
	{"attach", create(GtkButton, "Keyword", color_button, 5), 1, 6, 1, 1},
	{"attach", create(GtkButton, "Built-in", color_button, 6), 1, 7, 1, 1},
	{"attach", create(GtkButton, "Number", color_button, 7), 1, 8, 1, 1},
	{"attach", create(GtkButton, "Brace Highlight", color_button, 8), 1, 9, 1, 1},
	{"attach", create(GtkButton, "Line Number", color_button, 9), 1, 10, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, 1)}}, 
	    bold_toggle, 1), 2, 2, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, 2)}}, 
	    bold_toggle, 2), 2, 4, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, 4)}}, 
	    bold_toggle, 4), 2, 5, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, 8)}}, 
	    bold_toggle, 8), 2, 6, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, #10)}}, 
	    bold_toggle, #10), 2, 7, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, #20)}}, 
	    bold_toggle, #20), 2, 8, 1, 1},
	{"attach", create(GtkCheckButton, {
	    {"label", "Bold"}, {"active", 0 != and_bits(bold_flags, #40)}}, 
	    bold_toggle, #40), 2, 9, 1, 1}
	})
    
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

function OptionsLineWrap(atom handle)
    line_wrap = gtk:get(handle, "active")
    reinit_all_edits()
    return 0
end function

function OptionsReopenTabs(atom handle)
    reopen_tabs = gtk:get(handle, "active")
    return 0
end function

function OptionsCompleteStatements(atom handle)
    complete_statements = gtk:get(handle, "active")
    return 0
end function

function OptionsCompleteBraces(atom handle)
    complete_braces = gtk:get(handle, "active")
    return 0
end function

function OptionsIndent(atom handle)
    atom dialog, panel, hbox, hedit, indent_entry, tabs_entry, chk_guides, chk_usetabs
    integer indent_width, tab_width, use_tabs
    sequence val
    
    hedit = tab_hedit()
    tab_width = SSM(hedit, SCI_GETTABWIDTH)
    indent_width = SSM(hedit, SCI_GETINDENT)
    use_tabs = SSM(hedit, SCI_GETUSETABS)
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Indent"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})
	
    panel = create(GtkBox, VERTICAL, 5)
    set(panel, "margin bottom", 5)
    add(gtk:get(dialog, "content area"), panel)
    
    hbox = create(GtkBox, HORIZONTAL, 5)
    add(panel, hbox)
    add(hbox, create(GtkLabel, "Indent Size"))

    indent_entry = create(GtkEntry, {
	{"text", sprintf("%d", {indent_width})}})
    add(hbox, indent_entry)
    
    chk_guides = create(GtkCheckButton, {
	{"label", "Show indentation guides"},
	{"active", indentation_guides}})
    pack(panel, chk_guides)

    chk_usetabs = create(GtkCheckButton, {
	{"label", "Use tabs in indentation"},
	{"active", use_tabs}})
    pack(panel, chk_usetabs)

    hbox = create(GtkBox, HORIZONTAL, 5)
    add(panel, hbox)
    add(hbox, create(GtkLabel, "Tab Size"))
    
    tabs_entry = create(GtkEntry, {
	{"text", sprintf("%d", {tab_width})}})
    add(hbox, tabs_entry)

    show_all(dialog)
    while set(dialog, "run") = GTK_RESPONSE_OK do
	
	val = value(gtk:get(indent_entry, "text"))
	if val[1] = 0 and integer(val[2]) and val[2] >= 1 and val[2] <= 8 then
	    indent_width = val[2]
	else
	    set(indent_entry, "grab focus")
	    continue
	end if

	val = value(gtk:get(tabs_entry, "text"))
	if val[1] = 0 and integer(val[2]) and val[2] >= 1 and val[2] <= 8 then
	    tab_width = val[2]
	else
	    set(tabs_entry, "grab focus")
	    continue
	end if
		    
	use_tabs = gtk:get(chk_usetabs, "active")
	indentation_guides = gtk:get(chk_guides, "active")
	
	SSM(hedit, SCI_SETTABWIDTH, tab_width)
	SSM(hedit, SCI_SETINDENT, indent_width)
	SSM(hedit, SCI_SETUSETABS, use_tabs)
	reinit_all_edits()
	exit

    end while
    hide(dialog)
    return 0
end function

function RunStart(atom ctl)
    object lbl = gtk:get(ctl, "label")
    sequence cmd

    if save_if_modified(0) = 0 or length(file_name) = 0 then
        return 0 -- cancelled, or no name
    end if

    cmd = terminal_program
    if length(cmd) and cmd[$] != ' ' then
        cmd &= ' '
    end if
    
    run_file_name = file_name
    chdir(dirname(run_file_name))
    if match("Start", lbl) = 1 then
	reset_ex_err()
	cmd &= get_eu_bin(interpreter) & ' ' & quote_spaces(file_name)
	if not equal(lbl, "Start") then -- with arguments
	    if length(get_tab_arguments()) = 0 then
		if RunSetArguments() then
		    return 0
		end if
	    end if
	    cmd &= ' ' & get_tab_arguments()
	end if
	system(cmd)
	check_ex_err()
    elsif equal(lbl, "Bind") then
	system(cmd & get_eu_bin("eubind") & ' ' & quote_spaces(file_name))
    elsif equal(lbl, "Shroud") then
	system(cmd & get_eu_bin("eushroud") & ' ' & quote_spaces(file_name))
    elsif equal(lbl, "Translate and Compile") then
	system(cmd & get_eu_bin("euc") & ' ' & quote_spaces(file_name))
    else
	crash("Unable to get menu label")
    end if
    
    return 0
end function

function RunSetArguments()
    atom dialog, content, text_entry, result = -1
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Arguments"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})
    content = gtk:get(dialog, "content area")
    
    text_entry = create(GtkEntry, {
	{"activates default", TRUE},
	{"text", get_tab_arguments()},
	{"margin bottom", 5}})
    add(content, text_entry)

    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	set_tab_arguments(gtk:get(text_entry, "text"))
	result = 0
    end if
    hide(dialog)
    return result
end function

function ChooseInterpreter(atom ctl, atom text_entry)
  atom dialog
  sequence filenames

  dialog = create(GtkFileChooserDialog, {
    {"title", "Open..."},
    {"transient for", win},
    {"action", GTK_FILE_CHOOSER_ACTION_OPEN},
    {"add button", "gtk-cancel", GTK_RESPONSE_CLOSE},
    {"add button", "gtk-ok", GTK_RESPONSE_OK},
    {"position", GTK_WIN_POS_MOUSE},
    {"current folder", pathname(canonical_path(interpreter))}})

  if gtk:get(dialog, "run") = GTK_RESPONSE_OK then
    set(text_entry, "prepend text", gtk:get(dialog, "filename"))
    set(text_entry, "active", 1)
  end if
  set(dialog, "hide")
  return 0
end function

constant choose_interpreter = callback("ChooseInterpreter")

function RunSetInterpreter()
    atom dialog, text_entry, panel, row
    sequence interpreters = get_interpreters()
    integer index
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Choose Interpreter"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})

    panel = create(GtkBox, VERTICAL, 5)
    set(panel, "margin bottom", 5)
    add(gtk:get(dialog, "content area"), panel)
    
    pack(panel, create(GtkLabel,
`Enter an interpreter to use to run programs, or select one from the list.
Leave blank to use the default first item in the list.`))

    row = create(GtkBox, HORIZONTAL, 5)
    pack(panel, row, TRUE)

    text_entry = create(GtkComboBoxEntry, {
	{"margin bottom", 5},
	{"activates default", TRUE}})
    pack(row, text_entry, TRUE, TRUE)
    if length(interpreters) then
	add(text_entry, interpreters)
	index = find(interpreter, interpreters)
	if index then
	    set(text_entry, "active", index)
	end if
    end if
    pack(row, create(GtkButton, "...", choose_interpreter, text_entry))
    
    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	interpreter = gtk:get(text_entry, "active text")
    end if
    hide(dialog)
    return 0
end function

constant terminals = {
    "x-terminal-emulator -e",
    "urxvt -e",
    "rxvt -e",
    "terminator -e",
    "Eterm -e",
    "aterm -e",
    "xterm -e",
    "gnome-terminal -x",
    "roxterm -e",
    "xfce4-terminal -x",
    "termite -e",
    "lxterminal -e",
    "mate-terminal -e",
    "terminology -e"}

function RunSetTerminal()
    atom dialog, text_entry, panel
    sequence text
    integer n = 0

    dialog = create(GtkDialog, {
	{"border width", 5},
	{"add button", "gtk-close", GTK_RESPONSE_DELETE_EVENT},
	{"add button", "gtk-ok", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "Choose Terminal Emulator"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})

    panel = create(GtkBox, VERTICAL, 5)
    set(panel, "margin bottom", 5)
    add(gtk:get(dialog, "content area"), panel)

    pack(panel, create(GtkLabel,
`Enter a terminal emulator to use to run programs, or select one
from the list. Leave blank to run in parent terminal.`))
    
    text_entry = create(GtkComboBoxEntry, {
	{"margin bottom", 5},
	{"activates default", TRUE}})
    pack(panel, text_entry)
    for i = 1 to length(terminals) do
        if system_exec("which " & terminals[i] & " >/dev/null 2>&1") = 0 then
	    text = terminals[i]
	    add(text_entry, {text})
	    n += 1
	    if equal(text, terminal_program) then
	        set(text_entry, "active", n)
	    end if
        end if
    end for
    if length(terminal_program) and gtk:get(text_entry, "active") = 0 then
	set(text_entry, "prepend text", terminal_program)
	set(text_entry, "active", 1)
    end if

    show_all(dialog)
    if set(dialog, "run") = GTK_RESPONSE_OK then
	terminal_program = gtk:get(text_entry, "active text")
    end if
    hide(dialog)
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

function window_set_focus(atom widget)
    check_externally_modified_tabs()
    check_ex_err()
    return 0
end function

-------------------------------------------------------------

constant 
  group = create(GtkAccelGroup),
  win = create(GtkWindow, {
    {"border width", 0},
    {"add accel group", group},
    {"default size", x_size, y_size},
    {"move", x_pos, y_pos}}),
  panel = create(GtkBox, VERTICAL)

gtk_func("gtk_window_set_icon", {P,P}, {win, wee_icon})
connect(win, "destroy", main_quit)
connect(win, "configure-event", callback("configure_event"))
connect(win, "delete-event", callback("delete_event"))
connect(win, "focus-in-event", callback("window_set_focus"))
add(win, panel)

constant
  about_dialog = create(GtkAboutDialog, {
    {"transient for", win},
    {"name", "about:dialog"},
    {"program name", window_title},
    {"comments", "A small editor for Euphoria programming."},
    {"version", wee:version},
    {"authors", {author, "EuGTK by Irv Mullins http://sites.google.com/site/euphoriagtk/Home/"}},
    {"website", "https://github.com/peberlein/WEE/"},
    {"website label", "Wee on GitHub"},
    {"logo", wee_icon}
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
  filemenu = create(GtkMenu, {{"accel group", group}}),
  editmenu = create(GtkMenu, {{"accel group", group}}),
  searchmenu = create(GtkMenu, {{"accel group", group}}),
  viewmenu = create(GtkMenu, {{"accel group", group}}),
  runmenu = create(GtkMenu, {{"accel group", group}}),
  optionsmenu = create(GtkMenu, {{"accel group", group}}),
  helpmenu = create(GtkMenu, {{"accel group", group}}),
  chooseinterpreter_menu = create(GtkMenu),
  tabmenu = create(GtkMenu)

-- create a menu item with "activate" signal connected to local routine
-- and add parsed accelerator key 
function createmenuitem(sequence text, object r, object key = 0, object check = -1)
  atom widget, x
  if equal(check, -1) or sequence(check) then
    if sequence(key) then
      widget = create(GtkMenuItem, text, 0, 0, {group, key})
      if sequence(check) then
        -- check could be a second accelerator
        set(widget, "add accelerator", {group, check})
      end if
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
  createmenuitem("Select _All", "EditSelectAll", "<Control>A"),
  create(GtkSeparatorMenuItem),
  createmenuitem("Toggle Comment", "EditToggleComment", "<Control>M")
  })
set(menuEdit, "submenu", editmenu)

add(searchmenu, {
  createmenuitem("Find...", "SearchFind", "<Control>F", "<Control>F3"),
  createmenuitem("Find Next", "SearchFindNext", "<Control>G", "F3"),
  createmenuitem("Find Previous", "SearchFindPrevious", "<Control><Shift>G", "<Shift>F3"),
  createmenuitem("Replace...", "SearchReplace", "<Control>R")
  })
set(menuSearch, "submenu", searchmenu)

add(viewmenu, {
  createmenuitem("Subroutines...", "ViewSubs", "F2"),
  createmenuitem("Declaration", "ViewDecl", "<Control>D", "<Control>F2"),
  createmenuitem("Subroutine Arguments...", "ViewArgs", "<Shift>F2"),
  createmenuitem("Completions...", "ViewComp", "<Control>space"),
  createmenuitem("Goto Error", "ViewError", "F4"),
  createmenuitem("Go Back", "GoBack", "Escape")
  })
set(menuView, "submenu", viewmenu)

add(runmenu, {
  createmenuitem("Start", "RunStart", "F5"),
  createmenuitem("Start with Arguments", "RunStart", "<Shift>F5"),
  createmenuitem("Set Arguments...", "RunSetArguments"),
  createmenuitem("Set Interpreter...", "RunSetInterpreter"),
  createmenuitem("Set Terminal Emulator...", "RunSetTerminal"),
  create(GtkSeparatorMenuItem),
  createmenuitem("Bind", "RunStart"),
  createmenuitem("Shroud", "RunStart"),
  createmenuitem("Translate and Compile", "RunStart")
  })
set(menuRun, "submenu", runmenu)

add(optionsmenu, {
  createmenuitem("Font...", "OptionsFont"),
  createmenuitem("Line Numbers", "OptionsLineNumbers", 0, line_numbers),
  createmenuitem("Sort View Subroutines", "OptionsSortedSubs", 0, sorted_subs),
  createmenuitem("Colors...", "OptionsColors"),
  createmenuitem("Line Wrap", "OptionsLineWrap", 0, line_wrap),
  createmenuitem("Reopen Tabs Next Time", "OptionsReopenTabs", 0, reopen_tabs),
  createmenuitem("Complete Statements", "OptionsCompleteStatements", 0, complete_statements),
  createmenuitem("Complete Braces", "OptionsCompleteBraces", 0, complete_braces),
  createmenuitem("Indent...", "OptionsIndent")
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
function NotebookSwitchPage(atom nb, atom page, atom page_num)
    select_tab(page_num + 1)
    return 0
end function

function NotebookButtonPressEvent(atom nb, atom event)
  integer button = events:button(event)

  -- right click or middle click
  if button = 3 or button = 2 then
    atom x, y, lx, ly, lw, lh
    {x,y} = events:xy(event) -- get mouse coordinates
    atom allocation = allocate(4*4)
    for i = 1 to gtk:get(nb, "n_pages") do
      atom pg = gtk:get(nb, "nth_page", i-1)
      atom lbl = gtk:get(nb, "tab_label", pg)

      gtk_func("gtk_widget_get_allocation", {P,P}, {lbl, allocation})
      {lx, ly, lw, lh} = peek4u({allocation, 4}) -- get label rect

      if x >= lx-10 and x <= lx+lw+10 then
        if button = 3 then -- right click
          select_tab(i)
          set(tabmenu, "popup", NULL, NULL, NULL, NULL, 0, events:time(event))
	elsif button = 2 then -- middle click
	  select_tab(i)
	  close_tab()
        end if
        exit
      end if
    end for
    free(allocation)
    return 1
  end if

  return 0
end function

-- switch tabs when mouse wheel is scrolled
function NotebookScrollEvent(atom nb, atom event)
  integer dir = events:scroll_dir(event)
  if dir = 1 then
    select_tab(get_next_tab())
  elsif dir = 0 then
    select_tab(get_prev_tab())
  end if
  return 0
end function

-- detect <Control>Tab and <Shift><Control>Tab
function NotebookKeyPressEvent(atom nb, atom event)
    integer mod = events:state(event)
    if key(event) = -9 and and_bits(mod, GDK_CONTROL_MASK) then
	if and_bits(mod, GDK_SHIFT_MASK) then
	    select_tab(get_prev_tab())
	else
	    select_tab(get_next_tab())
	end if
	return 1
    end if
    return 0
end function


constant
  status_label = create(GtkLabel, "status"),
  notebook = create(GtkNotebook, {
    {"add_events", GDK_SCROLL_MASK},
    {"scrollable", TRUE},
    {"show border", FALSE}, -- seems to have opposite effect?
    {"action widget", status_label, GTK_PACK_END}})

pack(panel, notebook, TRUE, TRUE)
show(status_label)

connect(notebook, "switch-page", callback("NotebookSwitchPage"))
connect(notebook, "button-press-event", callback("NotebookButtonPressEvent"))
connect(notebook, "scroll-event", callback("NotebookScrollEvent"))
connect(notebook, "key-press-event", callback("NotebookKeyPressEvent"))

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
    if length(filemenu_items) = 0 and length(items) != 0 then
	add(filemenu, create(GtkSeparatorMenuItem))
    end if
    for i = 1 to length(items) do
        if i > length(filemenu_items) then
	    widget = create(GtkMenuItem, items[i])
	    set(widget, "use underline", 0)
	    filemenu_items &= widget
	    add(filemenu, widget)
	    connect(widget, "activate", callback("file_open_recent"), i)
	else
	    set(filemenu_items[i], "label", items[i])
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

constant sci_notify_cb = callback("sci_notify")

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
    set(notebook, "remove page", tab-1)

    -- remove the window handle
    ui_hedits = ui_hedits[1..tab-1] & ui_hedits[tab+1..$]
end procedure


constant filter1 = create(GtkFileFilter, {
    {"name", "Euphoria files"},
    {"add pattern", "*.e"},
    {"add pattern", "*.ex"},
    {"add pattern", "*.exw"},
    {"add pattern", "*.ew"},
    {"add pattern", "ex.err"},
    {"add pattern", "eu.cfg"}})

constant filter2 = create(GtkFileFilter, {
    {"name", "Text files"},
    {"add mime type", "text/*"}})

constant filter3 = create(GtkFileFilter, {
    {"name", "All files"},
    {"add pattern", "*"}})

global function ui_get_open_file_name()
  atom dialog
  sequence filename
  
  dialog = create(GtkFileChooserDialog, {
    {"title", "Open..."},
    {"transient for", win},
    {"action", GTK_FILE_CHOOSER_ACTION_OPEN},
    {"select multiple", TRUE},
    {"add button", "gtk-cancel", GTK_RESPONSE_CLOSE},
    {"add button", "gtk-ok", GTK_RESPONSE_OK},
    {"position", GTK_WIN_POS_MOUSE},
    {"current folder", pathname(canonical_path(file_name))}})
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
  
  dialog = create(GtkFileChooserDialog, {
    {"title", "Save As..."},
    {"transient for", win},
    {"action", GTK_FILE_CHOOSER_ACTION_SAVE},
    {"select multiple", FALSE},
    {"do overwrite confirmation", TRUE},
    {"add button", "gtk-cancel", GTK_RESPONSE_CLOSE},
    {"add button", "gtk-ok", GTK_RESPONSE_OK},
    {"filename", filename},
    {"position", GTK_WIN_POS_MOUSE},
    {"current folder", pathname(canonical_path(file_name))}})
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
  dialog = create(GtkMessageDialog, {
    {"title", title},
    {"transient for", win},
    {"add button", "gtk-cancel", -1},
    {"add button", "gtk-no", 0},
    {"add button", "gtk-yes", 1},
    {"transient for", win},
    {"destroy with parent", TRUE},
    {"text", message},
    {"position", GTK_WIN_POS_CENTER_ON_PARENT}})
  
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
    
    dialog = create(GtkDialog, {
	{"border width", 5},
	{"default size", 200, 400},
	{"add button", "gtk-close", GTK_RESPONSE_CLOSE},
	{"add button", "Open Ex.Err", GTK_RESPONSE_YES},
	{"add button", "Goto Error", GTK_RESPONSE_OK},
	{"transient for", win},
	{"title", "View Error"},
	{"default response", GTK_RESPONSE_OK},
	{"modal", TRUE}})
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

constant helpwin = create(GtkWindow, {
	{"transient for", win},
	{"title", "Help"},
	{"default size", 400, 400},
	{"border width", 10},
	{"deletable", FALSE}, --!
	{"resizable", FALSE}})
connect(helpwin, "delete-event", callback("Hide"))

constant helplbl = create(GtkLabel)
    add(helpwin,helplbl)
    connect(helplbl, "activate-link", callback("HelpActivateLink"))

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
    show_uri(uri)
end procedure

--------------------------------------------------

ui_refresh_file_menu(recent_files)

-- open files from last time and on command line
open_tabs()

show_all(win)
main()
