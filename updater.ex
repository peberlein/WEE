-- WEE source code updater

include std/console.e
--include std/net/http.e  -- doesn't support https
include std/io.e
include std/get.e
include std/filesys.e
include std/hash.e
include std/dll.e
include std/machine.e

ifdef WINDOWS then

--
-- Implement http_get via WinINet for Windows
--

constant
    wininet = open_dll("wininet.dll")
if wininet = 0 then
    puts(1, "Failed to open wininet.dll\n")
    abort(1)
end if

constant
    InternetOpen = define_c_func(wininet, "InternetOpenA", {C_POINTER, C_DWORD, C_POINTER, C_POINTER, C_DWORD}, C_HANDLE),
    InternetCloseHandle = define_c_func(wininet, "InternetCloseHandle", {C_HANDLE}, C_BOOL),
    InternetOpenUrl = define_c_func(wininet, "InternetOpenUrlA", {C_HANDLE, C_POINTER, C_POINTER, C_DWORD, C_DWORD, C_POINTER}, C_HANDLE),
    InternetReadFile = define_c_func(wininet, "InternetReadFile", {C_HANDLE, C_POINTER, C_DWORD, C_POINTER}, C_BOOL)
if InternetOpen = -1 or
   InternetCloseHandle = -1 or
   InternetOpenUrl = -1 or
   InternetReadFile = -1 then
    puts(1, "Failed to find functions in wininet\n")
    abort(1)
end if

constant
    INTERNET_OPEN_TYPE_PRECONFIG = 0

function http_get(sequence url)
    atom agent_ptr = allocate_string("Mozilla/4.0 (compatible)")
    atom url_ptr = allocate_string(url)
    atom ih, ch -- internet handle, connection handle
    integer bufsize = 4096
    atom buf_ptr = allocate(bufsize)
    atom bytesread_ptr = allocate(4) -- LPDWORD
    object res = -1

    ih = c_func(InternetOpen, {agent_ptr, INTERNET_OPEN_TYPE_PRECONFIG, NULL, NULL, 0})
    if ih then
        ch = c_func(InternetOpenUrl, {ih, url_ptr, NULL, 0, 0, NULL})
        if ch then
            res = ""
            while c_func(InternetReadFile, {ch, buf_ptr, bufsize, bytesread_ptr}) != 1 or
                  peek4u(bytesread_ptr) != 0 do
                res &= peek({buf_ptr, peek4u(bytesread_ptr)})
            end while
            res = {{{"Status","200"}}, res}

            c_func(InternetCloseHandle, {ih})
        end if
        c_func(InternetCloseHandle, {ih})
    end if

    free(agent_ptr)
    free(url_ptr)
    free(buf_ptr)
    free(bytesread_ptr)

    return res
end function

elsedef

--
-- Implement http_get via libcurl for UNIX
--

constant
    libcurl = open_dll("libcurl.so.3")
if libcurl = 0 then
    puts(1, "Failed to open libcurl.so.3\n")
    abort(1)
end if

constant
    curl_easy_init = define_c_func(libcurl, "curl_easy_init", {}, C_POINTER),
    curl_easy_setopt = define_c_proc(libcurl, "curl_easy_setopt", {C_POINTER, C_LONG, C_POINTER}),
    curl_easy_perform = define_c_func(libcurl, "curl_easy_perform", {C_POINTER}, C_LONG),
    curl_easy_cleanup = define_c_proc(libcurl, "curl_easy_cleanup", {C_POINTER})
if curl_easy_init = -1 or
   curl_easy_setopt = -1 or
   curl_easy_perform = -1 or
   curl_easy_cleanup = -1 then
    puts(1, "Failed to find functions in libcurl\n")
    abort(1)
end if

sequence cb_data

function curl_callback(atom ptr, atom size, atom nmemb, atom writedata)
    cb_data &= peek({ptr, size * nmemb})
    return nmemb
end function

constant curl_cb = call_back(routine_id("curl_callback"))

atom curl = c_func(curl_easy_init, {})
if not curl then
    puts(1, "Failed to init libcurl\n")
    abort(1)
end if

constant
    CURLOPT_URL = 10002,
    CURLOPT_WRITEFUNCTION = 20011,
    CURLOPT_WRITEDATA = 10001,
    CURLOPT_FOLLOWLOCATION = 52

c_proc(curl_easy_setopt, {curl, CURLOPT_WRITEFUNCTION, curl_cb})
c_proc(curl_easy_setopt, {curl, CURLOPT_WRITEDATA, 0})
c_proc(curl_easy_setopt, {curl, CURLOPT_FOLLOWLOCATION, 1})

function http_get(sequence url)
    atom url_ptr = allocate_string(url)
    atom res

    if not url_ptr then
        return -1
    end if

    cb_data = ""
    c_proc(curl_easy_setopt, {curl, CURLOPT_URL, url_ptr})
    res = c_func(curl_easy_perform, {curl})
    free(url_ptr)
    if res = 0 then
        return {{{"Status","200"}}, cb_data}
    end if
    return -1
end function

end ifdef






puts(1, "=== WEE Source Code Updater ===\n"&
    "This will overwrite any local changes to the source files.\n"&
    "Press a key to continue, or 'q' to quit.\n")
if wait_key() = 'q' then
    abort(0)
end if

constant
  repo = "peberlein/WEE/",
  base_url = "https://cdn.rawgit.com/" & repo -- & "commit/filename"

-- this needs to be .json since rawgit.com has a whitelist of extensions
-- otherwise it will just redirect to https://raw.githubusercontent.com
-- and http_get doesn't support https: protocol
constant
  manifest = http_get("https://rawgit.com/"& repo &"master/manifest.json")

procedure fail(sequence fmt, object args={})
    printf(1, fmt, args)
    puts(1, "\nPress any key to exit, then try updating again.\n")
    wait_key()
    abort(1)
end procedure

if atom(manifest) or not equal(manifest[1][1][2], "200") then
  display(manifest)
  fail("Failed to download manifest.json\n")
end if

-- manifest format
-- {
--  {"pathname", hash, "commit-tag", platform-bits, platforms...}
-- }

sequence files, name, commit_tag
files = value(manifest[2])
--display(files)
if files[1] != 0 then
  fail("Failed to parse manifest\n")
end if
files = files[2]

ifdef BITS64 then
constant PLATFORM_BITS = 64
elsedef
constant PLATFORM_BITS = 32
end ifdef

integer platform_bits
sequence platforms, subdir

object result, hashcode

for i = 1 to length(files) do
  if length(files[i]) < 4 then
      fail("Manifest file has invalid format.\n")
  end if

  name = files[i][1]
  hashcode = files[i][2]
  commit_tag = files[i][3]
  platform_bits = files[i][4]
  platforms = files[i][5..$]

  if length(platforms) and not find(platform(), platforms) then
    -- file not used on this platform

  elsif platform_bits != 0 and platform_bits != PLATFORM_BITS then
    -- file not compatible with 32/64-bit platform
  
  elsif equal(hashcode, hash(read_file(name), HSIEH30)) then
    -- file hash is ok
    printf(1, "%s is up-to-date.\n", {name})

  else
    printf(1, "Updating %s...\n", {name})
    result = http_get(base_url & commit_tag & "/" & name)
    if atom(result) or not equal(result[1][1][2], "200") then
      display(result)
      fail("Failed to download %s\n", {name})
    elsif not equal(hashcode, hash(result[2], HSIEH30)) then
      fail("Failed to validate %s\n", {name})
    else
      subdir = dirname(name)
      if length(subdir) and atom(dir(subdir)) then
          printf(1, "Creating directory %s\n", {subdir})
          create_directory(subdir)
      end if
      if write_file(name, result[2]) = -1 then
        printf(1, "Failed to write_file %s\n", {name})
      end if
    end if
  end if
end for

puts(1, "Done.  Press any key to exit.\n")
wait_key()


ifdef UNIX then
    c_proc(curl_easy_cleanup, {curl})
end ifdef
