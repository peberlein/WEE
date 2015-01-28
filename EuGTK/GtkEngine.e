
-------------
namespace gtk 
-------------

------------------------------------------------------------------------
-- This library is free software; you can redistribute it 
-- and/or modify it under the terms of the GNU Lesser General 
-- Public License as published by the Free Software Foundation;
-- either version 2 of the License, or (at your option) any later 
-- version. 

-- This library is distributed in the hope that it will be useful, 
-- but WITHOUT ANY WARRANTY; without even the implied warranty of 
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
-- See the GNU Lesser General Public License for more details. 

-- You should have received a copy of the GNU Lesser General Public 
-- License along with this library; if not, write to the Free Software 
-- Foundation, Inc., 59 Temple Pl, Suite 330, Boston, MA 02111-1307 USA
------------------------------------------------------------------------

export constant 
    version = "4.8.6",
    release = "Dec 15, 2014",
    copyright = "2014 by Irv Mullins"

public include GtkEnums.e -- enums includes most of Eu std libraries
    if not equal(gtk:version,enums:version) then
        crash("Version mismatch: GtkEnums should be version %s",{version})
   end if

include std/datetime.e 

public constant -- 'shorthand' identifiers save space in method prototypes;
  P = C_POINTER, I = C_INT,   S = E_OBJECT,  B = C_BYTE,
  D = C_DOUBLE,  F = C_FLOAT, A = E_SEQUENCE

ifdef OSX then
  constant libgtk = "/opt/local/lib/libgtk-3.dylib"
elsedef
  constant libgtk = "libgtk-3.so.0"
end ifdef

export constant GTK = open_dll(libgtk)
    if GTK = 0 then
        crash("Fatal Error: no "&libgtk&" found!")
    end if
    
constant cmd = command_line() -- used only to get program name 

if not gtk_func("gtk_init_check",{P,P},{0,0}) then -- initialize the GTK library;
    crash("GTK Library error - cannot init GTK!")
else -- success!
    gtk_proc("g_set_prgname",{S}," " & filename(cmd[2])) -- set default pgm name;
    gtk_proc("g_type_init",{}) -- initialize normal GTK types;
end if

public constant -- two special types must be initialized at run-time;
    gPIX = gtk_func("gdk_pixbuf_get_type"),
    gCOMBO = gtk_func("gtk_combo_box_get_type")

------------------------------------------------
-- obtain a lot of sometimes useful system info;
------------------------------------------------
include euphoria/info.e
   
constant os_info = os:uname()

public constant 
    major_version = gtk_func("gtk_get_major_version"),
    minor_version = gtk_func("gtk_get_minor_version"),
    micro_version = gtk_func("gtk_get_micro_version"),
    user_name = gtk_str_func("g_get_user_name"),
    real_name = gtk_str_func("g_get_real_name"),
    host_name = gtk_str_func("g_get_host_name"),
    host_addr = inet_address(),
    home_dir = gtk_str_func("g_get_home_dir"),
    temp_dir = gtk_str_func("g_get_tmp_dir"),
    curr_dir = gtk_str_func("g_get_current_dir"),
    data_dir = gtk_str_func("g_get_user_data_dir"),
    conf_dir = gtk_str_func("g_get_user_config_dir"),
    init_dir = init_curdir(),
    runt_dir = gtk_str_func("g_get_user_runtime_dir"),
    app_name = gtk_str_func("g_get_application_name"),
    prg_name = gtk_str_func("g_get_prgname"),
    os_pid = os:get_pid(), -- process id 
    os_name = os_info[1], -- e.g: Linux
    os_distro = os_info[2], -- e.g: Mint17
    os_version = os_info[3], -- e.g: 3.13.0-24-generic
    os_compiled = os_info[4],-- #46-Ubuntu SMP Thu Apr 10 19:11:08 UTC 2014
    os_architecture = os_info[5], -- e.g: x86_64
    os_shell = getenv("SHELL") -- e.g: /bin/bash

object os_term = getenv("TERM")
    if atom(os_term) then os_term = "none" end if

export constant info = { -- above in key/value form, sometimes more useful
    "version=" & version,
    "release=" & release,
    "copyright=" & copyright,
    sprintf("major=%d",major_version),
    sprintf("minor=%d",minor_version),
    sprintf("micro=%d",micro_version),
    "user_name=" & user_name,
    "real_name=" & real_name,
    "host_name=" & host_name,
    "host_addr=" & host_addr,
    "home_dir=" & home_dir,
    "temp_dir=" & temp_dir,
    "curr_dir=" & curr_dir,
    "data_dir=" & data_dir,
    "conf_dir=" & conf_dir,
    "init_dir=" & init_dir,
    "runt_dir=" & runt_dir,
    "app_name=" & app_name,
    "prg_name=" & prg_name,
    sprintf("os_pid=%g",os:get_pid()),
    "os_name=" & os_info[1],
    "os_distro=" & os_info[2],
    "os_version=" & os_info[3],
    "os_compiled=" & os_info[4],
    "os_architecture=" & os_info[5],
    "os_term=" & os_term,
    "os_shell=" & os_shell,
    "eu_version=" & version_string_short(),
    sprintf("eu_revision=%g",{version_revision()}),
    "eu_date=" & version_date()
    } 

------------------------------------------------------------------------
-- Following 3 functions simplify method calls; used mostly internally,
-- but can also be called by the programmer to execute any GTK, GDK or
-- GLib function which has not been implemented in EuGTK.
-------------------------------------------------------------------------
export function gtk_func(object name, object params={}, object values={})
-------------------------------------------------------------------------
-- syntax: result = gtk_func("gtk_*_*",{formal params},{values})
-- where formal params might be {P,P,I} (function expects Ptr, Ptr, and Int)
-- and values are the values to be inserted into the formal params before
-- the function named is called;
    for i = 1 to length(params) do
        if string(values[i]) then
            values[i] = allocate_string(values[i])
        end if
    end for 
atom fn = define_c_func(GTK,name,params,P)
if fn > 0 then
return c_func(fn,values)
else return -1
end if
end function

-----------------------------------------------------------------------------
export function gtk_str_func(object name, object params={}, object values={})
-----------------------------------------------------------------------------
-- syntax: same as above, except a string result is returned, so no 
-- conversion from a pointer is needed;
    for i = 1 to length(params) do
        if string(values[i]) then
            values[i] = allocate_string(values[i])
        end if
    end for
    object result = gtk_func(name,params,values)
    if result > 0 then
        return peek_string(result)
    else
        return -1
    end if
end function

--------------------------------------------------------------------------
export procedure gtk_proc(object name, object params={}, object values={})
--------------------------------------------------------------------------
-- syntax: same as above, but no value is returned, used to call GTK procs
    if string(values) then values = {values} end if
    for i = 1 to length(params) do
        if not atom(values) and string(values[i]) then 
            values[i] = allocate_string(values[i]) 
        end if
    end for
    if length(params) = 0 then
        c_proc(define_c_proc(GTK,name,{}))
    else
        if atom(values) then values = {values} end if
        c_proc(define_c_proc(GTK,name,params),values)
    end if
end procedure
   
 
enum NAME,PARAMS,RETVAL,VECTOR,CLASS

------------------------------------------------------------------------
public function create(integer class, 
        object p1=0, object p2=0, object p3=0, object p4=0,
        object p5=0, object p6=0, object p7=0, object p8=0)
------------------------------------------------------------------------
-- This function does the following:
-- 1. initializes the class if not already initialized,
-- 2. creates a new instance of the class (returning a handle to that instance)
-- 3. links signals to your specified Eu function (for commonly-used widgets).
-------------------------------------------------------------------------------
    
    if class = GtkStockList then -- GtkStock is not a real widget,
        return newStockList() -- also, stock items are deprecated in 3.10+
    end if
    
    if not initialized[class] then -- create a routine_id for each 'method' in class
        init(class)
    end if

    object method = lookup("new",vslice(widget[class],1),widget[class],0)
    if method[VECTOR] = -1 then -- if a 'new' method name not found,
        Error(0,,widget[class][$], -- issue an error message and die.
            sprintf("not implemented in GTK vers. %d.%d.%d",
                {major_version,minor_version,micro_version}),,2) 
        crash("\nFatal Error: %s\n************ not implemented in this GTK library version",
            {widget[class][$]})
    end if

    atom handle = 0
    object params = method[PARAMS]
    object args = {p1,p2,p3,p4,p5,p6,p7,p8}

    args = args[1..length(params)]
    
    ifdef PARAMS then display(params) end ifdef -- debug
    for i = 1 to length(params) do
        switch params[i] do
            case S then -- convert string to pointer to cstring;
                if string(args[i]) then 
                    args[i] = allocate_string(args[i]) 
                end if
        end switch
    end for

    ifdef CREATE then -- debug
        display(decode_method("Create",class,method),0) 
        display("\tArgs: []",decode_args(method,args))
        ifdef METHOD then
            display(method)
        end ifdef
    end ifdef

    if method[RETVAL] > 0 then -- it's a GTK function (routine_id is positive)
        handle = c_func(method[VECTOR],args)
    end if

    if method[RETVAL] < -1 then -- it's a Eu func (a negated routine_id)
        handle = call_func(-method[VECTOR],args)
    end if

    if handle = 0 then 
        Warn(,,"Create failed for class",widget[class][$])
        crash("Create failed for class %s",{widget[class][$]})
    end if

    switch class do -- connect a default signal for certain controls;
        case GtkButton then connect(handle,"clicked",p2,p3)
        case GtkToolButton then connect(handle,"clicked",p3,p4) 
        case GtkRadioButton then connect(handle,"toggled",p3,p4)
        case GtkRadioToolButton then connect(handle,"toggled",p3,p4)
        case GtkRadioMenuItem then connect(handle,"toggled",p3,p4)
        case GtkMenuItem then connect(handle,"select",p3,p4)
        case GtkImageMenuItem then connect(handle,"activate",p3,p4)
        case GtkCheckMenuItem then connect(handle,"toggled",p2,p3)
        case GtkFontButton then connect(handle,"font-set",p2,p3)
        case GtkStatusIcon then connect(handle,"activate",p1,p2)
        case GtkComboBoxText, GtkComboBoxEntry then connect(handle,"changed",p1,p2)
        case GtkCheckButton, GtkToggleButton, GtkToggleToolButton 
            then connect(handle,"toggled",p2,p3)    
    end switch

    ifdef CREATE then  -- debug
        display("\t[] => []\n",{widget[class][$],handle}) 
    end ifdef
    
    register(handle,class)
    return handle -- a pointer to the newly created instance
    
end function  /*create*/

------------------------------------------------------------------------
public function set(object handle, sequence property, 
    object p1=0, object p2=0, object p3=0, object p4=0,
    object p5=0, object p6=0, object p7=0, object p8=0)
------------------------------------------------------------------------
-- This routine sets a property for the given widget handle.
-- In order to work with Glade, widget names in string form
-- may be used.
-- Property is a string, p1...p8 are [optional] parameters.
-- Any parameter not supplied is set to null;
------------------------------------------------------------------------
integer class, x
object obj, name, nick, path
    
    if string(handle) then
        ifdef GLADE then
            handle = gtk_func("gtk_builder_get_object",{P,P},{builder,allocate_string(handle)})
            name = gtk_str_func("gtk_widget_get_name",{P},{handle})
        end ifdef
        nick = gtk_str_func("gtk_buildable_get_name",{P},{handle})
        path = gtk_func("gtk_widget_get_path",{P},{handle})
        x = gtk_func("gtk_widget_path_length",{P},{path})
        path = gtk_str_func("gtk_widget_path_to_string",{P},{path})
        path = split(path,' ')
        path = path[x]
        x = find('.',path)
        if x then
            path = head(path,x-1)
        end if
        x = find('(',path)
        if x then
            name = head(path,x-1)
            nick = path[x..find(')',path)]
        end if
        ifdef SET then
            display("String handle [] name [] nick []",{handle,name,nick})
            display(path)
        end ifdef
     
        class = find(name,class_name_index)
        if class = 0 then
        
        end if
        ifdef SET then display("Class []",class) end ifdef
        if not initialized[class] then
            init(class)
        end if
    else    
        class = vlookup(handle,registry,1,2,-1) -- get widget's class;
    end if
    
    if class = -1 then
        Error(,,"Cannot find property ",
            sprintf("%s for %s",{property,handle}))
        crash("Error - invalid handle")
    end if
    
    property = "set_" & lower(join(split(property,' '),'_')) -- conform;
    ifdef SET then 
        printf(1,"%s->%s\n",{widget[class][$],property}) 
    end ifdef
    
    object method = lookup_method(class,property)
  
    if atom(method) then -- method not defined, try fallback to generic Object;
        if not setProperty(handle,property[5..$],p1) then
            ifdef SET then --debug
                printf(1,"Caution: %s not found for class %d %s\n",
                    {property,class,classname(handle)})
            end ifdef
        end if
        return 0
    end if
    
 -- else, method was found;
    
        object params = method[PARAMS]

        switch method[1] do -- make life easier for a common operation;
            case "set_from_file" then p1 = canonical_path(p1)
        end switch

        object args = {handle,p1,p2,p3,p4,p5,p6,p7,p8}
        
        args = args[1..length(params)] -- match args to formal parameters;
        for i = 2 to length(args) do
            switch params[i] do
                case A then -- array of strings;
                    args[i] = allocate_string_pointer_array(args[i])
                case S then -- string;
                    if string(args[i]) then 
                        args[i] = allocate_string(args[i]) 
                    end if
                case I then -- apply patches for zero-based indexes;
                    switch method[1] do
                        case "add_attribute",
                        "set_active",
                        "set_text_column",
                        "set_pixbuf_column",
                        "set_tooltip_column",
                        "set_search_column",
                        "set_sort_column_id" then args[i]-=1
                    end switch
            end switch
        end for

        ifdef SET then -- debug
            display(decode_method("Set",class,method))  
            puts(1,"\tArgs: ") display(decode_args(method,args),
                {2,2,11,78,"%d","%2.22f",32,127,1,0})
            puts(1,"\n")
        end ifdef

        if method[VECTOR] = -1 then -- GTK doesn't know about this method!
            printf(1,`
    Warning: %s->%s call is invalid,
    ******** perhaps you need a later GTK version?
    `,{widget[class][$],property})
            return 0
        end if

        if method[RETVAL] = 0 then -- it's a GTK proc 
            c_proc(method[VECTOR],args)
            return 0
        end if

        if method[RETVAL] > 0 then -- it's a GTK func
            return c_func(method[VECTOR],args)
        end if

        if method[RETVAL] <-1 then -- it's a Eu func
            return call_func(-method[VECTOR],args)
        end if

    return 0
    
end function /*set*/

------------------------------------------------------------------------
export function get(object handle, sequence property,
    object p1=allocate(64), object p2=allocate(64), 
    object p3=allocate(64), object p4=allocate(64))
------------------------------------------------------------------------
-- This routine gets one or more values for a given property name.
-- Property name is always a string, handle is usually an atom,
-- but may sometimes be a string in order to work with Glade. 
--[optional] parameters p1...p4
-- are not often used when calling get, but are intended to store return
-- values from the GTK function. For example, get(win,"default size")
-- will return with the window width in p1, height in p2.
------------------------------------------------------------------------
integer class, x
object obj, name, nick, path
    
    if string(handle) then
        ifdef GLADE then
            handle = gtk_func("gtk_builder_get_object",{P,P},{builder,allocate_string(handle)})
            nick = gtk_str_func("gtk_buildable_get_name",{P},{handle})
        end ifdef
        name = gtk_str_func("gtk_widget_get_name",{P},{handle})
        path = gtk_func("gtk_widget_get_path",{P},{handle})
        x = gtk_func("gtk_widget_path_length",{P},{path})
        path = gtk_str_func("gtk_widget_path_to_string",{P},{path})
        path = split(path,' ')
        path = path[x]
        x = find('.',path)
        if x then
            path = head(path,x-1)
        end if
        x = find('(',path)
        if x then
            name = head(path,x-1)
            nick = path[x..find(')',path)]
        end if
        ifdef GET then
            display("String handle [] name [] nick [] ",{handle,name,nick})
            display(path)
        end ifdef
        
        class = find(name,class_name_index)
        if class = 0 then
        
        end if
        ifdef SET then display("Class []",class) end ifdef
        if not initialized[class] then
            init(class)
        end if
    else  
        class = vlookup(handle,registry,1,2,-1)
    end if

    property = "get_" & lower(join(split(property,' '),'_'))

    object method = lookup_method(class,property)
    object result = 0

    if atom(method) then -- not found, try fallback to Object;
        result = getProperty(handle,property[5..$])
        return result
    end if

 -- else, method found;
        object params = method[PARAMS]
        object args = {handle,p1,p2,p3,p4}
        args = args[1..length(params)]

    ifdef GET then -- debug
        display(decode_method("Get",class,method),0) 
        puts(1,"\tArgs: ") display(decode_args(method,args),
            {2,2,11,78,"%d","%2.22f",32,127,4,-1})
    end ifdef

    if method[VECTOR] = -1 then
        crash("\nERROR\n****** Invalid call: %s->%s",{widget[class][$],method[1]})
    end if
    
        for i = 2 to length(args) do -- convert args to pointers if necessary;
            switch method[PARAMS][i] do
                case S then
                    if string(args[i]) then args[i] = allocate_string(args[i]) end if
            end switch
        end for
        
        if method[RETVAL] = 0 then -- it's a GTK proc
            c_proc(method[VECTOR],args)

            for i = 2 to length(method[PARAMS]) do -- convert returned values;
                switch method[PARAMS][i] do
                    case D then args[i] = float64_to_atom(peek({args[i],8}))
                    case F then args[i] = float32_to_atom(peek({args[i],4}))
                    case S then if args[i] > 0 then args[i] = peek_string(args[i]) end if
                    case I then args[i] = peek4s(args[i])
                end switch
            end for
            result = args[2..$]
        end if

        if method[RETVAL] > 0 then -- it's a GTK func
            result = c_func(method[VECTOR],args)
            switch method[RETVAL] do
                case S then  -- convert string pointer to string;
                    if result > 0 then 
                        result = peek_string(result)
                    else
                        result = 0
                    end if
                case A then
                    result = to_sequence(result)
                case I then 
                        switch method[1] do -- patch for zero-based indexing
                            case "get_active",
                            "get_text_column",
                            "get_pixbuf_column",
                            "get_column",
                            "get_tooltip_column",
                            "get_search_column",
                            "get_sort_column_id" then result += 1
                        end switch
            end switch
        end if

        if method[RETVAL] <-1 then -- it's a Eu func (negated routine_id)
            result = call_func(-method[VECTOR],args)
        end if

        if method[CLASS] != GSList then
        if method[CLASS] != 0 then -- for widgets created 'internally' by GTK;
            if not initialized[method[CLASS]] then init(method[CLASS]) end if
            register(result,method[CLASS])
        end if
        end if
        
        ifdef GET then -- debug
            if string(result) then
                display("\tReturns: '[]'",{result})
            else
                display("\tReturns: []",{result})
            end if
        end ifdef
    
    return result
    
end function /*get*/

------------------------------------------------------------------------
public function add(atom parent, object child)
------------------------------------------------------------------------
-- add a child or a {list} of child widgets to parent container

    if classid(child) = GdkPixbuf then -- issue a warning;
        return Warn(,,"Cannot add a pixbuf to a container",
            "Create an image from it first,\nthen add the image,\nor save it for later use!")
    end if
    
    -- Switch below implements an easier-to-remember 'add' syntax 
    -- as an alias for the various calls shown;
    switch classid(parent) do 
    
        case GtkComboBoxText, GtkComboBoxEntry then
            for i = 1 to length(child) do
                set(parent,"append text",child[i])
            end for
            
        case GtkToolbar then
            if atom(child) then
                set(parent,"insert",child,-1)
            else for i = 1 to length(child) do
                    add(parent,child[i])
                end for
            end if
            return child
            
        case GtkFileChooserDialog then
            if atom(child) then
                if classid(child) = GtkFileFilter then
                    set(parent,"add filter",child)
                end if
            else for i = 1 to length(child) do
                    add(parent,child[i])
                end for
            end if
            
        case GtkSizeGroup then
            set(parent,"add widgets",child)
            return child
    
        case GtkTreeView then
            set(parent,"append columns",child)
            return child
            
        case GtkTreeViewColumn then
            if child > 0 then
                set(parent,"pack start",child)
            else
                set(parent,"pack end",-child)
            end if
            return child
            
        case GtkBuilder then
            atom err = allocate(64) err = 0
            if file_exists(canonical_path(child)) then
                set(parent,"add from file",canonical_path(child),err)
                set(parent,"connect")
                return 1
            end if
            if string(child) then
                set(parent,"add from string",child,err)
                set(parent,"connect")
                return 1
            end if
            
        case else 
            if atom(child) then
                gtk_proc("gtk_container_add",{P,P},{parent,child})
            else 
                for i = 1 to length(child) do
                    gtk_proc("gtk_container_add",{P,P},{parent,child[i]})
            end for
        end if
        return child
        
    end switch
return -1
end function /*add*/

------------------------------------------------------------------------
public procedure pack(atom parent, object child,
    integer expand=0, integer fill=0, integer padding=0)
------------------------------------------------------------------------
-- pack a child or {list} of child widgets into parent container;
-- prepending a negative sign to the child pointer means
--'pack end'; this can be more versatile than having 2 different calls
------------------------------------------------------------------------
    if atom(child) then
        if child > 0 then
            set(parent,"pack start",child,expand,fill,padding)
        else
            set(parent,"pack end",-child,expand,fill,padding)
        end if
    else 
        for i = 1 to length(child) do
            pack(parent,child[i],expand,fill,padding)
        end for
    end if
end procedure

------------------------------------------------------------------------
public procedure show(object x)
------------------------------------------------------------------------
    if atom(x) then -- show widget x or a {list} of widgets
        set(x,"show")
    else 
        for i = 1 to length(x) do 
            show(x[i]) 
        end for
    end if
end procedure

------------------------------------------------------------------------
public procedure show_all(atom x)
------------------------------------------------------------------------
    set(x,"show all") -- show container x and all children contained
end procedure

------------------------------------------------------------------------
public procedure hide(object x)
------------------------------------------------------------------------
    if atom(x) then -- hide a widget or a {list} of widgets;
        set(x,"hide")
    else
        for i = 1 to length(x) do
            hide(x[i])
        end for
    end if
end procedure

------------------------------------------------------------------------
public procedure hide_all(object x)
------------------------------------------------------------------------
    set(x,"hide all") -- hide container x and any children
end procedure

------------------------------------------------------------------------
public function Destroy(object ctl, object data)
------------------------------------------------------------------------
-- destroy a widget or {list} of widgets;
if atom(data) then
    gtk_proc("gtk_widget_destroy",{P},{data})
else
    for i = 1 to length(data) do
        Destroy(0,data[i])
    end for
end if
return 1
end function
export constant destroy = call_back(routine_id("Destroy"))

------------------------------------------------------------------------
export procedure main()
------------------------------------------------------------------------
    gtk_proc("gtk_main") -- start the GTK engine;
end procedure

------------------------------------------------------------------------
export function events_pending()
------------------------------------------------------------------------
    return gtk_func("gtk_events_pending")
end function 

------------------------------------------------------------------------
export procedure main_iteration()
------------------------------------------------------------------------
    gtk_proc("gtk_main_iteration")
end procedure

------------------------------------------------------------------------
export procedure main_iteration_do(integer i)
------------------------------------------------------------------------
-- used when multi-tasking;
    gtk_proc("gtk_main_iteration_do",{I},i)
end procedure

without warning {not_reached}
------------------------------------------------------------------------
export function Quit(atom ctl=0, object errcode=0)
------------------------------------------------------------------------
    abort(errcode) -- kill the GTK engine;
return 0
end function
export constant main_quit = call_back(routine_id("Quit"))

global function gtk_main_quit()
    abort(0)
return 0
end function

------------------------------------------------------------------------
-- Following are 4 pre-built, easy to use popup dialogs 
-- which save you the trouble of writing tons of code!
-- Refer to documentation/dialogs.html for details
------------------------------------------------------------------------
public function Info(object parent=0, object title="Info", 
    object pri_txt="", object sec_txt="",
    object flags=0, object btns=GTK_BUTTONS_OK, 
    object image=0, object size=GTK_ICON_SIZE_DIALOG,
    object icon=0, integer pos=GTK_WIN_POS_MOUSE)
    object p = 0
    atom dlg = create(GtkMessageDialog,parent,2,flags,btns)
    set(dlg,"transient for",parent)
    set(dlg,"destroy with parent",TRUE)
    set(dlg,"default response",MB_OK)
    set(dlg,"icon",icon)
return run_dlg(dlg,title,pri_txt,sec_txt,image,size)
end function

------------------------------------------------------------------------
public function Question(atom parent=0, object title="Question", 
    object pri_txt="", object sec_txt="",
    object flags=2, object btns=GTK_BUTTONS_YES_NO, 
    object image=0, object size=GTK_ICON_SIZE_DIALOG,
    object icon=0, integer pos=GTK_WIN_POS_MOUSE)
    atom dlg = create(GtkMessageDialog,parent,2,flags,btns)
    set(dlg,"transient for",parent)
    set(dlg,"destroy with parent",TRUE)
    set(dlg,"default response",MB_YES)
    set(dlg,"icon",icon)
return run_dlg(dlg,title,pri_txt,sec_txt,image,size)
end function

------------------------------------------------------------------------
public function Warn(atom parent=0, object title="Warning", 
    object pri_txt="", object sec_txt="",
    object flags=1, object btns=GTK_BUTTONS_CANCEL, 
    object image=0, object size=GTK_ICON_SIZE_DIALOG,
    object icon=0, integer pos=GTK_WIN_POS_MOUSE)
    atom dlg = create(GtkMessageDialog,parent,2,flags,btns)
    set(dlg,"transient for",parent)
    set(dlg,"destroy with parent",TRUE)
    set(dlg,"default response",MB_CANCEL)
    set(dlg,"icon",icon)
return run_dlg(dlg,title,pri_txt,sec_txt,image,size)
end function

------------------------------------------------------------------------
public function Error(atom parent=0, object title="Error", 
    object pri_txt="", object sec_txt="",
    object flags=3, object btns=GTK_BUTTONS_OK_CANCEL, 
    object image=0, object size=GTK_ICON_SIZE_DIALOG,
    object icon=0, integer pos=GTK_WIN_POS_MOUSE)
    atom dlg = create(GtkMessageDialog,parent,2,flags,btns)
    set(dlg,"transient for",parent)
    set(dlg,"destroy with parent",TRUE)
    set(dlg,"default response",MB_OK)
    set(dlg,"icon",icon)
return run_dlg(dlg,title,pri_txt,sec_txt,image,size)
end function

constant runDlg = define_c_func(GTK,"gtk_dialog_run",{P},I)
------------------------------------------------------------------------
function run_dlg(atom dlg, object title, 
    object pri_txt, object sec_txt, object img=0, object size=6)
    set(dlg,"title",title)
    set(dlg,"markup",sprintf("<b>%s</b>",{pri_txt}))
    set(dlg,"format secondary markup",sec_txt)
    set(dlg,"position",GTK_WIN_POS_MOUSE)
    
    if atom(img) and img = 0 then 
        goto "done"  
    end if 

    if classid(img) = GdkPixbuf then
        img = create(GtkImage,img)
    end if
    
    if string(img) then
        img = create(GtkImage,img,size)
    end if
    
    if img > 0 then
        set(dlg,"image",img) gtk_proc("gtk_widget_show",{P},{img})
    end if
    
 label "done"
    integer result = c_func(runDlg,{dlg})
    deregister(dlg)
    gtk_proc("gtk_widget_destroy",{P},{dlg})
    
return result
end function

------------------------------------------------------------------------
-- Following functions register and initialize class methods
------------------------------------------------------------------------
-- A class is initialized the first time a widget of that class is created.
-- This means the widget's method vectors are filled in with Eu routine_ids 
-- generated by define_c_func or define_c_proc as appropriate.

-- When a subsequent call is made to a widget method, that vector is 
-- used by calling c_func, c_proc, or call_func.

-- If the call is to a method not implemented by the widget, but is 
-- instead a method inherited from one of the widget's ancestors, 
-- then the ancestor is initialized (if necessary).

-- This scheme means that program startup isn't delayed as it would be 
-- if all widgets and methods were to be initialized first, most of which
-- would likely not be used in any given program.

------------------------------------------------------------------------
procedure init(integer class)
------------------------------------------------------------------------
object name, params, retval

    ifdef INIT then 
        display("\nInit class:[] []",{class,widget[class][$]}) 
    end ifdef

    for method = 3 to length(widget[class])-1 do

        name = sprintf("%s_%s",{widget[class][NAME],widget[class][method][NAME]})
        widget[class][method] = pad_tail(widget[class][method],5,0)
        params = widget[class][method][PARAMS]
        retval = widget[class][method][RETVAL]
        
        for i = 1 to length(params) do 
            switch params[i] do
                case A then params[i] = P 
                case D then
                    if equal("get_range",widget[class][method][NAME]) then
                        params[i] = P
                    end if
                case F then
                    if class = GtkAspectFrame then -- do nothing
                    else switch widget[class][method][NAME] do
                            case "add_mark","set_fraction","set_alignment" then -- do nothing
                            case else params[i] = P
                        end switch
                    end if
            end switch        
        end for
    
        if widget[class][method][RETVAL] = 0 then -- it's a GTK proc
            widget[class][method][VECTOR] = define_c_proc(GTK,name,params)
            goto "init"
        end if

        if widget[class][method][RETVAL] > 0 then -- it's a GTK func
            widget[class][method][VECTOR] = define_c_func(GTK,name,params,retval)
            goto "init"
        end if

        if widget[class][method][RETVAL] < -1 then -- it's a Eu func
            widget[class][method][VECTOR] = widget[class][method][RETVAL]
        end if

        label "init"
        
        initialized[class] = TRUE

        ifdef INIT then 
            display("\tCLASS:[] METHOD:[] RID:[]",
            {widget[class][$],widget[class][method][NAME],widget[class][method][VECTOR]}) 
        end ifdef

        ifdef INIT_ERR then
            if widget[class][method][VECTOR] = -1 then -- function invalid!
                display("\tINIT ERROR: CLASS:[] METHOD: [] ERR:[]",
                {widget[class][$],widget[class][method][NAME],widget[class][method][VECTOR]}) 
            end if
        end ifdef
        
    end for

end procedure /*init*/

export object registry = {}
------------------------------------------------------------------------
-- The registry associates a control's handle with its class,
-- so that future calls to set or get that control's properties
-- can go directly to the correct set of functions stored in the
-- widget{} structure.
---------------------------------------------------------------------------------------------
function register(atom handle, integer class, object name="-nil-", object nick = 0)
---------------------------------------------------------------------------------------------
integer x = find(handle,vslice(registry,1))

    if x > 0 then -- handle already exists, 
    -- update it in case handle has been recycled.
        registry[x] = {handle,class,widget[class][$],name,nick}
        return 1
    end if 
    
    -- else, add the widget to the registry;
    registry = append(registry,{handle,class,widget[class][$],name,nick})
      
    -- initialize class if this is the first use of that class;
    if not initialized[class] then init(class) end if

    ifdef REG then 
        printf(1,text:format("Registry + [3:16]\thandle: [1:12>]\tname: [4]\tnick: []\n\n",registry[$])) 
    end ifdef
    
return 1
end function /*register*/
  
---------------------------------------
procedure deregister(atom handle)
---------------------------------------
integer x = find(handle,vslice(registry,1))
if x > 0 then
    ifdef REG then
        printf(1,text:format("Registry - [3:16]\thandle: [1:12>]\t",registry[x]))
        if string(registry[x][4]) then printf(1,"name: %s",{registry[x][4]}) end if
        puts(1,"\n")
    end ifdef
    registry = remove(registry,x)
end if
end procedure

-- Returns an integer corresponding with a enumerated widget class;
------------------------------------------------------------------------
public function classid(object handle)
------------------------------------------------------------------------
    return vlookup(handle,registry,1,2,-1)
return -1
end function

-- returns classname as a string (e.g. "GtkWindow") for a given handle;
------------------------------------------------------------------------
public function classname(atom handle)
------------------------------------------------------------------------
    return vlookup(handle,registry,1,3,"?")
end function

-- returns name of object from registry
------------------------------------------------------------------------
public function objectname(atom handle)
------------------------------------------------------------------------
    return vlookup(handle,registry,1,4,"?")
end function

------------------------------------------------------------------------
function lookup_method(integer class, sequence prop)
------------------------------------------------------------------------
-- Finds the method to set or get a property for a given class,
-- if not found, ancestors of that class are checked until the method
-- is located. 
  if class = -1 then return 0 end if
  
    object method = lookup(prop,vslice(widget[class],NAME),widget[class],0)

    if atom(method) then -- try sans the set_ or get_ prefix;
        method = lookup(prop[5..$],vslice(widget[class],NAME),widget[class],0)
    end if

    if sequence(method) then -- method found in this class;
        return method 
    end if

    object ancestor -- if not found, need to look for method in ancestors;
        for i = 1 to length(widget[class][PARAMS]) do
            ancestor = widget[class][PARAMS][i] 
            if ancestor = 0 then return 0 end if
            
            if not initialized[ancestor] then 
                init(ancestor) 
            end if
            ifdef LOOK then
                display(widget[ancestor])
            end ifdef        
            method = lookup(prop,vslice(widget[ancestor],NAME),widget[ancestor],0)
            if atom(method) then
                method = lookup(prop[5..$],vslice(widget[ancestor],NAME),widget[ancestor],0)
            end if
            
            if sequence(method) then
                return method
            end if
            
        end for
        
    return -1
end function /*lookup*/

-----------------------------------------------------------------------------
public function connect(object ctl, object sig, object fn=0, object data=0, 
    atom closure=0, integer flags=0)
-----------------------------------------------------------------------------
-- tells control to call fn, sending data along for the ride,
-- whenever that control receives signal 'sig'

    if atom(fn) and fn = 0 then
        return 0 -- can't connect a null func!
    end if 

    ifdef GLADE then
    if string(ctl) then
        ctl = gtk_func("gtk_builder_get_object",{P,P},{builder,allocate_string(ctl)})
    end if
    end ifdef
    
    if string(fn) then
    
        ifdef COMPILE then -- do compile test if requested;
            display("Connecting [] Signal '[]' Data []",{classname(ctl),sig,data})
            if not equal("Quit",fn) then
                printf(1,"\n\tCaution: function %s will not link when compiled!\n\t********\n",{fn})
            end if
        end ifdef
        
        atom rid = routine_id(fn)
        if rid > 0 then -- named func is in scope;
            fn = call_back(rid) -- so obtain a callback;
        else
            printf(1,"\n\tError: function %s is not in scope\n\t****** (make it global or link via routine_id)\n",{fn})
        end if
        
    end if

    sig = allocate_string(sig)

    if integer(data) then -- can be attached directly;
        return gtk_func("g_signal_connect_data",{P,S,P,P,I,I},{ctl,sig,fn,data,closure,flags})
    end if

    if atom(data) then  
        data = prepend({data},"ATOM") -- must be serialized and unpacked later;
        data = allocate_wstring(serialize(data)+1)
        return gtk_func("g_signal_connect_data",{P,S,P,P,I,I},{ctl,sig,fn,data,closure,flags})
    end if

    if string(data) then 
        data = prepend({data},"STR") -- must be serialized and unpacked later;
        data = allocate_wstring(serialize(data)+1) 
        return gtk_func("g_signal_connect_data",{P,S,P,P,I,I},{ctl,sig,fn,data,closure,flags})
    end if

    if sequence(data) then
        data = prepend(data,"SEQ")-- must be serialized and unpacked later;
        data = allocate_wstring(serialize(data)+1)
        return gtk_func("g_signal_connect_data",{P,S,P,P,I,I},{ctl,sig,fn,data,closure,flags})
    end if

end function /*connect*/

------------------------------------------------------------------------
export procedure disconnect(atom ctl, integer sigid)
------------------------------------------------------------------------
-- disconnect a signal from ctl;
    gtk_proc("g_signal_handler_disconnect",{P,I},{ctl,sigid})
end procedure

------------------------------------------------------------------------
export function unpack(object data)
------------------------------------------------------------------------
-- retrieves data passed in a control's data space; 
if atom(data) and data = 0 then return 0 end if
object result = deserialize(peek_wstring(data)-1)
    switch result[1][1] do
        case "ATOM","STR","INT" then return result[1][2]
        case "SEQ" then return result[1][2..$]
    end switch
return result
end function

------------------------------------------------------------------------
-- following 3 'decode' functions are for debugging purposes; 
-- they make displays more readable
------------------------------------------------------------------------
function decode_args(object method, object args)
------------------------------------------------------------------------
for i = 1 to length(method[PARAMS]) do
    switch method[PARAMS][i] do
        case S then 
            if atom(args[i]) and args[i] > 0 then 
                args[i] = peek_string(args[i]) 
                if length(args[i]) > 40 then
                    args[i] = args[i][1..40] & "..."
                end if
                args[i] = args[i]
            end if
    end switch
end for
return args
end function 

constant ptype = {0,P,I,D,F,S,B,A}
constant pname = {{},"None","Ptr ","Int ","Dbl ","Flt ","Str ","Bool ","Array "}
------------------------------------------------------------------------
function decode_params(object params)
------------------------------------------------------------------------
return transmute(params,ptype,pname)
end function

------------------------------------------------------------------------
function decode_method(sequence title, integer class, object method)
------------------------------------------------------------------------
object z = {}
integer n
    z = prepend(method,widget[class][$]) 
    z = prepend(z,title) 
    z[4] = decode_params(method[PARAMS]) 
    while length(z) < 5 do
        z = append(z,0)
    end while
    if length(method) >= RETVAL then
        n = find(method[RETVAL],ptype) 
        z[5] = pname[n+1]
    end if 
return text:format("\n[]\n\tCall: []->[]\n\tParams: []\n\tReturn type: []\n\tVector: []",z)
end function

-- "helper" routine to get icon images from various sources;
------------------------------------------------------------------------
function get_icon_image(object icon, integer size=6)
------------------------------------------------------------------------
atom img = 0, default_theme

-- first, see if it's a stock icon; GtkImage
    if string(icon) then
        if find(icon,stock_list) then
            img = gtk_func("gtk_image_new_from_stock",{P,I},
                {allocate_string(icon),size})
            return img
        end if
    end if
    
-- next, see if there's a named icon;
    img = 0
    default_theme = gtk_func("gtk_icon_theme_get_default",{})
    if gtk_func("gtk_icon_theme_has_icon",{P,P},
        {default_theme,allocate_string(icon)}) then
        img = gtk_func("gtk_image_new_from_icon_name",{P,P},
            {allocate_string(icon),size}) 
        return img
    end if
    
-- no, maybe it's an image from a file;
    img = 0
    icon = canonical_path(icon)
    if file_exists(icon) then
        img = gtk_func("gtk_image_new_from_file",{P},{icon})
        return img
    end if
    
return -1   
end function

------------------------------------------------------------------------
public function to_sequence(atom glist, integer fmt=0) -- mostly internal
------------------------------------------------------------------------
-- convert glist pointer back to a Euphoria sequence;
-- results are returned in a choice of formats;
  integer len = gtk_func("g_list_length",{P},{glist}) 
  object s = {}
  atom data
    for i = 0 to len-1 do
        data = gtk_func("g_slist_nth_data",{P,I},{glist,i})
        switch fmt do
            case 0 then s = append(s,peek_string(data))
            ifdef TOSEQ then display(s) end ifdef
            case 1 then s = append(s,data)
            case 2 then s = append(s,gtk_str_func("gtk_tree_path_to_string",{P},{data}))
            case 3 then s = append(s,to_number(gtk_str_func("gtk_tree_path_to_string",{P},{data})))
        end switch
    end for
return s
end function

------------------------------------------------------------------------
-- Color handling routines - most are used internally
------------------------------------------------------------------------
export function to_rgba(object color) 
----------------------------------------
-- converts a color description to rgba ptr;
 atom rgba = allocate(32) 
 object c = color 
 if string(c) then c = allocate_string(c) end if
    if gtk_func("gdk_rgba_parse",{P,P},{rgba,c}) then
        return rgba
    else
        printf(1,"Error: invalid color '%s'\n******",{color})
    end if
return rgba
end function

-- converts rgba ptr to usable description;
----------------------------------------------------
export function from_rgba(object rgba, object fmt=0) 
----------------------------------------------------
object result = gtk_str_func("gdk_rgba_to_string",{P},{rgba})
 if fmt = 0 then return result 
 else return fmt_color(result,fmt) 
 end if
end function

-- Convert color to various usable formats - this can be used 
-- by the programmer, refer to ~/demos/documentation/HowItWorks.html#colors
------------------------------------------------------------------------
function fmt_color(object s, integer fmt)
------------------------------------------------------------------------
 if atom(s) then
    if string(peek_string(s)) then
        s = peek_string(s)
    end if
  end if
object w
    w = split_any(s,"(,)")
    if length(w[1]) = 3 then
        w[5] = "1"
    end if
    for i = 2 to 5 do
        w[i] = to_number(w[i])
    end for
    if atom(w[5]) then
        w[5] = round(w[5],100)
    end if
    switch fmt do
        case 0 then return w[1..length(w[1])+1]
        case 1 then return sprintf("#%02x%02x%02x",w[2..4])
        case 2 then return (256*256*w[2])+(256*w[3])+ w[4]
        case 3 then return {w[2],w[3],w[4]}
        case 4 then return {w[2],w[3],w[4],w[5]}
        case 5 then return {w[2],w[3],w[4],256*w[5]}
        case 6 then return sprintf("rgba(%d,%d,%d,%2.2f)",w[2..$])
        case 7 then return {w[2]/255,w[3]/255,w[4]/255,w[5]}
        case 8 then return sprintf("r=#%x, g=#%x, b=#%x, alpha=#%x",w[2..5])
    end switch
return s
end function

------------------------------------------------------------------------
-- METHOD DECLARATIONS:
------------------------------------------------------------------------

sequence initialized = repeat(0,GtkFinal)
-- This is a set of flags which are set to 1 when a given widget has 
-- been initialized. This prevents having to initialize a widget's
-- methods repeatedly.

sequence widget = repeat(0,GtkFinal)
-- This structure holds prototypes for each GTK method call,
-- organized by widget. When each widget is initialized,
-- vectors are added pointing to the routine_ids needed
-- to call the GTK functions that implement each method.

-- The list below need not be in any specific order.
-- Widget names must also be added to the list in GtkEnums  
------------------------------------------------------------------------
sequence stock_list = create(GtkStockList)

widget[GObject] = {"g_object",
{0}, -- {list of ancestors}
    {"new",{I,S,S,I},P}, -- method,{formal params},return type
    {"set",{P,S,P,P}}, 
    {"set_property",{P,S,P},-routine_id("setProperty")},
    {"get_property",{P,S},-routine_id("getProperty")},
    {"get_data",{P,S},S},
    {"set_data",{P,S,S}},
    {"set_data_full",{P,S,S,P}},
    {"steal_data",{P,S},P},
"GObject"} -- human-readable name

    constant 
        fn1 = define_c_proc(GTK,"g_object_get",{P,S,P,P}),
        doubles = {"angle","climb-rate","fraction","max-value","min-value",
        "scale","value","pulse-step","scale","size-points","text-xalign",
        "text-yalign","xalign","yalign"}

    function setProperty(object handle, object a, object b)
    --------------------------------------------------------------
    ifdef OBJ_SET then 
        display("Handle []",handle)
        display("Prop []",{a})
        display("Value  []",b)
    end ifdef
    if find(a,doubles) then 
        if string(a) then a = allocate_string(a) end if
        if string(b) then b = allocate_string(b) end if
        gtk_proc("g_object_set",{P,P,D,P},{handle,a,b,0})
    else
        if string(a) then a = allocate_string(a) end if
        if string(b) then b = allocate_string(b) end if
        gtk_proc("g_object_set",{P,P,P,P},{handle,a,b,0})
    end if
    return 1
    end function

    function getProperty(atom handle, object p)
    --------------------------------------------------
    atom x = allocate(32) 
    if string(p) then p = allocate_string(p) end if
    c_proc(fn1,{handle,p,x,0})
    object result = peek4u(x)
    free(x)
    return result
    end function

widget[GtkAdjustment] = {"gtk_adjustment",
{GObject},
    {"new",{D,D,D,D,D,D},P},
    {"set_value",{P,D}},
    {"get_value",{P},D},
    {"clamp_page",{P,D,D}},
    {"value_changed",{P}},
    {"configure",{P,D,D,D,D,D,D}},
    {"get_lower",{P},D},
    {"get_page_increment",{P},D},
    {"get_step_increment",{P},D},
    {"get_minimum_increment",{P},D},
    {"set_upper",{P,D}},
    {"get_upper",{P},D},
    {"set_page_increment",{P,D}},
    {"set_page_size",{P,D}},
    {"set_step_increment",{P,D}},
    {"set_upper",{P,D}},
"GtkAdjustment"}

widget[GtkWidgetPath] = {"gtk_widget_path",
{GObject},
    {"new",{},P},
    {"append_type",{P,I},I},
    {"append_with_siblings",{P,P,I},I},
    {"append_for_widget",{P,P},I},
    {"copy",{P},P,0,GtkWidgetPath},
    {"get_object_type",{P},I},
    {"has_parent",{P,I},B},
    {"is_type",{P,I},B},
    {"iter_add_class",{P,I,S}},
    {"iter_add_region",{P,I,S,I}},
    {"iter_clear_classes",{P,I}},
    {"iter_clear_regions",{P,I}},
    {"iter_get_name",{P,I},S},
    {"iter_get_object_type",{P,I},I},
    {"iter_get_siblings",{P,I},P,0,GtkWidgetPath},
    {"iter_get_sibling_index",{P,I},I},
    {"iter_has_class",{P,I,S},B},
    {"iter_has_name",{P,I,S},B},
    {"iter_has_qclass",{P,I,P},B},
    {"iter_has_qname",{P,I,P},B},
    {"iter_has_qregion",{P,I,P,I},B},
    {"iter_has_region",{P,I,S,I},B},
    {"iter_list_classes",{P,I},P,0,GSList},
    {"iter_list_regions",{P,I},P,0,GSList},
    {"iter_remove_class",{P,I,S}},
    {"iter_remove_region",{P,I,S}},
    {"iter_set_name",{P,I,S}},
    {"iter_set_object_type",{P,I,I}},
    {"iter_get_state",{P,I},I}, -- GTK3.14
    {"iter_set_state",{P,I,I}}, -- GTK3.14
    {"length",{P},I},
    {"prepend_type",{P,I}},
    {"to_string",{P},S},
"GtkWidgetPath"}

widget[GtkWidget] = {"gtk_widget",
{GtkWidgetPath,GtkAccessible,GtkBuildable,GObject},
-- aliases to fix awkward overrides; ordinarily you will use one of these 4;
    {"set_font",{P,S},-routine_id("setFont")},
    {"set_color",{P,P},-routine_id("setFg")}, 
    {"set_foreground",{P,P},-routine_id("setFg")},
    {"set_background",{P,P},-routine_id("setBg")},
-- only use following 2 versions when you need to change the color
-- of a control in a state other than normal;
    {"override_background_color",{P,I,P},-routine_id("overrideBg")},
    {"override_color",{P,I,P},-routine_id("overrideFg")},
    {"new",{I},P},
    {"destroy",{P}},
    {"in_destruction",{P},B},
    {"destroyed",{P},B},
    {"unparent",{P}},
    {"show",{P}},
    {"show_now",{P}},
    {"hide",{P}},
    {"show_all",{P}},
    {"map",{P}},
    {"unmap",{P}},
    {"realize",{P}},
    {"unrealize",{P}},
    {"draw",{P}},
    {"queue_draw",{P}},
    {"queue_resize",{P}},
    {"queue_resize_no_redraw",{P}},
    {"get_frame_clock",{P},P,0,GdkFrameClock},
    {"add_tick_callback",{P,P,P,P},I},
    {"remove_tick_callback",{P,I}}, -- GTK 3.8+
    {"set_size_request",{P,I,I}},
    {"size_allocate",{P,P}},
    {"size_allocate_with_baseline",{P,P,I}},
    {"add_accelerator",{P,S,P,I,I}},
    {"remove_accelerator",{P,P,I,I},B},
    {"set_accel_path",{P,S,P}},
    {"can_activate_accel",{P,I},B},
    {"event",{P,P},B},
    {"activate",{P},B},
    {"reparent",{P,P}}, -- deprecated 3.14
    {"intersect",{P,P,P},B},
    {"is_focus",{P},B},
    {"grab_focus",{P},B},
    {"grab_default",{P}},
    {"set_name",{P,S}},
    {"get_name",{P},S},
    {"set_sensitive",{P,B}},
    {"get_sensitive",{P},B},
    {"set_parent",{P,P}},
    {"get_parent",{P},P},
    {"set_parent_window",{P,P}},
    {"get_parent_window",{P},P},
    {"set_events",{P,I}},
    {"get_events",{P},I},
    {"add_events",{P,I}},
    {"set_device_events",{P,P,I}},
    {"get_device_events",{P,P,I},I},
    {"add_device_events",{P,P,I}},
    {"set_device_enabled",{P,P,B}},
    {"get_device_enabled",{P,P},B},
    {"get_toplevel",{P},P},
    {"get_ancestor",{P,I},P},
    {"is_ancestor",{P,P},B},
    {"set_visual",{P,P}},
    {"get_visual",{P},P,0,GdkVisual},
    {"get_pointer",{P,I,I}}, -- deprecated 3.4
    {"translate_coordinates",{P,P,I,I,I,I},B},
    {"hide_on_delete",{P},B},
    {"set_direction",{P,I}},
    {"get_direction",{P},I},
    {"set_default_direction",{I}},
    {"get_default_direction",{},I},
    {"shape_combine_region",{P,P}},
    {"create_pango_context",{P},P},
    {"get_pango_context",{P},P,0,PangoContext},
    {"create_pango_layout",{P,S},P},
    {"queue_draw_area",{P,I,I,I,I}},
    {"queue_draw_region",{P,P}},
    {"set_app_paintable",{P,B}},
    {"set_double_buffered",{P,B}}, -- deprecated 3.14
    {"set_redraw_on_allocate",{P,B}},
    {"mnemonic_activate",{P,B},B},
    {"send_expose",{P,P},I},
    {"send_focus_change",{P,P},B},
    {"get_accessible",{P},P},
    {"child_focus",{P,I},B},
    {"child_notify",{P,S}},
    {"freeze_child_notify",{P}},
    {"get_child_visible",{P},B},
    {"get_parent",{P},P},
    {"get_path",{P},P,0,GtkWidgetPath},
    {"get_settings",{P},P,0,GtkSettings},
    {"get_clipboard",{P,I},P,0,GtkClipboard},
    {"get_display",{P},P,0,GdkDisplay},
    {"get_root_window",{P},P,0,GdkWindow}, -- deprecated 3.12
    {"get_screen",{P},P,0,GdkScreen},
    {"has_screen",{P},B},
    {"get_size_request",{P,I,I}},
    {"set_child_visible",{P,B}},
    {"thaw_child_notify",{P}},
    {"set_no_show_all",{P,B}},
    {"get_no_show_all",{P},B},
    {"add_mnemonic_label",{P,P}},
    {"remove_mnemonic_label",{P,P}},
    {"is_compositied",{P},B},
    {"set_tooltip_markup",{P,S}},
    {"get_tooltip_markup",{P},S},
    {"set_tooltip_text",{P,S}},
    {"get_tooltip_text",{P},S},
    {"set_tooltip_window",{P,P}},
    {"get_tooltip_window",{P},P,0,GtkWindow},
    {"set_has_tooltip",{P,B}},
    {"get_has_tooltip",{P},B},
    {"trigger_tooltip_query",{P}},
    {"get_window",{P},P,0,GdkWindow},
    {"register_window",{P,P}}, -- GTK 3.8+
    {"unregister_window",{P,P}}, -- GTK 3.8+
    {"get_allocated_width",{P},I},
    {"get_allocated_height",{P},I},
    {"get_allocation",{P,P}},
    {"set_allocation",{P,P}},
    {"get_allocated_baseline",{P},I},
    {"get_app_paintable",{P},B},
    {"set_can_default",{P,B}},
    {"get_can_default",{P},B},
    {"get_can_focus",{P},B},
    {"get_double_buffered",{P},B}, -- deprecated 3.14
    {"get_has_window",{P},B},
    {"get_sensitive",{P},B},
    {"get_visible",{P},B},
    {"is_visible",{P},B}, -- GTK 3.8+
    {"set_visible",{P,B}},
    {"set_state_flags",{P,I,B}},
    {"unset_state_flags",{P,I}},
    {"get_state_flags",{P},I},
    {"has_default",{P},B},
    {"has_focus",{P},B},
    {"has_visible_focus",{P},B},
    {"has_grab",{P},B},
    {"is_drawable",{P},B},
    {"is_toplevel",{P},B},
    {"set_window",{P,P}},
    {"set_receives_default",{P,B}},
    {"get_receives_default",{P},B},
    {"set_support_multidevice",{P,B}},
    {"get_support_multidevice",{P},B},
    {"set_realized",{P,B}},
    {"get_realized",{P},B},
    {"set_mapped",{P,B}},
    {"get_mapped",{P},B},
    {"device_is_shadowed",{P,P},B},
    {"get_modifier_mask",{P,I},I},
    {"insert_action_group",{P,S,P}},
    {"get_opacity",{P},D},  -- GTK 3.8+
    {"set_opacity",{P,D}}, -- GTK 3.8+
    {"get_path",{P},P,0,GtkWidgetPath},
    {"get_style_context",{P},P,0,GtkStyleContext},
    {"reset_style",{P}},
    {"get_preferred_height",{P,I,I}},
    {"get_preferred_width",{P,I,I}},
    {"get_preferred_height_for_width",{P,I,I,I}},
    {"get_preferred_width_for_height",{P,I,I,I}},
    {"get_preferred_height_and_baseline_for_width",{P,I,I,I,I,I}},
    {"get_request_mode",{P},I},
    {"get_preferred_size",{P,P,P}},
    {"get_preferred_size_and_baseline",{P,P,I,I}},
    {"get_halign",{P},I},
    {"set_halign",{P,I}},
    {"get_valign",{P},I},
    {"set_valign",{P,I}},
    {"set_margin_left",{P,I}}, -- deprecated 3.12
    {"get_margin_left",{P},I}, -- deprecated 3.12
    {"set_margin_right",{P,I}}, -- deprecated 3.12
    {"get_margin_right",{P},I}, -- deprecated 3.12
    {"get_margin_end",{P},I}, -- new 3.12
    {"set_margin_end",{P,I}}, -- new 3.12
    {"get_margin_start",{P},I}, -- new 3.12
    {"set_margin_start",{P,I}}, -- new 3.12
    {"set_margin_top",{P,I}},
    {"get_margin_top",{P},I},
    {"set_margin_bottom",{P,I}},
    {"get_margin_bottom",{P},I},
    {"get_hexpand",{P},B},
    {"set_hexpand",{P,B}},
    {"get_hexpand_set",{P},B},
    {"set_hexpand_set",{P,B}},
    {"get_vexpand",{P},B},
    {"set_vexpand",{P,B}},
    {"get_vexpand_set",{P},B},
    {"set_vexpand_set",{P,B}},
    {"queue_compute_expand",{P}},
    {"compute_expand",{P,I},B},
    {"init_template",{P}},
    {"get_automated_child",{P,I,S},P,0,GObject},
    {"get_clip",{P,P}}, -- 3.14
    {"set_clip",{P},P}, -- 3.14
"GtkWidget"}

 -- This allows specifying a font name, e.g. "Courier bold 12", instead of 
 -- as a pango font description object;
    function setFont(atom x, object fnt)
    ------------------------------------
    fnt = gtk_func("pango_font_description_from_string",{P},{fnt})
    gtk_proc("gtk_widget_override_font",{P,P},{x,fnt})
    return 1
    end function

-- The functions below handle color conversion to/from rgba,
-- as well as supplying easier-to-use method names for setting background
-- and foreground. These methods are only used to set the colors of a widget
-- in the NORMAL state, whereas if you want to set the colors in 
-- some other state, such as mouse-over, etc, you use the original
-- set(widget,"override background",STATE,"color") syntax.

    function setFg(atom x, object c)
    --------------------------------
    return overrideFg(x,0,c)
    end function

    function setBg(atom x, object c)
    --------------------------------
    return overrideBg(x,0,c)
    end function

    function overrideFg(atom x, integer state=0, object c)
    ------------------------------------------------------
    if atom(c) then
        c = text:format("#[:06X]",c)
    end if
    gtk_proc("gtk_widget_override_color",{P,I,P},{x,state,to_rgba(c)})
    return 1
    end function

    function overrideBg(atom x, integer state=0, object c)
    ------------------------------------------------------
    if atom(c) then
        c = text:format("#[:06X]",c)
    end if
    gtk_proc("gtk_widget_override_background_color",{P,I,P},{x,state,to_rgba(c)})
    return 1
    end function

widget[GtkAccessible] = {"gtk_accessible",
{GObject},
    {"set_widget",{P,P}},
    {"get_widget",{P},P,0,GtkWidget},
"GtkAccessible"}

widget[GtkContainer] =  {"gtk_container",
{GtkWidget,GtkBuildable,GObject},
    {"add",{P,P}},
    {"remove",{P,P}},
    {"check_resize",{P}},
    {"foreach",{P,P,P}},
    {"get_children",{P},P,0,GList},
    {"get_path_for_child",{P,P},P},
    {"set_focus_child",{P,P}},
    {"get_focus_child",{P},P},
    {"set_focus_vadjustment",{P,P}},
    {"get_focus_vadjustment",{P},P,0,GtkAdjustment},
    {"set_focus_hadjustment",{P,P}},
    {"get_focus_hadjustment",{P},P,0,GtkAdjustment},
    {"child_type",{P},I},
    {"forall",{P,P,P}},
    {"set_border_width",{P,I}},
    {"get_border_width",{P},I},
"GtkContainer"}

widget[GdkKeymap] = {"gdk_keymap",
{GObject},
    {"new",{},-routine_id("newKeymap")},
    {"get_default",{},-routine_id("newKeymap")},
    {"get_for_display",{P},P,0,GdkKeymap},
    {"get_capslock_state",{P},B},
    {"get_numlock_state",{P},B},
    {"get_modifier_state",{P},I},
    {"get_direction",{P},I},
    {"have_bidi_layouts",{P},B},
    {"lookup_key",{P,P},I},
"GdkKeymap"}

    function newKeymap(atom disp=0)
    if disp=0 then
        return gtk_func("gdk_keymap_get_default")
    else
        return gtk_func("gdk_keymap_get_for_display",{P},P)
    end if
    end function

widget[GdkKeyval] = {"gdk_keyval",
{GdkKeymap,GObject},
    {"name",{I},S},
    {"from_name",{S},I},
    {"to_unicode",{I},I},
"GdkKeyval"}
          
widget[GtkBin] = {"gtk_bin", 
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"get_child",{P},P},
"GtkBin"}

widget[GtkButton] = {"gtk_button",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newBtn")},
    {"set_relief",{P,I}},
    {"get_relief",{P},I},
    {"set_label",{P,S}},
    {"get_label",{P},S},
    {"set_use_underline",{P,B}},
    {"get_use_underline",{P},B},
    {"set_focus_on_click",{P,B}},
    {"get_focus_on_click",{P},B},
    {"set_alignment",{P,F,F}}, -- Deprecated 3.14
    {"get_alignment",{P,F,F}}, -- Deprecated 3.15
    {"set_image",{P,P}},
    {"get_image",{P},P,0,GtkImage},
    {"set_image_position",{P,I}},
    {"get_image_position",{P},I},
    {"set_always_show_image",{P,B}}, -- GTK 3.6+
    {"get_always_show_image",{P},B}, -- GTK 3.6+
    {"get_event_window",{P},P,0,GdkWindow},
"GtkButton"}

    function newBtn(object cap = 0)
    ---------------------------------------------------------------
    -- handles creation of buttons with icons from various sources;
    -- this function modified greatly from earlier versions
    
    atom btn = 0, img = 0

    if sequence(cap) then
        if begins("gtk-",cap) then
            btn = gtk_func("gtk_button_new_from_stock",{P},{cap})
        else 
            btn = gtk_func("gtk_button_new_with_mnemonic",{P},{cap})
        end if
    else
        btn = gtk_func("gtk_button_new")
    end if

    object icon, title, tmp
    
    if string(cap) then
        if match("#",cap) then
            tmp = split(cap,'#') 
            icon = tmp[1]
            title = tmp[2]
            img = get_icon_image(icon,GTK_ICON_SIZE_BUTTON) 
            if img > 0 then
                gtk_proc("gtk_button_set_image",{P,P},{btn,img})
            end if
            gtk_proc("gtk_button_set_label",{P,P},{btn,allocate_string(title)})
        end if
    end if
    
    return btn      
    end function

widget[GtkBox] = {"gtk_box",
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{I,I},P},
    {"pack_start",{P,P,B,B,I}},
    {"pack_end",{P,P,B,B,I}},
    {"set_homogeneous",{P,B}},
    {"get_homogeneous",{P},B},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
    {"reorder_child",{P,P,I}},
    {"query_child_packing",{P,P,B,B,I,I}},
    {"set_child_packing",{P,P,B,B,I,I}},
    {"set_baseline_position",{P,I}},
    {"get_baseline_position",{P},I},
    {"get_center_widget",{P},P}, -- GTK 3.12.1
    {"set_center_widget",{P,P}}, -- GTK 3.12.1
"GtkBox"}

widget[GtkButtonBox] = {"gtk_button_box",
{GtkBox,GtkContainer,GtkWidget,GtkBuilder,GObject},
    {"new",{I},P},
    {"set_layout",{P,I}},
    {"get_layout",{P},I},
    {"set_child_secondary",{P,P,B}},
    {"get_child_secondary",{P,P},B},
    {"set_child_non_homogeneous",{P,P,B}},
    {"get_child_non_homogeneous",{P,P},P},
"GtkButtonBox"}

widget[GtkWindow] = {"gtk_window",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{I},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
    {"set_resizable",{P,B}},
    {"get_resizable",{P},B},
    {"get_size",{P,I,I}},
    {"set_default_size",{P,I,I}},
    {"get_default_size",{P,I,I}},
    {"set_position",{P,I}},
    {"get_position",{P,I,I}},
    {"add_accel_group",{P,P}},
    {"remove_accel_group",{P,P}},
    {"activate_focus",{P},B},
    {"activate_default",{P},B},
    {"set_modal",{P,B}},
    {"get_modal",{P},B},
    {"set_default_geometry",{P,I,I}},
    {"set_geometry_hints",{P,P,P,I}},
    {"set_gravity",{P,I}},
    {"get_gravity",{P},I},
    {"set_transient_for",{P,P}},
    {"get_transient_for",{P},P},
    {"set_attached_to",{P,P}},
    {"get_attached_to",{P},P},
    {"set_destroy_with_parent",{P,B}},
    {"get_destroy_with_parent",{P},B},
    {"set_hide_titlebar_when_maximized",{P,B}},
    {"get_hide_titlebar_when_maximized",{P},B},
    {"set_screen",{P,P}},
    {"get_screen",{P},P,0,GdkScreen},
    {"is_active",{P},B},
    {"has_toplevel_focus",{P},B},
    {"add_mnemonic",{P,I,P}},
    {"remove_mnemonic",{P,I,P}},
    {"set_mnemonics_visible",{P,B}},
    {"get_mnemonics_visible",{P},B},
    {"mnemonic_activate",{P,I,I},B},
    {"activate_key",{P,P},B},
    {"propagate_key_event",{P,P},B},
    {"get_focus",{P},P},
    {"set_focus",{P,P}},
    {"set_focus_visible",{P,B}},
    {"get_focus_visible",{P},B},
    {"get_default_widget",{P},P},
    {"set_default",{P,P}},
    {"present",{P}},
    {"present_with_time",{P,P}},
    {"iconify",{P}},
    {"deiconify",{P}},
    {"stick",{P}},
    {"unstick",{P}},
    {"maximize",{P}},
    {"unmaximize",{P}},
    {"fullscreen",{P}},
    {"unfullscreen",{P}},
    {"set_keep_above",{P,B}},
    {"set_keep_below",{P,B}},
    {"begin_resize_drag",{P,I,I,I,I,I}},
    {"begin_move_drag",{P,I,I,I,I}},
    {"set_decorated",{P,B}},
    {"get_decorated",{P},B},
    {"set_deletable",{P,B}},
    {"get_deletable",{P},B},
    {"set_mnemonic_modifier",{P,I}},
    {"get_mnemonic_modifier",{P},I},
    {"set_type_hint",{P,I}},
    {"get_type_hint",{P},I},
    {"set_skip_taskbar_hint",{P,B}},
    {"get_skip_taskbar_hint",{P},B},
    {"set_skip_pager_hint",{P,B}},
    {"get_skip_pager_hint",{P},B},
    {"set_urgency_hint",{P,B}},
    {"get_urgency_hint",{P},B},
    {"set_accept_focus",{P,B}},
    {"get_accept_focus",{P},B},
    {"set_focus_on_map",{P,B}},
    {"get_focus_on_map",{P},B},
    {"set_startup_id",{P,S}},
    {"set_role",{P,S}},
    {"get_role",{P},S},
    {"get_icon",{P},P,0,GdkPixbuf},
    {"get_icon_name",{P},S},
    {"get_group",{P},P},
    {"has_group",{P},B},
    {"get_window_type",{P},I},
    {"move",{P,I,I}},
    {"parse_geometry",{P,S},B},
    {"resize",{P,I,I}},
    {"resize_to_geometry",{P,I,I}},
    {"set_has_resize_grip",{P,B}},
    {"get_has_resize_grip",{P},B},
    {"resize_grip_is_visible",{P},B}, -- Deprecated 3.14
    {"get_resize_grip_area",{P,P},B}, -- Deprecated 3.14
    {"set_titlebar",{P,P}}, -- 3.10
    {"get_titlebar",{P},P}, -- 3.16
    {"set_icon",{P,P},-routine_id("setWinIcon")},
    {"restore",{P},-routine_id("restoreWin")}, 
    {"close",{P}}, -- 3.10
    {"set_opacity",{P,D}},
    {"is_maximized",{P},B}, -- 3.12
    {"set_interactive_debugging",{B}}, -- 3.14
"GtkWindow"}

 -- this replaces a handy but deprecated GTK function which 
 -- restores a window to its original size after being resized 
 -- to fit larger contents;  
    function restoreWin(atom win)
    -----------------------------

    set(win,"hide")
    set(win,"unrealize")
    set(win,"show")
    return 1
    end function
    
 -- manages the creation of window icon from a variety of
 -- source formats; makes life simpler for the programmer.
    function setWinIcon(object win, object icon)
    --------------------------------------------
    object path 
    
    if string(icon) then
        path = canonical_path(icon)
        if file_exists(path) then
            gtk_proc("gtk_window_set_icon_from_file",{P,P},
                {win,allocate_string(path)})
            return 1
        else
            gtk_proc("gtk_window_set_icon_name",{P,P},
                {win,allocate_string(icon)})
            return 1
        end if
    end if
    
    if atom(icon) then
        if classid(icon) = GtkImage then
            icon = get(icon,"pixbuf")
        end if
        if classid(icon) = GdkPixbuf then
            gtk_proc("gtk_window_set_icon",{P,P},{win,icon})
        end if
        return 1
    end if
    
    return 0
    end function

widget[GtkMisc] = {"gtk_misc", -- deprecated 3.14
{GtkWidget,GtkBuildable,GObject},
    {"set_alignment",{P,F,F}},
    {"get_alignment",{P,F,F}},
    {"set_padding",{P,I,I}},
    {"get_padding",{P,I,I}},
"GtkMisc"}

widget[GtkLabel] = {"gtk_label",
{GtkMisc,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"new_with_mnemonic",{S},P},
    {"set_text",{P,S}},
    {"get_text",{P},S},
    {"set_markup",{P,S}},
    {"set_text_with_mnemonic",{P,S}},
    {"set_markup_with_mnemonic",{P,S}},
    {"set_pattern",{P,S}},
    {"set_justify",{P,I}},
    {"get_justify",{P},I},
    {"set_ellipsize",{P,I}},
    {"get_ellipsize",{P},I},
    {"set_width_chars",{P,I}},
    {"get_width_chars",{P},I},
    {"set_max_width_chars",{P,I}},
    {"get_max_width_chars",{P},I},
    {"set_line_wrap",{P,B}},
    {"get_line_wrap",{P},B},
    {"set_line_wrap_mode",{P,I}},
    {"get_layout_offsets",{P,I,I}},
    {"get_mnemonic_keyval",{P},I},
    {"set_selectable",{P,B}},
    {"get_selectable",{P},B},
    {"select_region",{P,I,I}},
    {"get_selection_bounds",{P,I,I},B},
    {"set_mnemonic_widget",{P,P}},
    {"get_mnemonic_widget",{P},P},
    {"get_label",{P},S},
    {"get_layout",{P},P,0,PangoLayout},
    {"get_line_wrap_mode",{P},I},
    {"set_use_markup",{P,B}},
    {"get_use_markup",{P},B},
    {"set_use_underline",{P,B}},
    {"get_use_underline",{P},B},
    {"set_single_line_mode",{P,B}},
    {"get_single_line_mode",{P},B},
    {"set_angle",{P,D}},
    {"get_current_uri",{P},S},
    {"set_track_visited_links",{P,B}},
    {"get_track_visited_links",{P},B},
    {"set_lines",{P,I}}, -- 3.10
    {"get_lines",{P},I}, -- 3.10
    {"get_xalign",{P},F}, -- 3.16
    {"get_yalign",{P},F}, -- 3.16
    {"set_xalign",{P,F}}, -- 3.16
    {"set_yalign",{P,F}}, -- 3.16
"GtkLabel"}

widget[GtkImage] = {"gtk_image",
{GtkMisc,GtkWidget,GtkBuildable,GObject},
    {"new",{P,I,I,I},-routine_id("newImage")},
    {"set_from_file",{P,S}},
    {"set_from_pixbuf",{P,P}},
    {"set_from_icon_name",{P,S,I}},
    {"set_from_animation",{P,P}},
    {"set_from_gicon",{P,P,I}},
    {"set_from_resource",{P,S}},
    {"set_from_surface",{P,P}}, -- 3.10
    {"clear",{P}},
    {"set_pixel_size",{P,I}},
    {"get_pixel_size",{P},I},
    {"get_pixbuf",{P},P,0,GdkPixbuf},
    {"get_animation",{P},P,0,GdkPixbufAnimation},
    {"get_storage_type",{P},I},
    {"get_icon_name",{P},-routine_id("getIconName")},
    {"get_icon_size",{P},-routine_id("getIconSize")},
"GtkImage"}

 -- create an image from a variety of source formats
    function newImage(object icon=0, integer size=6, integer h, integer w)
    -------------------------------------------------------------
    atom img = 0, theme
    atom err = allocate(32) 
    err = 0
    
    if atom(icon) and icon = 0 then -- blank image
        return gtk_func("gtk_image_new")
    end if
        
    if size = 0 then size = 6 end if
    if size > 6 then -- load icon from theme, sized
            theme = gtk_func("gtk_icon_theme_get_default")
            img = gtk_func("gtk_icon_theme_load_icon",{P,S,I,I,P},
                {theme,icon,size,GTK_ICON_LOOKUP_USE_BUILTIN,err})
            return gtk_func("gtk_image_new_from_pixbuf",{P},{img})
    end if
        
    if string(icon) then --
        if begins("gtk-",icon) then -- from stock (deprecated)
            return gtk_func("gtk_image_new_from_stock",{P,I},
                {allocate_string(icon),size})
        end if
        
        if file_exists(canonical_path(icon)) then -- from file
            if size+h+w < 7 then
                return gtk_func("gtk_image_new_from_file",{P},
                    {allocate_string(canonical_path(icon))})
            else
                img = newPixbuf(icon,size,h,w)
                return gtk_func("gtk_image_new_from_pixbuf",{P},{img})
            end if
        end if

        
        return gtk_func("gtk_image_new_from_icon_name",{P,I},{icon,size})
            
    end if
    
    switch classid(icon) do
        case GdkPixbuf then
            img = gtk_func("gtk_image_new_from_pixbuf",{P},{icon})
        case GIcon then
            img = gtk_func("gtk_image_new_from_gicon",{P,I},{icon,size})
        case CairoSurface_t then
            img = gtk_func("gtk_image_new_from_surface",{P},{icon})
    end switch
    
    return img
    end function

    constant fnImageInfo  = define_c_proc(GTK,"gtk_image_get_icon_name",{P,P,P})
    
    function getIconName(atom img)
    ------------------------------
    atom name = allocate(32), size = allocate(32)
    c_proc(fnImageInfo,{img,name,size})
    name = peek4u(name)
    if name > 0 then
    return peek_string(name)
    else return "?"
    end if
    end function
    
    function getIconSize(atom img)
    ------------------------------
    atom name = allocate(32), size = allocate(32)
    c_proc(fnImageInfo,{img,name,size})
    return peek4u(size)
    end function
    
widget[GdkCursor] = {"gdk_cursor",
{GObject},
    {"new",{P,P,I,I},-routine_id("newCur")},
    {"get_display",{P},P,0,GdkDisplay},
    {"get_image",{P},P,0,GdkPixbuf},
    {"get_surface",{P,D,D},P,0,CairoSurface_t},
    {"get_cursor_type",{P},I},
"GdkCursor"}

 -- manages cursor creation from a variety of sources
    function newCur(object a, object b=0, integer c=0, integer d=0)
    ---------------------------------------------------------------
    if string(b) then 
        return gtk_func("gdk_cursor_new_from_name",{P,S},
            {a,allocate_string(b)})
    end if
    if classid(b) = GdkPixbuf then
        return gtk_func("gdk_cursor_new_from_pixbuf",{P,P,I,I},{a,b,c,d})
    end if
    if classid(b) = CairoSurface_t then
        return gtk_func("gdk_cursor_new_from_surface",{P,P,D,D},{a,b,c,d})
    end if
    if classid(a) = GdkDisplay then
        return gtk_func("gdk_cursor_new_for_display",{P,I},{a,b})
    end if
    return gtk_func("gdk_cursor_new",{I},{a})
    end function

widget[GdkWindow] = {"gdk_window",
{GObject},
    {"new",{P,P,P},P},
    {"set_title",{P,S}},
    {"destroy",{P}},
    {"get_window_type",{P},I},
    {"get_display",{P},P,0,GdkDisplay},
    {"get_screen",{P},P,0,GdkScreen},
    {"get_visual",{P},P,0,GdkVisual},
    {"show",{P}},
    {"show_unraised",{P}},
    {"hide",{P}},
    {"is_destroyed",{P},B},
    {"is_visible",{P},B},
    {"is_viewable",{P},B},
    {"is_input_only",{P},B},
    {"is_shaped",{P},B},
    {"set_composited",{P,B}}, -- deprecated 3.16
    {"get_composited",{P},B}, -- deprecated 3.16
    {"set_opacity",{P,D}},
    {"set_cursor",{P,P}},
    {"get_cursor",{P},P},
    {"get_state",{P},I},
    {"scroll",{P,I,I}},
    {"move_region",{P,P,I,I}},
    {"shape_combine_region",{P,P,I,I}},
    {"set_child_shapes",{P}},
    {"merge_child_shapes",{P}},
    {"input_shape_combine_region",{P,P,I,I}},
    {"get_geometry",{P,I,I,I,I}},
    {"set_background_rgba",{P,P}},
    {"set_fullscreen_mode",{P,I}},
    {"get_fullscreen_mode",{P},I},
    {"get_scale_factor",{P},I},
    {"set_opaque_region",{P,P}},
    {"get_effective_parent",{P},P,0,GdkWindow},
    {"get_effective_toplevel",{P},P,0,GdkWindow},
    {"beep",{}},
    {"focus",{P,I}},
    {"restack",{P,P,B}},
    {"raise",{P}},
    {"lower",{P}},
    {"set_keep_above",{P,B}},
    {"set_keep_below",{P,B}},
    {"reparent",{P,P,I,I}},
    {"ensure_native",{P},B},
    {"has_native",{P},B},
    {"register_dnd",{P}},
    {"move",{P,I,I}},
    {"scroll",{P,I,I}},
    {"resize",{P,I,I}},
    {"move_resize",{P,I,I,I,I}},
    {"move_region",{P,P,I,I}},
    {"begin_resize_drag",{P,I,I,I,I,I}},
    {"begin_resize_drag_for_device",{P,I,P,I,I,I,I}},
    {"begin_move_drag",{P,I,I,I,I}},
    {"begin_move_drag_for_device",{P,P,I,I,I,I}},
    {"show_window_menu",{P,P},B},
    {"create_gl_context",{P,I,P},P,0,GdkGLContext}, -- 3.16
    {"mark_paint_from_clip",{P,P}}, -- 3.16
    {"get_clip_region",{P},P,0,CairoRegion_t},
    {"begin_paint_rect",{P,P}},
    {"begin_paint_region",{P,P}},
    {"end_paint",{P}},
    {"get_visible_region",{P},P,0,CairoRegion_t},
    {"set_invalidate_handler",{P,I}},
    {"invalidate_rect",{P,P,B}},
    {"invalidate_region",{P,P,B}},
    {"invalidate_maybe_recurse",{P,P,I,P}},
    {"get_update_area",{P},P,0,CairoRegion_t},
    {"freeze_updates",{P}},
    {"thaw_updates",{P}},
    {"process_all_updates",{P}},
    {"process_updates",{P,B}},
    {"get_frame_clock",{P},P,0,GdkFrameClock},
"GdkWindow"}

widget[GdkPixbuf] = {"gdk_pixbuf",
{GObject},
    {"new",{P,I,I,I},-routine_id("newPixbuf")},
    {"get_from_window",{P,I,I,I,I},P,0,GdkPixbuf},
    {"get_from_surface",{P,I,I,I,I},P,0,GdkPixbuf},
    {"flip",{P,I},P,0,GdkPixbuf},
    {"rotate_simple",{P,I},P,0,GdkPixbuf},
    {"scale_simple",{P,I,I,I},P,0,GdkPixbuf},
    {"add_alpha",{P,B,I,I,I},P,0,GdkPixbuf},
    {"copy_area",{P,I,I,I,I,P,I,I}},
    {"apply_embedded_orientation",{P},P,0,GdkPixbuf},
    {"fill",{P,P}},
    {"get_n_channels",{P},I},
    {"get_has_alpha",{P},B},
    {"get_colorspace",{P},I},
    {"get_bits_per_sample",{P},I},
    {"get_pixels_with_length",{P,I},P},
    {"get_width",{P},I},
    {"get_height",{P},I},
    {"get_size",{P},-routine_id("getPixbufSize")},
    {"get_rowstride",{P},I},
    {"get_byte_length",{P},I},
    {"get_option",{P,S},S},
    {"saturate_and_pixelate",{P,P,F,B},0,GdkPixbuf},
    {"composite_color_simple",{P,I,I,I,I,I,P,P},P,0,GdkPixbuf},
    {"save",{P,P,P,P},-routine_id("savePixbuf")},
"GdkPixbuf"}

 -- creates a pixbuf from a variety of sources
    function newPixbuf(object name, integer w=0, integer h=0, integer ratio=0)
    --------------------------------------------------------------------------
    atom err = allocate(32) err = 0
    atom fn, fx 
    object path, temp=0

    if string(name) then
        path = canonical_path(name) 
        if file_exists(path) then
            path = allocate_string(path)
            goto "build"
        end if
        
        if has_icon(name) then
            path = icon_info(name) 
            path = allocate_string(path[3])
            goto "build"
        end if      
    end if -- string name;
    
    return 0
    
    label "build"
    
        if h = 0 and w = 0 then -- return at original size;
            return gtk_func("gdk_pixbuf_new_from_file",{P,P},{path,err})
        end if
        if w > 0 and h = 0 then
            h = -1
            return gtk_func("gdk_pixbuf_new_from_file_at_scale",{P,I,I,B,P},{path,w,h,ratio,err})
        end if
        if w = 0 and h > 0 then
            w = -1
            return gtk_func("gdk_pixbuf_new_from_file_at_scale",{P,I,I,B,P},{path,w,h,ratio,err})
        end if
        if w > 0 and h > 0 then
            return gtk_func("gdk_pixbuf_new_from_file_at_scale",{P,I,I,B,P},{path,w,h,ratio,err})
        end if
        
    return 0
    end function

 -- save a pixbuf in various formats based on file extension(.png, .jpg, etc)
    function savePixbuf(atom handle, object fn, object ft, object params = 0)
    -------------------------------------------------------------------------
        fn = allocate_string(fn)
        ft = allocate_string(ft)
        if string(params) then
            params = split(params,'=')
            for i = 1 to length(params) do
                params[i] = allocate_string(params[i])
            end for
        end if

    atom err = allocate(16) err = 0
    if atom(params) then 
        return gtk_func("gdk_pixbuf_save",{P,P,P,P,P},{handle,fn,ft,err,0})
    else
        return gtk_func("gdk_pixbuf_save",{P,P,P,P,P,P,P},{handle,fn,ft,err,params[1],params[2],0})
    end if
    end function

    function getPixbufSize(object pb)
    ---------------------------------------
    return {get(pb,"width"),get(pb,"height")}
    end function
    
widget[GtkDialog] = {"gtk_dialog",
{GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"run",{P},I},
    {"response",{P,I}},
    {"add_button",{P,S,I},P,0,GtkButton},
    {"get_action_area",{P},P,0,GtkBox}, -- Deprecated 3.12
    {"add_action_widget",{P,P,I}},
    {"get_content_area",{P},P,0,GtkBox},
    {"set_default_response",{P,I}},
    {"set_response_sensitive",{P,I,B}},
    {"get_response_for_widget",{P,P},I},
    {"get_widget_for_response",{P,I},P},
    {"get_header_bar",{P},P},-- GTK 3.12
"GtkDialog"}
   
widget[GtkMessageDialog] = {"gtk_message_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,I,I,I,S,S},P},
    {"new_with_markup",{P,I,I,I,S,S},P},
    {"set_markup",{P,S}},
    {"set_image",{P,P}}, -- Deprecated 3.12
    {"get_image",{P},P}, -- Deprecated 3.12
    {"format_secondary_text",{P,S,S}},
    {"format_secondary_markup",{P,S,S}},
"GtkMessageDialog"}

widget[GtkSeparator] = {"gtk_separator",
{GtkWidget,GtkBuildable,GObject},
    {"new",{I},P},
"GtkSeparator"}

widget[GtkEditable] = {"gtk_editable",
{GObject},
    {"select_region",{P,I,I}},
    {"get_selection_bounds",{P,I,I}},
    {"insert_text",{P,S,I,I}},
    {"delete_text",{P,I,I}},
    {"get_chars",{P,I,I},S},
    {"cut_clipboard",{P}},
    {"copy_clipboard",{P}},
    {"paste_clipboard",{P}},
    {"delete_selection",{P}},
    {"set_position",{P,I}},
    {"get_position",{P},I},
    {"set_editable",{P,B}},
    {"get_editable",{P},B},
"GtkEditable"}

widget[GtkEntry] = {"gtk_entry",
{GtkWidget,GtkEditable,GtkCellEditable,GObject},
    {"new",{},P},
    {"get_buffer",{P},P,0,GtkEntryBuffer},
    {"set_buffer",{P,P}},
    {"set_text",{P,S}},
    {"get_text",{P},S},
    {"get_text_length",{P},I},
    {"get_text_area",{P,P}},
    {"set_visibility",{P,B}},
    {"get_visibility",{P},B},
    {"set_invisible_char",{P,I}},
    {"get_invisible_char",{P},I},
    {"unset_invisible_char",{P}},
    {"set_max_length",{P,I}},
    {"get_max_length",{P},I},
    {"set_activates_default",{P,B}},
    {"get_activates_default",{P},B},
    {"set_has_frame",{P,B}},
    {"get_has_frame",{P},B},
    {"set_width_chars",{P,I}},
    {"get_width_chars",{P},I},
    {"set_alignment",{P,F}},
    {"get_alignment",{P},F},
    {"set_placeholder_text",{P,S}}, -- GTK 3.2+
    {"get_placeholder_text",{P},S}, -- GTK 3.2+
    {"set_overwrite_mode",{P,B}},
    {"get_overwrite_mode",{P},B},
    {"get_layout",{P},P,0,PangoLayout},
    {"set_completion",{P,P}},
    {"get_completion",{P},P,0,GtkEntryCompletion},
    {"set_progress_fraction",{P,D}},
    {"set_progress_pulse_step",{P,D}},
    {"progress_pulse",{P}},
    {"set_icon_from_stock",{P,I,S}}, -- deprecated 3.10
    {"set_icon_from_pixbuf",{P,I,P}},
    {"set_icon_from_icon_name",{P,I,S}},
    {"set_icon_from_gicon",{P,I,P}},
    {"get_icon_storage_type",{P,I},I},
    {"get_icon_pixbuf",{P,I},P,0,GdkPixbuf},
    {"get_icon_name",{P,I},S},
    {"get_icon_gicon",{P,I},P,0,GIcon},
    {"set_icon_activatable",{P,I,B}},
    {"set_icon_sensitive",{P,I,B}},
    {"get_icon_at_pos",{P,I,I},I},
    {"set_icon_tooltip_text",{P,I,S}},
    {"get_icon_tooltip_text",{P,I},S},
    {"set_icon_tooltip_markup",{P,I,S}},
    {"get_icon_tooltip_markup",{P,I},S},
    {"set_tabs",{P,P}}, -- 3.10
    {"get_tabs",{P},P,0,PangoTabArray}, -- 3.10
    {"get_max_width_chars",{P},I}, -- 3.12
    {"set_max_width_chars",{P,I}}, -- 3.12
    {"im_context_filter_keypress",{P,I},B},
"GtkEntry"}

widget[GtkSpinButton] = {"gtk_spin_button",
{GtkEditable,GtkEntry,GtkWidget,GtkBuildable,GObject},
    {"set_adjustment",{P,P}},
    {"get_adjustment",{P},P,0,GtkAdjustment},
    {"set_digits",{P,I}},
    {"get_digits",{P},I},
    {"set_range",{P,D,D}},
    {"get_range",{P,D,D}},
    {"set_value",{P,D}},
    {"get_value",{P},D},
    {"get_value_as_int",{P},I},
    {"set_update_policy",{P,I}},
    {"set_numeric",{P,B}},
    {"get_numeric",{P},B},
    {"set_wrap",{P,B}},
    {"get_wrap",{P},B},
    {"spin",{P,I,D}},
    {"update",{P}},
    {"get_increments",{P,D,D}},
    {"set_snap_to_ticks",{P,B}},
    {"get_snap_to_ticks",{P},B},
    {"configure",{P,P,D,I}},
    {"new",{D,D,D},-routine_id("newSpinBtn")},
"GtkSpinButton"}

    constant
        newsb1 = define_c_func(GTK,"gtk_spin_button_new",{P,D,I},P),
        newsb2 = define_c_func(GTK,"gtk_spin_button_new_with_range",{D,D,D},P)
        
 -- create a spin button from an ajustment object or from a range of values
    function newSpinBtn(atom a, atom b, atom c)
    -------------------------------------------
    atom sb = 0
    if classid(a) = GtkAdjustment then
        sb = c_func(newsb1,{a,b,c})
    else 
        sb = c_func(newsb2,{a,b,c})
    end if
    return sb
    end function

widget[GtkOrientable] = {"gtk_orientable",
{GObject},
    {"set_orientation",{P,I}},
    {"get_orientation",{P},I},
"GtkOrientable"}

widget[GtkRange] = {"gtk_range",
{GtkOrientable,GtkWidget,GtkBuildable,GObject},
    {"set_fill_level",{P,D}},
    {"get_fill_level",{P},D},
    {"set_restrict_to_fill_level",{P,B}},
    {"get_restrict_to_fill_level",{P},B},
    {"set_show_fill_level",{P,B}},
    {"get_show_fill_level",{P},B},
    {"set_adjustment",{P,P}},
    {"get_adjustment",{P},P},
    {"set_inverted",{P,B}},
    {"get_inverted",{P},B},
    {"set_value",{P,D}},
    {"get_value",{P},D},
    {"set_increments",{P,D,D}},
    {"set_range",{P,D,D}},
    {"set_round_digits",{P,I}},
    {"get_round_digits",{P},I},
    {"set_lower_stepper_sensitivity",{P,I}},
    {"get_lower_stepper_sensitivity",{P},I},
    {"set_upper_stepper_sensitivity",{P,I}},
    {"get_upper_stepper_sensitivity",{P},I},
    {"set_flippable",{P,B}},
    {"get_flippable",{P},B},
    {"set_min_slider_size",{P,I}},
    {"get_min_slider_size",{P},I},
    {"get_slider_range",{P,I,I}},
    {"set_slider_size_fixed",{P,B}},
    {"get_slider_size_fixed",{P},B},
"GtkRange"}

widget[GtkScale] = {"gtk_scale",
{GtkOrientable,GtkRange,GtkWidget,GtkBuildable,GObject},
    {"set_digits",{P,I}},
    {"get_digits",{P},I},
    {"set_draw_value",{P,B}},
    {"get_draw_value",{P},B},
    {"set_has_origin",{P,B}},
    {"get_has_origin",{P},B},
    {"set_value_pos",{P,I}},
    {"get_value_pos",{P},I},
    {"get_layout",{P},P,0,PangoLayout},
    {"get_layout_offsets",{P,I,I}},
    {"add_mark",{P,D,I,S}},
    {"clear_marks",{P}},
    {"new",{P,P,P,P},-routine_id("newScale")},
"GtkScale"}

 -- create scale from range or adjustment;
    function newScale(integer orient, atom min=0, atom max=0, atom step=0)
    ----------------------------------------------------------------------
    if classid(min) = GtkAdjustment then
        return gtk_func("gtk_scale_new",{I,P},{orient,min})
    else
        return gtk_func("gtk_scale_new_with_range",{I,D,D,D},{orient,min,max,step})
    end if
    end function 

widget[GTimeout] = {"g_timeout",
{0},
    {"new",{I,P,P},-routine_id("newTimeout")},
"GTimeout"}

    function newTimeout(integer ms, atom fn, atom data)
    ---------------------------------------------------
    return gtk_func("g_timeout_add",{I,P,P},{ms,fn,data})
    end function

widget[GIdle] = {"g_idle",
{0},
    {"add",{P,P},-routine_id("newIdle")},
"GIdle"}

    function newIdle(atom fn, atom data)
    ------------------------------------
    return gtk_func("g_idle_add",{P,P},{fn,data})
    end function

widget[GAppInfo] = {"g_app_info",
{0},
    {"get_name",{P},S},
    {"get_display_name",{P},S},
    {"get_description",{P},S},
    {"get_executable",{P},S},
    {"get_commandline",{P},S},
    {"get_icon",{P},P,0,GIcon},
    {"launch",{P,P,P,P},B},
    {"supports_files",{P},B},
    {"supports_uris",{P},B},
    {"launch_uris",{P,P,P,P},B},
    {"should_show",{P},B},
    {"can_delete",{P},B},
    {"delete",{P},B},
    {"set_as_default_for_type",{P,S,P},B},
    {"set_as_default_for_extension",{P,S,P},B},
    {"add_supports_type",{P,S,P},B},
    {"can_remove_supports_type",{P},B},
    {"remove_supports_type",{P,S,P},B},
    {"get_all",{},P,0,GList},
"GAppInfo"}

widget[GFile] = {"g_file",
{GObject},
    {"new",{P},-routine_id("newGFile")},
    {"get_parse_name",{P},S},
    {"parse_name",{S},P},
"GFile"}

 -- create a GFile from a path or uri
    function newGFile(object s)
    ---------------------------
    if file_exists(canonical_path(s)) then
        return gtk_func("g_file_new_for_path",{S},{canonical_path(s)})
    else
        return gtk_func("g_file_new_for_uri",{S},{s})
    end if
    return 0
    end function

widget[GIcon] = {"g_icon",
{GObject},
    {"hash",{P},I},
    {"equal",{P,P},B},
    {"to_string",{P},S},
    {"new_for_string",{S,P},P},
"GIcon"}

widget[GFileIcon] = {"g_file_icon",
{GIcon,GObject},
    {"new",{P},P},
    {"get_file",{P},P},
"GFileIcon"}

widget[GList] = {"g_list",
{GObject},
    {"new",{},-routine_id("newGList")},
    {"append",{P,P},P},
    {"length",{P},I},
    {"nth_data",{P,I},P},
"GList"}

    function newGList()
    -------------------
    atom x = allocate(64) x = 0
    return x
    end function

widget[GSList] = {"g_slist",
{GObject},
"GSList"}

widget[GdkDisplay] = {"gdk_display",
{GObject},
    {"new",{},-routine_id("getDisplay")},
    {"open",{S},P,0,GdkDisplay},
    {"get_default",{},P,0,GdkDisplay},
    {"get_name",{P},S},
    {"get_n_screens",{P},I},
    {"get_screen",{P,I},P,0,GdkScreen},
    {"get_default_screen",{P},P,0,GdkScreen},
    {"get_device_manager",{P},P,0,GdkDeviceManager},
    {"pointer_ungrab",{P,I}},
    {"pointer_is_grabbed",{P},B},
    {"device_is_grabbed",{P,P},B},
    {"beep",{P}},
    {"sync",{P}},
    {"flush",{P}},
    {"close",{P}},
    {"is_closed",{P},B},
    {"get_event",{P},P,0,GdkEvent},
    {"peek_event",{P},P,0,GdkEvent},
    {"put_event",{P,P}},
    {"has_pending",{P},B},
    {"set_double_click_time",{P,I}},
    {"set_double_click_distance",{P,I}},
    {"get_pointer",{P,S,I,I,I}},
    {"list_devices",{P},P,0,GList},
    {"get_window_at_pointer",{P,I,I},P,0,GdkWindow},
    {"warp_pointer",{P,S,I,I}},
    {"supports_cursor_color",{P},B},
    {"supports_cursor_alpha",{P},B},
    {"get_default_cursor_size",{P},I},
    {"get_maximal_cursor_size",{P,I,I}},
    {"get_default_group",{P},P,0,GdkWindow},
    {"supports_selection_notification",{P},B},
    {"request_selection_notification",{P,P},B},
    {"supports_clipboard_persistence",{P},B},
    {"store_clipboard",{P,P,I,P,I}},
    {"supports_shapes",{P},B},
    {"supports_input_shapes",{P},B},
    {"supports_composite",{P},B},
    {"get_app_launch_context",{P},P,0,GtkAppLaunchContext},
    {"notify_startup_complete",{P,S}},
"GdkDisplay"}

    function getDisplay()
    ---------------------
    return gtk_func("gdk_display_get_default",{})
    end function

widget[GdkDevice] = {"gdk_device",
{GObject},
    {"get_position",{P,P,I,I}},
"GdkDevice"}

widget[GdkScreen] = {"gdk_screen",
{GdkDevice,GObject},
    {"new",{},-routine_id("getDefScrn")},
    {"get_system_visual",{P},P,0,GdkVisual},
    {"get_rgba_visual",{P},P,0,GdkVisual},
    {"is_composited",{P},B},
    {"get_root_window",{P},P,0,GdkWindow},
    {"get_display",{P},P,0,GdkDisplay},
    {"get_number",{P},I},
    {"get_width",{P},I}, 
    {"get_height",{P},I},
    {"get_width_mm",{P},I},
    {"get_height_mm",{P},I},
    {"list_visuals",{P},P,0,GList},
    {"get_toplevel_windows",{P},P,0,GList},
    {"make_display_name",{P},S},
    {"get_n_monitors",{P},I},
    {"get_primary_monitor",{P},I},
    {"get_monitor_geometry",{P,I,P}},
    {"get_monitor_workarea",{P,I,P}},
    {"get_monitor_at_point",{P,I,I},I},
    {"get_monitor_at_window",{P,P},I},
    {"get_monitor_height_mm",{P,I},I},
    {"get_monitor_width_mm",{P,I},I},
    {"get_monitor_plug_name",{P,I},S},
    {"get_setting",{P,S,P},B},
    {"get_font_options",{P},P,0,CairoFontOptions},
    {"get_resolution",{P},D},
    {"set_resolution",{P,D}},
    {"get_active_window",{P},P,0,GdkWindow},
    {"get_window_stack",{P},P,0,GList},
"GdkScreen"}

    function getDefScrn()
    ---------------------
    return gtk_func("gdk_screen_get_default",{})
    end function

widget[GdkVisual] = {"gdk_visual",
{GObject},
"GdkVisual"}

widget[GThemedIcon] =  {"g_themed_icon",
{GIcon,GObject},
    {"new",{S},P},
    {"new_with_default_fallbacks",{S},P},
    {"get_names",{P},P},
"GThemedIcon"}

widget[GtkThemedIcon] = {"gtk_themed_icon",
{GObject},
"GtkThemedIcon"}

widget[GEmblem] = {"g_emblem",
{GObject},
    {"new",{P},P},
    {"get_icon",{P},P},
"GEmblem"}

widget[GEmblemedIcon] = {"g_emblemed_icon",
{GIcon,GObject},
    {"new",{P,P},P},
"GEmblemedIcon"}

widget[GdkDeviceManager] = {"gdk_device_manager",
{GObject},
    {"get_display",{P},P,0,GdkDisplay},
    {"list_devices",{P,I},P,0,GList},
    {"get_client_pointer",{P},P,0,GdkDevice},
"GdkDeviceManager"}

widget[GtkAppChooser] = {"gtk_app_chooser",
{GtkWidget,GObject},
    {"get_app_info",{P},P,0,GAppInfo},
    {"get_content_type",{P},S},
    {"refresh",{P}},
"GtkAppChooser"}

widget[GtkAppChooserButton] = {"gtk_app_chooser_button",
{GtkAppChooserDialog,GtkAppChooser,GtkComboBox,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"append_custom_item",{P,S,S,P}},
    {"append_separator",{P}},
    {"set_active_custom_item",{P,S}},
    {"set_show_default_item",{P,B}},
    {"get_show_default_item",{P},B},
    {"set_show_dialog_item",{P,B}},
    {"get_show_dialog_item",{P},B},
    {"set_heading",{P,S}},
    {"get_heading",{P},S},
"GtkAppChooserButton"}

widget[GMenu] = {"g_menu",
{GObject},
    {"new",{},P},
    {"append",{P,S,S}},
"GMenu"}

widget[GtkApplication] = {"gtk_application",
{GObject},
    {"new",{S,I},-routine_id("newApp")},
    {"add_window",{P,P}},
    {"remove_window",{P,P}},
    {"get_windows",{P},P,0,GList},
    {"get_window_by_id",{P,I},P,0,GtkWindow},
    {"get_active_window",{P},P,0,GtkWindow},
    {"inhibit",{P,P,I,S},I},
    {"uninhibit",{P,I}},
    {"is_inhibited",{P,I},B},
    {"get_app_menu",{P},P},
    {"set_app_menu",{P,P}},
    {"get_menubar",{P},P},
    {"set_menubar",{P,P}},
    {"add_accelerator",{P,S,S,P}},
    {"remove_accelerator",{P,S,P}},
    {"run",{P},-routine_id("appRun")},
    {"activate",{P},-routine_id("appActivate")},
    {"get_accels_for_action",{P,S},P,0,GSList}, -- 3.12
    {"set_accels_for_action",{P,S,S}},
    {"list_action_descriptions",{P},P,0,GSList},
    {"get_actions_for_accel",{P,S},P}, -- 3.14
    {"get_menu_by_id",{P,S},P}, -- 3.14
    {"prefers_app_menu",{},B}, -- 3.14
"GtkApplication"}

    function appValid(object x)
    ---------------------------
    return gtk_func("g_application_id_is_valid",{S},{x})
    end function

    function appActivate(object x)
    ------------------------------
    gtk_proc("g_application_activate",{P},{x})
    return 1
    end function

    function appRun(object x)
    -------------------------
    gtk_proc("g_application_run",{P,I,P},{x,0,0})
    return 1
    end function

    function newApp(object id, object flags)
    ----------------------------------------
    if string(id) then id = allocate_string(id) end if
    if appValid(id) then
        return gtk_func("gtk_application_new",{P,I},{id,flags})
    else
        crash("Error: invalid application id!")
    end if
    return 0
    end function
    
widget[GtkApplicationWindow] = {"gtk_application_window",
{GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},P},
    {"set_show_menubar",{P,B}},
    {"get_show_menubar",{P},B},
    {"get_id",{P},I},
"GtkApplicationWindow"}

widget[GtkAppLaunchContext] = {"gtk_app_launch_context",
{0},
"GtkAppLaunchContext"}

widget[GtkAspectFrame] = {"gtk_aspect_frame",
{GtkFrame,GtkBin,GtkContainer,GtkWidget,GtkBuilder,GObject},
    {"new",{S,F,F,F,B},P},
    {"set",{P,F,F,F,B}},
"GtkAspectFrame"}

widget[GtkAssistant] = {"gtk_assistant",
{GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuilder,GObject},
    {"new",{},P},
    {"set_current_page",{P,I}},
    {"get_current_page",{P},I},
    {"get_n_pages",{P},I},
    {"get_nth_page",{P,I},P,0,GtkWidget},
    {"prepend_page",{P,P},I},
    {"append_page",{P,P},I},
    {"insert_page",{P,P,I},I},
    {"remove_page",{P,I}},
    {"set_forward_page_func",{P,P,P,P}},
    {"set_page_type",{P,P,P}},
    {"get_page_type",{P,P},I},
    {"set_page_title",{P,P,S}},
    {"get_page_title",{P,P},S},
    {"set_page_complete",{P,P,B}},
    {"get_page_complete",{P,P},B},
    {"add_action_widget",{P,P}},
    {"remove_action_widget",{P,P}},
    {"update_buttons_state",{P}},
    {"commit",{P}},
    {"next_page",{P}},
    {"previous_page",{P}},
"GtkAssistant"}

widget[GtkCssProvider] = {"gtk_css_provider",
{GtkStyleProvider,GObject},
    {"new",{P},-routine_id("newProvider")},
    {"get_default",{},P,0,GtkCssProvider},
    {"get_named",{S,S},P,0,GtkCssProvider},
    {"load_from_data",{P,S,I,P},B},
    {"load_from_file",{P,P,P},B},
    {"load_from_path",{P,S,P},B},
    {"to_string",{P},S},
"GtkCssProvider"}

    function newProvider(object name=0)
    -----------------------------------
    atom provider = gtk_func("gtk_css_provider_get_default")
    atom style = create(GtkStyleContext)
    atom screen = get(style,"screen")

    atom err = allocate(64) err = 0
    register(provider,GtkCssProvider)
    if atom(name) then
        return provider
    end if
    if get(provider,"load from path",canonical_path(name),err) then
        set(style,"add provider for screen",screen,provider,800)           
    else 
        printf(1,"Error finding or parsing css %s \n",{name})
    end if
    return provider
    end function
    
widget[GtkCssSection] = {"gtk_css_section",
{GObject},
    {"get_end_line",{P},I},
    {"get_end_position",{P},I},
    {"get_file",{P},P},
    {"get_parent",{P},P,0,GtkCssSection},
    {"get_section_type",{P},I},
    {"get_start_line",{P},I},
    {"get_start_position",{P},I},
    {"ref",{P},P,0,GtkCssSection},
    {"unref",{P}},
"GtkCssSection"}

widget[GtkStatusIcon] = {"gtk_status_icon", -- Deprecated 3.14
{GObject},
    {"new",{},P},
    {"new_from_pixbuf",{P},P},
    {"new_from_file",{S},P},
    {"new_from_icon_name",{S},P},
    {"new_from_gicon",{P},P},
    {"set_from_pixbuf",{P,P}},
    {"set_from_file",{P,S}},
    {"set_from_icon_name",{P,S}},
    {"set_from_gicon",{P,P}},
    {"get_storage_type",{P},I},
    {"get_pixbuf",{P},P,0,GdkPixbuf},
    {"get_icon_name",{P},S},
    {"get_gicon",{P},P},
    {"get_size",{P},I},
    {"set_screen",{P,P}},
    {"get_screen",{P},P},
    {"set_tooltip_text",{P,S}},
    {"get_tooltip_text",{P},S},
    {"set_tooltip_markup",{P,S}},
    {"get_tooltip_markup",{P},S},
    {"set_has_tooltip",{P,B}},
    {"get_has_tooltip",{P},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
    {"set_name",{P,S}},
    {"set_visible",{P,B}},
    {"get_visible",{P},B},
    {"is_embedded",{P},B},
    {"get_geometry",{P,P,P,I},B},
    {"get_x11_window_id",{P},I},
    {"position_menu",{P,P,I,I,B},-routine_id("StatIconPosMenu")},
"GtkStatusIcon"}

    constant sipm = define_c_proc(GTK,"gtk_status_icon_position_menu",{P,I,I,I,P})

    function StatIconPosMenu(atom stat, atom menu, integer x, integer y, integer p)
    display("Stat [] Menu []",{stat,menu})
    c_proc(sipm,{menu,x,y,p,stat})
    return 1
    end function 
     
widget[GtkOffscreenWindow] = {"gtk_offscreen_window",
{GtkBuildable,GObject},
"GtkOffscreenWindow"}

widget[GtkAlignment] = {"gtk_alignment", -- deprecated 3.14
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{F,F,F,F},P},
    {"set",{P,F,F,F,F}},
    {"set_padding",{P,I,I,I,I}},
    {"get_padding",{P,I,I,I,I}},
"GtkAlignment"}

widget[GtkComboBox] = {"gtk_combo_box",
{GtkCellLayout,GtkBin,GtkContainer,GtkWidget,GtkCellLayout,GtkCellEditable,GtkBuildable,GObject},
    {"new",{P},-routine_id("newComboBox")},
    {"set_wrap_width",{P,I}},
    {"get_wrap_width",{P},I},
    {"set_row_span_column",{P,I}},
    {"get_row_span_column",{P},I},
    {"set_column_span_column",{P,I}},
    {"get_column_span_column",{P},I},
    {"set_active",{P,I}},
    {"get_active",{P},I},
    {"set_id_column",{P,I}},
    {"get_id_column",{P},I},
    {"set_active_id",{P,S}},
    {"get_active_id",{P},S},
    {"set_model",{P,P}},
    {"get_model",{P},P},
    {"popup_for_device",{P,P}},
    {"popup",{P}},
    {"popdown",{P}},
    {"get_popup_accessible",{P},P},
    {"set_row_separator_func",{P,P,P,P}},
    {"get_row_separator_func",{P},P},
    {"set_add_tearoffs",{P,B}}, -- Deprecated 3.10
    {"get_add_tearoffs",{P},B}, -- Deprecated 3.10
    {"set_title",{P,S}}, -- Deprecated 3.10
    {"get_title",{P},S}, -- Deprecated 3.10
    {"set_focus_on_click",{P,B}},
    {"get_focus_on_click",{P},B},
    {"set_button_sensitivity",{P,I}},
    {"get_button_sensitivity",{P},I},
    {"get_has_entry",{P},B},
    {"set_entry_text_column",{P,I}},
    {"get_entry_text_column",{P},I},
    {"set_popup_fixed_width",{P,B}},
    {"get_popup_fixed_width",{P},B},
"GtkComboBox"}

 -- create a combo box either empty or from a model
    function newComboBox(object x=0)
    --------------------------------
    if x = 0 then
        return gtk_func("gtk_combo_box_new",{},{})
    end if
    if classid(x) = GtkListStore then
        return gtk_func("gtk_combo_box_new_with_model",{P},{x})
    end if
    end function

widget[GtkComboBoxText] = {"gtk_combo_box_text",
{GtkComboBox,GtkBin,GtkContainer,GtkWidget,GtkCellLayout,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_entry",{},P},
    {"append",{P,S,S}},
    {"prepend",{P,S,S}},
    {"insert",{P,I,S,S}},
    {"append_text",{P,S}},
    {"prepend_text",{P,S}},
    {"insert_text",{P,I,S}},
    {"remove",{P,I}},
    {"remove_all",{P}},
    {"get_active_text",{P},S},
"GtkComboBoxText"}

widget[GtkComboBoxEntry] = {"gtk_combo_box_text",
{GtkComboBoxText,GtkComboBox,GtkBin,GtkContainer,GtkWidget,GObject},
    {"new",{},-routine_id("newComboBoxEntry")},
"GtkComboBoxEntry"}

    function newComboBoxEntry()
    ---------------------------
    return gtk_func("gtk_combo_box_text_new_with_entry",{},{})
    end function

widget[GtkFrame] = {"gtk_frame",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"set_label",{P,S}},
    {"get_label",{P},S},
    {"set_label_align",{P,F,F}},
    {"get_label_align",{P,F,F}},
    {"set_label_widget",{P,P}},
    {"get_label_widget",{P},P},
    {"set_shadow_type",{P,I}},
    {"get_shadow_type",{P},I},
"GtkFrame"}

widget[GtkToggleButton] = {"gtk_toggle_button",
{GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newToggleBtn")},
    {"new_with_label",{S},P},
    {"new_with_mnemonic",{S},P},
    {"set_mode",{P,B}},
    {"get_mode",{P},B},
    {"toggled",{P}},
    {"set_active",{P,B}},
    {"get_active",{P},B},
    {"set_inconsistent",{P,B}},
    {"get_inconsistent",{P},B},
"GtkToggleButton"}

 -- handles creation of buttons with icons from various sources;
 -- this function modified greatly from GTK versions prior to 10
    function newToggleBtn(object cap = 0)
    ---------------------------------------------------------------
    atom btn = 0, img = 0, default_theme = 0

    if atom(cap) and cap = 0 then  -- return a blank button;
        return gtk_func("gtk_toggle_button_new")
    end if
    
    object icon = 0, title = 0, tmp
    if string(cap) then
        if match("#",cap) then
            tmp = split(cap,'#') 
            icon = tmp[1]
            title = tmp[2]
        else
            icon = cap
            title = cap
        end if
    end if

    btn = gtk_func("gtk_toggle_button_new_with_mnemonic",{P},
        {allocate_string(title)})

    img = get_icon_image(icon,3)
    if img  > 0 then
        title = allocate_string(title)
        gtk_proc("gtk_button_set_image",{P,P},{btn,img})
        gtk_proc("gtk_button_set_label",{P,P},{btn,title})
    end if
    
    return btn      
    end function
    
widget[GtkCheckButton] = {"gtk_check_button",
{GtkToggleButton,GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newCheckBtn")},
"GtkCheckButton"}

    function newCheckBtn(object cap = 0)
---------------------------------------------------------------
    atom btn = 0, img = 0, default_theme = 0

    if atom(cap) and cap = 0 then  -- return a blank button;
        return gtk_func("gtk_check_button_new")
    end if
    
    object icon = 0, title = 0, tmp
    if string(cap) then
        if match("#",cap) then
            tmp = split(cap,'#') 
            icon = tmp[1]
            title = tmp[2]
        else
            icon = cap
            title = cap
        end if
    end if

    btn = gtk_func("gtk_check_button_new_with_mnemonic",{P},
        {allocate_string(title)})
    
    img = get_icon_image(icon,GTK_ICON_SIZE_SMALL_TOOLBAR)
    if img  > 0 then
        title = allocate_string(title)
        gtk_proc("gtk_button_set_image",{P,P},{btn,img})
        gtk_proc("gtk_button_set_label",{P,P},{btn,title})
    end if
    
    return btn      
    end function
    
widget[GtkRadioButton] = {"gtk_radio_button",
{GtkCheckButton,GtkToggleButton,GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},-routine_id("newRadioBtn")},
    {"set_group",{P,P}},
    {"get_group",{P,P}},
    {"join_group",{P,P}},
"GtkRadioButton"}

    function newRadioBtn(atom group, object cap = 0)
---------------------------------------------------------------
    atom btn = 0, img = 0, default_theme = 0

    if atom(cap) and cap = 0 then  -- return a blank button;
        return gtk_func("gtk_radio_button_new_from_widget",{P},{group})
    end if
    
    object icon = 0, title = 0, tmp
    if string(cap) then
        if match("#",cap) then
            tmp = split(cap,'#') 
            icon = tmp[1]
            title = tmp[2]
        else
            icon = cap
            title = cap
        end if
    end if

    btn = gtk_func("gtk_radio_button_new_with_mnemonic_from_widget",{P,P},
        {group,allocate_string(title)})

    img = get_icon_image(icon,GTK_ICON_SIZE_BUTTON)
    if img  > 0 then
        title = allocate_string(title)
        gtk_proc("gtk_button_set_image",{P,P},{btn,img})
        gtk_proc("gtk_button_set_label",{P,P},{btn,title})
    end if
    
    return btn      
    end function
    
widget[GtkColorButton] = {"gtk_color_button",
{GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GtkColorChooser,GObject},
    {"new",{},P},
    {"new_with_rgba",{P},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
"GtkColorButton"}

widget[GtkFontButton] = {"gtk_font_button",
{GtkFontChooser,GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_font",{S},P},
    {"set_font_name",{P,S}},
    {"get_font_name",{P},S},
    {"set_show_style",{P,B}},
    {"get_show_style",{P},B},
    {"set_show_size",{P,B}},
    {"get_show_size",{P},B},
    {"set_use_font",{P,B}},
    {"get_use_font",{P},B},
    {"set_use_size",{P,B}},
    {"get_use_size",{P},B},
    {"set_title",{P,S}},
    {"get_title",{P},S},
"GtkFontButton"}

widget[GtkLinkButton] = {"gtk_link_button",
{GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,S},-routine_id("newLinkButton")},
    {"set_uri",{P,S}},
    {"get_uri",{P},S},
    {"set_visited",{P,B}},
    {"get_visited",{P},B},
"GtkLinkButton"}

    function newLinkButton(object link, object lbl=0)
    -------------------------------------------------
    if lbl = 0 then return gtk_func("gtk_link_button_new",{S},{link}) 
    else return gtk_func("gtk_link_button_new_with_label",{S,S},{link,lbl})
    end if
    end function

widget[GtkLockButton] = {"gtk_lock_button", -- unable to make this work!
{GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},P},
    {"set_permission",{P,P}},
    {"get_permission",{P},P},
"GtkLockButton"}

widget[GtkScaleButton] = {"gtk_scale_button",
{GtkButton,GtkBin,GtkContainer,GtkWidget,GtkOrientable,GtkBuildable,GObject},
    {"new",{I,D,D,D,P},P},
    {"set_adjustment",{P,P}},
    {"get_adjustment",{P},P,0,GtkAdjustment},
    {"set_value",{P,D}},
    {"get_value",{P},D},
    {"get_popup",{P},P},
    {"get_plus_button",{P},P},
    {"get_minus_button",{P},P},
    {"set_icons",{P,P},-routine_id("setScaleButtonIcons")},
"GtkScaleButton"}

    function setScaleButtonIcons(atom btn, object icons)
    ----------------------------------------------------
    gtk_proc("gtk_scale_button_set_icons",{P,P},
            {btn,allocate_string_pointer_array(icons)})
    return 1
    end function

widget[GtkMenu] = {"gtk_menu",
{GtkMenuShell,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_from_model",{P},P},
    {"attach",{P,P,I,I,I,I}},
    {"attach_to_widget",{P,P,P}},
    {"get_attach_widget",{P},P},
    {"detach",{P}},
    {"popup",{P,P,P,P,P,I,I}},
    {"popdown",{P}},
    {"reposition",{P}},
    {"set_active",{P,I}},
    {"get_active",{P},P},
    {"popup_for_device",{P,P,P,P,P,P,P,I,I}},
    {"set_accel_group",{P,P}},
    {"get_accel_group",{P},P},
    {"set_accel_path",{P,S}},
    {"get_accel_path",{P},S},
    {"set_title",{P,S}}, -- Deprecated 3.10
    {"get_title",{P},S}, -- Deprecated 3.10
    {"set_monitor",{P,I}},
    {"get_monitor",{P},I},
    {"set_tearoff_state",{P,B}}, -- Deprecated 3.10
    {"get_tearoff_state",{P},B}, -- Deprecated 3.10
    {"set_reserve_toggle_size",{P,B}},
    {"get_reserve_toggle_size",{P},B},
    {"set_screen",{P,P}},
"GtkMenu"}

widget[GtkMenuBar] = {"gtk_menu_bar",
{GtkMenuShell,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_from_model",{P},P},
    {"set_pack_direction",{P,I}},
    {"get_pack_direction",{P},I},
    {"set_child_pack_direction",{P,I}},
    {"get_child_pack_direction",{P},I},
"GtkMenuBar"}

widget[GMenu] = {"g_menu",
{GMenuModel,GObject},
    {"new",{},P},
    {"freeze",{P}},
    {"insert",{P,I,S,S}},
    {"prepend",{P,S,S}},
    {"append",{P,S,S}},
    {"insert_item",{P,I,P}},
    {"append_item",{P,P}},
    {"prepend_item",{P,P}},
    {"insert_section",{P,I,S,P}},
    {"prepend_section",{P,S,P}},
    {"append_section",{P,S,P}},
    {"append_submenu",{P,S,P}},
    {"insert_submenu",{P,I,S,P}},
    {"prepend_submenu",{P,S,P}},
    {"remove",{P,I}},
"GMenu"}

widget[GMenuModel] = {"g_menu_model",
{GObject},
    {"is_mutable",{P},B},
    {"get_n_items",{P},I},
    {"get_item_attribute",{P,I,S,S,P},B},
    {"get_item_link",{P,I,S},P,0,GMenuModel},
    {"items_changed",{P,I,I,I}},
"GMenuModel"}

widget[GMenuItem] = {"g_menu_item",
{GObject},
    {"new",{S,S},P},
    {"new_section",{S,P},P,0,GMenuItem},
    {"new_submenu",{S,P},P,0,GMenuItem},
    {"set_label",{P,S}},
    {"set_action_and_target_value",{P,S,P}},
    {"set_detailed_action",{P,S}},
    {"set_section",{P,P}},
    {"set_submenu",{P,P}},
    {"set_attribute_value",{P,P,P}},
    {"set_link",{P,S,P}},
"GMenuItem"}

widget[GtkMenuButton] = {"gtk_menu_button", --3.6
{GtkToggleButton,GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_popup",{P,P}},
    {"get_popup",{P},P,0,GtkMenu},
    {"set_menu_model",{P,P}},
    {"get_menu_model",{P},P,0,GMenuModel},
    {"set_direction",{P,I}},
    {"get_direction",{P},I},
    {"set_align_widget",{P,P}},
    {"get_align_widget",{P},P,0,GtkWidget},
    {"set_popover",{P,P}}, -- 3.12
    {"get_popover",{P},P,0,GtkPopover}, -- 3.12
    {"set_use_popover",{P,B}}, -- 3.12
    {"get_use_popover",{P},B}, -- 3.12
"GtkMenuButton"}

widget[GtkMenuItem] = {"gtk_menu_item",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newMenuItem")},
    {"new_with_label",{S},P},
    {"new_with_mnemonic",{S},P},
    {"set_label",{P,S},P},
    {"get_label",{P},S},
    {"set_use_underline",{P,B}},
    {"get_use_underline",{P},B},
    {"set_submenu",{P,P}},
    {"get_submenu",{P},P},
    {"set_accel_path",{P,S}},
    {"get_accel_path",{P},S},
    {"select",{P}},
    {"deselect",{P}},
    {"activate",{P}},
    {"toggle_size_allocate",{P,I}},
    {"set_reserve_indicator",{P,B}},
    {"get_reserve_indicator",{P},B},
"GtkMenuItem"}

    function newMenuItem(object x=0)
    --------------------------------
    if string(x) then
        return gtk_func("gtk_menu_item_new_with_mnemonic",{P},{x})
    elsif x > 0 then
        return gtk_func("gtk_menu_item_new_with_mnemonic",{P},{x})
    else
        return gtk_func("gtk_menu_item_new",{},{})
    end if
    end function

widget[GtkImageMenuItem] = {"gtk_image_menu_item", -- warning: deprecated in 3.10
{GtkMenuItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,I,P,P},-routine_id("newImageMenuItem")},
    {"set_image",{P,P}},
    {"get_image",{P},P},
    {"set_use_stock",{P,B}},
    {"get_use_stock",{P},B},
    {"set_always_show_image",{P,B}},
    {"get_always_show_image",{P},B},
    {"set_accel_group",{P,P}},
"GtkImageMenuItem"}

 -- creates image menu item, with image from a variety of sources,
 -- and user-defined title with/without hot keys
    function newImageMenuItem(object stk, atom accel=0, object fn=0, atom data=0)
    -----------------------------------------------------------------------------
    object item=0, img=0, tmp, title=0, default_theme
    stk = split(stk,'#')

    if length(stk) = 2 then 
        title = stk[2]
        stk = stk[1]
    else
        stk = stk[1]
        title = 0
    end if
    
    if string(stk) then
    
        if begins("gtk-",stk) then
            item = gtk_func("gtk_image_menu_item_new_from_stock",{S,I},{stk,accel})
            if atom(title) then
                return item
            end if
        end if
    
        -- see if there's an icon;
        default_theme = gtk_func("gtk_icon_theme_get_default",{})
        tmp = allocate_string(stk) 
        if gtk_func("gtk_icon_theme_has_icon",{P,P},{default_theme,tmp}) then
                img = gtk_func("gtk_image_new_from_icon_name",{P,P},{tmp,1}) 
                if string(title) then
                    item = gtk_func("gtk_image_menu_item_new_with_mnemonic",{P},{title})
                else
                    item = gtk_func("gtk_image_menu_item_new")
                end if
                gtk_proc("gtk_image_menu_item_set_image",{P,P},{item,img})
                return item
        end if

        -- no, maybe it's an image from a file;
        if img = 0 then
            tmp = canonical_path(stk)  
            if file_exists(tmp) then
                img = create(GtkImage,tmp)
                if string(title) then
                    item = gtk_func("gtk_image_menu_item_new_with_mnemonic",{P},{title})
                else
                    item = gtk_func("gtk_image_menu_item_new")
                end if
                gtk_proc("gtk_image_menu_item_set_image",{P,P},{item,img})
                return item
            end if
        end if
        
    end if
    -- failed to find any image;
    item = gtk_func("gtk_menu_item_new_with_mnemonic",{P},{title})
    
    return item
    end function

widget[GtkNumerableIcon] = {"gtk_numerable_icon", -- Deprecated 3.14
{GIcon,GEmblemedIcon,GObject},
    {"new",{P},P,0,GIcon},
    {"new_with_style_context",{P,P},P,0,GIcon},
    {"get_background_gicon",{P},P,0,GIcon},
    {"set_background_gicon",{P,P}},
    {"get_background_icon_name",{P},S},
    {"set_background_icon_name",{P,S}},
    {"get_count",{P},I},
    {"set_count",{P,I}},
    {"get_label",{P},S},
    {"set_label",{P,S}},
    {"get_style_context",{P},P,0,GtkStyleContext},
    {"set_style_context",{P,P}},
"GtkNumerableIcon"}

widget[GtkEventBox] = {"gtk_event_box",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_above_child",{P,B}},
    {"get_above_child",{P},B},
    {"set_visible_window",{P,B}},
    {"get_visible_window",{P},B},
"GtkEventBox"}

widget[GtkExpander] = {"gtk_expander",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newExp")},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
    {"set_expanded",{P,B}},
    {"get_expanded",{P},B},
    {"set_label",{P,S}},
    {"get_label",{P},S},
    {"set_label_widget",{P,P}},
    {"get_label_widget",{P},P},
    {"set_label_fill",{P,B}},
    {"get_label_fill",{P},B},
    {"set_use_underline",{P,B}},
    {"get_use_underline",{P},B},
    {"set_use_markup",{P,B}},
    {"get_use_markup",{P},B},
    {"set_resize_toplevel",{P,B}},
    {"get_resize_toplevel",{P},B},
"GtkExpander"}

    function newExp(sequence caption)
    if match("_",caption) then
        return gtk_func("gtk_expander_new_with_mnemonic",{P},{caption})
    else
        return gtk_func("gtk_expander_new",{P},{caption})
    end if
    end function
    
widget[GtkToolItem] = {"gtk_tool_item",
{GtkBin,GtkContainer,GtkWidget,GObject},
    {"new",{},P},
    {"set_homogeneous",{P,B}},
    {"get_homogeneous",{P},B},
    {"set_expand",{P,B}},
    {"get_expand",{P},B},
    {"set_tooltip_text",{P,S}},
    {"set_tooltip_markup",{P,S}},
    {"set_use_drag_window",{P,B}},
    {"get_use_drag_window",{P},B},
    {"set_visible_horizontal",{P,B}},
    {"get_visible_horizontal",{P},B},
    {"set_visible_vertical",{P,B}},
    {"get_visible_vertical",{P},B},
    {"set_is_important",{P,B}},
    {"get_is_important",{P},B},
    {"get_ellipsize_mode",{P},I},
    {"get_icon_size",{P},I},
    {"get_orientation",{P},I},
    {"get_toolbar_style",{P},I},
    {"get_relief_style",{P},I},
    {"get_text_alignment",{P},F},
    {"get_text_orientation",{P},I},
    {"retrieve_proxy_menu_item",{P},P,0,GtkWidget},
    {"set_proxy_menu_item",{P,S,P}},
    {"get_proxy_menu_item",{P,S},P,0,GtkWidget},
    {"rebuild_menu",{P}},
    {"toolbar_reconfigured",{P}},
    {"get_text_size_group",{P},P,0,GtkSizeGroup},
"GtkToolItem"}

widget[GtkToolButton] = {"gtk_tool_button",
{GtkToolItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},-routine_id("newTB")},
    {"set_label",{P,S}},
    {"get_label",{P},S},
    {"set_use_underline",{P,B}},
    {"get_use_underline",{P},B},
    {"set_stock_id",{P,S}}, -- Deprecated 3.10
    {"get_stock_id",{P},S}, -- Deprecated 3.10
    {"set_icon_name",{P,S}},
    {"get_icon_name",{P},S},
    {"set_icon_widget",{P,P}},
    {"get_icon_widget",{P},P},
    {"set_label_widget",{P,P}},
    {"get_label_widget",{P},P},
"GtkToolButton"}

    function newTB(object icn=0, object lbl=0)
    --------------------------------------------------
    if string(icn) then
        icn = create(GtkImage,icn,1)
    end if
    if string(lbl) then
        lbl = allocate_string(lbl,1)
    end if
    atom btn = gtk_func("gtk_tool_button_new",{P,P},{icn,lbl})
    return btn
    end function

widget[GtkMenuToolButton] = {"gtk_menu_tool_button",
{GtkToolButton,GtkToolItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},-routine_id("newMenuTB")},
    {"set_menu",{P,P}},
    {"get_menu",{P},P},
    {"set_arrow_tooltip_text",{P,S}},
    {"set_arrow_tooltip_markup",{P,S}},
"GtkMenuToolButton"}

    function newMenuTB(object icn=0, object lbl=0)
    if string(icn) then
        icn = create(GtkImage,icn,1)
    end if
    if string(lbl) then
        lbl = allocate_string(lbl,1)
    end if
    atom btn = gtk_func("gtk_menu_tool_button_new",{P,P},{icn,lbl})
    return btn
    end function
    
widget[GtkToggleToolButton] = {"gtk_toggle_tool_button",
{GtkToolButton,GtkToolItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},-routine_id("newToggleToolButton")},
    {"set_active",{P,B}},
    {"get_active",{P},B},
"GtkToggleToolButton"}

    function newToggleToolButton(object txt)
    ----------------------------------------
    return gtk_func("gtk_toggle_tool_button_new_from_stock",{S},{txt})
    end function

widget[GtkRadioToolButton] = {"gtk_radio_tool_button",
{GtkToggleToolButton,GtkToolButton,GtkToolItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P},-routine_id("newRadioToolButton")},
    {"set_group",{P,P}},
    {"get_group",{P},P},
"GtkRadioToolButton"}

    function newRadioToolButton(atom id)
    ------------------------------------
    if classid(id) = GtkRadioToolButton then
        return gtk_func("gtk_radio_tool_button_new_from_widget",{P},{id})
    else
        return gtk_func("gtk_radio_tool_button_new",{P},{id})
    end if
    end function

widget[GtkSeparatorToolItem] = {"gtk_separator_tool_item",
{GtkToolItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_draw",{P,B}},
    {"get_draw",{P},B},
"GtkSeparatorToolItem"}

widget[GtkOverlay] = {"gtk_overlay",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"add_overlay",{P,P}},
"GtkOverlay"}

widget[GtkScrollable] = {"gtk_scrollable",
{GObject},
    {"set_hadjustment",{P,P}},
    {"get_hadjustment",{P},P,0,GtkAdjustment},
    {"set_vadjustment",{P,P}},
    {"get_vadjustment",{P},P,0,GtkAdjustment},
    {"set_hscroll_policy",{P,I}},
    {"get_hscroll_policy",{P},I},
    {"set_vscroll_policy",{P,I}},
    {"get_vscroll_policy",{P},I},
"GtkScrollable"}

widget[GtkScrolledWindow] = {"gtk_scrolled_window",
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},P},
    {"set_hadjustment",{P,P}},
    {"get_hadjustment",{P},P,0,GtkAdjustment},
    {"set_vadjustment",{P,P}},
    {"get_vadjustment",{P},P,0,GtkAdjustment},
    {"get_hscrollbar",{P},P},
    {"get_vscrollbar",{P},P},
    {"set_policy",{P,I,I}},
    {"get_policy",{P,I,I}},
    {"set_placement",{P,I}},
    {"unset_placement",{P}},
    {"set_shadow_type",{P,I}},
    {"get_shadow_type",{P},I},
    {"set_min_content_width",{P,I}},
    {"get_min_content_width",{P},I},
    {"set_min_content_height",{P,I}},
    {"get_min_content_height",{P},I},
    {"set_kinetic_scrolling",{P,B}},
    {"get_kinetic_scrolling",{P},B},
    {"set_capture_button_press",{P,B}},
    {"get_capture_button_press",{P},B},
    {"set_headers",{P,P}},
    {"add_with_viewport",{P,P}}, -- Deprecated 3.8
    {"get_overlay_scrolling",{P},B}, -- 3.16
    {"set_overlay_scrolling",{P,B}}, -- 3.16
"GtkScrolledWindow"}

widget[GtkSidebar] = {"gtk_sidebar", -- 3.16
{GtkBin,GtkContainer,GtkWidget,GObject},
    {"new",{},P},
    {"set_stack",{P,P}},
    {"get_stack",{P},P,0,GtkStack},
"GtkSidebar"}

widget[GtkTextBuffer] = {"gtk_text_buffer",
{GObject},
    {"new",{P},P},
    {"get_line_count",{P},I},
    {"get_char_count",{P},I},
    {"get_tag_table",{P},P,0,GtkTextTagTable},
    {"insert",{P,P,S,I}},
    {"insert_at_cursor",{P,S,I}},
    {"insert_interactive",{P,P,S,I,B},B},
    {"insert_interactive_at_cursor",{P,S,I,B},B},
    {"insert_range",{P,P,P,P}},
    {"insert_range_interactive",{P,P,P,P,B},B},
    {"insert_with_tags",{P,P,S,I,P,P}},
    {"insert_with_tags_by_name",{P,P,S,I,S}},
    {"delete",{P,P,P}},
    {"delete_interactive",{P,P,P,B},B},
    {"backspace",{P,P,B,B},B},
    {"set_text",{P,P},-routine_id("setBufferText")},
    {"get_text",{P},-routine_id("getBufferText")},
    {"get_slice",{P,P,P,B},S},
    {"insert_pixbuf",{P,P,P}},
    {"insert_child_anchor",{P,P,P}},
    {"create_child_anchor",{P,P},P,0,GtkTextChildAnchor},
    {"create_mark",{P,S,P,B},P,0,GtkTextMark},
    {"move_mark",{P,P,P}},
    {"move_mark_by_name",{P,S,P}},
    {"add_mark",{P,P,P}},
    {"delete_mark",{P,P}},
    {"delete_mark_by_name",{P,S}},
    {"get_mark",{P,S},P,0,GtkTextMark},
    {"get_insert",{P},P,0,GtkTextMark},
    {"get_selection_bound",{P},P,0,GtkTextMark},
    {"get_selection_bounds",{P},-routine_id("getSelectionBounds")},
    {"get_has_selection",{P},B},
    {"place_cursor",{P,P}},
    {"select_range",{P,P,P}},
    {"apply_tag",{P,P,P,P}},
    {"remove_tag",{P,P,P,P}},
    {"apply_tag_by_name",{P,S,P,P}},
    {"remove_tag_by_name",{P,S,P,P}},
    {"remove_all_tags",{P,P,P}},
    {"create_tag",{P,S,S,S},P,0,GtkTextTag},
    {"get_iter_at_line_offset",{P,P,I,I}},
    {"get_iter_at_offset",{P,P,I}},
    {"get_iter_at_line",{P,P,I}},
    {"get_iter_at_line_index",{P,P,I,I}},
    {"get_iter_at_mark",{P,P,P}},
    {"get_iter_at_child_anchor",{P,P,P}},
    {"get_start_iter",{P,P}},
    {"get_end_iter",{P,P}},
    {"get_bounds",{P,P,P}},
    {"set_modified",{P,B}},
    {"get_modified",{P},B},
    {"delete_selection",{P,B,B},B},
    {"paste_clipboard",{P,P,P,B}},
    {"copy_clipboard",{P,P}},
    {"cut_clipboard",{P,P,B}},
    {"get_selection_bounds",{P,P,P},B},
    {"begin_user_action",{P}},
    {"end_user_action",{P}},
    {"add_selection_clipboard",{P,P}},
    {"remove_selection_clipboard",{P,P}},
    {"deserialize",{P,P,I,P,I,I,P},B},
    {"deserialize_set_can_create_tags",{P,I,B}},
    {"deserialize_get_can_create_tags",{P,I},B},
    {"get_copy_target_list",{P},P,0,GtkTargetList},
    {"get_deserialize_formats",{P,I},P},
    {"get_paste_target_list",{P},P,0,GtkTargetList},
    {"get_serialize_formats",{P,I},P},
    {"register_deserialize_format",{P,S,P,P,P},P},
    {"register_deserialize_tagset",{P,S},P},
    {"register_serialize_format",{P,S,P,P,P},P},
    {"register_serialize_tagset",{P,S},P},
    {"serialize",{P,P,P,P,P,I},I},
    {"unregister_deserialize_format",{P,P}},
    {"unregister_serialize_format",{P,P}},
"GtkTextBuffer"}

    constant 
        fnBufStart = define_c_proc(GTK,"gtk_text_buffer_get_start_iter",{P,P}),
        fnBufEnd = define_c_proc(GTK,"gtk_text_buffer_get_end_iter",{P,P}),
        fnBufGet = define_c_func(GTK,"gtk_text_buffer_get_text",{P,P,P,B},S),
        fnBufSet = define_c_proc(GTK,"gtk_text_buffer_set_text",{P,S,I}),
        fnBufIns = define_c_func(GTK,"gtk_text_buffer_get_insert",{P},P),
        fnBufIter = define_c_proc(GTK,"gtk_text_buffer_get_iter_at_mark",{P,P,P}),
        fnBufBounds = define_c_func(GTK,"gtk_text_buffer_get_selection_bounds",{P,P,P},B)

    function getBufferText(object buf)
    ----------------------------------
    atom start = allocate(64) c_proc(fnBufStart,{buf,start})
    atom fini = allocate(64) c_proc(fnBufEnd,{buf,fini})
    object result = c_func(fnBufGet,{buf,start,fini,1})
    return peek_string(result)
    end function

    function getSelectionBounds(object buf)
    ---------------------------------------
    atom start = allocate(100)
    atom fini = allocate(100)
    atom iter = allocate(100)
    if c_func(fnBufBounds,{buf,start,fini}) then
        return {start,fini}
    else
        start = c_func(fnBufIns,{buf})
        c_proc(fnBufIter,{buf,iter,start})
    return {iter,iter}
    end if
    end function

    function setBufferText(object buf, object txt)
    object len
    if atom(txt) then 
        len = peek_string(txt)
        len = length(len)
    else
        len = length(txt)
        txt = allocate_string(txt)
    end if
    c_proc(fnBufSet,{buf,txt,len})
    return 1
    end function

widget[GtkClipboard] = {"gtk_clipboard",
{GObject},
    {"new",{I},-routine_id("newClipBoard")},
    {"get_for_display",{P,I},P,0,GtkClipboard},
    {"get_display",{P},P,0,GdkDisplay},
    {"set_with_data",{P,P,I,P,P,P},B},
    {"set_with_owner",{P,P,I,P,P,P},B},
    {"get_owner",{P},P,0,GObject},
    {"clear",{P}},
    {"set_text",{P,S,I}},
    {"set_image",{P,P}},
    {"request_contents",{P,I,P,P}},
    {"request_text",{P,P,P}},
    {"request_image",{P,P,P}},
    {"request_targets",{P,P,P}},
    {"request_rich_text",{P,P,P,P}},
    {"request_uris",{P,P,P}},
    {"wait_for_contents",{P,I},P,0,GtkSelectionData},
    {"wait_for_text",{P},S},
    {"wait_for_image",{P},P,0,GdkPixbuf},
    {"wait_for_rich_text",{P,P,I,I},I},
    {"wait_for_uris",{P},A},
    {"wait_is_text_available",{P},B},
    {"wait_is_image_available",{P},B},
    {"wait_is_rich_text_available",{P,P},B},
    {"wait_is_uris_available",{P},B},
    {"wait_for_targets",{P,P,I},B},
    {"wait_is_target_available",{P,I},B},
    {"set_can_store",{P,P,I}},
    {"store",{P}},
"GtkClipboard"}

    function newClipBoard(integer i)
    --------------------------------
    return gtk_func("gtk_clipboard_get",{I},{i})
    end function

widget[GtkSelectionData] = {"gtk_selection_data",
{0},
    {"set",{P,I,I,S,I}},
    {"set_text",{P,S,I},B},
    {"get_text",{P},S},
    {"set_pixbuf",{P,P},B},
    {"get_pixbuf",{P},P,0,GdkPixbuf},
    {"set_uris",{P,S},B},
    {"get_uris",{P},A},
    {"get_targets",{P,P,I},B},
    {"targets_include_image",{P,B},B},
    {"targets_include_text",{P},B},
    {"targets_include_uri",{P},B},
    {"targets_include_rich_text",{P,P},B},
    {"get_selection",{P},P},
    {"get_data",{P},S},
    {"get_length",{P},I},
    {"get_data_with_length",{P,I},S},
    {"get_data_type",{P},I},
    {"get_display",{P},P,0,GdkDisplay},
    {"get_format",{P},I},
    {"get_target",{P},I},
"GtkSelectionData"}

widget[GtkCellArea] = {"gtk_cell_area",
{GtkCellLayout,GtkBuildable,GObject},
    {"add",{P,P}},
    {"remove",{P,P}},
    {"has_renderer",{P,P},B},
    {"foreach",{P,P}},
    {"foreach_alloc",{P,P,P,P,P,P,P}},
    {"event",{P,P,P,P,P,I},I},
    {"render",{P,P,P,P,P,P,I,B}},
    {"get_cell_allocation",{P,P,P,P,P,P}},
    {"get_cell_at_position",{P,P,P,P,I,I,P},P},
    {"create_context",{P},P,0,GtkCellAreaContext},
    {"copy_context",{P,P},P,0,GtkCellAreaContext},
    {"get_request_mode",{P},I},
    {"get_preferred_width",{P,P,P,I,I}},
    {"get_preferred_height_for_width",{P,P,P,I,I,I}},
    {"get_preferred_height",{P,P,P,I,I}},
    {"get_preferred_width_for_height",{P,P,P,I,I,I}},
    {"get_current_path",{P},S},
    {"apply_attributes",{P,P,P,B,B}},
    {"attribute_connect",{P,P,S,I}},
    {"attribute_disconnect",{P,P,S}},
    {"is_activatable",{P},B},
    {"focus",{P,I},B},
    {"set_focus_cell",{P,P}},
    {"get_focus_cell",{P},P,0,GtkCellRenderer},
    {"add_focus_sibling",{P,P,P}},
    {"remove_focus_sibling",{P,P,P}},
    {"is_focus_sibling",{P,P,P},B},
    {"get_focus_from_sibling",{P,P},P,0,GtkCellRenderer},
    {"get_edited_cell",{P},P,0,GtkCellRenderer},
    {"get_edit_widget",{P},P,0,GtkCellEditable},
    {"stop_editing",{P,B}},
    {"request_renderer",{P,P,P,P,I,I,I}},
"GtkCellArea"}

widget[GtkCellAreaCell] = {"gtk_cell_area_cell",
{GtkCellArea},
    {"set_property",{P,P,S,P}},
    {"get_property",{P,P,S,P}},
"GtkCellAreaCell"}

widget[GtkCellAreaBox] = {"gtk_cell_area_box",
{GtkCellLayout,GtkOrientable,GtkBuildable},
    {"new",{},P},
    {"pack_start",{P,P,B,B,B}},
    {"pack_end",{P,P,B,B,B}},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
"GtkCellAreaBox"}

widget[GtkCellAreaContext] = {"gtk_cell_area_context",
{GObject},
    {"get_area",{P},P,0,GtkCellArea},
    {"allocate",{P,I,I}},
    {"reset",{P}},
    {"get_preferred_width",{P,I,I}},
    {"get_preferred_height",{P,I,I}},
    {"get_preferred_height_for_width",{P,I,I,I}},
    {"get_preferred_width_for_height",{P,I,I,I}},
    {"get_allocation",{P,I,I}},
    {"push_preferred_width",{P,I,I}},
    {"push_preferred_height",{P,I,I}},
"GtkCellAreaContext"}

widget[GtkCellEditable] = {"gtk_cell_editable",
{0},
    {"start_editing",{P,P}},
    {"editing_done",{P}},
    {"remove_widget",{P}},
"GtkCellEditable"}

widget[GtkCellLayout] = {"gtk_cell_layout",
{GObject},
    {"pack_start",{P,P,B}},
    {"pack_end",{P,P,B}},
    {"get_area",{P},P,0,GtkCellArea},
    {"get_cells",{P},P,0,GList},
    {"reorder",{P,P,I}},
    {"clear",{P}},
    {"add_attribute",{P,P,S,I}},
    {"set_cell_data_func",{P,P,P,P,P}},
    {"clear_attributes",{P,P}},
"GtkCellLayout"}

widget[GtkCellRenderer] = {"gtk_cell_renderer",
{GObject},
    {"set_fixed_size",{P,I,I}},
    {"get_fixed_size",{P,I,I}},
    {"set_visible",{P,B}},
    {"get_visible",{P},B},
    {"set_sensitive",{P,B}},
    {"get_sensitive",{P},B},
    {"set_alignment",{P,F,F}},
    {"get_alignment",{P,F,F}},
    {"set_padding",{P,I,I}},
    {"get_padding",{P,I,I}},
    {"get_state",{P,P,I},I},
    {"is_activatable",{P},B},
    {"get_aligned_area",{P,P,I,P,P}},
    {"render",{P,P,P,P,P,I}},
    {"activate",{P,P,P,P,P,P,I},B},
    {"start_editing",{P,P,P,P,P,P,I},P,0,GtkCellEditable},
    {"stop_editing",{P,B}},
    {"get_preferred_height",{P,P,I,I}},
    {"get_preferred_width",{P,P,I,I}},
    {"get_preferred_height_for_width",{P,P,I,I,I}},
    {"get_preferred_width_for_height",{P,P,I,I,I}},
    {"get_preferred_size",{P,P,P,P}},
    {"get_request_mode",{P},I},
"GtkCellRenderer"}

widget[GtkCellRendererAccel] = {"gtk_cell_renderer_accel",
{GtkCellRendererText,GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererAccel"}

widget[GtkCellRendererCombo] = {"gtk_cell_renderer_combo",
{GtkCellRendererText,GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererCombo"}

widget[GtkCellRendererText] = {"gtk_cell_renderer_text",
{GtkCellRenderer,GObject},
    {"new",{},P},
    {"set_fixed_height_from_font",{P,I}},
"GtkCellRendererText"}

widget[GtkCellRendererPixbuf] = {"gtk_cell_renderer_pixbuf",
{GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererPixbuf"}

widget[GtkCellRendererProgress] = {"gtk_cell_renderer_progress",
{GtkOrientable,GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererProgress"}

widget[GtkCellRendererSpin] = {"gtk_cell_renderer_spin",
{GtkCellRendererText,GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererSpin"}

widget[GtkCellRendererSpinner] = {"gtk_cell_renderer_spinner",
{GtkCellRenderer,GObject},
    {"new",{},P},
"GtkCellRendererSpinner"}

widget[GtkCellRendererToggle] = {"gtk_cell_renderer_toggle",
{GtkCellRenderer,GObject},
    {"new",{},P},
    {"set_radio",{P,B}},
    {"get_radio",{P},B},
    {"set_active",{P,B}},
    {"get_active",{P},B},
    {"set_activatable",{P,B}},
    {"get_activatable",{P},B},
"GtkCellRendererToggle"}

widget[GtkTreeModelFilter] = {"gtk_tree_model_filter",
{GObject},
    {"new",{P,P},P},
    {"set_visible_func",{P,P,P,P}},
    {"set_modify_func",{P,I,P,P,P,P}},
    {"set_visible_column",{P,I}},
    {"get_model",{P},P,0,GtkTreeModel},
    {"convert_child_iter_to_iter",{P,P,P},B},
    {"convert_iter_to_child_iter",{P,P,P},B},
    {"convert_child_path_to_path",{P,P},P,0,GtkTreePath},
    {"convert_path_to_child_path",{P,P},P,0,GtkTreePath},
    {"refilter",{P}},
    {"clear_cache",{P}},
"GtkTreeModelFilter"}

widget[GtkTreeModelSort] = {"gtk_tree_model_sort",
{GtkTreeModel,GtkTreeSortable,GtkTreeDragSource},
    {"new_with_model",{P},P},
    {"get_model",{P},P,0,GtkTreeModel},
    {"convert_child_path_to_path",{P,P},P,0,GtkTreePath},
    {"convert_child_iter_to_iter",{P,P,P},B},
    {"convert_path_to_child_path",{P,P},P,0,GtkTreePath},
    {"convert_iter_to_child_iter",{P,P,P}},
    {"reset_default_sort_func",{P}},
    {"clear_cache",{P}},
"GtkTreeModelSort"}

widget[GtkListStore] = {"gtk_list_store", -- HEAVILY-MODIFIED 4.8.2
{GtkTreeModel,GtkTreeSortable,GtkTreeDragSource,GtkTreeDragDest,GtkBuildable,GObject},
    {"new",{P},-routine_id("newListStore")},
    {"clear",{P}},
    {"set_data",{P,P},-routine_id("setListData")},
    {"get_data",{P},-routine_id("getListData")},
    {"get_n_rows",{P},-routine_id("nListRows")},
    {"get_n_cols",{P},-routine_id("nListCols")},
    {"set_row_data",{P,I,P},-routine_id("setListRowData")},
    {"get_row_data",{P,I},-routine_id("getListRowData")},
    {"set_col_data",{P,I,I,P},-routine_id("setListColData")},
    {"get_col_data",{P,I,I},-routine_id("getListColData")},
    {"get_col_data_from_iter",{P,P,I},-routine_id("getListColDatafromIter")},
    {"remove_row",{P,I},-routine_id("removeListRow")},
    {"replace_row",{P,I,P},-routine_id("replaceListRow")},
    {"insert_row",{P,I,P},-routine_id("insertListRow")},
    {"prepend_row",{P,P},-routine_id("prependListRow")},
    {"append_row",{P,P},-routine_id("appendListRow")},
    {"set_swap_rows",{P,I,I},-routine_id("swapListRows")},
    {"set_move_before",{P,I,I},-routine_id("movebeforeListRows")},
    {"set_move_after",{P,I,I},-routine_id("moveafterListRows")},
    {"set_move_after",{P,I,I},-routine_id("moveafterListRows")},
"GtkListStore"}

-- almost all calls to GtkListStore are overridden with Euphoria calls,
-- because the GTK versions are just too complex and tedious to set up,
-- making them impractical to use.
constant 
    TM1 = define_c_func(GTK,"gtk_tree_model_get_iter_first",{P,P},I),
    TM2 = define_c_func(GTK,"gtk_tree_model_iter_next",{P,P},I),
    TM3 = define_c_func(GTK,"gtk_tree_model_get_iter_from_string",{P,P,P},P),
    TM4 = define_c_proc(GTK,"gtk_tree_model_get",{P,P,I,P,I}),
    TM5 = define_c_func(GTK,"gtk_tree_model_get_column_type",{P,I},I),
    LS0 = define_c_proc(GTK,"gtk_list_store_clear",{P}),
    LS1 = define_c_proc(GTK,"gtk_list_store_insert",{P,P,I}),
    LS2 = define_c_proc(GTK,"gtk_list_store_append",{P,P}),
    LS3 = define_c_proc(GTK,"gtk_list_store_swap",{P,P,P}),
    LS4 = define_c_proc(GTK,"gtk_list_store_move_before",{P,P,P}),
    LS5 = define_c_proc(GTK,"gtk_list_store_move_after",{P,P,P}),
    LS6 = define_c_func(GTK,"gtk_list_store_iter_is_valid",{P,P},B),
    $

    function newListStore(object params)
    ------------------------------------
    object proto = I & repeat(P,length(params))
    params = length(params) & params -- must build func params 'on the fly'
    atom fn = define_c_func(GTK,"gtk_list_store_new",proto,P)
    return c_func(fn,params)
    end function

    function nListRows(object store)
    --------------------------------
    return gtk_func("gtk_tree_model_iter_n_children",{P,P},{store,0})
    end function 
    
    function nListCols(object store)
    --------------------------------
    return gtk_func("gtk_tree_model_get_n_columns",{P},{store})
    end function
    
    function setListData(object store, object data)
    -----------------------------------------------
    atom iter = allocate(32)
    integer len = length(data)
    for row = 1 to len do
        c_proc(LS1,{store,iter,len}) -- new row
        if string(data[row]) then
            setListRowData(store,row,{data[row]})
        else
            setListRowData(store,row,data[row])
        end if
    end for
    return 1
    end function 
    
    function setListRowData(atom store, integer row, object data)
    -----------------------------------------------------------
    atom iter = allocate(32)
    integer max_col = nListCols(store)
    for col = 1 to math:min({length(data),max_col}) do 
        setListColData(store,row,col,data[col])
    end for
    return 1
    end function

    function setListColData(object store, object row, integer col, object data)
    ----------------------------------------------------------------------------
    integer max_col = nListCols(store)
    if col < 1 or col > max_col then 
        crash("Invalid column #%d",col) 
    end if
    
    atom iter = allocate(32)
    if not c_func(TM3,{store,iter,allocate_string(sprintf("%d",row-1))}) then
        return -1
    end if
    
    object prototype  = {P,P,I,P,I}

    integer col_type = c_func(TM5,{store,col-1})
    
    switch col_type do
        case gDBL then prototype = {P,P,I,D,I}
        case gFLT then prototype = {P,P,I,D,I}
        case gPIX then prototype = {P,P,I,P,I} 
        case gINT then prototype = {P,P,I,I,I}
        case gBOOL then prototype = {P,P,I,I,I}
    end switch
    
    ifdef LISTSTORE then
        display("Setting row [] col [] data []",{row,col,data})
    end ifdef
   
    if string(data) then data = allocate_string(data) end if

    atom fn = define_c_proc(GTK,"gtk_list_store_set",prototype)
    object params = {store,iter,col-1,data,-1}
    c_proc(fn,params)
    
    return 1
    end function

    function getListData(object store) 
    ----------------------------------
    object data = {}
    for row = 1 to nListRows(store) do
        data = append(data,getListRowData(store,row))
    end for
    return data
    end function

    function getListRowData(object store, integer row)
    ------------------------------------------------
    object data = {}
    integer max_row = nListRows(store)
    if row > max_row then return -1 end if
    
    integer max_col = nListCols(store) 
    for i = 1 to max_col do
        data = append(data,getListColData(store,row,i))
    end for
    return data
    end function 
    
    function getListColData(atom store, integer row, integer col)
    -----------------------------------------------------------
    atom x  = allocate(64)
    
    ifdef LISTSTORE then
        display("Get Col Data ~ row [] col []",{row,col})
    end ifdef
    
    integer col_type = c_func(TM5,{store,col-1})
    ifdef BITS64 then 
        poke8(x,col_type) 
    elsedef
        poke4(x,col_type) 
    end ifdef

    atom iter = allocate(64)
    c_func(TM3,{store,iter,allocate_string(sprintf("%d",row-1))})
    c_proc(TM4,{store,iter,col-1,x,-1})

    switch col_type do
        case gSTR then 
            if peek4u(x) > 0 then return peek_string(peek4u(x))
            else return 0 end if
        case gINT then return peek4u(x)
        case gBOOL then return peek(x)
        case gDBL then return float64_to_atom(peek({x,8}))
        case gFLT then return float32_to_atom(peek({x,4}))
        case gPIX then return peek4u(x)
    end switch

    return 1
    end function
        
    function getListColDatafromIter(atom store, atom iter, integer col)
    -------------------------------------------------------------------
    atom x  = allocate(64)

    ifdef LISTSTORE then
        display("Get Col Data from Iter ~ store [] iter [] col []",{store,iter,col})
    end ifdef
    
    integer col_type = c_func(TM5,{store,col-1})
    ifdef BITS64 then 
        poke8(x,col_type) 
    elsedef
        poke4(x,col_type) 
    end ifdef
 
    c_proc(TM4,{store,iter,col-1,x,-1})
   
    switch col_type do
        case gSTR then 
            if peek4u(x) > 0 then return peek_string(peek4u(x))
            else return 0 end if
        case gINT then return peek4u(x)
        case gBOOL then return peek(x)
        case gDBL then return float64_to_atom(peek({x,8}))
        case gFLT then return float32_to_atom(peek({x,4}))
        case gPIX then return peek4u(x)
    end switch

    return 1
    end function
           
    function insertListRow(object store, object data, integer pos)
    --------------------------------------------------------------
    object tmp = getListData(store) 
    tmp = insert(tmp,data,pos)
    set(store,"clear")
    setListData(store,tmp)
    return tmp
    end function
        
    function appendListRow(atom store, object data)
    -----------------------------------------------
    object tmp = getListData(store)
    tmp = append(tmp,data)
    set(store,"clear")
    set(store,"data",tmp)
    return tmp
    end function 
    
    function prependListRow(atom store, object data)
    ------------------------------------------------
    object tmp = getListData(store)
    tmp = prepend(tmp,data)
    set(store,"clear")
    set(store,"data",tmp)
    return tmp
    end function 
    
    function removeListRow(atom store, integer row)
    -----------------------------------------------
    object tmp = getListData(store)
    tmp = remove(tmp,row)
    set(store,"clear")
    setListData(store,tmp)
    return tmp
    end function 
    
    function replaceListRow(atom store, object data, integer row)
    -------------------------------------------------------------
    object tmp = getListData(store)
    set(store,"clear") 
    tmp = replace(tmp,{data},row)
    setListData(store,tmp)
    return tmp
    end function 

    function swapListRows(atom store, integer row_a, integer row_b)
    ---------------------------------------------------------------
    if get(store,"is sorted") then
        Warn(0,,"Can't move items in a sorted list!")
        return -1
    end if
    atom iter_a = allocate(32), iter_b = allocate(32)
    c_func(TM3,{store,iter_a,allocate_string(sprintf("%d",row_a-1))})
    c_func(TM3,{store,iter_b,allocate_string(sprintf("%d",row_b-1))})
    c_proc(LS3,{store,iter_a,iter_b})
    return get(store,"data")
    end function
    
    function movebeforeListRows(atom store, integer row_a, integer row_b)
    ---------------------------------------------------------------------
    if get(store,"is sorted") then
        Error(0,,"Can't move items in a sorted list!")
        return -1
    end if
    atom iter_a = allocate(32), iter_b = allocate(32)
    c_func(TM3,{store,iter_a,allocate_string(sprintf("%d",row_a-1))})
    c_func(TM3,{store,iter_b,allocate_string(sprintf("%d",row_b-1))})
    c_proc(LS4,{store,iter_b,iter_a})
    return get(store,"data")
    end function
    
    function moveafterListRows(atom store, integer row_a, integer row_b)
    --------------------------------------------------------------------
    if get(store,"is sorted") then
        Error(0,,"Can't move items in a sorted list!")
        return -1
    end if
    atom iter_a = allocate(32), iter_b = allocate(32)
    c_func(TM3,{store,iter_a,allocate_string(sprintf("%d",row_a-1))})
    c_func(TM3,{store,iter_b,allocate_string(sprintf("%d",row_b-1))})
    c_proc(LS5,{store,iter_b,iter_a})
    return get(store,"data")
    end function
    
widget[GtkTreeStore] = {"gtk_tree_store",
{GtkTreeModel,GtkTreeDragSource,GtkTreeDragDest,GtkTreeSortable,GtkBuildable,GObject},
    {"new",{P},-routine_id("newTreeStore")},
    {"get_n_rows",{P},-routine_id("nTreeRows")},
    {"get_n_cols",{P},-routine_id("nTreeCols")},
    {"get_data",{P},-routine_id("getTreeData")},
    {"set_data",{P,P},-routine_id("setTreeData")},
    {"set_row_data",{P,P,P},-routine_id("setTreeRowData")},
    {"remove_row",{P,I},-routine_id("removeTreeRow")},
    {"insert_row",{P,P,P,I}},
    {"insert_before",{P,P,P,P}},
    {"insert_after",{P,P,P,P}},
    {"prepend",{P,P,P}},
    {"append",{P,P,P}},
    {"is_ancestor",{P,P,P},B},
    {"iter_depth",{P,P},I},
    {"clear",{P}},
    {"swap",{P,P,P}},
    {"move_before",{P,P,P}},
    {"move_after",{P,P,P}},
"GtkTreeStore"}

    constant TSA = define_c_proc(GTK,"gtk_tree_store_append",{P,P,P})
    constant TSX = define_c_proc(GTK,"gtk_tree_store_insert",{P,P,P,I}) 
    
    function newTreeStore(object params)
    ------------------------------------
    object proto = I & repeat(P,length(params))
    params = length(params) & params -- must build func params 'on the fly'
    atom fn = define_c_func(GTK,"gtk_tree_store_new",proto,P)
    return c_func(fn,params)
    end function
    
    function nTreeRows(object store)
    --------------------------------
    return gtk_func("gtk_tree_model_iter_n_children",{P,P},{store,0})
    end function 
    
    function nTreeCols(object store)
    --------------------------------
    return gtk_func("gtk_tree_model_get_n_columns",{P},{store})
    end function
    
    function setTreeData(object store, object data)
    -----------------------------------------------
    atom iter = allocate(32)
    puts(1,"\n")
    for row = 1 to length(data) do
        c_proc(TSA,{store,iter,0}) -- append new row
        setTreeRowData(store,data[row],iter)    
    end for
    return 1
    end function 
    
    function setTreeRowData(atom store, object data, object parent = 0)
    --------------------------------------------------------------------------
    integer max_col = nTreeCols(store) 
    atom iter1 = allocate(32) 
    atom iter2 = allocate(32)
    atom iter3 = allocate(32)
    atom iter4 = allocate(32)
    for i = 1 to length(data) do
        if string(data[i]) then
            setTreeColData(store,parent,i,data[i])
        else
            for j = 1 to length(data[i]) do
                if string(data[i][j]) then
                    c_proc(TSA,{store,iter1,parent})
                    setTreeColData(store,iter1,1,data[i][j])
                else
                    for k = 1 to length(data[i][j]) do
                        if string(data[i][j][k]) then
                            c_proc(TSA,{store,iter2,iter1})
                            setTreeColData(store,iter2,1,data[i][j][k])
                        else
                            for l = 1 to length(data[i][j][k]) do
                                if string(data[i][j][k][l]) then
                                    c_proc(TSA,{store,iter3,iter2})
                                    setTreeColData(store,iter3,1,data[i][j][k][l])
                                else
                                    for m = 1 to length(data[i][j][k][l]) do
                                        c_proc(TSA,{store,iter4,iter3})
                                        setTreeColData(store,iter4,1,data[i][j][k][l][m])
                                    end for
                                end if
                            end for
                        end if
                    end for
                end if
            end for
        end if
    end for
    return 1
    end function

    function setTreeColData(object store, object iter, integer col, object item)
    ----------------------------------------------------------------------------
    integer max_col = nTreeCols(store)
    if col < 1 or col > max_col then 
        crash("Invalid column #%d",col) 
    end if
    
    object prototype  = {P,P,I,P,I}

    integer col_type

    col_type = c_func(TM5,{store,col-1})
    switch col_type do
        case gDBL then prototype = {P,P,I,D,I}
        case gFLT then prototype = {P,P,I,D,I}
        case gPIX then prototype = {P,P,I,P,I} 
        case gINT then prototype = {P,P,I,I,I}
        case gBOOL then prototype = {P,P,I,I,I}
        case gSTR then prototype = {P,P,I,P,I}
            if atom(item) then item = sprintf("%g",item) end if
    end switch

    if string(item[1]) then item = item[1] end if
    if string(item) then item = allocate_string(item) end if

    atom fn = define_c_proc(GTK,"gtk_tree_store_set",prototype)
    object params = {store,iter,col-1,item,-1}
    c_proc(fn,params)
        
    return iter
    end function
    
    function getTreeData(atom store)
    --------------------------------
    object rowdata = {}
    object column = {}
    for row = 1 to nTreeRows(store) do
        for col = 1 to nTreeCols(store) do
            column = append(column,get(store,"col data",col))
        end for
        rowdata = append(rowdata,column)
        column = {}
    end for
    return rowdata
    end function
    
    function removeTreeRow(atom store, integer row)
    -----------------------------------------------
    object tmp = get(store,"data")
    tmp = remove(tmp,row)
    set(store,"data",tmp)
    return tmp
    end function
    
widget[GtkTreeDragSource] = {"gtk_tree_drag_source",
{0},
"GtkTreeDragSource"}

widget[GtkTreeDragDest] = {"gtk_tree_drag_dest",
{0},
"GtkTreeDragDest"}

widget[GtkTreePath] = {"gtk_tree_path",
{GObject},
    {"new",{P},-routine_id("newPath")},
    {"to_string",{P},S},
    {"to_integer",{P},-routine_id("pathtoNumber")},
    {"new_first",{},P,0,GtkTreePath},
    {"append_index",{P,I}},
    {"prepend_index",{P,I}},
    {"get_depth",{P},I},
    {"get_indices",{P},A},
    {"get_indices_with_depth",{P,I},A},
    {"free",{P}},
    {"copy",{P},P,0,GtkTreePath},
    {"compare",{P,P},I},
    {"next",{P}},
    {"prev",{P},B},
    {"up",{P},B},
    {"down",{P}},
    {"is_ancestor",{P,P},B},
    {"is_descendant",{P,P},B},
"GtkTreePath"}

    function newPath(object x=0)
    ----------------------------
    if atom(x) and x > 0 then
        x = sprintf("%d",x-1)
    end if
    if string(x) then
        x = allocate_string(x)
    end if
    if x > 0 then
        return gtk_func("gtk_tree_path_new_from_string",{P},{x})
    else 
        return gtk_func("gtk_tree_path_new",{},{})
    end if
    end function 
    
    function pathtoNumber(object x)
    -------------------------------
    integer n = to_number(gtk_str_func("gtk_tree_path_to_string",{P},{x}))
    return n+1
    end function 
    
widget[GtkTreeRowReference] = {"gtk_tree_row_reference",
{GObject},
    {"new",{P,P},P,0,GtkTreeRowReference},
    {"get_model",{P},P,0,GtkTreeModel},
    {"get_path",{P},P,0,GtkTreePath},
    {"valid",{P},B},
    {"free",{P}},
    {"copy",{P},P,0,GtkTreeRowReference},
    {"inserted",{P,P}},
    {"deleted",{P,P}},
    {"reordered",{P,P,P,A}},
"GtkTreeRowReference"}

widget[GtkTreeIter] = {"gtk_tree_iter",
{GObject},
    {"new",{},-routine_id("newIter")},
    {"copy",{P},P,0,GtkTreeIter},
    {"free",{P}},
"GtkTreeIter"}

    function newIter()
    ------------------
    return allocate(64)
    end function

widget[GtkTreeModel] = {"gtk_tree_model",
{GObject},
    {"get_flags",{P},I},
    {"get_n_columns",{P},I},
    {"get_column_type",{P,I},I},
    {"get_iter",{P,P,P},B},
    {"get_iter_first",{P,P},B},
    {"get_path",{P,P},P,0,GtkTreePath},
    {"get_value",{P,P,I},-routine_id("getTMVal")},
    {"set_value",{P,I,I,P},-routine_id("setTMColVal")},
    {"iter_next",{P,P},B},
    {"iter_previous",{P,P},B},
    {"iter_children",{P,P,P},B},
    {"iter_has_child",{P,P},B},
    {"iter_n_children",{P,P},I},
    {"iter_nth_child",{P,P,P,I},B},
    {"iter_parent",{P,P,P},B},
    {"get_string_from_iter",{P,P},-routine_id("tmStrIter")},
    {"ref_node",{P,P}},
    {"unref_node",{P,P}},
    {"foreach",{P,P,P}},
    {"n_rows",{P},-routine_id("getTMnRows")},
    {"row_changed",{P,P,P}},
    {"row_inserted",{P,P,P}},
    {"row_has_child_toggled",{P,P,P}},
    {"row_deleted",{P,P}},
    {"rows_reordered",{P,P,P,P}},
    {"get_iter_n",{P,I},-routine_id("tmIterN")},
    {"get_iter_from_string",{P,S},-routine_id("tmIterStr")},
    {"get_iter_from_path",{P,P},-routine_id("tmIterPath")},
    {"get_col_value",{P,P,I},-routine_id("tmColVal")},
    {"get_row_values",{P,P},-routine_id("tmRowVals")},
    {"get_col_data",{P,P,I},-routine_id("getTreeModelCol")},
    {"get_row_data",{P,I},-routine_id("getTreeModelRow")},
"GtkTreeModel"}

    constant 
        tmstriter = define_c_func(GTK,"gtk_tree_model_get_string_from_iter",{P,P},P),
        tmiterstr = define_c_func(GTK,"gtk_tree_model_get_iter_from_string",{P,S,P},P),
        tmcolset = define_c_proc(GTK,"gtk_list_store_set",{P,P,I,P,I}),
        tmnrows = define_c_func(GTK,"gtk_tree_model_iter_n_children",{P,P},I)
        
    function getTMnRows(atom model)
    return c_func(tmnrows,{model,0})
    end function

    function tmStrIter(atom model, atom iter)
    return peek_string(c_func(tmstriter,{model,iter}))
    end function
    
    function tmIterStr(atom model, object str)
    ------------------------------------------
    atom iter = newIter() 
    if string(str) then str = allocate_string(str) end if
    if c_func(tmiterstr,{model,iter,str}) then
        return iter
    end if
    return 0
    end function

    function tmIterN(atom model, integer path)
    ------------------------------------------
    return tmIterStr(model,sprintf("%d",path-1))
    end function

    function tmIterPath(atom model, object path)
    --------------------------------------------
    return tmIterStr(model,peek_string(path))
    end function

    constant 
        fntmget = define_c_proc(GTK,"gtk_tree_model_get_value",{P,P,I,P}),
        fncoltype = define_c_func(GTK,"gtk_tree_model_get_column_type",{P,I},I),
        gtvfn = define_c_proc(GTK,"gtk_tree_model_get",{P,P,I,P,I}),
        tmncol = define_c_func(GTK,"gtk_tree_model_get_n_columns",{P},I)

    function getTMVal(atom mdl, atom iter, integer col)
    ---------------------------------------------------
    atom x  = allocate(32)
    integer ct = c_func(fncoltype,{mdl,col-1})
    ifdef BITS64 then 
        poke8(x,ct) 
    elsedef
        poke4(x,ct) 
    end ifdef
    c_proc(gtvfn,{mdl,iter,col-1,x,-1}) 
    switch ct do
        case gSTR then if peek4u(x)> 0 then return peek_string(peek4u(x)) end if
        case gINT then return peek4u(x)
        case gBOOL then return peek4u(x)
        case gFLT then return float32_to_atom(peek({x,4}))
        case gPIX then return peek4u(x)
        case else return x
    end switch
    end function

    function tmRowVals(atom mdl, atom iter)
    ---------------------------------------
    integer ncols = c_func(tmncol,{mdl}) 
    object results = repeat(0,ncols)
    for n = 1 to ncols do
        results[n] = getTMVal(mdl,iter,n)
    end for
    return results
    end function

    function tmColVal(atom mdl, integer row, integer col)
    -----------------------------------------------------
    atom iter = allocate(32)
    object data = tmRowVals(mdl,iter)
    return data[col]
    end function

    function setTMColVal(atom mdl, integer row, integer col, object data)
    ---------------------------------------------------------------------
    atom iter = tmIterN(mdl,row)
    c_proc(tmcolset,{mdl,iter,col-1,allocate_string(data),-1})
    return 1
    end function
    
    function getTreeModelCol(atom mdl, integer row, integer col)
    ------------------------------------------------------------
    object data = getTreeModelRow(mdl,row)
    return data[col]
    end function

    function getTreeModelRow(atom mdl, integer row)
    -----------------------------------------------
    atom iter = tmIterN(mdl,row)
    return tmRowVals(mdl,iter)
    end function

widget[GtkTreeSortable] = {"gtk_tree_sortable",
{GtkTreeModel,GObject},
    {"sort_column_changed",{P}},
    {"set_sort_column_id",{P,I,I}},
    {"get_sort_column_id",{P},-routine_id("TSgetSortColID")},
    {"get_sort_order",{P},-routine_id("TSgetSortOrder")},
    {"is_sorted",{P},-routine_id("TSisSorted")},
    {"set_sort_func",{P,I,P,P,P}},
    {"set_default_sort_func",{P,P,P,P}},
    {"has_default_sort_func",{P},B},
"GtkTreeSortable"}

    constant TS1 = define_c_func(GTK,"gtk_tree_sortable_get_sort_column_id",{P,P,P},B)
    
    function TSisSorted(atom mdl)
    -----------------------------
    return gtk_func("gtk_tree_sortable_get_sort_column_id",{P,P,P},{mdl,0,0})
    end function
    
    function TSsetSortColID(atom mdl, integer col, integer order)
    -------------------------------------------------------------
    gtk_proc("gtk_tree_sortable_set_sort_column_id",{P,I,I},{mdl,col-1,order})
    return 1
    end function
    
    function TSgetSortColID(atom mdl)
    ---------------------------------
    boolean success = FALSE
    integer col = allocate(16), order = allocate(16)
    if c_func(TS1,{mdl,col,order}) then
        return peek4u(col)+1
    else
        return 0
    end if
    end function
        
    function TSgetSortOrder(atom mdl)
    ---------------------------------
    boolean success = FALSE
    integer col = allocate(16), order = allocate(16)
    if c_func(TS1,{mdl,col,order}) then
        return peek4u(order)
    else
        return 0
    end if
    end function
    
widget[GtkViewport] = {"gtk_viewport",
{GtkScrollable,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},P},
    {"set_shadow_type",{P,I}},
    {"get_shadow_type",{P},I},
    {"get_bin_window",{P},P,0,GdkWindow},
    {"get_view_window",{P},P,0,GdkWindow},
"GtkViewport"}

widget[GtkAppChooserWidget] = {"gtk_app_chooser_widget",
{GtkAppChooser,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"set_show_default",{P,B}},
    {"get_show_default",{P},B},
    {"set_show_recommended",{P,B}},
    {"get_show_recommended",{P},B},
    {"set_show_fallback",{P,B}},
    {"get_show_fallback",{P},B},
    {"set_show_other",{P,B}},
    {"get_show_other",{P},B},
    {"set_show_all",{P,B}},
    {"get_show_all",{P},B},
    {"set_default_text",{P,S}},
    {"get_default_text",{P},S},
"GtkAppChooserWidget"}

widget[GtkVolumeButton] = {"gtk_volume_button",
{GtkOrientable,GtkScaleButton,GtkButton,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
"GtkVolumeButton"}

widget[GtkColorChooserWidget] = {"gtk_color_chooser_widget",
{GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GtkColorChooser,GObject},
    {"new",{},P},
"GtkColorChooserWidget"}

widget[GtkColorChooser] = {"gtk_color_chooser",
{GObject},
    {"set_rgba",{P,P},-routine_id("setccRGBA")},
    {"get_rgba",{P,I},-routine_id("getccRGBA")},
    {"set_use_alpha",{P,B},-routine_id("setccAlpha")},
    {"get_use_alpha",{P},-routine_id("getccAlpha")},
    {"add_palette",{P,I,I,I,A}},
"GtkColorChooser"}

    constant 
        fngetccrgba = define_c_proc(GTK,"gtk_color_chooser_get_rgba",{P,P}),
        fngetccalpha = define_c_func(GTK,"gtk_color_chooser_get_use_alpha",{P},B)
        
    function setccRGBA(atom x, object c)
    ------------------------------------
        gtk_proc("gtk_color_chooser_set_rgba",{P,P},{x,to_rgba(c)})
    return 1
    end function

    function getccRGBA(atom x, integer fmt)
    ---------------------------------------
    atom rgba = allocate(32)
        c_proc(fngetccrgba,{x,rgba})
    object c = gtk_func("gdk_rgba_to_string",{P},{rgba})
    return fmt_color(c,fmt)
    end function

    function setccAlpha(atom x, integer b)
    --------------------------------------
        gtk_proc("gtk_color_chooser_set_use_alpha",{P,B},{x,b})
    return 1
    end function

    function getccAlpha(atom x)
    ---------------------------
        return c_func(fngetccalpha,{x})
    end function

widget[GtkColorSelection] =  {"gtk_color_selection", -- Deprecated
{GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_has_opacity_control",{P,B}},
    {"get_has_opacity_control",{P},B},
    {"set_has_palette",{P,B}},
    {"get_has_palette",{P},B},
    {"set_current_rgba",{P,S},-routine_id("setCurrentRGBA")},
    {"get_current_rgba",{P,I},-routine_id("getCurrentRGBA")},
    {"set_current_alpha",{P,I}},
    {"get_current_alpha",{P},I},
    {"set_previous_rgba",{P,S},-routine_id("setPreviousRGBA")},
    {"get_previous_rgba",{P,I},-routine_id("getPreviousRGBA")},
    {"set_previous_alpha",{P,I}},
    {"get_previous_alpha",{P},I},
    {"is_adjusting",{P},B},
"GtkColorSelection"}

------------------------------------------------------------------------
-- following color functions make using RGB colors much easier, 
-- converting automatically between various color notations
------------------------------------------------------------------------
    constant 
        fngetCurCol = define_c_proc(GTK,"gtk_color_selection_get_current_rgba",{P,P}),
        fngetPrevCol = define_c_proc(GTK,"gtk_color_selection_get_previous_rgba",{P,P})

    function setCurrentRGBA(atom x, object c)
    -----------------------------------------
     c =peek_string(c)
    gtk_proc("gtk_color_selection_set_current_rgba",{P,P},{x,to_rgba(c)})
    return 1
    end function

    function setPreviousRGBA(atom x, object c)
    ------------------------------------------
    c = peek_string(c)
    gtk_proc("gtk_color_selection_set_previous_rgba",{P,P},{x,to_rgba(c)})
    return 1
    end function

    function getCurrentRGBA(atom x, integer fmt=0)
    ----------------------------------------------
    atom rgba = allocate(32) 
    c_proc(fngetCurCol,{x,rgba}) 
    object c = gtk_str_func("gdk_rgba_to_string",{P},{rgba}) 
    return fmt_color(c,fmt)
    end function

    function getPreviousRGBA(atom x, integer fmt=0)
    -----------------------------------------------
    atom rgba = allocate(32)
    c_proc(fngetPrevCol,{x,rgba})
    object c = gtk_func("gdk_rgba_to_string",{rgba})
    return fmt_color(c,fmt)
    end function

widget[GtkFileChooser] = {"gtk_file_chooser",
{GObject},
    {"set_action",{P,I}},
    {"get_action",{P},I},
    {"set_local_only",{P,B}},
    {"get_local_only",{P},B},
    {"set_select_multiple",{P,B}},
    {"get_select_multiple",{P},B},
    {"set_show_hidden",{P,B}},
    {"get_show_hidden",{P},B},
    {"set_do_overwrite_confirmation",{P,B}},
    {"get_do_overwrite_confirmation",{P},B},
    {"set_create_folders",{P,B}},
    {"get_create_folders",{P},B},
    {"get_current_name",{P},S}, --GTK3.10
    {"set_current_name",{P,S}},
    {"set_filename",{P,S}},
    {"get_filename",{P},S},
    {"get_filenames",{P},A,0,GSList},
    {"select_filename",{P,S}},
    {"unselect_filename",{P},S},
    {"select_all",{P}},
    {"unselect_all",{P}},
    {"set_current_folder",{P,S}},
    {"get_current_folder",{P},S},
    {"set_uri",{P,S}},
    {"get_uri",{P},S},
    {"select_uri",{P,S}},
    {"unselect_uri",{P,S}},
    {"get_uris",{P},A},
    {"set_current_folder_uri",{P,S}},
    {"get_current_folder_uri",{P},S},
    {"set_preview_widget",{P,P}},
    {"get_preview_widget",{P},P},
    {"set_preview_widget_active",{P,B}},
    {"get_preview_widget_active",{P},B},
    {"set_use_preview_label",{P,B}},
    {"get_use_preview_label",{P},B},
    {"get_preview_filename",{P},S},
    {"get_preview_uri",{P},S},
    {"set_extra_widget",{P,P}},
    {"get_extra_widget",{P},P},
    {"add_filter",{P,P}},
    {"remove_filter",{P,P}},
    {"list_filters",{P},A},
    {"set_filter",{P,P}},
    {"get_filter",{P},P,0,GtkFileFilter},
    {"add_shortcut_folder",{P,S,P},B},
    {"remove_shortcut_folder",{P,S,P},B},
    {"list_shortcut_folders",{P},A},
    {"add_shortcut_folder_uri",{P,S,P},B},
    {"remove_shortcut_folder_uri",{P,S,P},B},
    {"list_shortcut_folder_uris",{P},A},
    {"get_current_folder_file",{P},P,0,GFile},
    {"get_file",{P},P,0,GFile},
    {"get_files",{P},A},
    {"get_preview_file",{P},P,0,GFile},
    {"select_file",{P,P,P},B},
    {"set_current_folder_file",{P,P,P},B},
    {"set_file",{P,P,P},B},
    {"unselect_file",{P,P}},
"GtkFileChooser"}

widget[GtkFileChooserButton] = {"gtk_file_chooser_button",
{GtkFileChooser,GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,I},P},
    {"new_with_dialog",{P},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
    {"set_width_chars",{P,I}},
    {"get_width_chars",{P},I},
    {"set_focus_on_click",{P,B}},
    {"get_focus_on_click",{P},B},
"GtkFileChooserButton"}

widget[GtkFileChooserWidget] = {"gtk_file_chooser_widget",
{GtkFileChooser,GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{I},P},
"GtkFileChooserWidget"}

widget[GtkFileFilter] = {"gtk_file_filter",
{GtkBuildable,GObject},
    {"new",{},P},
    {"set_name",{P,S}},
    {"get_name",{P},S},
    {"add_mime_type",{P,S}},
    {"add_pattern",{P,S}},
    {"add_pixbuf_formats",{P}},
    {"add_custom",{P,I,P,P,P}},
    {"get_needed",{P},I},
    {"filter",{P,P},B},
"GtkFileFilter"}

widget[GtkFontChooser] = {"gtk_font_chooser",
{GObject},
    {"get_font_family",{P},P,0,PangoFontFamily},
    {"get_font_face",{P},P,0,PangoFontFace},
    {"get_font_size",{P},I},
    {"set_font",{P,S}},
    {"get_font",{P},S},
    {"set_font_desc",{P,P}},
    {"get_font_desc",{P},P,0,PangoFontDescription},
    {"set_preview_text",{P,S}},
    {"get_preview_text",{P},S},
    {"set_show_preview_entry",{P,B}},
    {"get_show_preview_entry",{P},B},
    {"set_filter_func",{P,P,P,P}},
"GtkFontChooser"}

widget[GtkFontChooserWidget] = {"gtk_font_chooser_widget",
{GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject,GtkFontChooser},
    {"new",{},P},
"GtkFontChooserWidget"}

widget[GtkInfoBar] = {"gtk_info_bar",
{GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"add_action_widget",{P,P,I}},
    {"add_button",{P,S,I},P},
    {"set_response_sensitive",{P,I,B}},
    {"set_default_response",{P,I}},
    {"response",{P,I}},
    {"set_message_type",{P,I}},
    {"get_message_type",{P},I},
    {"get_action_area",{P},P,0,GtkWidget},
    {"get_content_area",{P},P,0,GtkWidget},
    {"set_show_close_button",{P,B}}, -- 3.10
    {"get_show_close_button",{P},B}, -- 3.10
"GtkInfoBar"}

widget[GtkRecentChooser] = {"gtk_recent_chooser",
{GObject},
    {"set_show_private",{P,B}},
    {"get_show_private",{P},B},
    {"set_show_not_found",{P,B}},
    {"get_show_not_found",{P},B},
    {"set_show_icons",{P,B}},
    {"get_show_icons",{P},B},
    {"set_select_multiple",{P,B}},
    {"get_select_multiple",{P},B},
    {"set_local_only",{P,B}},
    {"get_local_only",{P},B},
    {"set_limit",{P,I}},
    {"get_limit",{P},I},
    {"set_show_tips",{P,B}},
    {"get_show_tips",{P},B},
    {"set_sort_type",{P,I}},
    {"get_sort_type",{P},I},
    {"set_sort_func",{P,P,P,P}},
    {"set_current_uri",{P,S,P},B},
    {"get_current_uri",{P},S},
    {"get_current_item",{P},P,0,GtkRecentInfo},
    {"select_uri",{P,S,P},B},
    {"unselect_uri",{P,S}},
    {"select_all",{P}},
    {"unselect_all",{P}},
    {"get_items",{P},A,0,GSList},
    {"get_uris",{P},A},
    {"add_filter",{P,P}},
    {"remove_filter",{P,P}},
    {"list_filters",{P},A,0,GSList},
    {"set_filter",{P,P}},
    {"get_filter",{P},P,0,GtkRecentFilter},
"GtkRecentChooser"}

widget[GtkRecentChooserWidget] = {"gtk_recent_chooser_widget",
{GtkRecentChooser,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
"GtkRecentChooserWidget"}

widget[GtkStatusbar] = {"gtk_statusbar",
{GtkOrientable,GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"get_context_id",{P,S},I},
    {"push",{P,I,S},I},
    {"pop",{P,I}},
    {"remove",{P,I,I}},
    {"remove_all",{P,I}},
    {"get_message_area",{P},P},
"GtkStatusBar"}

widget[GtkFixed] = {"gtk_fixed",
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"put",{P,P,I,I}},
    {"move",{P,P,I,I}},
"GtkFixed"}

widget[GtkGrid] = {"gtk_grid",
{GtkOrientable,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"attach",{P,P,I,I,I,I}},
    {"attach_next_to",{P,P,P,I,I,I}},
    {"get_child_at",{P,I,I},P},
    {"insert_row",{P,I}},
    {"remove_row",{P,I}}, --3.10
    {"insert_column",{P,I}},
    {"remove_column",{P,I}}, --3.10
    {"insert_next_to",{P,P,I}},
    {"set_row_homogeneous",{P,B}},
    {"get_row_homogeneous",{P},B},
    {"set_column_homogeneous",{P,B}},
    {"get_column_homogeneous",{P},B},
    {"set_row_spacing",{P,I}},
    {"get_row_spacing",{P},I},
    {"set_column_spacing",{P,I}},
    {"get_column_spacing",{P},I},
    {"set_baseline_row",{P,I}}, --3.10
    {"get_baseline_row",{P},I}, --3.10
    {"set_row_baseline_position",{P,I,I}}, --3.10
    {"get_row_baseline_position",{P,I},I}, --3.10
"GtkGrid"}

widget[GtkPaned] = {"gtk_paned",
{GtkOrientable,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{I},P},
    {"add1",{P,P}},
    {"add2",{P,P}},
    {"pack1",{P,P,B,B}},
    {"pack2",{P,P,B,B}},
    {"get_child1",{P},P},
    {"get_child2",{P},P},
    {"set_position",{P,I}},
    {"get_position",{P},I},
    {"get_handle_window",{P},P,0,GdkWindow},
    {"get_wide_handle",{P},B},
    {"set_wide_handle",{P,B}},
"GtkPaned"}

widget[GtkIconInfo] = {"gtk_icon_info",
{GObject},
    {"new",{P,P},-routine_id("newIconInfo")},
    {"get_base_size",{P},I},
    {"get_base_scale",{P},I}, --3.10
    {"get_filename",{P},S},
    {"get_display_name",{P},S}, -- Deprecated 3.14
    {"get_builtin_pixbuf",{P},P,0,GdkPixbuf}, -- Deprecated 3.14
    {"load_icon",{P},-routine_id("iconinfoLoadIcon")},
    {"load_surface",{P,P,P},P,0,CairoSurface_t},
    {"load_icon_async",{P,P,P,P}},
    {"load_icon_finish",{P,P,P},P,0,GdkPixbuf},
    {"load_symbolic",{P,P,P,P,P,B,P},P,0,GdkPixbuf},
    {"load_symbolic_async",{P,P,P,P,P,P,P,P}},
    {"load_symbolic_finish",{P,P,P,P},P,0,GdkPixbuf},
    {"load_symbolic_for_context",{P,P,P,P},P,0,GdkPixbuf},
    {"load_symbolic_for_context_async",{P,P,P,P,P}},
    {"load_symbolic_for_context_finish",{P,P,P,P},P,0,GdkPixbuf},
    {"set_raw_coordinates",{P,B}}, -- Deprecated 3.14
    {"get_embedded_rect",{P,P},B}, -- Deprecated 3.14
    {"get_attach_points",{P,A,P},B}, -- Deprecated 3.14
    {"is_symbolic",{P},B}, -- 3.12
"GtkIconInfo"}

    function iconinfoLoadIcon(atom info)
    ------------------------------------
    atom err = allocate(8) err = 0
    atom icn = gtk_func("gtk_icon_info_load_icon",{P,P},{info,err})
    register(icn,GdkPixbuf)
    return icn
    end function
    
    function newIconInfo(atom theme, atom pix)
    ------------------------------------------
    return gtk_func("gtk_icon_info_new_for_pixbuf",{P,P},{theme,pix})
    end function

widget[GtkIconTheme] = {"gtk_icon_theme",
{GObject},
    {"new",{},-routine_id("getDefaultIconTheme")},
    {"get_for_screen",{P},P,0,GtkIconTheme},
    {"set_screen",{P,P}},
    {"set_search_path",{P,S,I}},
    {"get_search_path",{P,P,I}},
    {"append_search_path",{P,S}},
    {"prepend_search_path",{P,S}},
    {"set_custom_theme",{P,S}},
    {"has_icon",{P,S},B},
    {"lookup_icon",{P,S,I,I},P,0,GtkIconInfo},
    {"lookup_icon_for_scale",{P,P,I,I,I},P,0,GtkIconInfo},
    {"choose_icon",{P,A,I,I},P,0,GtkIconInfo},
    {"choose_icon_for_scale",{P,A,I,I,I},P,0,GtkIconInfo},
    {"lookup_by_gicon",{P,P,I,I},P,0,GtkIconInfo},
    {"load_icon",{P,S,I,I},-routine_id("iconthemeLoadIcon")},
    {"load_icon_for_scale",{P,S,I,I,I,P},P,0,GdkPixbuf},
    {"load_surface",{P,S,I,I,P,I,P},P,0,CairoSurface_t},
    {"list_contexts",{P},-routine_id("iconthemeListContexts")},
    {"list_icons",{P,S},-routine_id("iconthemeListIcons")},
    {"get_icon_sizes",{P,S},A},
    {"rescan_if_needed",{P},B},
    {"get_example_icon_name",{P},S},
    {"add_builtin_icon",{S,I,P}},
    {"add_resource_path",{P,S}}, -- 3.14
"GtkIconTheme"}

    function iconthemeLoadIcon(atom theme, object name, integer size, integer flags)
    --------------------------------------------------------------------------------
    atom err = allocate(8) err = 0
    return gtk_func("gtk_icon_theme_load_icon",{P,S,I,I,P},{theme,name,size,flags,err})
    end function
    
    function iconthemeListContexts(atom theme)
    ------------------------------------------
    object list = gtk_func("gtk_icon_theme_list_contexts",{P},{theme})
    return to_sequence(list)
    end function

    function iconthemeListIcons(atom theme, object context)
    -------------------------------------------------------
    object list = gtk_func("gtk_icon_theme_list_icons",{P,S},{theme,context})
    return to_sequence(list)
    end function

    function getDefaultIconTheme()
    ------------------------------
    return gtk_func("gtk_icon_theme_get_default")
    end function

widget[GtkIconView] = {"gtk_icon_view",
{GtkScrollable,GtkCellLayout,GtkContainer,GtkWidget,GtkBuildable,GObject,GtkScrollable,GtkCellLayout},
    {"new",{},P},
    {"new_with_area",{P},P},
    {"new_with_model",{P},P},
    {"set_model",{P,P}},
    {"set_text_column",{P,I}},
    {"get_text_column",{P},I},
    {"set_markup_column",{P,I}},
    {"get_markup_column",{P},I},
    {"set_pixbuf_column",{P,I}},
    {"get_pixbuf_column",{P},I},
    {"get_path_at_pos",{P,I,I},P,0,GtkTreePath},
    {"get_item_at_pos",{P,I,I,P,P},B},
    {"convert_widget_to_bin_window_coords",{P,I,I,I,I}},
    {"set_cursor",{P,P,P,B}},
    {"get_cursor",{P,P,P},B},
    {"selected_foreach",{P,P,P}},
    {"set_selection_mode",{P,I}},
    {"get_selection_mode",{P},I},
    {"set_columns",{P,I}},
    {"get_columns",{P},I},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
    {"set_row_spacing",{P,I}},
    {"get_row_spacing",{P},I},
    {"set_column_spacing",{P,I}},
    {"get_column_spacing",{P},I},
    {"set_margin",{P,I}},
    {"get_margin",{P},I},
    {"set_item_padding",{P,I}},
    {"get_item_padding",{P},I},
    {"set_activate_on_single_click",{P,B}}, --3.8
    {"get_activate_on_single_click",{P},B}, --3.8
    {"get_cell_rect",{P,P,P,P},B}, --3.6
    {"select_path",{P,P}},
    {"unselect_path",{P,P}},
    {"path_is_selected",{P,P},B},
    {"get_selected_items",{P},P,0,GSList},
    {"select_all",{P}},
    {"unselect_all",{P}},
    {"item_activated",{P,P}},
    {"scroll_to_path",{P,P,B,F,F}},
    {"get_visible_range",{P,P,P},B},
    {"set_tooltip_item",{P,P,P}},
    {"set_tooltip_cell",{P,P,P,P}},
    {"get_tooltip_context",{P,I,I,B,P,P,P},B},
    {"set_tooltip_column",{P,I}},
    {"get_tooltip_column",{P},I},
    {"get_item_row",{P,P},I},
    {"get_item_column",{P,P},I},
    {"enable_model_drag_source",{P,I,P,I,I}},
    {"enable_model_drag_dest",{P,P,I,I}},
    {"unset_model_drag_source",{P}},
    {"unset_model_drag_dest",{P}},
    {"set_reorderable",{P,B}},
    {"get_reorderable",{P},B},
    {"set_drag_dest_item",{P,P,I}},
    {"get_drag_dest_item",{P,P,I}},
    {"get_dest_item_at_pos",{P,I,I,P,I},B},
    {"create_drag_icon",{P,P},P,0,CairoSurface_t},
"GtkIconView"}

widget[GtkLayout] = {"gtk_layout",
{GtkScrollable,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,P},P},
    {"put",{P,P,I,I}},
    {"move",{P,P,I,I}},
    {"set_size",{P,I,I}},
    {"get_size",{P,I,I}},
    {"get_bin_window",{P},P,0,GdkWindow},
"GtkLayout"}

widget[GtkSeparatorMenuItem] = {"gtk_separator_menu_item",
{GtkMenuItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
"GtkSeparatorMenuItem"}

widget[GtkRecentChooserMenu] = {"gtk_recent_chooser_menu",
{GtkRecentChooser,GtkMenu,GtkMenuShell,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_for_manager",{P},P},
    {"set_show_numbers",{P,B}},
    {"get_show_numbers",{P},B},
"GtkRecentChooserMenu"}

widget[GtkRecentFilter] = {"gtk_recent_filter",
{GtkBuildable,GObject},
    {"new",{},P},
    {"set_name",{P,S}},
    {"get_name",{P},S},
    {"add_mime_type",{P,S}},
    {"add_pattern",{P,S}},
    {"add_pixbuf_formats",{P}},
    {"add_group",{P,S}},
    {"add_age",{P,I}},
    {"add_application",{P,S}},
    {"add_custom",{P,I,P,P,P}},
    {"get_needed",{P},I},
    {"filter",{P,P},B},
"GtkRecentFilter"}

widget[GtkRecentInfo] = {"gtk_recent_info",
{GObject},
    {"get_uri",{P},S},
    {"get_display_name",{P},S},
    {"get_description",{P},S},
    {"get_mime_type",{P},S},
    {"get_added",{P},I},
    {"get_modified",{P},I},
    {"get_visited",{P},I},
    {"get_private_hint",{P},B},
    {"get_application_info",{P,S,S,I,I},B},
    {"get_applications",{P,I},A},
    {"last_application",{P},S},
    {"has_application",{P,S},B},
    {"create_app_info",{P,S,P},P,0,GAppInfo},
    {"get_groups",{P,I},A},
    {"has_group",{P,S},B},
    {"get_icon",{P,I},P,0,GdkPixbuf},
    {"get_gicon",{P},P,0,GIcon},
    {"get_short_name",{P},S},
    {"get_uri_display",{P},S},
    {"get_age",{P},I},
    {"is_local",{P},B},
    {"exists",{P},B},
    {"match",{P,P},B},
"GtkRecentInfo"}

widget[GtkSettings] = {"gtk_settings",
{GtkStyleProvider,GObject},
"GtkSettings"}

widget[GtkSizeGroup] = {"gtk_size_group",
{GtkBuildable,GObject},
    {"new",{I},P},
    {"set_mode",{P,I}},
    {"get_mode",{P},I},
    {"set_ignore_hidden",{P,B}},
    {"get_ignore_hidden",{P},B},
    {"add_widget",{P,P}},
    {"add_widgets",{P,P},-routine_id("addWidgets")},
    {"remove_widget",{P,P}},
    {"get_widgets",{P},P,0,GSList},
"GtkSizeGroup"}

    function addWidgets(atom group, object widgets)
    -----------------------------------------------
    if atom(widgets) then
        set(group,"add widget",widgets)
    else
        for i = 1 to length(widgets) do
            set(group,"add widget",widgets[i])
        end for
    end if
    return 1
    end function
    
widget[GtkTargetEntry] = {"gtk_target_entry",
{GObject},
    {"new",{S,I,I},P},
    {"copy",{P},P,0,GtkTargetEntry},
    {"free",{P}},
"GtkTargetEntry"}

widget[GtkTargetList] = {"gtk_target_list",
{GObject},
    {"new",{P,I},P},
    {"add",{P,P,I,I}},
    {"add_table",{P,P,I}},
    {"add_text_targets",{P,I}},
    {"add_image_targets",{P,I,B}},
    {"add_uri_targets",{P,I}},
    {"add_rich_text_targets",{P,I,B,P}},
    {"remove",{P,P}},
    {"find",{P,P,P},B},
"GtkTargetList"}

widget[GtkTextChildAnchor] = {"gtk_text_child_anchor",
{GObject},
"GtkTextChildAnchor"}

widget[GtkTextMark] = {"gtk_text_mark",
{GObject},
    {"new",{S,B},P},
    {"set_visible",{P,B}},
    {"get_visible",{P},B},
    {"get_deleted",{P},B},
    {"get_name",{P},S},
    {"get_buffer",{P},P,0,GtkTextBuffer},
    {"get_left_gravity",{P},B},
"GtkTextMark"}

widget[GtkTextTag] = {"gtk_text_tag",
{GObject},
    {"new",{S},P},
    {"set_priority",{P,I}},
    {"get_priority",{P},I},
    {"event",{P,P,P,P},B},
"GtkTextTag"}

widget[GtkTextAttributes] = {"gtk_text_attributes",
{GObject},
    {"new",{},P},
    {"copy",{P},P,0,GtkTextAttributes},
    {"copy_values",{P,P}},
"GtkTextAttributes"}

widget[GtkTextTagTable] = {"gtk_text_tag_table",
{GtkBuildable,GObject},
    {"new",{},P},
    {"add",{P,P}},
    {"remove",{P,P}},
    {"lookup",{P,S},P,0,GtkTextTag},
    {"foreach",{P,P,P}},
    {"get_size",{P},I},
"GtkTextTagTable"}

widget[GtkCheckMenuItem] = {"gtk_check_menu_item",
{GtkMenuItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},-routine_id("newCheckMenuItem")},
    {"set_active",{P,B}},
    {"get_active",{P},B},
    {"toggled",{P}},
    {"set_inconsistent",{P,B}},
    {"get_inconsistent",{P},B},
    {"set_draw_as_radio",{P,B}},
    {"get_draw_as_radio",{P},B},
"GtkCheckMenuItem"}

    function newCheckMenuItem(object txt)
    -------------------------------------
    return gtk_func("gtk_check_menu_item_new_with_mnemonic",{S},{txt})
    end function
  
widget[GtkRadioMenuItem] = {"gtk_radio_menu_item",
{GtkCheckMenuItem,GtkMenuItem,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,S},-routine_id("newRadioMenuItem")},
    {"set_group",{P,P}},
    {"get_group",{P},P},
"GtkRadioMenuItem"}

    function newRadioMenuItem(atom group, atom txt)
    -----------------------------------------------
    object item
    if group = 0 then
        item = gtk_func("gtk_radio_menu_item_new_with_mnemonic",{P,S},{group,txt})
    else
        item = gtk_func("gtk_radio_menu_item_new_with_mnemonic_from_widget",{P,S},{group,txt})
    end if
    return item
    end function
    
widget[GtkMenuShell] = {"gtk_menu_shell",
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"append",{P,P},-routine_id("appendMenuShell")},
    {"prepend",{P,P}},
    {"insert",{P,P,I}},
    {"deactivate",{P}},
    {"select_item",{P,P}},
    {"select_first",{P,B}},
    {"deselect",{P}},
    {"activate_item",{P,P,B}},
    {"cancel",{P}},
    {"set_take_focus",{P,B}},
    {"get_take_focus",{P},B},
    {"get_selected_item",{P},P,0,GtkWidget},
    {"get_parent_shell",{P},P,0,GtkWidget},
    {"bind_model",{P,P,S,B}}, --3.6
"GtkMenuShell"}

    function appendMenuShell(atom menu, object items)
    -------------------------------------------------
    if atom(items) then
        gtk_proc("gtk_menu_shell_append",{P,P},{menu,items})
    else
        for i = 1 to length(items) do
            appendMenuShell(menu,items[i])
        end for
    end if
    return 1
    end function
        
widget[GtkNotebook] = {"gtk_notebook",
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"append_page",{P,P,P},I},
    {"append_page_menu",{P,P,P,P},I},
    {"prepend_page",{P,P,P},I},
    {"prepend_page_menu",{P,P,P,P},I},
    {"insert_page",{P,P,P,I},I},
    {"insert_page_menu",{P,P,P,P,I},I},
    {"remove_page",{P,I}},
    {"page_num",{P,P},I},
    {"next_page",{P}},
    {"prev_page",{P}},
    {"reorder_child",{P,P,I}},
    {"set_tab_pos",{P,I}},
    {"get_tab_pos",{P},I},
    {"set_show_tabs",{P,B}},
    {"get_show_tabs",{P},B},
    {"set_show_border",{P,B}},
    {"get_show_border",{P},B},
    {"set_scrollable",{P,B}},
    {"get_scrollable",{P},B},
    {"popup_enable",{P}},
    {"popup_disable",{P}},
    {"get_current_page",{P},I},
    {"set_menu_label",{P,P}},
    {"get_menu_label",{P,P},P},
    {"get_menu_label_text",{P,P},S},
    {"get_n_pages",{P},I},
    {"get_nth_page",{P,I},P},
    {"set_tab_label",{P,P}},
    {"get_tab_label",{P,P},P},
    {"set_tab_label_text",{P,P,S}},
    {"get_tab_label_text",{P,P},S},
    {"set_tab_detachable",{P,P,B}},
    {"get_tab_detachable",{P,P},B},
    {"set_current_page",{P,I}},
    {"set_group_name",{P,S}},
    {"get_group_name",{P},S},
    {"set_action_widget",{P,P,I}},
    {"get_action_widget",{P,I},P},
"GtkNotebook"}

widget[GtkSocket] = {"gtk_socket",
{GtkContainer,GtkWidget,GObject},
    {"new",{},P},
    {"add_id",{P,P}},
    {"get_id",{P},P},
    {"get_plug_window",{P},P,0,GdkWindow},
"GtkSocket"}

widget[GtkPlug] = {"gtk_plug",
{GObject},
    {"new",{I},P},
    {"get_id",{P},I},
    {"get_embedded",{P},B},
    {"get_socket_window",{P},P,0,GdkWindow},
"GtkPlug"}

widget[GtkToolPalette] = {"gtk_tool_palette",
{GtkOrientable,GtkContainer,GtkWidget,GtkScrollable,GtkBuildable,GObject},
    {"new",{},P},
    {"set_exclusive",{P,P,B}},
    {"get_exclusive",{P,P},B},
    {"set_expand",{P,P,B}},
    {"get_expand",{P,P},B},
    {"set_group_position",{P,P,I}},
    {"get_group_position",{P,P},I},
    {"set_icon_size",{P,I}},
    {"get_icon_size",{P},I},
    {"unset_icon_size",{P}},
    {"set_style",{P,I}},
    {"get_style",{P},I},
    {"unset_style",{P}},
    {"add_drag_dest",{P,P,I,I,I}},
    {"get_drag_item",{P,P},P,0,GtkWidget},
    {"get_drop_group",{P,I,I},P,0,GtkToolItemGroup},
    {"set_drag_source",{P,I}},
"GtkToolPalette"}

widget[GtkTextView] = {"gtk_text_view",
{GtkContainer,GtkWidget,GtkScrollable,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_buffer",{P},P},
    {"set_buffer",{P,P}},
    {"get_buffer",{P},P,0,GtkTextBuffer},
    {"scroll_to_mark",{P,P,D,B,D,D}},
    {"scroll_to_iter",{P,P,D,B,D,D},B},
    {"scroll_mark_onscreen",{P,P}},
    {"place_cursor_onscreen",{P},B},
    {"get_visible_rect",{P,P}},
    {"get_iter_location",{P,P,P}},
    {"get_cursor_locations",{P,P,P,P}},
    {"get_line_at_y",{P,P,I,I}},
    {"get_line_yrange",{P,P,I,I}},
    {"get_iter_at_location",{P,P,I,I}},
    {"get_iter_at_position",{P,P,I,I,I}},
    {"buffer_to_window_coords",{P,P,I,I,I,I}},
    {"window_to_buffer_coords",{P,P,I,I,I,I}},
    {"get_window",{P,I},P,0,GdkWindow},
    {"set_border_window_size",{P,I,I}},
    {"get_border_window_size",{P,P},I},
    {"forward_display_line",{P,P},B},
    {"backward_display_line",{P,P},B},
    {"forward_display_line_end",{P,P},B},
    {"backward_display_line_start",{P,P},B},
    {"starts_display_line",{P,P},B},
    {"move_visually",{P,P,I},B},
    {"add_child_at_anchor",{P,P,P}},
    {"add_child_in_window",{P,P,P,I,I}},
    {"move_child",{P,P,I,I}},
    {"set_wrap_mode",{P,I}},
    {"get_wrap_mode",{P},I},
    {"set_editable",{P,B}},
    {"get_editable",{P},B},
    {"set_cursor_visible",{P,B}},
    {"get_cursor_visible",{P},B},
    {"set_overwrite",{P,B}},
    {"get_overwrite",{P},B},
    {"set_pixels_above_lines",{P,I}},
    {"get_pixels_above_lines",{P},I},
    {"set_pixels_below_lines",{P,I}},
    {"get_pixels_below_lines",{P},I},
    {"set_pixels_inside_wrap",{P,I}},
    {"get_pixels_inside_wrap",{P},I},
    {"set_justification",{P,I}},
    {"get_justification",{P},I},
    {"set_left_margin",{P,I}},
    {"get_left_margin",{P},I},
    {"set_right_margin",{P,I}},
    {"get_right_margin",{P},I},
    {"set_indent",{P,I}},
    {"get_indent",{P},I},
    {"set_tabs",{P,A}},
    {"get_tabs",{P},A,0,PangoTabArray},
    {"set_accepts_tab",{P,B}},
    {"get_accepts_tab",{P},B},
    {"im_context_filter_keypress",{P,P},B},
    {"reset_im_context",{P}},
    {"set_input_purpose",{P,I}}, -- GTK 3.6+
    {"get_input_purpose",{P},I}, -- GTK 3.6+
    {"set_input_hints",{P,I}}, -- GTK 3.6+
    {"get_input_hints",{P},I}, -- GTK 3.6+
    {"get_monospace",{P},B}, -- 3.16
    {"set_monospace",{P,B}}, -- 3.16
"GtkTextView"}

widget[GtkToolShell] = {"gtk_tool_shell",
{GtkWidget},
    {"get_ellipsize_mode",{P},I},
    {"get_icon_size",{P},I},
    {"get_orientation",{P},I},
    {"get_relief_style",{P},I},
    {"get_style",{P},I},
    {"get_text_alignment",{P},F},
    {"get_text_orientation",{P},I},
    {"get_text_size_group",{P},P,0,GtkSizeGroup},
    {"rebuild_menu",{P}},
"GtkToolShell"}

widget[GtkToolbar] = {"gtk_toolbar",
{GtkOrientable,GtkContainer,GtkWidget,GtkBuildable,GObject,GtkToolShell},
    {"new",{},P},
    {"insert",{P,P,I}},
    {"get_item_index",{P,P},I},
    {"get_n_items",{P},I},
    {"get_nth_item",{P},P},
    {"get_drop_index",{P,I,I},I},
    {"set_drop_highlight_item",{P,P,I}},
    {"set_show_arrow",{P,B}},
    {"get_show_arrow",{P},B},
    {"set_icon_size",{P,I}},
    {"get_icon_size",{P},I},
    {"unset_icon_size",{P}},
    {"set_style",{P,I}},
    {"get_style",{P},I},
    {"unset_style",{P}},
"GtkToolbar"}

widget[GtkToolItemGroup] = {"gtk_tool_item_group",
{GtkToolShell,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"set_collapsed",{P,B}},
    {"get_collapsed",{P},B},
    {"set_ellipsize",{P,I}},
    {"get_ellipsize",{P},I},
    {"get_drop_item",{P,I,I},P,0,GtkToolItem},
    {"get_n_items",{P},I},
    {"get_nth_item",{P,I},P,0,GtkToolItem},
    {"set_label",{P,S}},
    {"get_label",{P},S},
    {"set_label_widget",{P,P}},
    {"get_label_widget",{P},P,0,GtkWidget},
    {"set_header_relief",{P,I}},
    {"get_header_relief",{P},I},
    {"insert",{P,P,I}},
    {"set_item_position",{P,P,I}},
"GtkToolItemGroup"}

widget[GtkTooltip] = {"gtk_tooltip",
{GObject},
    {"set_text",{P,S}},
    {"set_markup",{P,S}},
    {"set_icon",{P,P}},
    {"set_icon_from_icon_name",{P,S,I}},
    {"set_icon_from_gicon",{P,P,I}},
    {"set_custom",{P,P}},
    {"trigger_tooltip_query",{P}},
    {"set_tip_area",{P,P}},
"GtkTooltip"}

widget[GtkTreeView] = {"gtk_tree_view",
{GtkContainer,GtkScrollable,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_model",{P},P},
    {"set_model",{P,P}},
    {"get_model",{P},P,0,GtkTreeModel},
    {"get_selection",{P},P,0,GtkTreeSelection},
    {"set_headers_visible",{P,B}},
    {"get_headers_visible",{P},B},
    {"set_headers_clickable",{P,B}},
    {"get_headers_clickable",{P},B},
    {"set_show_expanders",{P,B}},
    {"get_show_expanders",{P},B},
    {"set_expander_column",{P,P}},
    {"get_expander_column",{P},P,0,GtkTreeViewColumn},
    {"set_level_indentation",{P,I}},
    {"get_level_indentation",{P},I},
    {"columns_autosize",{P}},
    {"set_rules_hint",{P,B}}, -- Deprecated 3.14
    {"get_rules_hint",{P},B}, -- Deprecated 3.14
    {"set_activate_on_single_click",{P,B}}, -- GTK 3.8+
    {"get_activate_on_single_click",{P},B}, -- GTK 3.8+
    {"append_column",{P,P},I},
    {"append_columns",{P,P},-routine_id("tvAppendCols")},
    {"remove_column",{P,P,I}},
    {"insert_column",{P,P,I}},
    {"insert_column_with_attributes",{P,I,S,S,I,I}},
    {"insert_column_with_data_func",{P,I,S,P,P,P,P}},
    {"get_n_columns",{P},I},
    {"get_column",{P,I},P,0,GtkTreeViewColumn},
    {"get_columns",{P},A,0,GList},
    {"move_column_after",{P,P,P}},
    {"set_column_drag_function",{P,P,P,P}},
    {"scroll_to_point",{P,I,I}},
    {"scroll_to_cell",{P,P,P,P,F,F},-routine_id("tvScrol2Cel")},
    {"set_cursor",{P,P,P,B}},
    {"set_cursor_on_cell",{P,P,P,P,B}},
    {"get_cursor",{P,P,P}},
    {"row_activated",{P,P,P}},
    {"expand_row",{P,P,B},B},
    {"expand_all",{P}},
    {"expand_to_path",{P,P}},
    {"collapse_all",{P}},
    {"map_expanded_rows",{P,P,P}},
    {"row_expanded",{P,P},B},
    {"set_reorderable",{P,B}},
    {"get_reorderable",{P,B}},
    {"get_path_at_pos",{P,I,I,P,P,I,I},B},
    {"is_blank_at_pos",{P,I,I,P,P,I,I},B},
    {"get_cell_area",{P,P,P,P}},
    {"get_background_area",{P,P,P,P}},
    {"get_visible_rect",{P,P}},
    {"get_visible_range",{P,P,P},B},
    {"get_bin_window",{P},P,0,GdkWindow},
    {"convert_bin_window_to_tree_coords",{P,I,I,I,I}},
    {"convert_bin_window_to_widget_coords",{P,I,I,I,I}},
    {"convert_tree_to_bin_window_coords",{P,I,I,I,I}},
    {"convert_tree_to_widget_coords",{P,I,I,I,I}},
    {"convert_widget_to_bin_window_coords",{P,I,I,I,I}},
    {"convert_widget_to_tree_coords",{P,I,I,I,I}},
    {"enable_model_drag_dest",{P,P,I,I}},
    {"enable_model_drag_source",{P,I,P,I,I}},
    {"unset_rows_drag_source",{P}},
    {"unset_rows_drag_dest",{P}},
    {"set_drag_dest_row",{P,P,I}},
    {"get_drag_dest_row",{P,P,P}},
    {"get_drag_dest_row_at_pos",{P,I,I,P,P},B},
    {"create_row_drag_icon",{P,P},P,0,CairoSurface_t},
    {"set_enable_search",{P,B}},
    {"get_enable_search",{P},B},
    {"set_search_column",{P,I}},
    {"get_search_column",{P},I},
    {"set_search_equal_func",{P,P,P,P}},
    {"get_search_equal_func",{P},P},
    {"set_search_entry",{P,P}},
    {"get_search_entry",{P},P,0,GtkEntry},
    {"set_search_position_func",{P,P,P,P}},
    {"get_search_position_func",{P},P},
    {"set_fixed_height_mode",{P,B}},
    {"get_fixed_height_mode",{P},B},
    {"set_hover_selection",{P,B}},
    {"get_hover_selection",{P},B},
    {"set_hover_expand",{P,B}},
    {"get_hover_expand",{P},B},
    {"set_destroy_count_func",{P,P,P,P}},
    {"set_row_separator_func",{P,P,P,P}},
    {"get_row_separator_func",{P},P},
    {"set_rubber_banding",{P,B}},
    {"get_rubber_banding",{P},B},
    {"set_enable_tree_lines",{P,B}},
    {"get_enable_tree_lines",{P},B},
    {"set_grid_lines",{P,B}},
    {"get_grid_lines",{P},B},
    {"set_tooltip_row",{P,P,P}},
    {"set_tooltip_cell",{P,P,P,P,P}},
    {"set_tooltip_column",{P,I}},
    {"get_tooltip_column",{P},I},
    {"get_tooltip_context",{P,I,I,B,P,P,P},B},
    {"select_row",{P,P,D,D},-routine_id("tvSelectRow")},
"GtkTreeView"}

    constant scrl2cell = define_c_proc(GTK,"gtk_tree_view_scroll_to_cell",{P,P,P,I,F,F})
    
    function tvScrol2Cel(atom v, atom p, atom c, integer align, atom row, atom col)
    c_proc(scrl2cell,{v,p,c,align,row,col})
    return 1
    end function
    
    constant appcol = define_c_func(GTK,"gtk_tree_view_append_column",{P,P},I)
    function tvAppendCols(atom store, object cols)
    ---------------------------------------------------------------------------
    if atom(cols) then
        c_func(appcol,{store,cols})
    else
    for i = 1 to length(cols) do
        c_func(appcol,{store,cols[i]})
    end for
    end if
    return 1
    end function

    function tvSelectRow(atom tv, object path, atom rowalign=0,  atom colalign=0)
        path = create(GtkTreePath,path)
        gtk_func("gtk_tree_view_scroll_to_cell",
            {P,P,I,I,F,F},{tv,path,0,1,rowalign,colalign})
    return 1
    end function
    
widget[GtkTreeViewColumn] = {"gtk_tree_view_column",
{GtkCellLayout,GtkBuildable,GObject},
    {"new",{},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
    {"pack_start",{P,P,B}},
    {"pack_end",{P,P,B}},
    {"clear",{P}},
    {"clicked",{P}},
    {"add_attribute",{P,P,S,I}},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
    {"set_visible",{P,B}},
    {"get_visible",{P},B},
    {"set_resizable",{P,B}},
    {"get_resizable",{P},B},
    {"set_sizing",{P,I}},
    {"get_sizing",{P},I},
    {"set_fixed_width",{P,I}},
    {"get_fixed_width",{P},I},
    {"set_min_width",{P,I}},
    {"get_min_width",{P},I},
    {"set_max_width",{P,I}},
    {"get_max_width",{P},I},
    {"set_expand",{P,B}},
    {"get_expand",{P},B},
    {"set_clickable",{P,B}},
    {"get_clickable",{P},B},
    {"set_widget",{P,P}},
    {"get_widget",{P},P},
    {"get_button",{P},P,0,GtkWidget},
    {"set_alignment",{P,F}},
    {"get_alignment",{P},F},
    {"set_reorderable",{P,B}},
    {"get_reorderable",{P},B},
    {"set_sort_column_id",{P,I}},
    {"get_sort_column_id",{P},I},
    {"set_sort_indicator",{P,B}},
    {"get_sort_indicator",{P},B},
    {"set_sort_order",{P,I}},
    {"get_sort_order",{P},I},
    {"cell_set_cell_data",{P,P,P,B,B}},
    {"cell_get_size",{P,P,I,I,I,I}},
    {"cell_get_position",{P,P,I,I},B},
    {"cell_is_visible",{P},B},
    {"focus_cell",{P,P}},
    {"queue_resize",{P}},
    {"get_tree_view",{P},P,0,GtkWidget},
    {"get_x_offset",{P},I},
"GtkTreeViewColumn"}

widget[GtkTreeSelection] = {"gtk_tree_selection",
{GObject},
    {"set_mode",{P,I}},
    {"get_mode",{P},I},
    {"set_select_function",{P,P,P,P}},
    {"get_select_function",{P},P},
    {"get_user_data",{P},P},
    {"get_tree_view",{P},P},
    {"get_selected",{P,P,P},B},
    {"selected_foreach",{P,P,P}},
    {"count_selected_rows",{P},I},
    {"select_path",{P,P}},
    {"unselect_path",{P,P}},
    {"path_is_selected",{P,P},B},
    {"select_iter",{P,P}},
    {"unselect_iter",{P,P}},
    {"iter_is_selected",{P,P},B},
    {"select_all",{P}},
    {"unselect_all",{P}},
    {"select_range",{P,P,P}},
    {"unselect_range",{P,P,P}},
    {"get_selected_rows",{P,P},-routine_id("getSelRows")},
    {"get_selected_row",{P,P},-routine_id("getSelRow")},
"GtkTreeSelection"}

    function getSelRows(atom selection, atom model)
    -------------------------------------------------
    object list = gtk_func("gtk_tree_selection_get_selected_rows",{P,P},{selection,model})
    list = to_sequence(list,3)
    return list +1
    end function

    function getSelRow(atom selection, atom model)
    -------------------------------------------------
    object list = gtk_func("gtk_tree_selection_get_selected_rows",{P,P},{selection,model})
    list = to_sequence(list,3)
    if length(list) = 0 then
        return -1
    else
        return list[1] +1
    end if
    end function

widget[GtkActionBar] = {"gtk_action_bar", -- GTK 3.12
{GtkBox,GtkWidget,GtkBuildable,GObject}, 
    {"new",{},P},
    {"pack_start",{P,P}},
    {"pack_end",{P,P}},
    {"get_center_widget",{P},P},
    {"set_center_widget",{P,P}},
"GtkActionBar"}

widget[GtkAccelLabel] = {"gtk_accel_label",
{GtkLabel,GtkMisc,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"get_accel",{P,I,I}}, -- 3.14
    {"set_accel_closure",{P,P}},
    {"set_accel_widget",{P,P}},
    {"get_accel_widget",{P},P,0,GtkWidget},
    {"get_accel_width",{P},I},
    {"refetch",{P},B},
"GtkAccelLabel"}

widget[GtkAccelGroup] = {"gtk_accel_group",
{GObject},
    {"new",{},P},
    {"connect",{P,I,I,I,P}},
    {"connect_by_path",{P,S,P}},
    {"disconnect",{P,P},B},
    {"disconnect_key",{P,I,I},B},
    {"activate",{P,I,P,I,I},B},
    {"lock",{P}},
    {"unlock",{P}},
    {"get_is_locked",{P},B},
    {"from_accel_closure",{P},P,0,GtkAccelGroup},
    {"get_modifier_mask",{P},I},
    {"find",{P,P,P},P},
"GtkAccelGroup"}

widget[GtkArrow] = {"gtk_arrow", -- Deprecated 3.14
{GtkMisc,GtkWidget,GtkBuildable,GObject},
    {"new",{I,I},P},
    {"set",{P,I,I}},
"GtkArrow"}

widget[GtkCalendar] = {"gtk_calendar",
{GtkWidget,GtkBuildable,GObject},
    {"clear_marks",{P}},
    {"get_date",{P,P},-routine_id("getCalendarDate")},
    {"get_ymd",{P,I},-routine_id("getCalendarYMD")},
    {"get_y,m,d",{P,I},-routine_id("getCalendarYMD")},
    {"get_eu_date",{P},-routine_id("getCalendarEuDate")},
    {"get_day",{P},-routine_id("getCalendarDay")},
    {"get_month",{P},-routine_id("getCalendarMonth")},
    {"get_year",{P},-routine_id("getCalendarYear")},
    {"get_day_is_marked",{P,I},B},
    {"get_display_options",{P},I},
    {"mark_day",{P,I},B},
    {"new",{},P},
    {"select_day",{P,I}},
    {"select_month",{P,I,I},-routine_id("selectCalendarMonth")},
    {"set_display_options",{P,I}},
    {"unmark_day",{P,I},B},
    {"set_detail_func",{P,P,P,P}},
    {"set_detail_width_chars",{P,I}},
    {"get_detail_width_chars",{P},I},
    {"get_detail_height_rows",{P},I},
    {"set_detail_height_rows",{P,I}},
    {"set_date",{P,P},-routine_id("setCalendarDate")},
"GtkCalendar"}

------------------------------------------------------------------------
-- Calendar convenience functions
------------------------------------------------------------------------
-- Handle odd month numbering scheme:
-- Q: If the first day of the month is 1, then why is the first month 
-- of the year zero? 
-- A: Blame a C programmer!

-- Here we fix that, plus change the set_date routine from two steps
-- to one; also, provide for standard formatting to be used when 
-- getting the date. See std/datetime.e for the formats available.
------------------------------------------------------------------------

    constant get_date = define_c_proc(GTK,"gtk_calendar_get_date",{P,I,I,I})

    ------------------------------------------------------------------------
    function selectCalendarMonth(atom handle, integer mo, integer yr=0)
    ------------------------------------------------------------------------
        while mo < 1 do yr -= 1 mo += 12 end while
        while mo > 12 do yr += 1 mo -= 12 end while
        gtk_proc("gtk_calendar_select_month",{P,I,I},{handle,mo-1,yr})
    return 1
    end function
    
    ------------------------------------------------------------------------
    function setCalendarDate(atom handle, object date)
    ------------------------------------------------------------------------
    integer yr = date[1], mo = date[2], da = date[3]
        gtk_proc("gtk_calendar_select_month",{P,I,I},{handle,mo-1,yr})
        gtk_proc("gtk_calendar_select_day",{P,I},{handle,da})
    return 1
    end function

    ------------------------------------------------------------------------
    function getCalendarDate(atom handle, object fmt=0)
    ------------------------------------------------------------------------
        atom y = allocate(64)
        atom m = allocate(64)
        atom d = allocate(64)
        object clock
        if atom(fmt) then
                fmt = "%A, %b %d, %Y" 
        end if
        object result
        c_proc(get_date,{handle,y,m,d})
        result = datetime:new(peek4u(y),peek4u(m)+1,peek4u(d))
        clock = datetime:now()
        result = result[1..3] & clock[4..6]
        result = datetime:format(result,fmt)
        free(y) free(m) free(d)
        return result
    end function

    ------------------------------------------------------------------------
    function getCalendarEuDate(atom handle) --returns {y,m,d} in Eu fmt.
    ------------------------------------------------------------------------
        atom y = allocate(64)
        atom m = allocate(64)
        atom d = allocate(64)
        c_proc(get_date,{handle,y,m,d})
        sequence result = {peek4u(y)-1900,peek4u(m)+1,peek4u(d)}
        free(y) free(m) free(d)
        return result
    end function

    ------------------------------------------------------------------------
    function getCalendarYMD(atom handle, integer full=0)
    ------------------------------------------------------------------------
    object clock
    switch full do
        case 0 then return getCalendarEuDate(handle) + {1900,0,0}
        case 1 then return getCalendarEuDate(handle) + {1900,0,0} & {0,0,0}
        case 2 then clock = datetime:now() 
                return getCalendarEuDate(handle) + {1900,0,0} & clock[4..6]
    end switch
    end function

    ------------------------------------------------------------------------
    function getCalendarDay(atom handle)
    ------------------------------------------------------------------------
        atom y = allocate(64)
        atom m = allocate(64)
        atom d = allocate(64)
        c_proc(get_date,{handle,y,m,d})
        integer result = peek4u(d)
        free(y) free(m) free(d)
        return result
    end function

    ------------------------------------------------------------------------
    function getCalendarMonth(atom handle)
    ------------------------------------------------------------------------
        atom y = allocate(64)
        atom m = allocate(64)
        atom d = allocate(64)
        c_proc(get_date,{handle,y,m,d})
        integer result = peek4u(m)
        free(y) free(m) free(d)
        return result+1
    end function

    ------------------------------------------------------------------------
    function getCalendarYear(atom handle)
    ------------------------------------------------------------------------
        atom y = allocate(64)
        atom m = allocate(64)
        atom d = allocate(64)
        c_proc(get_date,{handle,y,m,d})
        integer result = peek4u(y)
        free(y) free(m) free(d)
        return result
    end function

widget[GtkCellView] = {"gtk_cell_view",
{GtkCellLayout,GtkOrientable,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_context",{P},P},
    {"new_with_text",{S},P},
    {"new_with_markup",{S},P},
    {"new_with_pixbuf",{P},P},
    {"set_model",{P,P}},
    {"get_model",{P},P},
    {"set_displayed_row",{P,P}},
    {"get_displayed_row",{P},P,0,GtkTreePath},
    {"set_draw_sensitive",{P,B}},
    {"get_draw_sensitive",{P},B},
    {"set_fit_model",{P,B}},
    {"get_fit_model",{P},B},
"GtkCellView"}

widget[GtkDrawingArea] = {"gtk_drawing_area",
{GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
"GtkDrawingArea"}

widget[GtkSearchEntry] = {"gtk_search_entry", --3.6
{GtkEditable,GtkEntry,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
"GtkSearchEntry"}

widget[GtkEntryBuffer] = {"gtk_entry_buffer",
{GtkBuildable,GObject},
    {"new",{S,I},P},
    {"get_text",{P},S},
    {"set_text",{P,S,I}},
    {"get_bytes",{P},I},
    {"get_length",{P},I},
    {"set_max_length",{P,I}},
    {"get_max_length",{P},I},
    {"insert_text",{P,I,S,I},I},
    {"delete_text",{P,I,I},I},
    {"emit_deleted_text",{P,I,I}},
    {"emit_inserted_text",{P,I,S,I}},
"GtkEntryBuffer"}

widget[GtkEntryCompletion] = {"gtk_entry_completion",
{GtkCellLayout,GtkBuildable,GObject},
    {"new",{},P},
    {"new_with_area",{P},P},
    {"get_entry",{P},P,0,GtkWidget},
    {"set_model",{P,P}},
    {"get_model",{P},P,0,GtkTreeModel},
    {"set_match_func",{P,P,P,P}},
    {"set_minimum_key_length",{P,I}},
    {"get_minimum_key_length",{P},I},
    {"compute_prefix",{P,S},S},
    {"get_completion_prefix",{P},S},
    {"insert_prefix",{P}},
    {"insert_action_text",{P,I,S}},
    {"insert_action_markup",{P,I,S}},
    {"delete_action",{P,I}},
    {"set_text_column",{P,I}},
    {"get_text_column",{P},I},
    {"set_inline_completion",{P,B}},
    {"get_inline_completion",{P},B},
    {"set_inline_selection",{P,B}},
    {"get_inline_selection",{P},B},
    {"set_popup_completion",{P,B}},
    {"get_popup_completion",{P},B},
    {"set_popup_set_width",{P,B}},
    {"get_popup_set_width",{P},B},
    {"set_popup_single_match",{P,B}},
    {"get_popup_single_match",{P},B},
    {"complete",{P}},
"GtkEntryCompletion"}

widget[GtkRevealer] = {"gtk_revealer", -- new in GTK 3.10
{GtkContainer,GtkBuildable,GtkWidget},
    {"new",{},P},
    {"set_reveal_child",{P,B}},
    {"get_reveal_child",{P},B},
    {"get_child_revealed",{P},B},
    {"set_transition_duration",{P,I}},
    {"get_transition_duration",{P},I},
    {"set_transition_type",{P,I}},
    {"get_transition_type",{P},I},
"GtkRevealer"}

widget[GtkSearchBar] = {"gtk_search_bar", -- new in GTK 3.10
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"connect_entry",{P,P}},
    {"set_search_mode",{P,B}},
    {"get_search_mode",{P},B},
    {"set_show_close_button",{P,B}},
    {"get_show_close_button",{P},B},
    {"handle_event",{P,P},B},
"GtkSearchBar"}

widget[GtkStack] = {"gtk_stack", -- new in GTK 3.10
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"add_named",{P,P,S}},
    {"add_titled",{P,P,S,S}},
    {"set_visible_child",{P,P}},
    {"get_visible_child",{P},P,0,GtkWidget},
    {"set_visible_child_name",{P,S}},
    {"get_visible_child_name",{P},S},
    {"set_visible_child_full",{P,S,I}},
    {"set_homogeneous",{P,B}},
    {"get_homogeneous",{P},B},
    {"set_transition_duration",{P,I}},
    {"get_transition_duration",{P},I},
    {"set_transition_type",{P,I}},
    {"get_transition_type",{P},I},
    {"get_child_by_name",{P,S},P,0,GtkWidget}, -- 3.12
    {"get_transition_running",{P},B}, -- 3.12
    {"get_hhomogeneous",{P},B}, -- 3.16
    {"set_hhomogeneous",{P,B}}, -- 3.16
    {"get_vhomogeneous",{P},B}, -- 3.16
    {"set_vhomogeneous",{P,B}}, -- 3.16
"GtkStack"}
    
widget[GtkStackSwitcher] = {"gtk_stack_switcher",
{GtkBox,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_stack",{P,P}},
    {"get_stack",{P},P,0,GtkStack},
"GtkStackSwitcher"}

widget[GtkScrollbar] = {"gtk_scrollbar",
{GtkOrientable,GtkRange,GtkWidget,GtkBuildable,GObject},
    {"new",{I,P},P},
"GtkScrollbar"}

widget[GtkInvisible] = {"gtk_invisible",
{GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"new_for_screen",{P},P},
    {"set_screen",{P,P}},
    {"get_screen",{P},P,0,GdkScreen},
"GtkInvisible"}

widget[PangoFont] = {"pango_font",
{0},
    {"get_metrics",{P,P},P},
    {"get_font_map",{P},P,0,PangoFontMap},
"PangoFont"}

widget[PangoFontDescription] = {"pango_font_description",
{PangoFont},
    {"new",{S},-routine_id("newPangoFontDescription")},
    {"set_family",{P,S}},
    {"get_family",{P},S},
    {"set_style",{P,P}},
    {"get_style",{P},P},
    {"set_variant",{P,I}},
    {"get_variant",{P},P},
    {"set_weight",{P,I}},
    {"get_weight",{P},I},
    {"set_stretch",{P,I}},
    {"get_stretch",{P},I},
    {"set_size",{P,I}},
    {"get_size",{P},I},
    {"set_absolute_size",{P,D}},
    {"get_size_is_absolute",{P},B},
    {"set_gravity",{P,I}},
    {"get_gravity",{P},I},
    {"to_string",{P},S},
    {"to_filename",{P},S},
"PangoFontDescription"}

    function newPangoFontDescription(object name)
    ---------------------------------------------
    return gtk_func("pango_font_description_from_string",{S},{name})
    end function

widget[GtkProgressBar] = {"gtk_progress_bar",
{GtkOrientable,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"pulse",{P}},
    {"set_fraction",{P,D}},
    {"get_fraction",{P},D},
    {"set_inverted",{P,B}},
    {"get_inverted",{P},B},
    {"set_show_text",{P,B}},
    {"get_show_text",{P},B},
    {"set_text",{P,S}},
    {"get_text",{P},S},
    {"set_ellipsize",{P,B}},
    {"get_ellipsize",{P},B},
    {"set_pulse_step",{P,D}},
    {"get_pulse_step",{P},D},
"GtkProgressBar"}

widget[GtkSpinner] = {"gtk_spinner",
{GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"start",{P}},
    {"stop",{P}},
"GtkSpinner"}

widget[GtkSwitch] = {"gtk_switch",
{GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_active",{P,B}},
    {"get_active",{P},B},
    {"get_state",{P},B}, -- GTK3.14
    {"set_state",{P,B}}, -- GTK3.14
"GtkSwitch"}

widget[GtkLevelBar] = {"gtk_level_bar",-- GTK3.6+
{GtkOrientable,GtkWidget,GtkBuildable},
    {"new",{},P},
    {"new_for_interval",{D,D},P},
    {"set_mode",{P,I}},
    {"get_mode",{P},I},
    {"set_value",{P,D}},
    {"get_value",{P},D},
    {"set_min_value",{P,D}},
    {"get_min_value",{P},D},
    {"set_max_value",{P,D}},
    {"get_max_value",{P},D},
    {"add_offset_value",{P,S,D}},
    {"remove_offset_value",{P,S}},
    {"get_offset_value",{P,S,D},B},
    {"get_inverted",{P},B}, --GTK3.8+
    {"set_inverted",{P,B}}, --GTK3.8+
"GtkLevelBar"} 

widget[GtkAboutDialog] = {"gtk_about_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_program_name",{P,S}},
    {"get_program_name",{P},S},
    {"set_version",{P,S}},
    {"get_version",{P},S},
    {"set_copyright",{P,S}},
    {"get_copyright",{P},S},
    {"set_comments",{P,S}},
    {"get_comments",{P},S},
    {"set_license",{P,S}},
    {"get_license",{P},S},
    {"set_wrap_license",{P,B}},
    {"get_wrap_license",{P},B},
    {"set_license_type",{P,I}},
    {"get_license_type",{P},I},
    {"set_website",{P,S}},
    {"get_website",{P},S},
    {"set_website_label",{P,S}},
    {"get_website_label",{P},S},
    {"set_authors",{P,A}},
    {"get_authors",{P},A},
    {"set_artists",{P,A}},
    {"get_artists",{P},A},
    {"set_documenters",{P,A}},
    {"get_documenters",{P},A},
    {"set_translator_credits",{P,S}},
    {"get_translator_credits",{P},S},
    {"set_logo",{P,P}},
    {"get_logo",{P},P,0,GdkPixbuf},
    {"set_logo_icon_name",{P,S}},
    {"get_logo_icon_name",{P},S},
    {"add_credit_section",{P,S,A}},
"GtkAboutDialog"}

widget[GtkAppChooserDialog] = {"gtk_app_chooser_dialog",
{GtkAppChooser,GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{P,I,S},-routine_id("newforURI")},
    {"new_for_uri",{P,I,S},-routine_id("newforURI")},
    {"new_for_file",{P,I,P},-routine_id("newforFIL")},
    {"new_for_content_type",{P,I,S},P},
    {"get_widget",{P},P,0,GtkAppChooserWidget},
    {"set_heading",{P,S}},
    {"get_heading",{P},S},
"GtkAppChooserDialog"}

    function newforURI(atom parent, integer flags, object uri)
    ----------------------------------------------------------
    return gtk_func("gtk_app_chooser_dialog_new_for_content_type",{P,I,S},
        {parent,flags,uri})
    end function

    function newforFIL(atom parent, integer flags, object fil)
    ----------------------------------------------------------
    fil = allocate_string(canonical_path(fil))
    fil = gtk_func("g_file_new_for_path",{S},{fil})
    return gtk_func("gtk_app_chooser_dialog_new",{P,I,P})
    end function

widget[GtkColorChooserDialog] = {"gtk_color_chooser_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GtkColorChooser,GObject},
    {"new",{S,P},P},
"GtkColorChooserDialog"}

widget[GtkColorSelectionDialog] = {"gtk_color_selection_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S},P},
    {"get_color_selection",{P},P,0,GtkColorSelection},
"GtkColorSelectionDialog"}

widget[GtkFileChooserDialog] = {"gtk_file_chooser_dialog",
{GtkFileChooser,GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,P,I,S},P},
"GtkFileChooserDialog"}

widget[GtkFontChooserDialog] = {"gtk_font_chooser_dialog",
{GtkFontChooser,GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,P},P},
"GtkFontChooserDialog"}

widget[GtkStock] = {"gtk_stock",
{GObject},
"GtkStock"}

widget[GtkRcStyle] = {"gtk_rc_style",
{GObject},
"GtkRcStyle"}

widget[GtkStyle] = {"gtk_style", -- deprecated
{GObject},
"GtkStyle"}

widget[GtkStyleProvider] = {"gtk_style_provider",
{0},
    {"get_style_property",{P,P,I,P,P},B},
"GtkStyleProvider"}

widget[GtkStyleContext] = {"gtk_style_context",
{GtkStyleProvider,GObject},
    {"new",{},P},
    {"add_provider",{P,P,I}},
    {"add_provider_for_screen",{P,P,P,I},-routine_id("addProvider")},
    {"get",{P,I,S,P,I}},
    {"get_junction_sides",{P},I},
    {"get_parent",{P},P,0,GtkStyleContext},
    {"get_path",{P},P,0,GtkWidgetPath},
    {"get_property",{P,S,I,P}},
    {"get_screen",{P},P,0,GdkScreen},
    {"get_frame_clock",{P},P,0,GdkFrameClock},
    {"get_state",{P},I},
    {"get_style",{P,S,P,I}},
    {"get_style_property",{P,S,P}},
    {"get_section",{P,S},P,0,GtkCssSection},
    {"get_color",{P,I,P}},
    {"get_background_color",{P,I,P}}, -- Deprecated 3.16
    {"get_border_color",{P,I,P}}, -- Deprecated 3.16
    {"get_border",{P,I,P}},
    {"get_padding",{P,I,P}},
    {"get_margin",{P,I,P}},
    {"invalidate",{P}},
    {"lookup_color",{P,S,P},B},
    {"remove_provider",{P,P}},
    {"remove_provider_for_screen",{P,P}},
    {"reset_widgets",{P}},
    {"set_background",{P,P}},
    {"restore",{P}},
    {"save",{P}},
    {"set_junction_sides",{P,I}},
    {"set_parent",{P,P}},
    {"set_path",{P,P}},
    {"add_class",{P,S}},
    {"remove_class",{P,S}},
    {"has_class",{P,S},B},
    {"list_classes",{P},P,0,GList},
    {"add_region",{P,S,I}}, -- Deprecated 3.14
    {"remove_region",{P,S}}, -- Deprecated 3.14
    {"has_region",{P,S,I},B}, -- Deprecated 3.14
    {"list_regions",{P},P,0,GList}, -- Deprecated 3.14
    {"get_screen",{P,P}},
    {"set_frame_clock",{P,P}},
    {"set_state",{P,I}},
    {"set_scale",{P,I}}, -- GTK3.10
    {"get_scale",{P},I}, -- GTK3.10
"GtkStyleContext"}
    
    function addProvider(atom context, atom scrn, atom provider, integer priority)
    ------------------------------------------------------------------------------
    gtk_proc("gtk_style_context_add_provider_for_screen",{P,P,I},{scrn,provider,priority})
    return 1
    end function
    
widget[GtkRecentChooserDialog] = {"gtk_recent_chooser_dialog",
{GtkRecentChooser,GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,P,P},P},
    {"new_for_manager",{S,P,P,P},P},
"GtkRecentChooserDialog"}

widget[PangoContext] = {"pango_context",
{GObject},
    {"new",{},P},   
    {"load_font",{P,P},P},
    {"load_fontset",{P,P,P},P},
    {"get_metrics",{P,P,P},P},
    {"list_families",{P,A,I}},
    {"set_font_description",{P,P}},
    {"get_font_description",{P},P},
    {"set_font_map",{P,P}},
    {"get_font_map",{P},P},
    {"set_base_gravity",{P,I}},
    {"get_language",{P},P},
    {"set_language",{P,P}},
    {"get_layout",{P},P},
    {"get_base_dir",{P},I},
    {"set_base_dir",{P,I}},
    {"get_base_gravity",{P},I},
    {"set_base_gravity",{P,I}},
    {"get_gravity",{P},I},
    {"get_gravity_hint",{P},I},
    {"set_gravity_hint",{P,I}},
    {"get_matrix",{P},P},
    {"set_matrix",{P,P}},
"PangoContext"}

widget[PangoFontsetSimple] = {"pango_fontset_simple",
{GObject},
    {"new",{P},P},
    {"append",{P,P}},
    {"size",{P},I},
"PangoFontsetSimple"}

widget[PangoFontSet] = {"pango_fontset",
{PangoFontsetSimple},
    {"get_font",{P,I},P,0,PangoFont},
    {"get_metrics",{P},P},
    {"foreach",{P,P,P}},
"PangoFontSet"}

widget[PangoFontMap] = {"pango_font_map",
{PangoFontSet},
    {"create_context",{P},P},
    {"load_font",{P,P,S},P},
    {"load_fontset",{P,P,S,P},P},
    {"list_families",{P,A,I}},
    {"get_shape_engine_type",{P},S},
"PangoFontMap"}


widget[PangoFontFace] = {"pango_font_face",
{PangoFontMap},
    {"get_face_name",{P},-routine_id("getFaceName")},
    {"list_sizes",{P,P,I}},
    {"describe",{P},P,0,PangoFontDescription},
    {"is_synthesized",{P},B},
"PangoFontFace"}

    function getFaceName(atom  x)
    -----------------------------
    return gtk_str_func("pango_font_face_get_face_name",{P},{x})
    end function

widget[PangoFontFamily] = {"pango_font_family",
{PangoFontFace},
    {"get_name",{P},-routine_id("getFamilyName")},
    {"is_monospace",{P},B},
"PangoFontFamily"}

    function getFamilyName(atom x)
    ------------------------------
    return gtk_str_func("pango_font_family_get_name",{P},{x})
    end function
    
widget[PangoLayout] = {"pango_layout",
{GObject},
    {"new",{P},P},
    {"set_text",{P,S,I}},
    {"get_text",{P},S},
    {"set_markup",{P,S,I}},
    {"set_font_description",{P,P}},
    {"get_font_description",{P},P},
    {"set_width",{P,I}},
    {"get_width",{P},I},
    {"set_height",{P,I}},
    {"get_height",{P},I},
    {"set_wrap",{P,I}},
    {"get_wrap",{P},I},
    {"is_wrapped",{P},B},
    {"set_ellipsize",{P,I}},
    {"get_ellipsize",{P},I},
    {"is_ellipsized",{P},B},
    {"set_indent",{P,I}},
    {"get_extents",{P,P,P}},
    {"get_indent",{P},I},
    {"get_pixel_size",{P,I,I}},
    {"get_size",{P,I,I}},
    {"set_spacing",{P,I}},
    {"get_spacing",{P},I},
    {"set_justify",{P,B}},
    {"get_justify",{P},B},
    {"set_auto_dir",{P,B}},
    {"get_auto_dir",{P},B},
    {"set_alignment",{P,P}},
    {"get_alignment",{P},P},
    {"set_tabs",{P,A}},
    {"get_tabs",{P},A},
    {"set_single_paragraph_mode",{P,B}},
    {"get_single_paragraph_mode",{P},B},
    {"get_unknown_glyphs_count",{P},I},
    {"get_log_attrs",{P,P,I}},
    {"get_log_attrs_readonly",{P,I},P},
    {"index_to_pos",{P,I,P}},
    {"index_to_line",{P,I,B,I,I}},
    {"xy_to_line",{P,I,I,I,I},B},
    {"get_cursor_pos",{P,I,P,P}},
    {"move_cursor_visually",{P,B,I,I,I,I,I}},
    {"get_extents",{P,P,P}},
    {"get_pixel_extents",{P,P,P}},
    {"get_size",{P,I,I}},
    {"get_pixel_size",{P,I,I}},
    {"get_baseline",{P},I},
    {"get_line_count",{P},I},
    {"get_line",{P,I},P,0,PangoLayoutLine},
    {"get_line_readonly",{P,I},P,0,PangoLayoutLine},
    {"get_lines",{P},P,0,GSList},
    {"get_lines_readonly",{P},P,0,GSList},
    {"get_iter",{P},P,0,PangoLayoutIter},
"PangoLayout"}

widget[PangoLayoutLine] = {"pango_layout_line",
{0},
    {"ref",{P},P},
    {"unref",{P}},
    {"get_extents",{P,P,P}},
    {"get_pixel_extents",{P,P,P}},
    {"index_to_x",{P,I,B,I}},
    {"x_to_index",{P,I,I,I},B},
"PangoLayoutLine"}

widget[PangoLayoutIter] = {"pango_layout_iter",
{0},
    {"copy",{P},P,0,PangoLayoutIter},
    {"free",{P}},
    {"next_run",{P},B},
    {"next_char",{P},B},
    {"next_cluster",{P},B},
    {"next_line",{P},B},
    {"at_last_line",{P},B},
    {"get_index",{P},I},
    {"get_baseline",{P},I},
    {"get_run",{P},P,0,PangoLayoutRun},
    {"get_run_readonly",{P},P,0,PangoLayoutRun},
    {"get_line",{P},P,0,PangoLayoutLine},
    {"get_line_readonly",{P},P,0,PangoLayoutLine},
    {"get_layout",{P},P,0,PangoLayout},
    {"get_char_extents",{P,P}},
    {"get_cluster_extents",{P,P,P}},
    {"get_run_extents",{P,P,P}},
    {"get_line_yrange",{P,I,I}},
    {"get_line_extents",{P,P,P}},
    {"get_layout_extents",{P,P,P}},
"PangoLayoutIter"}

widget[PangoLayoutRun] = {"pango_layout_run",
{0},
"PangoLayoutRun"}

widget[PangoTabArray] = {"pango_tab_array",
{0},
"PangoTabArray"}

widget[GdkCairo_t] = {"gdk_cairo",
{Cairo_t},
    {"new",{P},-routine_id("newGdkCairo")},
    {"draw_from_gl",{P,P,I,I,I,I,I,I,I}}, -- 3.16
    {"get_clip_rectangle",{P,P},B},
    {"set_source_pixbuf",{P,P,D,D}},
    {"set_source_window",{P,P,D,D}},
    {"region",{P,P}},
    {"region_create_from_surface",{P},P},
    {"surface_create_from_pixbuf",{P,I,P},P,0,CairoSurface_t},
    {"set_source_rgba",{P,I,I,I,D},-routine_id("setCairoRGBA")},
    {"set_color",{P,P},-routine_id("setCairoColor")},
"GdkCairo_t"}

    function newGdkCairo(atom win)
    ------------------------------
    return gtk_func("gdk_cairo_create",{P},{win})
    end function
    
    ----------------------------------------------------------------
    -- to use the (awkward) Cairo color specs, where colors are 0.0 => 1.0
    ----------------------------------------------------------------------
    function setCairoRGBA(atom cr, atom r, atom g, atom b, atom a=1)
        gtk_proc("cairo_set_source_rgba",{P,D,D,D,D},{cr,r,g,b,a})
    return 1
    end function
    
    --------------------------------------------
    -- it's easier to use named colors
    --------------------------------------------
    function setCairoColor(atom cr, object color)
        if atom(color) then color = sprintf("#%06x",color) end if
        color = to_rgba(color)
        color = from_rgba(color,7) 
        setCairoRGBA(cr,color[1],color[2],color[3],color[4])
    return 1
    end function

widget[Cairo_t] = {"cairo",
{GObject},
    {"create",{P},P},
    {"reference",{P},P},
    {"destroy",{P}},
    {"status",{P},I},
    {"save",{P}},
    {"restore",{P}},
    {"get_target",{P},P,0,CairoSurface_t},
    {"push_group",{P}},
    {"push_group_with_content",{P,P}},
    {"pop_group",{P},P},
    {"pop_group_to_source",{P}},
    {"get_group_target",{P},P},
    {"set_source_rgb",{P,D,D,D}},
    {"set_source",{P,P}},
    {"get_source",{P},P},
    {"set_source_surface",{P,P,D,D}},
    {"set_antialias",{P,I}},
    {"get_antialias",{P},I},
    {"set_dash",{P,P,I,D}},
    {"get_dash_count",{P},I},
    {"get_dash",{P,D,D}},
    {"set_fill_rule",{P,I}},
    {"get_fill_rule",{P},I},
    {"set_line_cap",{P,I}},
    {"get_line_cap",{P},I},
    {"set_line_join",{P,I}},
    {"get_line_join",{P},I},
    {"set_line_width",{P,D}},
    {"get_line_width",{P},D},
    {"set_miter_limit",{P,I}},
    {"get_miter_limit",{P},I},
    {"set_operator",{P,I}},
    {"get_operator",{P},I},
    {"set_tolerance",{P,D}},
    {"get_tolerance",{P},D},
    {"clip",{P}},
    {"clip_preserve",{P}},
    {"clip_extents",{P,D,D,D,D}},
    {"in_clip",{P,D,D},B},
    {"reset_clip",{P}},
    {"rectangle_list_destroy",{P}},
    {"fill",{P}},
    {"fill_preserve",{P}},
    {"fill_extents",{P,D,D,D,D}},
    {"in_fill",{P,D,D},B},
    {"mask",{P,P}},
    {"mask_surface",{P,P,D,D}},
    {"paint",{P}},
    {"paint_with_alpha",{P,D}},
    {"stroke",{P}},
    {"stroke_preserve",{P}},
    {"stroke_extents",{P,D,D,D,D}},
    {"in_stroke",{P,D,D},B},
    {"copy_page",{P}},
    {"show_page",{P}},
    {"copy_path",{P},P},
    {"copy_path_flat",{P},P},
    {"path_destroy",{P}},
    {"append_path",{P,P}},
    {"has_current_point",{P},B},
    {"get_current_point",{P,D,D}},
    {"new_path",{P}},
    {"new_sub_path",{P}},
    {"close_path",{P}},
    {"set_user_data",{P,S,P,P},I},
    {"get_user_data",{P,S}},
    {"arc",{P,D,D,D,D,D}},
    {"arc_negative",{P,D,D,D,D,D}},
    {"move_to",{P,D,D}},
    {"rel_move_to",{P,D,D}},
    {"line_to",{P,D,D}},
    {"rel_line_to",{P,D,D}},
    {"rectangle",{P,D,D,D,D}},
    {"glyph_path",{P,I,I}},
    {"text_path",{P,S}},
    {"curve_to",{P,D,D,D,D,D,D}},
    {"rel_curve_to",{P,D,D,D,D,D,D}},
    {"path_extents",{P,D,D,D,D}},
    {"set_font_face",{P,S}},
    {"device_get_type",{P},I},
    {"device_status",{P},I},
    {"status_to_string",{I},S},
    {"translate",{P,D,D}},
    {"scale",{P,D,D}},
    {"rotate",{P,D}},
    {"transform",{P,P}},
    {"translate",{P,D,D}},
    {"scale",{P,D,D}},
    {"rotate",{P,D}},
    {"transform",{P,P}},
    {"set_matrix",{P,P}},
    {"get_matrix",{P,P}},
    {"identity_matrix",{P}},
    {"user_to_device",{P,D,D}},
    {"user_to_device_distance",{P,D,D}},
    {"device_to_user",{P,D,D}},
    {"device_to_user_distance",{P,D,D}},
    {"version",{},I},
    {"version_string",{},S},
    {"set_font_size",{P,D}},
    {"set_font_matrix",{P,P}},
    {"get_font_matrix",{P,P}},
    {"set_font_options",{P,P}},
    {"get_font_options",{P,P}},
    {"select_font_face",{P,S,I,I}},
    {"get_font_face",{P},P},
    {"set_scaled_font",{P,P}},
    {"get_scaled_font",{P},P},
    {"show_glyphs",{P,P}},
    {"show_text_glyphs",{P,S,I,P,I,P,I,I}},
    {"font_extents",{P,P}},
    {"text_extents",{P,S,P}},
    {"glyph_extents",{P,P,I,P}},
    {"select_font_face",{P,S,I,I}},
    {"toy_font_face_create",{S,I,I},P},
    {"toy_font_face_get_slant",{P},I},
    {"toy_font_face_get_weight",{P},I},
    {"glyph_allocate",{I},P},
    {"glyph_free",{P}},
    {"text_cluster_allocate",{I},P},
    {"text_cluster_free",{P}},
    {"show_text",{P,S}},
    {"set_source_rgba",{P,D,D,D,D},-routine_id("setCairoRGBA")},
    {"set_color",{P,S},-routine_id("setCairoColor")},
"Cairo_t"}

widget[CairoPattern_t] = {0,
{Cairo_t},
"CairoPattern_t"}

widget[CairoPattern] = {"cairo_pattern",
{CairoPattern_t},
    {"new",{P},-routine_id("newCairoPattern")},
    {"add_color_stop_rgb",{P,D,D,D,D}},
    {"add_color_stop_rgba",{P,D,D,D,D,D}},
    {"get_color_stop_count",{P,I},P,0,CairoStatus_t},
    {"get_color_stop_rgba",{P,I,D,D,D,D,D},P,0,CairoStatus_t},
    {"create_rgb",{D,D,D},P,0,CairoPattern_t},
    {"create_rgba",{D,D,D,D},P,0,CairoPattern_t},
    {"get_rgba",{P,D,D,D,D},P,0,CairoPattern_t},
    {"create_for_surface",{P},P,0,CairoPattern_t},
    {"reference",{P},P,0,CairoPattern_t},
    {"destroy",{P}},
    {"status",{P},P,0,CairoStatus_t},
    {"set_extend",{P,I}},
    {"get_extent",{P},I},
    {"set_filter",{P,I}},
    {"get_filter",{P},I},
    {"set_matrix",{P,P}},
    {"get_matrix",{P,P}},
    {"get_type",{P},I},
    {"get_reference_count",{P},I},
"CairoPattern"}

    function newCairoPattern(atom surf)
    -----------------------------------
    return gtk_func("cairo_pattern_create_for_surface",{P},{surf})
    end function

widget[CairoLinearGradient] = {"cairo_pattern",
{CairoPattern},
    {"new",{D,D,D,D},-routine_id("newLinearGradient"),0,CairoPattern_t},
    {"get_linear_points",{P,D,D,D,D},P,0,CairoStatus_t},
"CairoLinearGradient"}

    function newLinearGradient(atom a, atom b, atom c, atom d)
    ----------------------------------------------------------
    return gtk_func("cairo_pattern_create_linear",{D,D,D,D},{a,b,c,d})
    end function

widget[CairoRadialGradient] = {"cairo_pattern",
{CairoPattern},
    {"new",{D,D,D,D,D,D},-routine_id("newRadialGradient"),0,CairoPattern_t},
    {"get_radial_circles",{P,D,D,D,D,D,D},P,0,CairoStatus_t},
"CairoRadialGradient"}

    function newRadialGradient(atom a, atom b, atom c, atom d, atom e, atom f)
    --------------------------------------------------------------------------
    return gtk_func("cairo_pattern_create_radial",{D,D,D,D,D,D},{a,b,c,d,e,f})
    end function

widget[CairoRegion_t] = {"cairo_region_t",
{Cairo_t},
"CairoRegion_t"}

widget[CairoSurface_t] = {"cairo_surface_t",
{Cairo_t},
    {"get_write_to_png",{P,S},-routine_id("writetoPNG")},
    {"create_similar",{P,P,I,I},P,0,CairoSurface_t},
    {"create_for_rectangle",{P,D,D,D,D},P,0,CairoSurface_t},
    {"reference",{P},P,0,CairoSurface_t},
    {"destroy",{P}},
    {"finish",{P}},
    {"flush",{P}},
    {"get_font_options",{P,P}},
    {"mark_dirty",{P}},
    {"mark_dirty_rectangle",{P,I,I,I,I}},
    {"show_page",{P}},
"CairoSurface_t"}

    function writetoPNG(atom surf, object name)
    -------------------------------------------
    return gtk_func("cairo_surface_write_to_png",{P,S},{surf,name})
    end function

widget[CairoImageSurface] = {"cairo_image_surface",
{CairoSurface_t},
    {"new",{P},-routine_id("newCairoImageSurface")},
    {"get_format",{P},I},
    {"get_width",{P},P},
    {"get_height",{P},P},
    {"get_stride",{P},I},
"CairoImageSurface"}

    function newCairoImageSurface(object png)
    -----------------------------------------
    if string(png) then
        png = allocate_string(canonical_path(png))
    end if
    return gtk_func("cairo_image_surface_create_from_png",{S},{png})
    end function

widget[PangoCairoLayout] = {"pango_cairo",
{PangoLayout},
    {"new",{P},-routine_id("newPangoCairoLayout"),0,PangoLayout},
    {"update_layout",{P,P},-routine_id("updateLayout")},
    {"show_glyph_string",{P,P,P}},
    {"show_glyph_item",{P,S,P}},
    {"show_layout",{P,P},-routine_id("showLayout")},
    {"show_layout_line",{P,P}},
    {"layout_line_path",{P,P}},
    {"layout_path",{P,P}},
"PangoCairoLayout"}

    function newPangoCairoLayout(atom cr)
    -------------------------------------
    return gtk_func("pango_cairo_create_layout",{P},{cr})
    end function

    function updateLayout(atom pl, atom cr)
    ---------------------------------------
    gtk_proc("pango_cairo_update_layout",{P,P},{cr,pl})
    return 1
    end function

    function showLayout(atom pl, atom cr)
    -------------------------------------
    gtk_proc("pango_cairo_show_layout",{P,P},{cr,pl})
    return 1
    end function

widget[GtkPrintSettings] = {"gtk_print_settings",
{GObject},
    {"new",{},P},
    {"new_from_file",{S,P},P,0,GtkPrintSettings},
    {"new_from_key_file",{S,P},P,0,GtkPrintSettings},
    {"load_file",{P,S,P},B},
    {"to_file",{P,S,P},B},
    {"load_key_file",{P,P,S,P},B},
    {"to_key_file",{P,P,S}},
    {"copy",{P},P,0,GtkPrintSettings},
    {"has_key",{P,S},B},
    {"get",{P,S},S},
    {"set",{P,S,S}},
    {"unset",{P,S}},
    {"foreach",{P,P,P}},
    {"get_bool",{P,S},B},
    {"set_bool",{P,S,B}},
    {"get_double",{P,S},D},
    {"get_double_with_default",{P,S,D},D},
    {"set_double",{P,S,D}},
    {"get_length",{P,S,I},D},
    {"set_length",{P,S,D,I}},
    {"get_int",{P,S},I},
    {"get_int_with_default",{P,S,I},I},
    {"set_int",{P,S,I}},
    {"get_printer",{P},S},
    {"set_printer",{P,S}},
    {"get_orientation",{P},I},
    {"set_orientation",{P,I}},
    {"get_paper_size",{P},P,0,GtkPaperSize},
    {"set_paper_size",{P,P}},
    {"get_paper_width",{P,I},D},
    {"set_paper_width",{P,D,I}},
    {"get_paper_height",{P,I},D},
    {"set_paper_height",{P,D,I}},
    {"get_use_color",{P},B},
    {"set_use_color",{P,B}},
    {"get_collate",{P},B},
    {"set_collate",{P,B}},
    {"get_reverse",{P},B},
    {"set_reverse",{P,B}},
    {"get_duplex",{P},I},
    {"set_duplex",{P,I}},
    {"get_quality",{P},I},
    {"set_quality",{P,I}},
    {"get_n_copies",{P},I},
    {"set_n_copies",{P,I}},
    {"get_number_up",{P},I},
    {"set_number_up",{P,I}},
    {"get_number_up_layout",{P},I},
    {"set_number_up_layout",{P,I}},
    {"get_resolution",{P},I},
    {"set_resolution",{P,I}},
    {"get_resolution_x",{P},I},
    {"get_resolution_y",{P},I},
    {"get_printer_lpi",{P},D},
    {"set_printer_lpi",{P,D}},
    {"get_scale",{P},D},
    {"set_scale",{P,D}},
    {"get_print_pages",{P},I},
    {"set_print_pages",{P,I}},
    {"get_page_ranges",{P,I},P,0,GtkPageRange},
    {"set_page_ranges",{P,P},-routine_id("setPageRanges")},
    {"get_page_set",{P},I},
    {"set_page_set",{P,I}},
    {"get_default_source",{P},S},
    {"set_default_source",{P,S}},
    {"get_media_type",{P},S},
    {"set_media_type",{P,S}},
    {"get_dither",{P},S},
    {"set_dither",{P,S}},
    {"get_finishings",{P},S},
    {"set_finishings",{P,S}},
    {"get_output_bin",{P},S},
    {"set_output_bin",{P,S}},
"GtkPrintSettings"}

    function setPageRanges(atom x, object r)
    ----------------------------------------
    gtk_proc("gtk_print_settings_set_pages_ranges",{P,P,I},{x,r,length(r)})
    return 1
    end function

widget[GtkPaperSize] = {"gtk_paper_size",
{GObject},
    {"new",{S},P},
    {"new_from_ppd",{S,S,D,D},P},
    {"new_from_ipp",{S,D,D},P,0,GtkPaperSize}, -- 3.16
    {"new_custom",{S,S,D,D,I},P},
    {"copy",{P},P,0,GtkPaperSize},
    {"is_equal",{P,P},B},
    {"get_name",{P},S},
    {"get_display_name",{P},S},
    {"get_ppd_name",{P},S},
    {"get_width",{P,I},D},
    {"get_height",{P,I},D},
    {"is_custom",{P},B},
    {"set_size",{P,D,D,I}},
    {"get_default_top_margin",{P,I},D},
    {"get_default_bottom_margin",{P,I},D},
    {"get_default_left_margin",{P,I},D},
    {"get_default_right_margin",{P,I},D},
"GtkPaperSize"}

widget[GtkPageSetup] = {"gtk_page_setup",
{GObject},
    {"new",{},P},
    {"copy",{P},P,0,GtkPageSetup},
    {"get_orientation",{P},I},
    {"set_orientation",{P,I}},
    {"get_paper_size",{P},P,0,GtkPaperSize},
    {"set_paper_size",{P,P}},
    {"get_top_margin",{P,I},D},
    {"set_top_margin",{P,D,I}},
    {"get_bottom_margin",{P,I},D},
    {"set_bottom_margin",{P,D,I}},
    {"get_left_margin",{P,I},D},
    {"set_left_margin",{P,D,I}},
    {"get_right_margin",{P,I},D},
    {"set_right_margin",{P,D,I}},
    {"set_paper_size_and_default_margins",{P,P}},
    {"get_paper_width",{P,I},D},
    {"get_paper_height",{P,I},D},
    {"get_page_width",{P,I},D},
    {"get_page_height",{P,I},D},
    {"new_from_file",{S,P},P,0,GtkPageSetup},
    {"load_file",{P,S,P},B},
    {"to_file",{P,S},-routine_id("setPgSetupToFile")},
"GtkPageSetup"}

    function setPgSetupToFile(atom setup, object filename)
    ------------------------------------------------------
    atom err = allocate(8) err = 0
    return gtk_func("gtk_page_setup_to_file",{P,P,P},{setup,filename,err})
    end function
    
widget[GtkPrintOperation] = {"gtk_print_operation",
{GObject},
    {"new",{},P},
    {"set_allow_async",{P,B}},
    {"get_error",{P,P}},
    {"set_default_page_setup",{P,P}},
    {"get_default_page_setup",{P},P,0,GtkPageSetup},
    {"set_print_settings",{P,P}},
    {"get_print_settings",{P},P,0,GtkPrintSettings},
    {"set_job_name",{P,S}},
    {"get_job_name",{P},-routine_id("getPrintOpJobName")},
    {"set_n_pages",{P,I}},
    {"get_n_pages_to_print",{P},I},
    {"set_current_page",{P,I}},
    {"set_use_full_page",{P,B}},
    {"set_unit",{P,I}},
    {"set_export_filename",{P,S}},
    {"set_show_progress",{P,B}},
    {"set_track_print_status",{P,B}},
    {"set_custom_tab_label",{P,S}},
    {"run",{P,P,P,P},I},
    {"cancel",{P}},
    {"draw_page_finish",{P}},
    {"set_defer_drawing",{P}},
    {"get_status",{P},I},
    {"get_status_string",{P},S},
    {"is_finished",{P},B},
    {"set_support_selection",{P,B}},
    {"get_support_selection",{P},B},
    {"set_has_selection",{P,B}},
    {"get_has_selection",{P},B},
    {"set_embed_page_setup",{P,B}},
    {"get_embed_page_setup",{P},B},
"GtkPrintOperation"}

    function getPrintOpJobName(atom op)
    -----------------------------------
    object job = allocate(32), err = allocate(32) err = 0
    gtk_func("g_object_get",{P,S,P,P},{op,"job name",job,err})
    return peek_string(peek4u(job))
    end function
    
widget[GtkPrintContext] = {"gtk_print_context",
{GObject},
    {"get_cairo_context",{P},P,0,Cairo_t},
    {"set_cairo_context",{P,P,D,D}},
    {"get_page_setup",{P},P,0,GtkPageSetup},
    {"get_width",{P},D},
    {"get_height",{P},D},
    {"get_dpi_x",{P},D},
    {"get_dpi_y",{P},D},
    {"get_pango_fontmap",{P},P,0,PangoFontMap},
    {"create_pango_context",{P},P,0,PangoContext},
    {"create_pango_layout",{P},P,0,PangoLayout},
    {"get_hard_margins",{P,D,D,D,D},B},
"GtkPrintContext"}

widget[GtkPrintUnixDialog] = {"gtk_print_unix_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,P},P},
    {"set_page_setup",{P,P}},
    {"get_page_setup",{P},P,0,GtkPageSetup},
    {"set_current_page",{P,I}},
    {"get_current_page",{P},I},
    {"set_settings",{P,P}},
    {"get_settings",{P},P,0,GtkPrintSettings},
    {"get_selected_printer",{P},P,0,GtkPrinter},
    {"add_custom_tab",{P,P,P}},
    {"set_support_selection",{P,B}},
    {"get_support_selection",{P},B},
    {"get_has_selection",{P},B},
    {"set_embed_page_setup",{P,B}},
    {"get_embed_page_setup",{P},B},
    {"set_manual_capabilities",{P,I}},
    {"get_manual_capabilities",{P},I},
"GtkPrintUnixDialog"}

widget[GtkPageSetupUnixDialog] = {"gtk_page_setup_unix_dialog",
{GtkDialog,GtkWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{S,P},P},
    {"set_page_setup",{P,P}},
    {"get_page_setup",{P},P,0,GtkPageSetup},
    {"set_print_settings",{P,P}},
    {"get_print_settings",{P},P,0,GtkPrintSettings},
"GtkPageSetupUnixDialog"}

widget[GtkListBox] = {"gtk_list_box", -- new in GTK 3.10
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"prepend",{P,P}},
    {"insert",{P,P,I}},
    {"select_row",{P,P}},
    {"select_all",{P}}, -- 3.14
    {"unselect_all",{P}}, -- 3.14
    {"unselect_row",{P,P}}, -- 3.14
    {"get_selected_row",{P},P},
    {"get_selected_rows",{P},A},-- 3.14
    {"row_is_selected",{P},B}, -- 3.14
    {"selected_foreach",{P,P,P}}, -- 3.14
    {"set_selection_mode",{P,I}},
    {"get_selection_mode",{P},I},
    {"set_activate_on_single_click",{P,B}}, 
    {"get_activate_on_single_click",{P},B}, 
    {"set_adjustment",{P,P}},
    {"get_adjustment",{P},P,0,GtkAdjustment},
    {"set_placeholder",{P,P}},
    {"get_row_at_index",{P,I},P,0,GtkListBoxRow},
    {"get_row_at_y",{P,I},P,0,GtkListBoxRow},
    {"invalidate_filter",{P}},
    {"invalidate_headers",{P}},
    {"invalidate_sort",{P}},
    {"set_filter_func",{P,P,P,P}},
    {"set_header_func",{P,P,P,P}},
    {"set_sort_func",{P,P,P,P}},
    {"drag_highlight_row",{P,P}}, 
    {"drag_unhighlight_row",{P}}, 
"GtkListBox"}

widget[GtkListBoxRow] = {"gtk_list_box_row",
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"changed",{P}},
    {"get_header",{P},P,0,GtkWidget},
    {"get_type",{},I},
    {"set_header",{P,P}},
    {"get_index",{P},I},
    {"set_activatable",{P,B}},
    {"set_selectable",{P,B}},
    {"get_selectable",{P},B},
"GtkListBoxRow"}

widget[GtkPopover] = {"gtk_popover", -- new in GTK 3.12
{GtkBin,GtkContainer,GtkWidget,GObject},
    {"new",{P},P},
    {"new_from_model",{P,P},P},
    {"bind_model",{P,P,S}},
    {"set_relative_to",{P,P}},
    {"get_relative_to",{P},P,0,GtkWidget},
    {"set_pointing_to",{P,P}},
    {"get_pointing_to",{P,P},B},
    {"set_position",{P,I}},
    {"get_position",{P},I},
    {"set_modal",{P,B}},
    {"get_modal",{P},B},
"GtkPopover"}

widget[GtkPopoverMenu] = {"gtk_popover_menu", -- 3.12
{GtkPopover,GtkBin,GtkContainer,GtkWidget,GObject},
    {"new",{},P},
    {"open_submenu",{P,S}},
"GtkPopoverMenu"}

widget[GtkPlacesSidebar] = {"gtk_places_sidebar", -- new 3.10
{GtkScrolledWindow,GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_open_flags",{P,I}},
    {"get_open_flags",{P},I},
    {"set_location",{P,P}},
    {"get_location",{P},P,0,GFile},
    {"set_show_desktop",{P,B}},
    {"get_show_desktop",{P},B},
    {"add_shortcut",{P,P}},
    {"remove_shortcut",{P,P}},
    {"list_shortcuts",{P},P,0,GSList},
    {"get_nth_bookmark",{P,I},P,0,GFile},
    {"get_show_connect_to_server",{P},B},
    {"set_show_connect_to_server",{P,B}},
    {"set_local_only",{P,B}}, -- 3.12
    {"get_local_only",{P},B}, -- 3.12
    {"get_show_enter_location",{P},B}, --3.14
    {"set_show_enter_location",{P,B}}, --3.14
"GtkPlacesSidebar"}

widget[GtkHeaderBar] = {"gtk_header_bar", -- new in GTK 3.10
{GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"set_title",{P,S}},
    {"get_title",{P},S},
    {"set_subtitle",{P,S}},
    {"get_subtitle",{P},S},
    {"set_has_subtitle",{P,B}}, -- 3.12
    {"get_has_subtitle",{P},B}, -- 3.12
    {"set_custom_title",{P,P}},
    {"get_custom_title",{P},P,0,GtkWidget},
    {"pack_start",{P,P}},
    {"pack_end",{P,P}},
    {"set_show_close_button",{P,B}},
    {"get_show_close_button",{P},B},
    {"set_decoration_layout",{P,S}}, -- 3.12
    {"get_decoration_layout",{P},S}, -- 3.12
"GtkHeaderBar"}

widget[PangoLanguage] = {"pango_language",
{GObject},
    {"new",{S},-routine_id("newPangoLanguage")},
    {"get_default",{P},-routine_id("getDefaultLanguage")},
    {"get_sample_string",{P},-routine_id("getSampleStr")},
    {"to_string",{P},S},
    {"matches",{P,S},B},
    {"includes_script",{P,P},B},
"PangoLanguage"}

    function newPangoLanguage(object s)
    -----------------------------------
    return gtk_func("pango_language_from_string",{S},{s})
    end function

    function getDefaultLanguage(object junk)
    ----------------------------------------
    return gtk_str_func("pango_language_get_default")
    end function

    function getSampleStr(object x)
    -------------------------------
        return gtk_str_func("pango_language_get_sample_string",{P},{x})
    end function

widget[GtkPrinter] = {"gtk_printer",
{GObject},
    {"new",{S,P,B},P},
    {"get_backend",{P},P},
    {"get_name",{P},S},
    {"get_state_message",{P},S},
    {"get_description",{P},S},
    {"get_location",{P},S},
    {"get_icon_name",{P},S},
    {"get_job_count",{P},I},
    {"is_active",{P},B},
    {"is_paused",{P},B},
    {"is_accepting_jobs",{P},B},
    {"is_virtual",{P},B},
    {"is_default",{P},B},
    {"accepts_ps",{P},B},
    {"accepts_pdf",{P},B},
    {"list_papers",{P},P,0,GList},
    {"compare",{P,P},I},
    {"has_details",{P},B},
    {"request_details",{P}},
    {"get_capabilities",{P},I},
    {"get_default_page_size",{P},P,0,GtkPageSetup},
    {"get_hard_margins",{P,D,D,D,D},B},
"GtkPrinter"}

widget[GtkPrintJob] = {"gtk_print_job",
{GObject},
    {"new",{S,P,P,P},P},
    {"get_settings",{P},P,0,GtkPrintSettings},
    {"get_printer",{P},P,0,GtkPrinter},
    {"get_title",{P},S},
    {"get_status",{P},I},
    {"set_source_file",{P,S,P},B},
    {"get_surface",{P,P},P,0,CairoSurface_t},
    {"send",{P,P,P,P}},
    {"set_track_print_status",{P,B}},
    {"get_track_print_status",{P},B},
    {"get_pages",{P},I},
    {"set_pages",{P,I}},
    {"get_page_ranges",{P,I},P,0,GtkPageRange},
    {"set_page_ranges",{P,P,I}},
    {"get_page_set",{P},I},
    {"set_page_set",{P,I}},
    {"get_num_copies",{P},I},
    {"set_num_copies",{P,I}},
    {"get_scale",{P},D},
    {"set_scale",{P,D}},
    {"get_n_up",{P},I},
    {"set_n_up",{P,I}},
    {"get_n_up_layout",{P},I},
    {"set_n_up_layout",{P,I}},
    {"get_rotate",{P},B},
    {"set_rotate",{P,B}},
    {"get_collate",{P},B},
    {"set_collate",{P,B}},
    {"get_reverse",{P},B},
    {"set_reverse",{P,B}},
"GtkPrintJob"}

widget[GtkFlowBox] = {"gtk_flow_box", -- GTK 3.12
{GtkBin,GtkContainer,GtkWidget,GtkBuildable,GObject},
    {"new",{},P},
    {"insert",{P,P,I}},
    {"get_child_at_index",{P,I},P,0,GtkFlowBoxChild},
    {"set_hadjustment",{P,P}},
    {"set_vadjustment",{P,P}},
    {"set_homogeneous",{P,B}},
    {"get_homogeneous",{P},B},
    {"set_row_spacing",{P,I}},
    {"get_row_spacing",{P},I},
    {"set_column_spacing",{P,I}},
    {"get_column_spacing",{P},I},
    {"set_min_children_per_line",{P,I}},
    {"get_min_children_per_line",{P},I},
    {"set_max_children_per_line",{P,I}},
    {"get_max_children_per_line",{P},I},
    {"set_activate_on_single_click",{P,B}},
    {"get_activate_on_single_click",{P},B},
    {"selected_foreach",{P,P,P}},
    {"get_selected_children",{P},P,0,GList},
    {"select_child",{P,P}},
    {"unselect_child",{P,P}},
    {"select_all",{P}},
    {"unselect_all",{P}},
    {"set_selection_mode",{P,I}},
    {"get_selection_mode",{P},I},
    {"set_filter_func",{P,P,P,P}},
    {"invalidate_filter",{P}},
    {"set_sort_func",{P,P,P,P}},
    {"invalidate_sort",{P}},
"GtkFlowBox"}

widget[GtkFlowBoxChild] = {"gtk_flow_box_child", -- GTK 3.12
{GtkFlowBox},
    {"new",{},P},
    {"get_index",{P},I},
    {"is_selected",{P},B},
    {"changed",{P}},
"GtkFlowBoxChild"}

widget[GtkMountOperation]  = {"gtk_mount_operation",
{GObject},
    {"new",{P},P},
    {"is_showing",{P},B},
    {"set_parent",{P,P}},
    {"get_parent",{P},P,0,GtkWindow},
    {"set_screen",{P,P}},
    {"get_screen",{P},P,0,GdkScreen},
"GtkMountOperation"}

-- stocklist is not a GTK widget, we just fake it for convenience
widget[GtkStockList] = {"gtk_stocklist", -- deprecated in GTK 3.12+
{0}, 
"GtkStockList"}

    function newStockList()
    -----------------------
    object list = gtk_func("gtk_stock_list_ids")
    return to_sequence(list)
    end function

widget[GtkEventController] = {"gtk_event_controller",
{GObject},
    {"get_propagation_phase",{P},I},
    {"set_propagation_phase",{P,I}},
    {"handle_event",{P,P},B},
    {"get_widget",{P},P,0,GtkWidget},
    {"reset",{P}},
"GtkEventController"}

widget[GtkGesture] = {"gtk_gesture", --GTK3.14
{GtkEventController,GObject},
    {"get_device",{P},P},
    {"get_window",{P},P},
    {"set_window",{P,P}},
    {"is_active",{P},B},
    {"is_recognized",{P},B},
    {"get_sequence_state",{P,P},I},
    {"set_sequence_state",{P,P,I},B},
    {"set_state",{P,I},B},
    {"get_sequences",{P},A},
    {"handles_sequence",{P,P},B},
    {"get_last_updated_sequence",{P},P},
    {"get_last_event",{P,P},P},
    {"get_point",{P,P,D,D},B},
    {"get_bounding_box",{P,P},B},
    {"get_bounding_box_center",{P,D,D},B},
    {"group",{P,P}},
    {"ungroup",{P}},
    {"get_group",{P},A},
    {"is_grouped_with",{P,P},B},
"GtkGesture"}

widget[GtkGestureSingle] = {"gtk_gesture_single",
{GtkGesture,GtkEventController,GObject},
    {"get_exclusive",{P},B},
    {"set_exclusive",{P,B}},
    {"get_touch_only",{P},B},
    {"set_touch_only",{P,B}},
    {"get_button",{P},I},
    {"set_button",{P,I}},
    {"get_current_button",{P},I},
    {"get_current_sequence",{P},P},
"GtkGestureSingle"}

widget[GtkGestureRotate] = {"gtk_gesture_rotate",
{GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
    {"get_angle_delta",{P},D},
"GtkGestureRotate"}

widget[GtkGestureZoom] = {"gtk_gesture_zoom",
{GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
    {"get_scale_delta",{P},D},
"GtkGestureZoom"}

widget[GtkGestureDrag] = {"gtk_gesture_drag", -- 3.14
{GtkGestureSingle,GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
    {"get_start_point",{P,D,D},B},
    {"get_offset",{P,D,D},B}, 
"GtkGestureDrag"}

widget[GtkGesturePan] = {"gtk_gesture_pan",
{GtkGestureDrag,GtkGestureSingle,GtkGesture,GtkEventController,GObject},
    {"new",{P,I},P},
    {"get_orientation",{P},I},
    {"set_orientation",{P,I}},
"GtkGesturePan"}

widget[GtkGestureSwipe] = {"gtk_gesture_swipe",
{GtkGestureSingle,GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
    {"get_velocity",{P,D,D},B},
"GtkGestureSwipe"}

widget[GtkGestureLongPress] = {"gtk_gesture_long_press",
{GtkGestureSingle,GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
"GtkGestureLongPress"}

widget[GtkGestureMultiPress] = {"gtk_gesture_multi_press",
{GtkGestureSingle,GtkGesture,GtkEventController,GObject},
    {"new",{P},P},
    {"get_area",{P,P},B},
    {"set_area",{P,P}},
"GtkGestureMultiPress"}

widget[GtkGLArea] = {"gtk_gl_area", -- GTK 3.16
{GtkWidget,GObject},
    {"new",{},P},
    {"get_context",{P},P},
    {"set_has_alpha",{P,B}},
    {"get_has_alpha",{P},B},
    {"set_has_depth_buffer",{P,B}},
    {"gete_has_depth_buffer",{P},B},
    {"make_current",{P}},
"GtkGLArea"}

widget[GdkFrameClock] = {"gdk_frame_clock",
{GObject},
    {"get_frame_time",{P},I},
    {"request_phase",{P,P}},
    {"begin_updating",{P}},
    {"end_updating",{P}},
    {"get_frame_counter",{P},I},
    {"get_history_start",{P},I},
    {"get_timings",{P,I},P},
    {"get_current_timings",{P},P,0,GdkFrameTimings},
    {"get_refresh_info",{P,I,I,I}},
"GdkFrameClock"}

widget[GdkFrameTimings] = {"gdk_frame_timings",
{GObject},
    {"get_frame_counter",{P},I},
    {"get_complete",{P},B},
    {"get_frame_time",{P},I},
    {"get_presentation_time",{P},I},
    {"get_refresh_interval",{P},I},
    {"get_predicted_presentation_time",{P},I},
"GdkFrameTimings"}

widget[GdkEvent] = {"gdk_event",
{GObject},
    {"new",{},P},
    {"peek",{},P,0,GdkEvent},
    {"get",{},P,0,GdkEvent},
    {"put",{P}},
    {"copy",{P},P,0,GdkEvent},
    {"get_axis",{P,I,D},B},
    {"get_button",{P,P},B},
    {"get_keycode",{P,P},B},
    {"get_keyval",{P,P},B},
    {"get_root_coords",{P,D,D},B},
    {"get_scroll_direction",{P,P},B},
    {"get_scroll_deltas",{P,D,D},B},
    {"get_state",{P,P},B},
    {"get_time",{P},I},
    {"get_window",{P},P,0,GdkWindow},
    {"get_event_type",{P},I},
    {"get_event_sequence",{P},P,0,GdkEventSequence},
    {"request_motions",{P}},
    {"get_click_count",{P,P},B},
    {"get_coords",{P,D,D},B},
    {"triggers_context_menu",{P},B},
    {"handler_set",{P,P,P}},
    {"set_screen",{P,P}},
    {"get_screen",{P},P,0,GdkScreen},
    {"set_device",{P,P}},
    {"get_device",{P},P,0,GdkDevice},
    {"set_source_device",{P,P}},
    {"get_source_device",{P},P,0,GdkDevice},
"GdkEvent"}

widget[GdkEventSequence] = {"gdk_event_sequence",
{GdkEvent},
"GdkEventSequence"}

widget[GdkX11Display] = {"gdk_x11_display",
{GObject},
    {"get_user_time",{P},I},
    {"broadcase_startup_message",{P,S,S,I}},
    {"get_startup_notification_id",{P},S},
    {"set_startup_notification_id",{P,S}},
    {"get_xdisplay",{P},P},
    {"grab",{P}},
    {"ungrab",{P}},
    {"set_cursor_theme",{P,S,I}},
    {"set_window_scale",{P,I}},
    {"get_glx_version",{P,I,I},B},
"GdkX11Display"}

widget[GdkX11Screen] = {"gdk_x11_screen",
{GObject},
    {"get_screen_number",{P},I},
    {"get_xscreen",{P},P},
    {"get_window_manager_name",{P},S},
    {"get_monitor_output",{P,I},I},
    {"lookup_visual",{P,I},P,0,GdkVisual},
    {"get_number_of_desktops",{P},I},
    {"get_current_desktop",{P},I},
"GdkX11Screen"}

widget[GdkX11Window] = {"gdk_x11_window",
{GObject},
    {"lookup_for_display",{P,P},P,0,GdkWindow},
    {"get_xid",{P},P},
    {"move_to_current_desktop",{P}},
    {"move_to_desktop",{P,I}},
    {"get_desktop",{P},I},
"GdkX11Window"}

widget[GdkGLContext] = {"gdk_gl_context",
{GObject},
    {"new",{},-routine_id("glContext")},
    {"get_current",{},-routine_id("glContext")},
    {"clear_current",{}},
    {"make_current",{P}},
    {"get_window",{P},P,0,GdkWindow},
    {"get_visual",{P},P,0,GdkVisual},
"GdkGLContext"}

    function glContext()
    return c_func("gdk_gl_context_get_current")
    end function

--WIP: these are not yet implemented;
widget[CairoFontOptions] = {0,{0},"CairoFontOptions"}
widget[CairoContent_t] = {0,{0},"CairoContent_t"}
widget[CairoStatus_t] = {0,{0},"CairoStatus_t"}
widget[CairoSurfaceType_t] = {0,{0},"CairoSurfaceType_t"}
widget[GtkPrintOperationPreview] = {0,{0},"GtkPrintOperationPreview"}
widget[GtkPageRange] = {0,{0},"GtkPageRange"}
widget[GdkPixbufAnimation] = {0,{0},"GdkPixbufAnimation"}
widget[GdkPixbufAnimationIter] = {0,{0},"GdkPixbufAnimationIter"}

------------------------------------------------------------------------
-- Low-level hardware functions.
------------------------------------------------------------------------
export function event_id(atom event)
return peek4u(event)
end function

export function event_button(atom event) -- get mouse button clicked;
---------------------------------------------------------------------
    ifdef BITS64 then
        return peek(event+52)
    end ifdef
return peek(event+40)
end function

export function mouse_button(atom event) -- alias for above;
return event_button(event)
end function

export function event_type(atom event)
return peek(event)
end function

export function event_window(atom event)
return peek(event+4)
end function

export function event_state(atom event)
    ifdef BITS64 then
        return peek(event+24)
    end ifdef
return peek(event+12)
end function

export function event_hwcode(atom event)
    ifdef BITS64 then
        return peek(event+44)
    end ifdef
return peek(event+32)
end function

export function event_key(atom event) -- get key pressed;
    ifdef BITS64 then
        return peek(event+28)
    end ifdef
return peek(event+20)
end function

export function keypressed(atom event) -- alias for above;
return event_key(event)
end function

export function event_clicks(atom event)
atom ct = allocate(64)
object result
    if gtk_func("gdk_event_get_click_count",{P,I},{event,ct}) then
        result = peek4u(ct)
    else
        result = -1
    end if
    free(ct)
return result
end function

export function event_scroll_dir(atom event)
atom dir = allocate(64)
object result
    if gtk_func("gdk_event_get_scroll_direction",{P,I},{event,dir}) then
        result = peek4u(dir)
    else
        result = -1
    end if
    free(dir)
return result
end function

------------------------------------------------------------------------
-- Internet conveniences
------------------------------------------------------------------------
------------------------------------
export function show_uri(object uri)
------------------------------------
integer x = find('#',uri)
object tmp
if x > 0 then
    tmp = canonical_path(uri[1..x-1])
    if file_exists(tmp) then
        uri = "file:///" & tmp & uri[x..$]
    end if
else
    tmp = canonical_path(uri)
    if file_exists(tmp) then
        uri = "file:///" & tmp
    end if
end if

atom err = allocate(100) err = 0 
object result = gtk_func("gtk_show_uri",{P,P,P,P},
        {0,allocate_string(uri,1),0,err})
    free(err)
    
return result
end function

--------------------------------
export function inet_address()
--------------------------------
object ip
sequence tmp = temp_file(,"MYIP-")
if system_exec(sprintf("ifconfig |  grep 'inet addr:' | grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}' > %s ",{tmp}),0) = 0 then
   ip = read_lines(tmp)
   if length(ip) = 0 then
       return "127.0.0.1"
    else
        return ip[1]
    end if
end if
end function

---------------------------------
export function inet_connected()
---------------------------------
return not equal("127.0.0.1",inet_address())
end function

------------------------------------------------------------------------
-- Icon functions
------------------------------------------------------------------------

----------------------------
export function list_icons()
----------------------------
atom theme = gtk_func("gtk_icon_theme_get_default")
object list = gtk_func("gtk_icon_theme_list_icons",{P,P},{theme,0})
return to_sequence(list)
end function

----------------------------------------
export function has_icon(object name)
----------------------------------------
atom theme = gtk_func("gtk_icon_theme_get_default")
    name = allocate_string(name)
return gtk_func("gtk_icon_theme_has_icon",{P,P},{theme,name})
end function

--------------------------------------------------------
export function icon_info(object name, integer size=6)
--------------------------------------------------------
atom theme = gtk_func("gtk_icon_theme_get_default")
atom err = allocate(32) err = 0

atom icon_info = gtk_func("gtk_icon_theme_lookup_icon",{P,P,I,I},
    {theme,name,size,GTK_ICON_LOOKUP_USE_BUILTIN})

object results = repeat(0,5)
    results[1] = gtk_func("gtk_icon_info_load_icon",{P,P},{icon_info,err})
    results[2] = gtk_func("gtk_icon_info_get_display_name",{P},{icon_info})
    results[3] = gtk_str_func("gtk_icon_info_get_filename",{P},{icon_info})
    results[4] = gtk_func("gtk_icon_info_get_base_size",{P},{icon_info})
    results[5] = gtk_func("gtk_icon_info_get_base_scale",{P},{icon_info})
return results
-- returns {pointer to icon_info structure, display name or null,
--          full path to icon file, base size, base scale}
end function
    
------------------------------------------------------------------------
-- BUILDABLE   (WIP)
------------------------------------------------------------------------
widget[GtkBuildable] = {"gtk_buildable",
{GObject},
    {"set_name",{P,S}},
    {"get_name",{P},S},
    {"add_child",{P,P,P,S}},
    {"set_buildable_property",{P,P,S,P}},
    {"construct_child",{P,P,S},P,0,GObject},
    {"custom_tag_start",{P,P,P,S,P,P},B},
    {"custom_tag_end",{P,P,P,S,P}},
    {"custom_finished",{P,P,P,S,P}},
    {"parser_finished",{P,P}},
    {"get_internal_child",{P,P,S},P,0,GObject},
"GtkBuildable"}

widget[GtkBuilder] = {"gtk_builder",
{GObject},
    {"new",{},P},
    {"add_callback_symbol",{P,S,P}}, -- 3.10
    {"lookup_callback_symbol",{P,S},P}, -- 3.10
    {"add_from_file",{P,S},-routine_id("addBuilderObjects")},
    {"add_from_string",{P,P},-routine_id("addBuilderObjectsStr")},
    {"get_object",{P,S},P},
    {"get_objects",{P},P,0,GSList},
    {"set_application",{P,P}}, -- 3.10
    {"get_application",{P},P}, -- 3.10
    {"connect",{P},-routine_id("BuilderConnect")},
"GtkBuilder"}

    constant bad_from_file = define_c_func(GTK,"gtk_builder_add_from_file",{P,S,P},I)
    constant bad_from_string = define_c_func(GTK,"gtk_builder_add_from_string",{P,P,I,P},I)
   
 -- add objects from Glade XML file;  
    function addBuilderObjects(atom bld, object fname)
    atom err = allocate(64) err = 0
    integer result = c_func(bad_from_file,{bld,fname,err})
    if result = 0 then
        printf(1,"Error loading Builder from file!\n\n")
        printf(1,"Possible GTK version mismatch ")
        printf(1,"or other error in file\n %s\n\n",{peek_string(fname)})
        abort(0)
    end if
    return result 
    end function

 -- add object from inline string;
    function addBuilderObjectsStr(atom bld, object str)
    atom err = allocate(64) err = 0
    integer len = length(str)
    str = allocate_string(str)
    integer result = c_func(bad_from_string,{bld,str,len,err})
    if result = 0 then
        printf(1,"Error loading Builder from string!\n\n")
        printf(1,"Possible GTK version mismatch ")
        printf(1,"or other error in Glade.\n\n")
        abort(0)
    end if
    return result
    end function
    
 -- link signals defined in Glade
    function BuilderConnect(atom bld)
    ---------------------------------
    gtk_func("gtk_builder_connect_signals_full",{P,P,P},{bld,builder_connect_func,0})
    return 1
    end function

    constant builder_connect_func =  call_back(routine_id("BuilderConnectFunc"))

 -- links Glade controls to user-written or Eu functions 
    function BuilderConnectFunc(atom bld, atom obj, object sig, object handlr, object data=0)
    -----------------------------------------------------------------------------------------
    handlr = peek_string(handlr)
    sig = peek_string(sig)

    object name = gtk_str_func("gtk_buildable_get_name",{P},{obj})   
    object path = gtk_func("gtk_widget_get_path",{P},{obj})
    object nick = gtk_str_func("gtk_widget_get_name",{P},{obj})
    integer len = gtk_func("gtk_widget_path_length",{P},{path})
    path = gtk_str_func("gtk_widget_path_to_string",{P},{path})

    atom rid = routine_id(handlr) 
        if rid = -1 then 
            printf(1,"Error: function not found => %s",{handlr})
            if match("Gtk",nick) then nick = nick[4..$] end if 
            show_template(handlr)
            abort(1)
        end if
        rid = call_back(rid) 

    integer flag = 0
    for n = 1 to length(path) do
        if path[n] = '(' then flag = 1
        elsif path[n] = ')' then flag = 0
        end if
        if flag and path[n] = ' ' then path[n] = '_' end if
    end for
    
    path = split(path,' ')
    object class = path[$]
    len = find('.',class)
    if len then
        class = head(class,len-1)
    end if
    len = find('(',class)
    if len then
        class = head(class,len-1)
    end if
    len = find('[',class)
    if len then
        class = head(class,len-1)
    end if
    integer id = find(class,class_name_index)

    ifdef CONNECT then
        display("Class [] [] ID []  Handle [] Nick [] Data []\n",
            {id,class,name,obj,nick,data})
    end ifdef
    
    register(obj,id,name,nick)
    connect(obj,sig,rid,data)

    return 1
    end function

------------------------------------------------------------------------------------------
procedure show_template(object handlr)
------------------------------------------------------------------------------------------
puts(1,"\nYou may copy and paste the following code:\n\n")
printf(1,`

-----------------------------------------------------------------------
global function %s() 
-----------------------------------------------------------------------
  
return 1
end function


`,{handlr})

end procedure

ifdef GLADE then

    global constant builder = create(GtkBuilder)
    
end ifdef
  
sequence class_name_index = repeat(0,GtkFinal)
    for i = 1 to GtkFinal-1 do
        class_name_index[i] = widget[i][$]
    end for

function _(atom x, integer t)
init(t) register(x,t)
return 1
end function

export type Object(atom x)return _(x,GObject)end type
export type Window(atom x)return _(x,GtkWindow)end type
export type Dialog(atom x)return _(x,GtkDialog)end type
export type AboutDialog(atom x)return _(x,GtkAboutDialog)end type
export type Assistant(atom x)return _(x,GtkAssistant)end type
export type Box(atom x)return _(x,GtkBox)end type
export type Grid(atom x)return _(x,GtkGrid)end type
export type Revealer(atom x)return _(x,GtkRevealer)end type
export type ListBox(atom x)return _(x,GtkListBox)end type
export type FlowBox(atom x)return _(x,GtkFlowBox)end type
export type Stack(atom x)return _(x,GtkStack)end type
export type StackSwitcher(atom x)return _(x,GtkStackSwitcher)end type
export type Sidebar(atom x)return _(x,GtkSidebar)end type
export type ActionBar(atom x)return _(x,GtkActionBar)end type
export type HeaderBar(atom x)return _(x,GtkHeaderBar)end type
export type Overlay(atom x)return _(x,GtkOverlay)end type
export type ButtonBox(atom x)return _(x,GtkButtonBox)end type
export type Paned(atom x)return _(x,GtkPaned)end type
export type Layout(atom x)return _(x,GtkLayout)end type
export type Notebook(atom x)return _(x,GtkNotebook)end type
export type Expander(atom x)return _(x,GtkExpander)end type
export type AspectFrame(atom x)return _(x,GtkAspectFrame)end type
export type Label(atom x)return _(x,GtkLabel)end type
export type Image(atom x)return _(x,GtkImage)end type
export type Spinner(atom x)return _(x,GtkSpinner)end type
export type InfoBar(atom x)return _(x,GtkInfoBar)end type
export type ProgressBar(atom x)return _(x,GtkProgressBar)end type
export type LevelBar(atom x)return _(x,GtkLevelBar)end type
export type Statusbar(atom x)return _(x,GtkStatusbar)end type
export type AccelLabel(atom x)return _(x,GtkAccelLabel)end type
export type Button(atom x)return _(x,GtkButton)end type
export type CheckButton(atom x)return _(x,GtkCheckButton)end type
export type RadioButton(atom x)return _(x,GtkRadioButton)end type
export type ToggleButton(atom x)return _(x,GtkToggleButton)end type
export type LinkButton(atom x)return _(x,GtkLinkButton)end type
export type MenuButton(atom x)return _(x,GtkMenuButton)end type
export type Switch(atom x)return _(x,GtkSwitch)end type
export type ScaleButton(atom x)return _(x,GtkScaleButton)end type
export type VolumeButton(atom x)return _(x,GtkVolumeButton)end type
export type LockButton(atom x)return _(x,GtkLockButton)end type
export type Entry(atom x)return _(x,GtkEntry)end type
export type EntryBuffer(atom x)return _(x,GtkEntryBuffer)end type
export type EntryCompletion(atom x)return _(x,GtkEntryCompletion)end type
export type Scale(atom x)return _(x,GtkScale)end type
export type SpinButton(atom x)return _(x,GtkSpinButton)end type
export type SearchEntry(atom x)return _(x,GtkSearchEntry)end type
export type SearchBar(atom x)return _(x,GtkSearchBar)end type
export type Editable(atom x)return _(x,GtkEditable)end type
export type TextMark(atom x)return _(x,GtkTextMark)end type
export type TextBuffer(atom x)return _(x,GtkTextBuffer)end type
export type TextTag(atom x)return _(x,GtkTextTag)end type
export type TextTagTable(atom x)return _(x,GtkTextTagTable)end type
export type TextView(atom x)return _(x,GtkTextView)end type
export type TreeModel(atom x)return _(x,GtkTreeModel)end type
export type TreeSelection(atom x)return _(x,GtkTreeSelection)end type
export type TreeViewColumn(atom x)return _(x,GtkTreeViewColumn)end type
export type TreeView(atom x)return _(x,GtkTreeView)end type
export type IconView(atom x)return _(x,GtkIconView)end type
export type CellRendererText(atom x)return _(x,GtkCellRendererText)end type
export type CellRendererAccel(atom x)return _(x,GtkCellRendererAccel)end type
export type CellRendererCombo(atom x)return _(x,GtkCellRendererCombo)end type
export type CellRendererPixbuf(atom x)return _(x,GtkCellRendererPixbuf)end type
export type CellRendererProgress(atom x)return _(x,GtkCellRendererProgress)end type
export type CellRendererSpin(atom x)return _(x,GtkCellRendererSpin)end type
export type CellRendererToggle(atom x)return _(x,GtkCellRendererToggle)end type
export type CellRendererSpinner(atom x)return _(x,GtkCellRendererSpinner)end type
export type ListStore(atom x)return _(x,GtkListStore)end type
export type TreeStore(atom x)return _(x,GtkTreeStore)end type
export type ComboBox(atom x)return _(x,GtkComboBox)end type
export type ComboBoxText(atom x)return _(x,GtkComboBoxText)end type
export type Menu(atom x)return _(x,GtkMenu)end type
export type MenuBar(atom x)return _(x,GtkMenuBar)end type
export type MenuItem(atom x)return _(x,GtkMenuItem)end type
export type RadioMenuItem(atom x)return _(x,GtkRadioMenuItem)end type
export type CheckMenuItem(atom x)return _(x,GtkCheckMenuItem)end type
export type SeparatorMenuItem(atom x)return _(x,GtkSeparatorMenuItem)end type
export type Toolbar(atom x)return _(x,GtkToolbar)end type
export type ToolItem(atom x)return _(x,GtkToolItem)end type
export type ToolPalette(atom x)return _(x,GtkToolPalette)end type
export type ToolButton(atom x)return _(x,GtkToolButton)end type
export type MenuToolButton(atom x)return _(x,GtkMenuToolButton)end type
export type ToggleToolButton(atom x)return _(x,GtkToggleToolButton)end type
export type RadioToolButton(atom x)return _(x,GtkRadioToolButton)end type
export type Popover(atom x)return _(x,GtkPopover)end type
export type PopoverMenu(atom x)return _(x,GtkPopoverMenu)end type
export type ColorChooser(atom x)return _(x,GtkColorChooser)end type
export type ColorButton(atom x)return _(x,GtkColorButton)end type
export type ColorChooserWidget(atom x)return _(x,GtkColorChooserWidget)end type
export type ColorChooserDialog(atom x)return _(x,GtkColorChooserDialog)end type
export type FileChooser(atom x)return _(x,GtkFileChooser)end type
export type FileChooserButton(atom x)return _(x,GtkFileChooserButton)end type
export type FileChooserDialog(atom x)return _(x,GtkFileChooserDialog)end type
export type FileChooserWidget(atom x)return _(x,GtkFileChooserWidget)end type
export type FileFilter(atom x)return _(x,GtkFileFilter)end type
export type FontChooser(atom x)return _(x,GtkFontChooser)end type
export type FontButton(atom x)return _(x,GtkFontButton)end type
export type FontChooserWidget(atom x)return _(x,GtkFontChooserWidget)end type
export type FontChooserDialog(atom x)return _(x,GtkFontChooserDialog)end type
export type PlacesSidebar(atom x)return _(x,GtkPlacesSidebar)end type
export type Frame(atom x)return _(x,GtkFrame)end type
export type Scrollbar(atom x)return _(x,GtkScrollbar)end type
export type ScrolledWindow(atom x)return _(x,GtkScrolledWindow)end type
export type Adjustment(atom x)return _(x,GtkAdjustment)end type
export type Calendar(atom x)return _(x,GtkCalendar)end type
export type GLArea(atom x)return _(x,GtkGLArea)end type
export type Tooltip(atom x)return _(x,GtkTooltip)end type
export type Viewport(atom x)return _(x,GtkViewport)end type
export type Widget(atom x)return _(x,GtkWidget)end type
export type Container(atom x)return _(x,GtkContainer)end type
export type Bin(atom x)return _(x,GtkBin)end type
export type Range(atom x)return _(x,GtkRange)end type
export type PrintContext(atom x)return _(x,GtkPrintContext)end type
export type ListBoxRow(atom x)return _(x,GtkListBoxRow)end type
export type FontFamily(atom x)return _(x,PangoFontFamily)end type
export type FontDescription(atom x)return _(x,PangoFontDescription)end type
export type AppChooserDialog(atom x)return _(x,GtkAppChooserDialog)end type
export type PaperSize(atom x)return _(x,GtkPaperSize)end type

----------------------
-- © 2015 by Irv Mullins
-------------------------
