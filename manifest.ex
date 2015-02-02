include std/pretty.e
include std/io.e
include std/hash.e
include std/os.e
include std/pipeio.e


sequence files
files = {
-- platform independent
 {"wee.exw", 0, 0, 0},
 {"scintilla.e", 0, 0, 0},
 {"parser.e", 0, 0, 0},
 {"updater.ex", 0, 0, 0},
-- windows
 {"ui_win.e", 0, 0, 0, WINDOWS},
 {"window.ew", 0, 0, 0, WINDOWS},
-- GTK
 {"ui_gtk.e", 0, 0, 0, LINUX, OSX},
 {"EuGTK/GtkEngine.e", 0, 0, 0, LINUX, OSX},
 {"EuGTK/GtkEnums.e", 0, 0, 0, LINUX, OSX},
 {"EuGTK/GtkPrinter.e", 0, 0, 0, LINUX, OSX},
 {"EuGTK/README.txt", 0, 0, 0, LINUX, OSX},
 {"EuGTK/license.txt", 0, 0, 0, LINUX, OSX},
-- scintilla
 {"scintilla/SciLexer.dll", 0, 0, 0, WINDOWS},
 {"scintilla/scintilla32.so", 0, 0, 32, LINUX},
 {"scintilla/scintilla64.so", 0, 0, 64, LINUX},
 {"scintilla/scintillaOSX.dylib", 0, 0, 64, OSX},
 {"scintilla/License.txt", 0, 0, 0}
}

object file, p

for i = 1 to length(files) do
  files[i][2] = hash(read_file(files[i][1]), HSIEH30)
  -- git log -n 1 --format=oneline -- ui_gtk.e
  p = pipeio:exec("git log -n1 --format=oneline -- "&files[i][1], pipeio:create())
  files[i][3] = pipeio:read(p[pipeio:STDOUT], 10)
  pipeio:kill(p)
end for

--display(files)
? write_file("manifest.json", pretty_sprint(files, {2}))
