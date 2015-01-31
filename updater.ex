-- WEE source code updater

include std/console.e
include std/net/http.e
include std/io.e
include std/get.e
include std/filesys.e
include std/hash.e

constant
  base_url = "http://cdn.rawgit.com/peberlein/WEE/" -- & "commit/filename"

-- this needs to be .json since rawgit.com has a whitelist of extensions
-- otherwise it will just redirect to https://raw.githubusercontent.com
constant
  manifest = http_get("http://rawgit.com/peberlein/WEE/master/manifest.json")

if atom(manifest) or not equal(manifest[1][1][2], "200") then
  display(manifest)
  puts(1, "Failed to download manifest.json\n")
  abort(1)
end if

-- manifest format
-- {
--  {"pathname", hash, "commit-tag", platform-bits, platforms...}
-- }

sequence files, name, commit_tag
files = value(manifest[2])
--display(files)
if files[1] != 0 then
  puts(1, "Failed to parse manifest\n")
  abort(1)
end if
files = files[2]

ifdef BITS64 then
constant PLATFORM_BITS = 64
elsedef
constant PLATFORM_BITS = 32
end ifdef

integer platform_bits
sequence platforms

object result, hashcode

for i = 1 to length(files) do
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
      printf(1, "Failed to download %s\n", {name})
    else
      if atom(dir(dirname(name))) then
          printf(1, "Creating directory %s\n", {dirname(name)})
          create_directory(dirname(name))
      end if
      if write_file(name, result[2]) = -1 then
        printf(1, "Failed to write_file %s\n", {name})
      end if
    end if
  end if
end for
