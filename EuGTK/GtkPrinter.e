------------------
namespace printer
------------------
constant version = "4.9.4"

include GtkEngine.e
include std/datetime.e

--------------------------------------------------------------------------------
-- This version handles most common printing needs, but it will not yet respect
-- 'marked up' a.k.a. 'rich' text, i.e. text with colors and styles such as 
-- set by test59. It just prints them as plain text. 
-- However, it DOES print text marked up with GTK's HTML subset, so you can use
-- <b>, <i>, <u>, <span ... etc. in your printouts!
--------------------------------------------------------------------------------
-- The following exported variables can be modified before calling the 
-- print routines;

public object header = "[1]\n"

public object subheader = 0

public object footer = "<small>\n<i>Printed by EuGTK [8] on [9]'s computer</i></small>"

export integer 
    n_pages = 0, -- number of pages to print (0=all)
    n_copies = 1,
    collate = FALSE,
    duplex = 0,
    number_up = 1,
    number_up_layout = 1,
    units = GTK_UNIT_INCH,
    use_line_numbers = TRUE,
    use_color = TRUE, -- print eu comments in red if true
    lines_per_page = 60,
    wrap_at = 0,
    track_status = TRUE, 
    show_progress = TRUE, -- enable the built-in progressbar
    embed_page_setup = FALSE,
    orientation = 0,
    order = 0, 
    confirm = FALSE,
    sourcecode = TRUE,
    use_full_page = FALSE, -- ignore margins
    has_selection = FALSE,
    support_selection = FALSE,
    quality = GTK_PRINT_QUALITY_DRAFT,
    action = GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG

export atom 
    scale = 100,
    top_margin = 0.25, -- in inch units 
    left_margin = 0.25,
    right_margin = 0.25,
    bottom_margin = 0.25,
    parent = 0,

    signal_status_changed = call_back(routine_id("show_status")),
    signal_begin_print = call_back(routine_id("begin_print")),
    signal_draw_page = call_back(routine_id("draw_page")),
    signal_end_print = call_back(routine_id("end_print")),
    signal_request_page_setup = 0,
    signal_done = 0,
    signal_ready = 0,
    signal_got_page_size = 0

export object
    name = 0,
    font = "Ubuntu Mono 8",
    jobname = 0,
    settings_file = 0,
    setup_file = 0,
    export_file = 0,
    page_ranges = 0,
    page_set = GTK_PAGE_SET_ALL,
    custom_tab_hook = 0,
    custom_tab_label = 0,
    custom_tab_func = 0

ifdef WINDOWS then font = "Courier New 16" end ifdef

export object 
    line_number_format = "[:4] []\n",   -- controls line # format AND code line!
    paper_name = "na_letter",           -- 8.5x11.0"
    tabs = "  ",                        -- replace tab chars with 2 spaces 
    file_name = 0,
    short_name = 0,
    page_title = 0,
    sub_title = 0

export atom 
    progress = create(GtkProgressBar),
    settings = create(GtkPrintSettings)

--For use in header and footer;
-- 1 = page title (for first page)
-- 2 = sub title (for subsequent pages - leave null to use page title (1) on all pgs)
-- 3 = file name 
-- 4 = short name (file name w/o path)
-- 5 = current page number
-- 6 = n_pages printed e.g. pg 1 of n
-- 7 = n_copies requested
-- 8 = today's date in date_format
-- 9 = user name
--10 = user's real name
--11 = font name used for this print job
--12 = file length
--13 = file timestamp
--14 = exported filename

-- use date and time formats in std/datetime.e;
export sequence date_format = "%A, %B %d %Y %l:%M %p"

sequence user
ifdef WINDOWS then
    user = "User"
elsedef
    user = proper(getenv("USER"))
end ifdef

-- for local use;
atom fontdesc
integer filesize = 0
object timestamp = 0
sequence text
sequence today  = datetime:format(datetime:now(),date_format)

------------------------------------------------------------------------
export function PrintFile(object f=0, object x=0)
------------------------------------------------------------------------

if string(f) and string(x) then 
    page_title = f
    file_name = canonical_path(x)
    text = read_file(file_name)
    text = process_text(text)
    timestamp = file_timestamp(file_name)
    filesize = file_length(file_name)
    short_name = filebase(file_name)
    setup_printer()
    return 1
end if

if string(f) and atom(x) and x = 0 then 
    f = canonical_path(f)
    file_name = f
    timestamp = file_timestamp(f)
    filesize = file_length(f)
    short_name = filebase(f)
    page_title = filename(f)
    text = read_file(f)
    text = process_text(text)
    setup_printer()
    return 1
end if

if string(f) and atom(x) and x < 100 then
    page_title = f
    short_name = f
    file_name = f
    text = read_file(x)
    text = process_text(text)
    setup_printer()
    return 1
end if

if atom(f) and atom(x) and x < 101 then 
    text = read_file(x)
    text = process_text(text)
    if atom(file_name) then
        file_name = ""
    end if
    if atom(short_name) then
        short_name = ""
    end if
    if atom(page_title) then
        page_title = ""
    end if
    setup_printer()
    return 1
end if

if atom(f) and atom(x) then
    x = unpack(x) 
    x = canonical_path(x) 
    file_name = x
    short_name = filebase(x)
    page_title = filename(x)
    text = read_file(x)
    text = process_text(text)
    setup_printer()
    return 1
end if

return 1
end function
export constant print_file = call_back(routine_id("PrintFile"))

------------------------------------------------------------------------
export function PrintText(object f=0, object x=0)
------------------------------------------------------------------------

if string(f) and string(x) then
    page_title = f 
    text = process_text(x) 
    setup_printer()
    return 1
end if

if atom(f) and string(x) then
	text = process_text(x)
	setup_printer()
	return 1
end if

if atom(f) and  atom(x) then
    if atom(page_title) and page_title = 0 then
        page_title = ""
    end if
    text = unpack(x)
    text = process_text(text)
    setup_printer()
    return 1
end if

return 0
end function
export constant print_text = call_back(routine_id("PrintText"))

integer status_code
sequence status_string

-----------------------------------------------
export function show_status(atom op)
-----------------------------------------------
atom 
    fn1 = define_func("gtk_print_operation_get_status",{P},I),
    fn2 = define_func("gtk_print_operation_get_status_string",{P},S)

status_code = c_func(fn1,{op}) 
status_string = peek_string(c_func(fn2,{op}))

ifdef PRINT then display("Status [] []",{status_code,status_string}) end ifdef

if show_progress then
    set(progress,"text",status_string)
end if

ifdef DELAY then sleep(0.15) end ifdef

return 1
end function

------------------------------------------------------
export function begin_print(atom op, atom context)
------------------------------------------------------
ifdef PRINT then display("Begin printing [] pages ",length(text)) end ifdef

fontdesc = create(PangoFontDescription,font)
-- Some settings may have been changed by the user in the
-- setup dialog, so we should retrieve any we are interested
-- in at this point, before printing starts;
-- For example, modify the lines_per_page to fit different
-- paper sizes and orientations, scale, etc.
-- Figuring out how to do this is beyond my skill level :p
-- I just set the options in my program which calls the 
-- print routine.

set(op,"n pages",n_pages) 
-- important, as a new value for n_pages is computed
-- based on the length of the file being read, unless a set number
-- has been provided from the calling program.

if show_progress then -- turn on the progress dialog in the calling program
    show_all(progress) 
end if

return 1 
end function

----------------------------------------------------------------------------
export function draw_page(atom op, atom context, integer pg, atom data)
----------------------------------------------------------------------------
atom fn6 = define_func("gtk_print_context_get_cairo_context",{P},P)

atom cr = c_func(fn6,{context})
atom pl = create(PangoCairoLayout,cr)
    set(pl,"font description",fontdesc)

pg += 1 
if pg > length(text) then
    set(progress,"text","Printing complete")
    return 0
end if

if show_progress then
    set(progress,"text",sprintf("Printing page %d",pg))
    set(progress,"fraction",pg/n_pages)
end if

ifdef DELAY then sleep(0.25) end ifdef

object details = {
    page_title,sub_title,file_name,short_name,
    pg,n_pages,n_copies,
    today,user,real_name,font,filesize,timestamp,export_file
    }

object page

if atom(header) then header = "<b><u>[1]</u> page [5] of [6]</b>\n\n" end if

if pg = 1 or atom(subheader) then
    page = text:format(header,details) 
    & flatten(text[pg])
    & text:format(footer,details)
else
    page = text:format(subheader,details)
    & flatten(text[pg])
    & text:format(footer,details)
end if

    set(pl,"markup",page,length(page))
    set(pl,"update layout",cr)
    set(pl,"show layout",cr)

ifdef PRINT then printf(1,"Page %d\n",pg) end ifdef

return 1
end function

------------------------------------------------------------------------
function process_text(object txt)
------------------------------------------------------------------------
txt = split(txt,'\n')
integer comment
object a,b
object test


for i = 1 to length(txt) do -- replace chars which will confuse markup

    txt[i] = join(split(txt[i],'&'),"&amp;")
    txt[i] = join(split(txt[i],"&amp;amp;"),"&amp;")
    
    if sourcecode then
        txt[i] = join(split(txt[i],'<'),"&lt;")
        txt[i] = join(split(txt[i],'>'),"&gt;")
    end if
    
    if use_color then
        comment = match("--",txt[i]) 
        if comment then
            comment -=1 
            txt[i] = txt[i][1..comment] & "<span color='red'>" & txt[i][comment+1..$] & "</span>"
        end if
    end if
    
    if use_line_numbers then
        txt[i] =  text:format(line_number_format,{i,txt[i]})
    else
        txt[i] &= '\n'
    end if

end for

txt = breakup(txt,lines_per_page)
if n_pages = 0 then -- no selection
    n_pages = length(txt)
end if

return txt
end function

------------------------------------------------------------------------
export function end_print()
------------------------------------------------------------------------
status_string  = "Printing complete"
ifdef PRINT then display(status_string) end ifdef
return 1
end function

---------------------------------------------------------------
export function setup_printer()
---------------------------------------------------------------
atom _size = create(GtkPaperSize,paper_name)
atom err = allocate(16) err = 0
object results = 0

atom fn7 = define_func("gtk_print_operation_run",{P,I,P,P},I)
atom fn8 = define_func("gtk_print_run_page_setup_dialog",{P,P,P},P)

    set(settings,"paper size",_size,units)
    set(settings,"n copies",n_copies)
    set(settings,"collate",collate)
    set(settings,"duplex",duplex)
    set(settings,"reverse",order)
    set(settings,"scale",scale) 
    set(settings,"quality",quality)
    set(settings,"number up",number_up)
    set(settings,"number up layout",number_up_layout)

    if string(name) then
        set(settings,"printer",name)
    end if

atom setup = create(GtkPageSetup)
    set(setup,"paper size",_size)
    set(setup,"orientation",orientation)
    set(setup,"left margin",left_margin,units)
    set(setup,"right margin",right_margin,units)
    set(setup,"top margin",top_margin,units)
    set(setup,"bottom margin",bottom_margin,units)

atom printop = create(GtkPrintOperation)
    set(printop,"print settings",settings)
    set(printop,"default page setup",setup)
    set(printop,"show progress",show_progress)
    set(printop,"track print status",track_status)
    set(printop,"embed page setup",embed_page_setup)
    set(printop,"support selection",support_selection)
    set(printop,"has selection",has_selection)
    set(printop,"use full page",use_full_page)
    
    if action = GTK_PRINT_OPERATION_ACTION_EXPORT then
        export_file = canonical_path(export_file)
        set(printop,"export filename",export_file)
    end if
    
    if string(jobname) then
        set(printop,"job name",jobname)
    end if

    if custom_tab_hook != 0 then
        set(printop,"custom tab label",custom_tab_label)
        connect(printop,"create-custom-widget",custom_tab_func,printop)
        connect(printop,"custom-widget-apply",custom_tab_hook)
    end if

    connect(printop,"status-changed",signal_status_changed)
    connect(printop,"begin-print",signal_begin_print)
    connect(printop,"draw-page",signal_draw_page)
    connect(printop,"end-print",signal_end_print)
    connect(printop,"request-page-setup",signal_request_page_setup)
    connect(printop,"done",signal_done)
    connect(printop,"ready",signal_ready)
    connect(printop,"got-page-size",signal_got_page_size)

    c_func(fn7,{printop,action,parent,err}) -- start the print process;
    
    if string(settings_file) then
          get(settings,"to file",settings_file)
    end if
    if string(setup_file) then
          get(setup,"to file",setup_file)
    end if

object jobname = get(printop,"job name")
    if confirm then 
        if action =  GTK_PRINT_OPERATION_ACTION_EXPORT then
            if Question(0,"PDF Written",
                sprintf("%s\n<small>Folder: %s</small>",
                    {filename(export_file),pathname(export_file)}),
                sprintf("%s\nStatus: %d\n%s\nClick Yes to view",{jobname,status_code,status_string})
                ,,,"cups") then
            show_uri(export_file)
            end if
        else
            Info(0,"Print Job",jobname,
                sprintf("Status: %d %s",{status_code,status_string})
                ,,"cups")
        end if
    end if

    page_title = 0
    n_pages = 0
    n_copies = 1
    action = GTK_PRINT_OPERATION_ACTION_PRINT_DIALOG

return 1
end function

header = "<b><u>[1]</u></b>\n\n"

-------------------------
-- © 2015 by Irv Mullins
-------------------------
