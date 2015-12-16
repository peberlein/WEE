-- parser.e
-- 
-- Copyright (c) 2015 Pete Eberlein
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
-- THE SOFTWARE.

-- todo:
--  OE4 while "with entry" and "label"
--  OE4 loop until
--  OE4 labels and goto
--  OE4 switch statement
--  use eu.cfg for finding includes
--  get_declarations with namespace shouldn't include local symbols

-- file.e doesn't work right on OSX
--include file,e -- for walk_dir and dir
include std/filesys.e
include std/os.e
include std/text.e
include std/map.e
include std/dll.e
include std/machine.e
include std/pretty.e

constant 
    OE4 = 1, -- enable OpenEuphoria 4 syntax
    ERROR_ABORT = 0, -- enable abort on errors?
    ERROR_PRINT = 0  -- enable printing errors?
sequence defined_words
defined_words = {"OE", "OE4"}
if platform() = WIN32 then
  defined_words &= {"WINDOWS", "WIN32"}
elsif platform() = LINUX then
  defined_words &= {"LINUX", "UNIX"}
elsif platform() = OSX then
  defined_words &= {"OSX", "UNIX"}
end if

-- ast node types that are also opcodes
global constant
  END = 0,
  LOAD = 1,
  LOADHI = 2,
  MOV = 3,
  ADD = 4,
  ADDU8 = 5,
  MUL = 6,
  DIV = 7,
  REM = 8,
  JL = 9,
  JLE = 10,
  JE = 11,
  JNE = 12,
  JMP = 13,
  EQ = 14,
  NEQ = 15,
  LT = 16,
  GTE = 17,
  LTE = 18,
  GT = 19,
  QPRINT = 20,
  SUB = 21,
  SUBU8 = 22,
  NOT = 23,
  NEG = 24,
  AND = 25,
  OR = 26,
  XOR = 27

global constant
    DECL_ATOM = 1,
    DECL_CONSTANT = 2,
    DECL_ENUM = 3,
    DECL_FUNCTION = 4,
    DECL_INTEGER = 5,
    DECL_OBJECT = 6,
    DECL_PROCEDURE = 7,
    DECL_SEQUENCE = 8,
    DECL_TYPE = 9

-- ast node types that are not opcodes
global constant
  VAR_DECL = 256, -- {VAR_DECL, "type", pos, {"name", pos, scope-start, [expr]}...}
  ASSIGN = 257,   -- {ASSIGN, "name", pos, expr}
  FUNC = 258,     -- {FUNC, "name", pos, [args...]}
  PROC = 259,     -- {PROC, "name", pos, [args...]}
  VARIABLE = 260, -- {VARIABLE, "name", pos}
  SUBSCRIPT = 261, -- {SUBSCRIPT, expr, index-expr}
  SLICE = 262,     -- {SLICE, expr, start-expr, end-expr}
  CONST_DECL = 263, -- {CONST_DECL, {"name", pos, scope-start, expr}... }
  CAT = 264,    -- {CAT, expr, expr}
  RETURN = 265, -- {RETURN, [expr]}
  EXIT = 266,   -- {EXIT}
  SEQ = 267,    -- {SEQ, [expr,]...}
  NUMBER = 268,
  WHILE = 269,  -- {WHILE, expr, scope-start, scope-end, stmts...}
  IF = 270,     -- {IF, expr, {scope-start, scope-end, stmts...}, 
                --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
                --     [{scope-start, scope-end, else-stmts...}]}
  ELSE = 271,
  FOR = 272,    -- {FOR, name, pos, expr, expr, by, scope-start, scope-end, stmts...}
  FUNC_DECL = 273, -- {FUNC_DECL, "name", pos,
                   --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
                   --    scope-start, scope-end, stmts...}
  PROC_DECL = 274, -- {PROC_DECL, ...}
  TYPE_DECL = 275, -- {TYPE_DECL, ...}
  SEQ_ASSIGN = 276, -- {SEQ_ASSIGN, ["name1", pos1,]... expr}
  ADDTO = 277,     -- {ADDTO, "name", pos, expr}
  SUBTO = 278,
  MULTO = 279,
  DIVTO = 280,
  CATTO = 281,
  STRING = 282, -- {STRING, "string-literal"}
  SUB_ASSIGN = 283, -- {SUB_ASSIGN, "name", pos, index-expr..., expr}
  SUB_ADDTO = 284,
  SUB_SUBTO = 285,
  SUB_MULTO = 286,
  SUB_DIVTO = 287,
  SUB_CATTO = 288,
  SLICE_ASSIGN = 289, -- {SLICE_ASSIGN, "name", pos, index-expr..., start-expr, end-expr, expr}
  SLICE_ADDTO = 290,
  SLICE_SUBTO = 291,
  SLICE_MULTO = 292,
  SLICE_DIVTO = 293,
  SLICE_CATTO = 294,
  SEQ_LEN = 295, -- {SEQ_LEN}, shorthand for length of enclosing sequence in SUBSCRIPT, SLICE, SUB_*, SLICE_*
  ENUM_DECL = 296, -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
                  --             {"name", pos, scope-start, [expr]}...}
  INCLUDE = 297, -- {INCLUDE, includes-idx, scope-start, ["namespace"]}
  GLOBAL = 298,    -- {GLOBAL, decl...}
  PUBLIC = 299,    -- {PUBLIC, decl...}
  EXPORT = 300,    -- {EXPORT, decl...}
  NAMESPACE = 301, -- {NAMESPACE, "name"}
  IFDEF = 302,     -- same layout as IF
  ELSEDEF = 303,
  SWITCH = 304,  -- {SWITCH, expr, bool-fallthru, label-string,
                 --   [{case-values...}, {scope-start, scope-end, stmts...},]... }
                 --  ("case else" will have case-values={} )
  BREAK = 305,    -- {BREAK, [label-string]}
  CONTINUE = 306, -- {CONTINUE, [label-string]}
  DEFAULT = 307,  -- {DEFAULT}, used for default arguments in subroutine calls
  ENTRY = 308,    -- {ENTRY}, used with while loops
  RETRY = 309,    -- {RETRY}, used with while loops
  LABEL = 310,    -- {LABEL, "label"}
  GOTO = 311,     -- {GOTO, "label"}
  SYNTAX_ERROR = 312 -- {SYNTAX_ERROR, pos, len, "message"}

global constant ast_names = { "var_decl", "assign", "func", "proc", "variable",
  "subscript", "slice", "const_decl", "not", "mul", "div", "add", "sub",
  "cat", "lt", "gt", "lte", "gte", "eq", "neq", "and", "or", "xor",
  "seq", "integer", "while", "if", "for", "proc", "func_decl",
  "proc_decl", "elsif", "else", "qprint", "addto", "subto", 
  "multo", "divto", "catto", "string" }

sequence cache -- { {"path", timestamp, stmts...} ...}
cache = {}

sequence maps -- map "decl-name" -> { locator... }
maps = {}
-- functions, procedures, types, enum types:
--   locator = ast-index
-- variables, constants, enum values:
--   locator = { ast-index, pos, scope-start, [scope-end] }

sequence keywords
keywords = {"global", "function", "procedure", "type", "end", "if", "then",
            "else", "elsif", "for", "to", "by", "while", "do", "include", 
            "with", "without"}
if OE4 then
  keywords &= {"enum", "label", "break", "case", "fallthru", "routine", "entry", "retry"}
  -- "namespace" is not a reserved word, since it can be used as an identifier
end if

-- returns text from file, else -1
function read_file(sequence filename)
  integer f
  object line
  sequence text

  f = open(filename, "rb")
  if f = -1 then
    puts(2, "Warning: unable to read file: "&filename&"\n")
    return -1
  end if
  line = gets(f)
  text = {}
  while sequence(line) do
    text &= line
    line = gets(f)
  end while
  close(f)
  return text
end function

sequence text, source_filename, tok, errors
text = ""
source_filename = "<none>"
tok = ""
errors = {} -- { {SYNTAX_ERROR, pos, len, msg}... }

integer idx, tok_idx, ifdef_ok, ast_idx
idx = 1
tok_idx = 1
ifdef_ok = 1
ast_idx = 1 -- current top-level ast index used for declaring stuff

map:map cur_map -- the current maps[] during parsing


-- declare name, with name = "name" or {"name", pos, scope-start, [scope-end]}
procedure declare(sequence name)
  object loc = ast_idx
  
  if length(name) = 0 or length(name[1]) = 0 then
    return
  end if

  if sequence(name[1]) then
    loc = name
--    if length(value) < 3 or
--       not sequence(value[1]) or
--       not atom(value[2]) or
--       not atom(value[3]) or
--       (length(value) >= 4 and (not atom(value[4]) or value[4] <= value[3])) then
--      puts(1, "invalid declaration\n")
--      pretty_print(1, value)
--      return
--    end if
    name = name[1]
    loc[1] = ast_idx
  end if
  
  map:put(cur_map, name, append(map:get(cur_map, name, {}), loc))
end procedure

function prefixed(sequence s)
  return s[1] = GLOBAL or s[1] = PUBLIC or s[1] = EXPORT
end function

-- update the declarations in this ast to the end of scope
procedure declare_ast(sequence ast, integer start_idx, integer scope_end, integer top = 0)

  for j = start_idx to length(ast) do
    sequence s = ast[j]
    integer n = prefixed(s)
    integer decl = s[n+1]
    
    if top then
      ast_idx = j
    end if

    if decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      declare(s[n+2])
      sequence args = s[n+4]
      integer sub_scope_end = s[n+6]
      for i = 1 to length(args) do
        declare(args[i][2..4] & sub_scope_end)
      end for
      declare_ast(s, n+7, sub_scope_end)

    elsif decl = VAR_DECL then
      -- {VAR_DECL, "type", pos, {"name", pos, scope-start, [expr]}...}
      for i = n+4 to length(s) do
        declare(s[i][1..3] & scope_end)
      end for
      
    elsif decl = CONST_DECL then
      -- {CONST_DECL, {"name", pos, scope-start, expr}... }
      for i = n+2 to length(s) do
        declare(s[i][1..3] & scope_end)
      end for
      
    elsif decl = WHILE then
      -- {WHILE, expr, scope-start, scope-end, stmts...}
      declare_ast(s, n+5, s[n+4])
      
    elsif decl = IF then
      -- {IF, expr, {scope-start, scope-end, stmts...}, 
      --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
      --     [{scope-start, scope-end, else-stmts...}]}
      for i = n+2 to length(s) by 2 do
        if i = length(s) then
          declare_ast(s[i], 3, s[i][2])
        else
          declare_ast(s[i+1], 3, s[i+1][2])
        end if
      end for

    elsif decl = FOR then
      -- {FOR, "name", pos, expr, expr, by, scope-start, scope-end, stmts...}
      declare(s[n+2..n+3] & s[n+7..n+8])
      declare_ast(s, n+9, s[n+8])

    elsif decl = ENUM_DECL then
      -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
      --             {"name", pos, scope-start, [expr]}...}
      if length(s[n+2]) then
        declare(s[n+2])
      end if
      for i = n+6 to length(s) do
        declare(s[i][1..3] & scope_end)
      end for

    elsif decl = SWITCH then
      -- {SWITCH, expr, bool-fallthru, label-string,
      --   [{case-values...}, {scope-start, scope-end, stmts...},]... }
      --  ("case else" will have case-values={} )
      for i = n+6 to length(s) by 2 do
        declare_ast(s[i], 3, s[i][2])
      end for

    end if
  end for
end procedure


-- prints an error message indicated at tok_idx
procedure error(sequence msg)
  integer line, start

  if length(tok) then
    errors = append(errors, {SYNTAX_ERROR, tok_idx, length(tok), msg})
  end if
  
  if not ERROR_PRINT then return end if

  line = 1
  start = 1
  
  for i = 1 to tok_idx do
    if text[i] = '\n' then
      line += 1
      start = i+1
    end if
  end for
  for i = tok_idx to length(text) do
    if text[i] = '\n' then
      --? {start, idx, tok_idx}
      printf(2, "%s:%d\n%s\n%s%s\n", {
        source_filename,
        line, 
        msg,
        text[start..i],
        repeat(' ', tok_idx - start) & '^'})
      if ERROR_ABORT then abort(1) end if
      --wait_key()
      return
    end if
  end for
  puts(2, "unexpected end of file\n")
  if ERROR_ABORT then abort(1) end if
end procedure



procedure skip_whitespace()
  integer c
  if idx > length(text) then return end if
  c = text[idx]
  if idx = 1 and c = '#' and text[idx+1] = '!' then
    -- skip special comment for shell interpreter
    while not find(c, "\r\n") do
      idx += 1
      if idx > length(text) then return end if
      c = text[idx]
    end while
  end if
  while find(c, "\t\r\n -") or (OE4 and c='/') do
    if c = '-' then
      if idx >= length(text) or text[idx+1] != '-' then 
        exit 
      end if
      -- skip comment
      while not find(c, "\r\n") do
        idx += 1
        if idx > length(text) then return end if
        c = text[idx]
      end while
    elsif OE4 and c = '/' then
      if idx >= length(text) or text[idx+1] != '*' then 
        return
      end if
      idx += 2
      -- skip multiline comment
      while idx <= length(text) and not equal(text[idx-1..idx], "*/") do
        idx += 1
      end while
    end if
    idx += 1
    if idx > length(text) then return end if
    c = text[idx]
  end while
end procedure


  
function isalpha(integer c)
  return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z') or (OE4 and c = '_')
end function

function isnum(integer c)
  return (c >= '0' and c <= '9') or (OE4 and c = '_')
end function

function isalphanum(integer c)
  return isalpha(c) or isnum(c) or c = '_' or (OE4 and c = ':')
end function

function ishex(integer c)
  return isnum(c) or (c >= 'A' and c <= 'F')
end function

function isanyhex(integer c)
  return isnum(c) or (c >= 'A' and c <= 'F') or (c >= 'a' and c <= 'f')
end function


procedure num_token()
    if tok[1] != '.' then
      while idx <= length(text) and isnum(text[idx]) do
        idx += 1
      end while
      if OE4 and idx <= length(text) and tok[1] = '0' and 
                 idx = tok_idx+1 and find(text[idx], "xXbBoO") then
        idx += 1
        while idx <= length(text) and isanyhex(text[idx]) do
          idx += 1
        end while
        return
      end if
      if idx < length(text) and text[idx] = '.' and text[idx+1] != '.' then
        idx += 1
      end if
    else
      idx += 1
    end if
    while idx <= length(text) and isnum(text[idx]) do
      idx += 1
    end while
    if idx <= length(text) and (text[idx] = 'e' or text[idx] = 'E') then
      idx += 1
      while idx <= length(text) and isnum(text[idx]) do
        idx += 1
      end while
    end if
end procedure

integer print_token
print_token = 0

function token(sequence try)
  if length(tok) = 0 then
    skip_whitespace()
    if idx > length(text) then
      return equal(tok, try)
    end if
    tok_idx = idx
    tok = {text[idx]}
    idx += 1
    if isalpha(tok[1]) then
      while idx <= length(text) and (isalphanum(text[idx]) or (OE4 and text[idx] = ':')) do
        idx += 1
      end while
      tok = text[tok_idx..idx-1]
    elsif tok[1] = '.' and idx <= length(text) and text[idx] = '.' then
      tok &= '.'
      idx += 1
    elsif isnum(tok[1]) or tok[1] = '.' then
      num_token()
      tok = text[tok_idx..idx-1]
    elsif idx <= length(text) and text[idx] = '=' and find(tok[1], "<>+-*/&!") then
      tok &= '='
      idx += 1
    elsif tok[1] = '#' then
      while idx <= length(text) and ishex(text[idx]) do
        idx += 1
      end while
      tok = text[tok_idx..idx-1]
    end if
    --if print_token then printf(1, "token: %s\n", {tok}) end if
  end if
  if equal(tok, try) then
    tok = ""
    return 1
  end if
  return 0
end function

procedure expect(sequence try)
  if not token(try) then
    error("expected '" & try & "', not '"&tok&"'")
    tok = ""
  end if
end procedure

function identifier()
  if length(tok) = 0 then
    if token("") then
      return 0
    end if
  end if
  return isalpha(tok[1]) and not find(tok, keywords)
end function

function get_token()
  sequence result
  result = tok
  tok = ""
  return result
end function


function escape_character(integer c)
  integer i
  sequence s
  i = find(c, "trn\\\'\"")
  if i = 0 then
    error("unknown escape character")
    return c
  end if
  s = "\t\r\n\\\'\""
  return s[i]
end function

function string_literal()
  sequence s
  s = ""

  -- check for triple-quoted string
  if idx+1 <= length(text) and text[idx] = '"' and text[idx+1] = '"' then
    -- triple-quoted string
    integer start_idx = idx+2
    idx += 2
    while text[idx] != '"' or text[idx+1] != '"' or text[idx+2] != '"' do
      idx += 1
      if idx+2 > length(text) then
        error("unexpected end of file")
        exit
      end if
    end while
    idx += 3
    return text[start_idx..idx-4]
  end if
 
  while idx <= length(text) and text[idx] != '"' do
    if text[idx] = '\n' or text[idx] = '\r' then
      error("unterminated string literal")
      return s
    end if
    if text[idx] = '\\' then
      idx += 1
      if idx <= length(text) then
        s &= escape_character(text[idx])
      end if
    else
      s &= text[idx]
    end if
    idx += 1
    if idx > length(text) then
      error("unexpected end of file")
      return s
    end if
  end while
  idx += 1
  return s
end function

function multiline_string_literal()
  integer start_idx

  start_idx = idx
  while text[idx] != '`' do
    idx += 1
    if idx > length(text) then
      error("unexpected end of file")
      return text[start_idx..idx-1]
    end if
  end while
  idx += 1
  return text[start_idx..idx-2]
end function

function character_literal()
  integer c = 0
  if idx <= length(text) then
    c = text[idx]
    if c = '\n' or c = '\r' then
      error("unterminated character literal")
    end if
    idx += 1
    if c = '\\' and idx <= length(text) then
      c = escape_character(text[idx])
      idx += 1
    end if
  end if
  if idx > length(text) then
    error("unexpected end of file")
    return c
  end if
  if text[idx] != '\'' then
    tok_idx = idx
    error("expected '''")
  end if
  idx += 1
  return c
end function

-- returns a bare or quoted filename following an include statement
-- when quoted, backslashes must be escaped
function filename()
  sequence s
  skip_whitespace()
  if idx <= length(text) and text[idx] = '\"' then
    idx += 1
    tok_idx = idx
    return string_literal()
  end if
  s = ""
  tok_idx = idx
  while idx <= length(text) and not find(text[idx], "\t\r\n ") do
    s &= text[idx]
    idx += 1
  end while
  return s
end function


-- returns a sequence of paths from the eu.cfg
-- name is path to eu.cfg file, mode can be "interpret", "translate", "bind"
global function parse_eu_cfg(sequence name, sequence mode = "interpret")
    integer fd, section_ok = 1
    object line
    sequence result = {}
    sequence allowed_sections = {"[all]", "["&mode&"]"}
    ifdef WINDOWS then
	allowed_sections &= {"[windows]", "["&mode&":windows]"}
    end ifdef
    ifdef UNIX then
	allowed_sections &= {"[unix]", "["&mode&":unix]"}
    end ifdef
    
    fd = open(name, "r")
    if fd = -1 then return {} end if
    line = gets(fd)
    while sequence(line) do
	line = trim(line)
        if length(line) then
	    if line[1] = '-' then
	        -- comment or compiler option, ignore it
	    elsif line[1] = '[' then
	        -- section
	        section_ok = find(line, allowed_sections)
	    elsif section_ok then
	        result = append(result, line)
	    end if
        end if
        line = gets(fd)
    end while
    close(fd)
    return result
end function

-- TODO: return a list of paths
function locate_eu_cfg(sequence current_dir)
    return {}
end function

-- returns a unique timestamp for filename, or -1 if doesn't exist
global function get_timestamp(sequence filename)
  object info
  info = dir(filename)
  if atom(info) or length(info) = 0 or length(info[1]) < 9 then
    return -1
  end if
  info = info[1]
  -- timestamp is contrived (unlike seconds since epoch)
  -- just needs to be unique so we can tell if a file was changed.
  -- there will be gaps since not all months have 31 days.
  return info[D_SECOND] + 60 * (
         info[D_MINUTE] + 60 * (
         info[D_HOUR] + 24 * (
         info[D_DAY] + 31 * (
         info[D_MONTH] + 12 *
         info[D_YEAR]))))
end function

-- returns index of new/existing cache entry, or -1 if file can't be opened
function cache_entry(sequence filename)
  object tmp
  integer f

  -- find an existing entry
  for i = 1 to length(cache) do
    if equal(cache[i][1], filename) then
      return i
    end if
  end for

  -- create new cache and map entries
  cache = append(cache, {filename, 0})
  maps = append(maps, map:new())
  return length(cache)
end function

-- returns -1 if not found, or index of cache entry
function include_file(sequence filename)
  sequence state, tmp, paths
  atom ts = -1
  object new_text
  integer f

  tmp = filename
  ts = get_timestamp(tmp)
  if ts = -1 and not equal(source_filename, "<none>") then
    -- checks for the include file in the same directory as the parent
    tmp = dirname(source_filename) & SLASH & tmp
    ts = get_timestamp(tmp)
    --printf(1, "%s %d\n", {tmp, ts})
    if ts = -1 then
	-- search for a eu.cfg in the same directory as the parent?
	tmp = dirname(source_filename) & SLASH & "eu.cfg"
	paths = parse_eu_cfg(tmp)
	for i = 1 to length(paths) do
	    tmp = paths[i]
	    if tmp[$] != SLASH then
	        tmp &= SLASH
	    end if
	    tmp &= filename
	    ts = get_timestamp(tmp)
	    if ts != -1 then
	        exit
	    end if
	end for
    end if
  end if
  if ts = -1 then
    -- search standard include paths (of the editor interpreter instance)
    paths = include_paths(0)
    for i = 1 to length(paths) do
        tmp = paths[i]
        if tmp[$] != SLASH then
            tmp &= SLASH
        end if
        tmp &= filename
        ts = get_timestamp(tmp)
        --printf(1, "%s %d\n", {tmp, ts})
        if ts != -1 then
            exit
        end if
    end for
  end if
  if ts = -1 then 
    return -1 -- file not found
  end if

  filename = canonical_path(tmp, 0, CORRECT)

  -- verify that the file can be opened
  f = open(filename, "rb")
  if f = -1 then
    puts(2, "Warning: unable to read file: "&filename&"\n")
    return -1 -- unable to read file
  end if
  close(f)
  
  --printf(1, "%s %d\n", {tmp, ts})
  return cache_entry(filename)
end function


function to_number(sequence s)
  atom x, y
  integer base, start

  x = 0
  y = 0
  base = 10
  start = 1

  if s[1] = '#' then
    base = 16
    start = 2
  elsif OE4 and length(s) >= 2 and s[1] = '0' then
    if s[2] = 'b' or s[2] = 'B' then
      base = 2
      start = 2
    elsif s[2] = 'x' or s[2] = 'X' then
      base = 16
      start = 2
    elsif s[2] = 'o' or s[2] = 'O' then
      base = 8
      start = 2
    end if
  end if

  for i = start to length(s) do
    if s[i] = '.' then
      y = 1
    elsif s[i] != '_' then
      if y = 0 then
        x = x * base + (s[i] - '0')
        if s[i] >= 'A' then
          x += (10 - 'A')
        end if
      else
        -- fractional part
        y /= base
        x += y * (s[i] - '0')
        -- FIXME, this is probably not accurate
        if s[i] >= 'A' then
          x += y * (10 - 'A')
        end if
      end if
    end if
  end for
  return x
end function


constant 
  precedence = {
    {"and", "or", "xor"},
    {"<=", ">=", "<", ">", "=", "!="},
    {"&"},
    {"+", "-"},
    {"*", "/"}
  },
  precedence_ast = {
    {AND, OR, XOR},
    {LTE, GTE, LT, GT, EQ, NEQ},
    {CAT},
    {ADD, SUB},
    {MUL, DIV}
  }


function expr(integer depth)
  sequence e
  integer ok
  
  if depth <= length(precedence) then
    e = expr(depth + 1)
    ok = 1
    while ok do
      ok = 0
      for i = 1 to length(precedence[depth]) do
        if token(precedence[depth][i]) then
          e = {precedence_ast[depth][i], e, expr(depth+1)}
          ok = 1
        end if
      end for
    end while
    return e
  end if

  if token("not") then
    e = {NOT, expr(depth)}
  elsif identifier() then
    e = {VARIABLE, get_token(), tok_idx}
    --printf(1, "identifier %s\n", {e[2]})
    if token("(") then
      -- function call
      e[1] = FUNC
      if not token(")") then
        --printf(1, "function call %s\n", {e[2]})
        ok = 1
        while ok do
          if OE4 and token(",") then
            e = append(e, {DEFAULT})
          else
            e = append(e, expr(1))
            ok = token(",")
          end if
        end while
        expect(")")
      end if
    else 
      while token("[") do
        e = {SUBSCRIPT, e, expr(1)}
        if token("..") then
          e[1] = SLICE
          e = append(e, expr(1))
          expect("]")
          exit
        end if
        expect("]")
      end while
    end if

  elsif token("(") then
    e = expr(1)
    expect(")")

  elsif token("{") then
    e = {SEQ}
    if not token("}") then
      e = append(e, expr(1))
      while token(",") do
        if OE4 and token("$") then exit end if
        e = append(e, expr(1))
      end while
      expect("}")
    end if

  elsif token("..") then
    --error("expected an expression")
    e = {SYNTAX_ERROR, tok_idx, length(tok), "expected an expression"}
  elsif length(tok) and (isnum(tok[1]) or tok[1] = '#' or tok[1] = '.') then
    e = {NUMBER, to_number(get_token())}
  elsif token("-") then
    e = {NEG, expr(depth)}
    if length(e[2]) and e[2][1] = NUMBER then
      e = {NUMBER, -e[2][2]}
    end if
  elsif token("+") then
    e = expr(depth)
  elsif token("\"") then
    e = {STRING, string_literal()}
  elsif OE4 and token("`") then
    e = {STRING, multiline_string_literal()}
  elsif token("'") then
    e = {NUMBER, character_literal()}
  elsif token("$") then
    e = {SEQ_LEN}
  else
    --error("expected an expression  tok="&tok)
    e = {SYNTAX_ERROR, tok_idx, length(tok), "expected an expression"}
  end if
  
  --printf(1, "expr(%d): ", {depth})
  --? e
  return e
end function

-- returns a boolean
function ifdef_reduce(sequence e)
    if length(e) = 0 then
        return 0
    elsif e[1] = AND then
        return ifdef_reduce(e[2]) and ifdef_reduce(e[3])
    elsif e[1] = OR then
        return ifdef_reduce(e[2]) or ifdef_reduce(e[3])
    elsif e[1] = XOR then
        return ifdef_reduce(e[2]) xor ifdef_reduce(e[3])
    elsif e[1] = NOT then
        return not ifdef_reduce(e[2])
    elsif e[1] = VARIABLE then
        return find(e[2], defined_words) != 0
    end if
    return 0
end function

function variable_declaration()
  sequence result, tmp
  integer save_idx

  save_idx = idx
  result = {VAR_DECL, get_token(), tok_idx}
  if not identifier() then
    -- restore the last token
    tok = result[2]
    tok_idx = result[3]
    idx = save_idx
    return {}
  end if

  while 1 do
    tmp = {get_token(), tok_idx, 0}
    if OE4 and token("=") then
      tmp = append(tmp, expr(1))
    end if
    tmp[3] = tok_idx -- scope-start
    result = append(result, tmp)
    if not token(",") or (OE4 and token("$")) then
      exit
    end if
    if not identifier() then
      error("expected an identifier")
      exit
    end if
  end while

  return result
end function

function constant_declaration()
  sequence result, tmp

  result = {CONST_DECL}
  while identifier() do
    tmp = {get_token(), tok_idx, 0, 0}
    expect("=")
    tmp[4] = expr(1)
    tmp[3] = tok_idx -- scope-start
    result = append(result, tmp)
    if not token(",") or (OE4 and token("$")) then
      return result
    end if
  end while
  error("expected an identifier name")
  return result
end function

function assignment_or_procedure_call()
  sequence result, ops
  integer ok, save_idx = idx
  
  if not identifier() then
    return {}
  end if

  result = {0, get_token(), tok_idx}
  if token("(") then
    -- procedure call
    result[1] = PROC
    if not token(")") then
      ok = 1
      while ok do
        if OE4 and token(",") then
          result = append(result, {DEFAULT})
        else
          result = append(result, expr(1))
          ok = token(",")
        end if
      end while
      expect(")")
    end if
    return result
  
  elsif token("[") then
    ops = {SUB_ASSIGN, SUB_ADDTO, SUB_SUBTO, SUB_MULTO, SUB_DIVTO, SUB_CATTO}
    tok = "["
    while token("[") do
      result = append(result, expr(1))
      if token("..") then
        result = append(result, expr(1))
        expect("]")
        ops = {SLICE_ASSIGN, SLICE_ADDTO, SLICE_SUBTO, SLICE_MULTO, SLICE_DIVTO, SLICE_CATTO}
        exit
      end if
      expect("]")
    end while
  else
    ops = {ASSIGN, ADDTO, SUBTO, MULTO, DIVTO, CATTO}
  end if
    
  if token("=") then
    result[1] = ops[1]
  elsif token("+=") then
    result[1] = ops[2]
  elsif token("-=") then
    result[1] = ops[3]
  elsif token("*=") then
    result[1] = ops[4]
  elsif token("/=") then
    result[1] = ops[5]
  elsif token("&=") then
    result[1] = ops[6]
  else
    tok = result[2]
    tok_idx = result[3]
    idx = save_idx
    return {}
  end if
  return append(result, expr(1))
end function

function subroutine_declaration(integer subroutine)
  sequence result, args, tmp
  result = {subroutine, "", 0}
  if identifier() then
    result[2] = get_token()
    result[3] = tok_idx
  else
    error("expected an identifier name")
  end if
  expect("(")
  args = {}
  while not token(")") do
    if length(args) and not token(",") then
      error("expected ',' or ')'")
      exit
    end if
    if identifier() then
      tmp = {get_token(), 0, 0, 0}
    else
      error("expected a type name")
      exit
    end if
    if identifier() then
      tmp[2] = get_token()
      tmp[3] = tok_idx
    else
      error("expected an argument name")
      exit
    end if
    if OE4 and token("=") then
      tmp = append(tmp, expr(1))
    end if
    tmp[4] = tok_idx -- scope-start
    args = append(args, tmp)
  end while
  result = append(result, args)
  return result
end function

function enum_declaration()
  sequence result, tmp

  result = {ENUM_DECL, "", 0, '+', {NUMBER, 1}}
  if token("type") then
    if identifier() then
      result[2] = get_token()
      result[3] = tok_idx -- scope-start
    else
      error("expected an identifier name")
    end if
  end if
  if token("by") then
    if token("+") then
    elsif token("-") then
      result[4] = '-'
    elsif token("*") then
      result[4] = '*'
    elsif token("/") then
      result[4] = '/'
    else
      error("expected one of: + - * /")
    end if
    result[5] = expr(1)
  end if
  while identifier() do
    tmp = {get_token(), tok_idx, 0}
    if token("=") then
      tmp = append(tmp, expr(1))
    end if
    tmp[3] = tok_idx -- scope-start
    result = append(result, tmp)
    if not token(",") or (OE4 and token("$")) then
      exit
    end if
  end while
  if length(result[2]) then
    expect("end")
    expect("type")
  end if
  return result
end function

function for_declaration()
    sequence result
    result = {FOR, "", 0}
    if identifier() then
      result[2] = get_token()
      result[3] = tok_idx
    else
      error("expected an identifier name")
    end if
    expect("=")
    result = append(result, expr(1))
    expect("to")
    result = append(result, expr(1))
    if token("by") then
      result = append(result, expr(1))
    else
      result = append(result, {NUMBER, 1})
    end if
    if OE4 and token("label") then
      if token("\"") and length(string_literal()) then
      else
          error("expected a label string")
      end if
    end if
    expect("do")
    return result
end function

function return_statement(integer subroutine)
  if subroutine = FUNC then
    return {RETURN, expr(1)}
  elsif subroutine = PROC then
    return {RETURN}
  end if
  error("'return' is not allowed here")
  return {}
end function

procedure with_or_without(integer mode)
  if token("type_check") then
  elsif token("warning") then
    if not OE4 then return end if
    if token("save") or token("restore") or token("strict") then
      return
    end if
    if token("=") or token("&=") or token("+=") then
    end if
    if token("{") then
      while tok_idx < length(text) and not token("}") do
        get_token()
      end while
    end if
  elsif token("trace") then
  elsif token("profile") then
  elsif token("profile_time") then
  elsif OE4 and token("batch") then
  elsif OE4 and token("indirect_includes") then
  elsif OE4 and token("inline") then
  else
    error("unknown with/without option")
  end if
end procedure

-- returns a if test is true, otherwise b
function choose(integer test, object a, object b)
  if test then
    return a
  end if
  return b
end function

constant NONE = 0

function check_mode(integer mode, sequence token)
  if mode = NONE then
    return 0
  elsif mode = IF then
    tok = "if"
  elsif mode = WHILE then
    tok = "while"
  elsif mode = FOR then
    tok = "for"
  elsif mode = SWITCH then
    tok = "switch"
  elsif mode = FUNC_DECL then
    tok = "function"
  elsif mode = PROC_DECL then
    tok = "procedure"
  elsif mode = TYPE_DECL then
    tok = "type"
  elsif mode = IFDEF or mode = ELSEDEF then
    return 0
  else
    tok = "unknown"
  end if
  error("expected 'end "&tok&"' not '"&token&"'")
  tok = token
  return 1
end function

-- mode is NONE, FUNC_DEC, PROC_DECL, TYPE_DECL, IF, IFDEF, SWITCH, WHILE, FOR
-- sub is 0, FUNC, PROC (used to determine if return needs expr)
function statements(integer mode, integer sub)
  sequence ast, s
  integer var_decl_ok, prefix, prefix_idx, saved_ifdef_ok
  object state

  ast = {idx, 0} -- scope-start, scope-end
  var_decl_ok = OE4 or find(mode, {NONE,FUNC_DECL,PROC_DECL,TYPE_DECL})
  while idx <= length(text) do
    if mode = IF and token("elsif") then
        tok = "elsif"
        exit
    elsif mode = IF and token("else") then
        tok = "else"
        exit
    elsif mode = IFDEF and token("elsifdef") then
        tok = "elsifdef"
        exit
    elsif mode = IFDEF and token("elsedef") then
        tok = "elsedef"
        exit
    elsif mode = SWITCH and token("case") then
        tok = "case"
        exit
    elsif mode = SWITCH and token("end") then
        tok = "end"
        exit
    elsif token("end") then
      if mode != NONE then
        exit
      end if
      error("'end' was not expected here")
    end if
    prefix = 0

    if token("global") then
      if check_mode(mode, "global") then exit end if
      prefix = GLOBAL
      prefix_idx = tok_idx
    elsif OE4 and token("public") then
      if check_mode(mode, "public") then exit end if
      prefix = PUBLIC
      prefix_idx = tok_idx
    elsif OE4 and token("export") then
      if check_mode(mode, "export") then exit end if
      prefix = EXPORT
      prefix_idx = tok_idx
    end if

    s = {}
    if token("while") then
      s = {WHILE, expr(1)}
      if OE4 and token("with") then
        expect("entry")
      elsif OE4 and token("entry") then
        -- weird early syntax? appears in std includes
      end if
      if OE4 and token("label") then
        if token("\"") and length(string_literal()) then
            -- optional label string
        else
            error("expected a label string")
        end if
      end if
      expect("do")
      s &= statements(WHILE, sub)
      expect("while")

    elsif OE4 and token("entry") then
      s = {ENTRY}
    
    elsif OE4 and token("label") then
      if token("\"") then
          s = {LABEL, string_literal()}-- optional label string
      else
          error("expected a label string")
      end if

    elsif token("for") then
      s = for_declaration()
      s &= statements(FOR, sub)
      -- {FOR, name, pos, expr, expr, by, scope-start, scope-end, stmts...}
      expect("for")

    elsif token("exit") then
      -- FIXME: error if not in a loop
      s = {EXIT}
      if OE4 and token("\"") then
        s &= {string_literal()}  -- optional label string
      end if

    elsif token("if") then
      s = {IF, expr(1)}
      expect("then")
      s = append(s, statements(IF, sub))
      while token("elsif") do
        s = append(s, expr(1))
        expect("then")
        s = append(s, statements(IF, sub))
      end while
      if token("else") then
        s = append(s, statements(ELSE, sub))
      end if
      expect("if")

    elsif OE4 and token("ifdef") then
      if not identifier() then error("expected an identifier") end if
      saved_ifdef_ok = ifdef_ok
      ifdef_ok = ifdef_reduce(expr(1)) and saved_ifdef_ok
      expect("then")
      s = choose(ifdef_ok, statements(IFDEF, sub), {})
      while token("elsifdef") do
        if not identifier() then error("expected an identifier") end if
        ifdef_ok = ifdef_reduce(expr(1)) and length(s) = 0 and saved_ifdef_ok
        expect("then")
        s = choose(ifdef_ok, statements(IFDEF, sub), s)
      end while
      if token("elsedef") then
        ifdef_ok = length(s) = 0 and saved_ifdef_ok
        s = choose(ifdef_ok, statements(ELSEDEF, sub), s)
      end if
      expect("ifdef")
      ifdef_ok = saved_ifdef_ok
      if length(s) then
        -- splice statements into ast
        ast &= s[3..$]
        s = {}
      end if

    elsif OE4 and token("switch") then
      s = {SWITCH, expr(1), 0, ""}
      if token("with") then
        expect("fallthru")
        s[3] = 1 -- enable fallthru
      end if
      if token("label") then
        if token("\"") then
            s[4] = string_literal()  -- optional label string
        else
            error("expected a label string")
        end if
      end if
      expect("do")
      while token("case") do
        s = append(s, {})
        if token("else") then
          s = append(s, statements(SWITCH, sub)) -- case else statements
          exit
        else
          while identifier() or find(tok[1], "\"'0123456789#") do
            if token("\"") then
              s[$] = append(s[$], '"'&string_literal()&'"') -- case values
            elsif token("'") then
              s[$] = append(s[$], '\''&character_literal()&'\'') -- case values
            else
              s[$] = append(s[$], get_token()) -- case values
            end if
            if not token(",") then exit end if
          end while
          expect("then")
          s = append(s, statements(SWITCH, sub)) -- case statements
        end if
      end while
      expect("end")
      expect("switch")

    elsif OE4 and token("break") then
      s = {BREAK}
      if token("\"") then
        s = append(s, string_literal()) -- optional label string
      end if

    elsif OE4 and token("continue") then
      s = {CONTINUE}
      if token("\"") then
        s = append(s, string_literal()) -- optional label string
      end if

    elsif OE4 and token("goto") then
      s = {GOTO}
      expect("\"")
      s = append(s, string_literal()) -- label string

    elsif token("?") then
      s = {QPRINT, expr(1)}
      
    elsif token("with") then
      if check_mode(mode, "with") then exit end if
      with_or_without(1)

    elsif token("without") then
      if check_mode(mode, "without") then exit end if
      with_or_without(0)

    elsif token("include") then
      if check_mode(mode, "include") then exit end if
      s = filename()
      if ifdef_ok then
        state = include_file(s)
        if state != -1 then
          s = {INCLUDE, state, idx}  
        else
          error("can't find '"&s&"'")
        end if
        
      end if
      if prefix = PUBLIC then
        --puts(1, "public include next_token="&tok&"\n")
        s = PUBLIC & s
        prefix = 0
      end if
      if OE4 and token("as") then
        if identifier() then 
	  s = append(s, get_token())
	else 
	  error("expected an identifier")
	end if
      end if
      if not ifdef_ok then
        s = {}
      end if

    elsif token("constant") then
      if check_mode(mode, "constant") then exit end if
      s = constant_declaration()

    elsif token("function") then
      if check_mode(mode, "function") then exit end if
      s = subroutine_declaration(FUNC_DECL)
      s &= statements(FUNC_DECL, FUNC)
      expect("function")

    elsif token("procedure") then
      if check_mode(mode, "procedure") then exit end if
      s = subroutine_declaration(PROC_DECL)
      s &= statements(PROC_DECL, PROC)
      expect("procedure")

    elsif token("type") then
      if check_mode(mode, "type") then exit end if
      s = subroutine_declaration(TYPE_DECL)
      s &= statements(TYPE_DECL, FUNC)
      expect("type")

    elsif token("return") then
      s = return_statement(sub)

    elsif OE4 and token("enum") then
      if check_mode(mode, "enum") then exit end if
      s = enum_declaration()
      
    elsif OE4 and mode = NONE and length(ast) = 2 and token("namespace") then
      if not identifier() then 
        error("expected namespace identifier")
      end if
      s = {NAMESPACE, get_token()}

    elsif OE4 and token("{") then
      s = {SEQ_ASSIGN}
      while identifier() do
        s &= {get_token(), tok_idx}
        if not token(",") then
          exit
        end if
      end while
      expect("}")
      expect("=")
      s &= {expr(1)}
    
    elsif identifier() then
      if var_decl_ok then
        s = variable_declaration()
      end if
      if length(s) = 0 then
        s = assignment_or_procedure_call()
      end if
      if length(s) = 0 then
        error("expected statement, not '"&tok&"'")
        tok = ""
      end if

    elsif length(tok) then
      error("expected statement, not '"&tok&"'")
      tok = ""
    end if
    if prefix then
      if (length(s) > 0 and find(s[1], {VAR_DECL, CONST_DECL, ENUM_DECL, 
                                        PROC_DECL, FUNC_DECL, TYPE_DECL})) then
        s = prefix & s
      else
        tok_idx = prefix_idx
        error("scope prefix wasn't expected here")
        tok = ""
      end if
    end if

    if length(s) then
      ast = append(ast, s)
    end if
    if length(errors) then
      ast &= errors
      errors = {}
    end if
  end while
  if mode != NONE and idx > length(text) then
    error("unexpected end of input")
  end if
  ast[2] = idx -- scope-end
  return ast
end function

global function parse(sequence source_text, sequence file_name)
  integer cache_idx
  sequence ast

  file_name = canonical_path(file_name, 0, CORRECT)
  cache_idx = cache_entry(file_name)

  source_filename = file_name
  text = source_text
  idx = 1
  tok_idx = 1
  tok = ""
  ifdef_ok = 1
  ast_idx = 3
  cur_map = maps[cache_idx]
  map:clear(cur_map)
  ast = statements(NONE, 0)
  declare_ast(ast, 3, length(text), 1)
  ast[1..2] = cache[cache_idx][1..2]
  cache[cache_idx] = ast

  return ast
end function

global function parse_file(sequence file_name)
  object text = read_file(file_name)
  if atom(text) then
    return {} -- unable to read file
  end if
  return parse(text, file_name)
end function

-- during get_decls we might need to reparse a file if its timestamp changed
procedure check_cache_timestamp(integer idx)
    sequence ast, file_name
    atom ts
    file_name = cache[idx][1]
    ts = get_timestamp(file_name)
    if cache[idx][2] != ts then
        cache[idx][2] = ts
        ast = parse_file(file_name)
        if length(ast) >= 2 then
          ast[1] = file_name
          ast[2] = ts
          cache[idx] = ast
        end if
    end if
end procedure



constant 
  F = "function",
  P = "procedure",
  T = "type",
  I = "integer",
  O = "object",
  S = "sequence",
  A = "atom",
  builtins = {
  {F, "abort", I, "errcode", 0},
  {F, "and_bits", O, "a", 0, O, "b", 0},
  {F, "append", S, "target", 0, O, "x", 0},
  {F, "arctan", O, "tangent", 0},
  {T, A, O, "x", 0},
  {F, "c_func", I, "rid", 0, S, "args", 1},
  {P, "c_proc", I, "rid", 0, S, "args", 1},
  {F, "call", I, "id", 0, S, "args", 1},
  {F, "call_func", I, "id", 0, S, "args", 1},
  {P, "call_proc", I, "id", 0, S, "args", 1},
  {P, "clear_screen"},
  {P, "close", A, "fn", 0},
  {F, "command_line"},
  {F, "compare", O, "compared", 0, O, "reference", 0},
  {F, "cos", O, "angle", 0},
  {F, "date"},
  {P, "delete", O, "x", 0},
  {F, "delete_routine", O, "x", 0, I, "rid", 0},
  {F, "equal", O, "left", 0, O, "right", 0},
  {F, "find", O, "needle", 0, S, "haystack", 0, I, "start", 1},
  {F, "floor", O, "value", 0},
  {F, "get_key"},
  {F, "getc", I, "fn", 0},
  {F, "getenv", S, "var_name", 0},
  {F, "gets", I, "fn", 0},
  {F, "hash", O, "source", 0, A, "algo", 0},
  {F, "head", S, "source", 0, A, "size", 1},
  {F, "include_paths", I, "convert", 0},
  {F, "insert", S, "target", 0, O, "what", 0, I, "index", 0},
  {T, I, O, "x", 0},
  {F, "length", O, "target", 0},
  {F, "log", O, "value", 0},
  {F, "machine_func", I, "machine_id", 0, O, "args", 1},
  {P, "machine_proc", I, "machine_id", 0, O, "args", 1},
  {F, "match", S, "needle", 0, S, "haystack", 0, I, "start", 1},
  {P, "mem_copy", A, "destination", 0, A, "origin", 0, I, "len", 0},
  {P, "mem_set", A, "destination", 0, I, "byte_value", 0, I, "how_many", 0},
  {F, "not_bits", O, "a", 0},
  {T, O, O, "x", 0},
  {F, "open", S, "path", 0, S, "mode", 0, I, "cleanup", 1},
  {F, "option_switches"},
  {F, "or_bits", O, "a", 0, O, "b", 0},
  {F, "peek", O, "addr_n_length", 0},
  {F, "peek2s", O, "addr_n_length", 0},
  {F, "peek2u", O, "addr_n_length", 0},
  {F, "peek4s", O, "addr_n_length", 0},
  {F, "peek4u", O, "addr_n_length", 0},
  {F, "peek8s", O, "addr_n_length", 0},
  {F, "peek8u", O, "addr_n_length", 0},
  {F, "peek_string", A, "addr", 0},
  {F, "peeks", O, "addr_n_length", 0},
  {F, "pixel"},
  {F, "platform"},
  {P, "poke", A, "addr", 0, O, "x", 0},
  {P, "poke2", A, "addr", 0, O, "x", 0},
  {P, "poke4", A, "addr", 0, O, "x", 0},
  {P, "poke8", A, "addr", 0, O, "x", 0},
  {P, "position", I, "row", 0, I, "column", 0},
  {F, "power", O, "base", 0, O, "exponent", 0},
  {F, "prepend", S, "target", 0, O, "x", 0},
  {P, "print", I, "fn", 0, O, "x", 0},
  {P, "printf", I, "fn", 0, S, "format", 0, O, "values", 0},
  {P, "puts", I, "fn", 0, O, "text", 0},
  {F, "rand", O, "maximum", 0},
  {F, "remainder", O, "dividend", 0, O, "divisor", 0},
  {F, "remove", S, "target", 0, A, "start", 0, A, "stop", 1},
  {F, "repeat", O, "item", 0, A, "count", 0},
  {F, "replace", S, "target", 0, O, "replacement", 0, I, "start", 0, I, "stop", 1},
  {F, "routine_id", S, "routine_name", 0},
  {T, S, O, "x", 0},
  {F, "sin", O, "angle", 0},
  {F, "splice", S, "target", 0, O, "what", 0, I, "index", 0},
  {F, "sprintf", S, "format", 0, O, "values", 0},
  {F, "sqrt", O, "value", 0},
  {P, "system", S, "command", 0, I, "mode", 1},
  {F, "system_exec", S, "command", 0, I, "mode", 1},
  {F, "tail", S, "source", 0, A, "size", 1},
  {F, "tan", O, "angle", 0},
  {P, "task_clock_start"},
  {P, "task_clock_stop"},
  {F, "task_create", I, "rid", 0, S, "args", 0},
  {F, "task_list"},
  {F, "task_schedule", A, "task_id", 0, O, "schedule", 0},
  {F, "task_self"},
  {F, "task_schedule", A, "task_id", 0},
  {F, "task_suspend", A, "task_id", 0},
  {F, "task_yield"},
  {F, "time"},
  {P, "trace", I, "mode", 0},
  {F, "xor_bits", O, "a", 0, O, "b", 0}
  }

map:map builtins_map = map:new()
for i = 1 to length(builtins) do
  
end for

global function get_builtins()
  sequence s
  s = {}
  for i = 1 to length(builtins) do
    if i > 1 then s &= ' ' end if
    s &= builtins[i][2]
  end for
  return s
end function


sequence include_ids, include_flags
constant
  FILTER_LOCAL = 1,
  FILTER_GLOBAL = 2,
  FILTER_PUBLIC = 4,
  FILTER_EXPORT = 8,
  FILTER_INCLUDE = 16,
  FILTER_INCLUDE_AS = 32,
  FILTER_ALL = 63



  
function get_include_filter(sequence s, sequence name_space, integer filter, integer prefix)
  integer idx, include_filter

  idx = s[2] -- cache[] index
  if length(name_space) then
    --if length(s) >= 3 then
    --    printf(1, "filter=%x namespace=%s include as %s\n", {filter, name_space, s[3]})
    --end if
    if filter = FILTER_GLOBAL + FILTER_PUBLIC + FILTER_EXPORT then
        -- include as namespace -> include
        include_filter = FILTER_PUBLIC
    elsif filter = FILTER_PUBLIC and prefix = FILTER_PUBLIC then
      -- a public include from nested include
      include_filter = FILTER_PUBLIC
    elsif and_bits(filter, FILTER_INCLUDE_AS) and length(cache[idx]) >= 3 and 
          equal(cache[idx][3], {NAMESPACE, name_space}) then
      -- include has same namespace
      include_filter = FILTER_GLOBAL + FILTER_PUBLIC + FILTER_EXPORT
    else
      include_filter = 0
    end if
  elsif and_bits(filter, FILTER_INCLUDE_AS) then
    -- top-level include
    include_filter = FILTER_GLOBAL + FILTER_PUBLIC + FILTER_EXPORT
  elsif and_bits(filter, FILTER_PUBLIC) and prefix = FILTER_PUBLIC then
    -- public sub-include
    include_filter = FILTER_GLOBAL + FILTER_PUBLIC
  else
    -- sub-include
    include_filter = FILTER_GLOBAL
  end if
  idx = find(s[2], include_ids)
  if idx = 0 then
    -- new entry
    include_ids &= s[2]
    include_flags &= 0
    idx = length(include_ids)
  elsif and_bits(include_flags[idx], include_filter) = include_filter then
    -- avoid adding the same symbols again
    return -1
  end if

  include_filter = and_bits(include_filter, not_bits(include_flags[idx]))
  include_flags[idx] = or_bits(include_flags[idx], include_filter)
 
  return include_filter + FILTER_INCLUDE
end function
	

-- returns {{"subroutine-type", "name", ["arg1-type", "arg1-name", is_default]... }... }
function get_args(sequence ast, sequence word, sequence name_space, integer filter)
  sequence result, s
  integer x, decl, prefix, include_filter

  if length(name_space) and (length(ast) < 3 or not equal(ast[3], {NAMESPACE, name_space})) then
      filter = and_bits(filter, FILTER_INCLUDE + FILTER_INCLUDE_AS)
      if filter = 0 then
         return {}  -- no namespace or mismatch
      end if
  end if

  result = {}
  for i = 3 to length(ast) do
    s = ast[i]

    prefix = power(2, find(s[1], {GLOBAL, PUBLIC, EXPORT}))
    if prefix > 1 then
      s = s[2..$] -- remove prefix      
    end if
    decl = s[1]
    if and_bits(filter, prefix) = 0 and decl != INCLUDE then
      decl = 0
    end if

    if decl = INCLUDE and and_bits(filter, FILTER_INCLUDE) then
      -- {INCLUDE, includes-index, scope-start, ["namespace"]}
      x = s[2]
      if x != -1 and and_bits(filter, FILTER_INCLUDE) then
        include_filter = get_include_filter(s, name_space, filter, prefix)
        if include_filter != -1 then
          result &= get_args(cache[x], word, name_space, include_filter)
        end if
      end if

    elsif decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL and equal(s[2], word) then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      if decl = FUNC_DECL then
        result &= {{"function", s[2]}}
      elsif decl = PROC_DECL then
        result &= {{"procedure", s[2]}}
      elsif decl = TYPE_DECL then
        result &= {{"type", s[2]}}
      end if
      for j = 1 to length(s[4]) do -- display arguments
        result[$] &= {s[4][j][1], s[4][j][2], length(s[4][j]) = 5}  -- {"type", "name", has-default}
      end for
      
    end if
  end for
  -- scan builtins
  if length(result) = 0 then
      for i = 1 to length(builtins) do
          if equal(word, builtins[i][2]) then
              result &= {builtins[i]}
              exit
          end if
      end for
  end if
  return result
end function

function type_to_decl(sequence name)
    if equal(name, "atom") then
        return DECL_ATOM
    elsif equal(name, "sequence") then
        return DECL_SEQUENCE
    elsif equal(name, "integer") then
        return DECL_INTEGER
    end if
    return DECL_OBJECT
end function

-- to prevent recursion, symbols may be included from a file
-- only once for each type of flag: global, public, export

-- namespace matches:
--  top-level file has same namespace
--  top-level file has include as same namespace
--  included file has same namespace
--  included file is publicly included by file with same namespace

-- get a list of declarations from ast in scope at pos
-- returns {{"name1", pos1, type1}, {"name2", pos2, type2}...}
--  pos may be be an integer for the position in the current file,
--  or {pos, "include-path"} for included files.

function get_decls(sequence ast, integer pos, sequence name_space, integer filter)
  sequence result, s
  integer x, decl, prefix, include_filter

  if length(name_space) and (length(ast) < 3 or not equal(ast[3], {NAMESPACE, name_space})) then
      filter = and_bits(filter, FILTER_INCLUDE + FILTER_INCLUDE_AS)
      if filter = 0 then
         return {}  -- no namespace or mismatch
      end if
  end if

  result = {}
  for i = 3 to length(ast) do
    s = ast[i]

    prefix = power(2, find(s[1], {GLOBAL, PUBLIC, EXPORT}))
    if prefix > 1 then
      s = s[2..$] -- remove prefix
    end if
    decl = s[1]
    if and_bits(prefix, filter) = 0 and decl != INCLUDE then
      -- the scope modifier didn't pass the filter
      decl = 0
    end if

    if decl = INCLUDE and and_bits(filter, FILTER_INCLUDE) then
      -- {INCLUDE, includes-index, scope-start, ["namespace"]}
      x = s[2] -- includes-index into cache
      if x != -1 then
        --printf(1, "include %s filter=%x\n", {cache[x][1], filter})
        if length(name_space) and and_bits(filter, FILTER_INCLUDE_AS) and 
          length(s) >= 4 and equal(s[4], name_space) and pos >= s[3] then
          -- found a matching "include as"
          filter = 0
          include_filter = FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT
          result = {}
          name_space = {}
        else  
          include_filter = get_include_filter(s, name_space, filter, prefix)
        end if
        if include_filter != -1 then
          check_cache_timestamp(x)
          s = get_decls(cache[x], 0, name_space, include_filter)
          --printf(1, "%s: %d\n", {cache[x][1], length(cache[x])})
          for j = 1 to length(s) do
            --printf(1, "%s: %d\n", {s[j-1], s[j]})
            if not sequence(s[j][2]) then
              s[j][2] = {cache[x][1], s[j][2]} -- is {filename, pos}
            end if
          end for
          result &= s
        end if
      end if

    elsif decl = CONST_DECL then
      -- {CONST_DECL, {"name", pos, scope-start, expr}... }
      --printf(1, "constant\n", {})
      for j = 2 to length(s) do
        --printf(1, "  %s: %d\n", {s[j][1], s[j][2]})
        if length(s[j]) >= 3 and (pos >= s[j][3] or filter) then -- in scope?
          result = append(result, {s[j][1], s[j][2], DECL_CONSTANT})
        end if
      end for

    elsif decl = VAR_DECL then
      -- {VAR_DECL, "type", pos, {"name", pos, scope-start, [expr]}...}
      --printf(1, s[2] & "\n", {})
      for j = 4 to length(s) do
        --printf(1, "  %s: %d\n", {s[j][1], s[j][2]})
        if length(s[j]) >= 3 and (pos >= s[j][3] or filter) then -- in scope?
          result = append(result, {s[j][1], s[j][2], type_to_decl(s[2])})
        end if
      end for

    elsif decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      if decl = FUNC_DECL then
        --printf(1, "function %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
        result = append(result, {s[2], s[3], DECL_FUNCTION})
      elsif decl = PROC_DECL then
        --printf(1, "procedure %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
        result = append(result, {s[2], s[3], DECL_PROCEDURE})
      elsif decl = TYPE_DECL then
        --printf(1, "type %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
	result = append(result, {s[2], s[3], DECL_TYPE})
      end if
      if length(s) >= 6 and pos >= s[5] and pos <= s[6] then -- in scope?
        for j = 1 to length(s[4]) do -- display arguments
          if length(s[4][j]) >= 4 and pos >= s[4][j][4] then
            --printf(1, "  %s %s: %d\n", {s[4][j][1], s[4][j][2], s[4][j][3]})
            result = append(result, {s[4][j][2], s[4][j][3], type_to_decl(s[4][j][1])})
          end if
        end for
        result &= get_decls(s[5..$], pos, name_space, filter)
      end if

    elsif decl = FOR then
      -- {FOR, name, pos, expr, expr, by, scope-start, scope-end, stmts...}
      if length(s) >= 8 and pos >= s[7] and pos <= s[8] then -- in scope?
        --printf(1, "for %s: %d\n", {s[2], s[3]})
        result = append(result, {s[2], s[3], DECL_ATOM})
        result &= get_decls(s[7..$], pos, name_space, filter)
      end if

    elsif decl = WHILE then
      -- {WHILE, expr, scope-start, scope-end, stmts...}
      if length(s) >= 4 and pos >= s[3] and pos <= s[4] then -- in scope?
        result &= get_decls(s[3..$], pos, name_space, filter)
      end if

    elsif decl = IF then
      -- {IF, expr, {scope-start, scope-end, stmts...}, 
      --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
      --     [{scope-start, scope-end, else-stmts...}]}
      for j = 2 to length(s) by 2 do
        x = (j != length(s))
        if length(s[j+x]) >= 2 and pos >= s[j+x][1] and pos <= s[j+x][2] then -- in scope?
          result &= get_decls(s[j+x], pos, name_space, filter)
        end if
      end for

    elsif decl = ENUM_DECL then
      -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
      --             {"name", pos, scope-start, [expr]}...}
      if length(s[2]) then -- has typename
        result = append(result, {s[2], s[3], DECL_TYPE})
      end if
      for j = 6 to length(s) do
        if length(s[j]) >= 3 and pos >= s[j][3] then -- in scope?
          result = append(result, {s[j][1], s[j][2], DECL_ENUM})
        end if
      end for

    end if
  end for
  return result
end function

global function get_declarations(sequence ast, integer pos, sequence name_space)
  include_ids = {}
  include_flags = {}
  return get_decls(ast, pos, name_space, FILTER_ALL)
end function

global function get_subroutines(sequence ast)
  sequence result, s
  integer decl, n

  result = {}
  for i = 3 to length(ast) do
    s = ast[i]
    n = prefixed(s)
    decl = s[n+1]

    if decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      result = append(result, {s[n+2], s[n+3]})
    end if
  end for
  return result
end function

-- returns {["subroutine-type", {["arg1-type", "arg1-name", has-default]...}, ]...}
global function get_subroutine_arguments(sequence ast, sequence word, sequence namespace)
  include_ids = {}
  include_flags = {}
  return get_args(ast, word, namespace, FILTER_ALL)
end function



-- returns {word, namespace, start, end} otherwise {""}
global function word_pos(sequence text, integer pos)
  if pos > length(text) then
    return {""}
  end if
  for i = pos+1 to 1 by -1 do
    -- find the start of the word
    if i = 1 or not isalphanum(text[i-1]) then
      -- find the end of the word
      while pos < length(text) and isalphanum(text[pos+1]) do
        pos += 1
      end while
      -- words must start with a letter
      if i <= length(text) and isalpha(text[i]) then
        -- look for a colon
        for j = i to pos do
          if text[j] = ':' then
            -- found namespace and word
            return {text[j+1..pos], text[i..j-1], j+1, pos}
          end if
        end for
        -- found word only
        return {text[i..pos], "", i, pos}
      end if
      exit
    end if
  end for
  return {""}
end function


sequence suggested_includes, suggested_word, suggested_namespace, suggested_path

function walk_include(sequence path_name, sequence dirent)
    object state
    sequence decls

    path_name &= SLASH & dirent[D_NAME]
    if length(path_name) < 2 or (path_name[$] != 'e' and path_name[$] != 'E') or path_name[$-1] != '.' then
      -- path_name doesn't end with .e or .E
      return 0
    end if
    state = cache_entry(canonical_path(path_name, 0, CORRECT))
    if state > 0 then
      check_cache_timestamp(state)
    end if
    if state > 0 then
      include_ids = {}
      include_flags = {}
      decls = get_decls(cache[state], 0, suggested_namespace, 
                        FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT)
      for i = 1 to length(decls) do
        --puts(1, "  "&decls[i]&"\n")
        if length(decls[i][1]) >= length(suggested_word) and 
           equal(decls[i][1][1..length(suggested_word)], suggested_word) then
          --puts(1, dirent[D_NAME]&" matched!\n")
          suggested_includes = append(suggested_includes, 
	    {decls[i][1] & " --include "& path_name[length(suggested_path)+2..$],
		{cache[state][1], decls[i][2]}, decls[i][3]})
        end if
      end for
    end if

    return 0 -- keep searching all files
end function

constant walk_include_id = routine_id("walk_include")

-- returns a list of include files which contain a declaration decl
global function suggest_includes(sequence word, sequence name_space)
  sequence paths, path

  suggested_includes = {}
  suggested_word = word
  suggested_namespace = name_space
  paths = include_paths(0)
  for i = 1 to length(paths) do
    path = paths[i]
    --puts(1, "include_dir="&paths[i]&"\n")
    if path[$] = SLASH then
      path = path[1..$-1]
    end if
    if length(path) > 8 and equal(path[$-7..$], SLASH & "include") then
      suggested_path = path
      if walk_dir(path, walk_include_id, 1) = 0 then
        -- success!
      end if
    end if
  end for
  return suggested_includes
end function

-- parse argument expressions, returning the last argument position
global function parse_argument_position(sequence source_text)
  integer arg, old_idx
  sequence e

  text = source_text
  idx = 1
  tok_idx = 1
  tok = ""
  arg = 1
  for i = 1 to 1000 do
    if tok_idx > length(text) then
	return arg
    end if
    if token(")") then
        return 0
    end if
    if token(",") then
        arg += 1
    end if
    old_idx = tok_idx
    e = expr(1)
    --? {e, tok, tok_idx}
    --if length(e) = 0 and length(tok) = 0 then
    if old_idx = tok_idx then
      return arg
    end if
  end for
  printf(1, "stuck parsing argument position for \"%s\"\n", {text})
  ? e
  ? tok
  return arg
end function

-- cur_ast: {cache-idx...}
-- cur_scope: {FILTER_* or'd...}
-- cur_namespace: {"namespace"...}
sequence cur_ast, cur_scope, cur_namespace, check_result = {}
integer cur_sub = 0 -- whether or not inside subroutine

-- scan ast for a declaration at pos, returns 0 if not found, otherwise
-- one of FUNC_DECL, PROC_DECL, TYPE_DEC, VAR_DECL, CONST_DECL or FOR
function decl_kind(sequence ast, integer start_idx, integer pos)
  for j = start_idx to length(ast) do
    sequence s = ast[j]
    integer decl = s[1]

    if decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      if pos = s[3] then
        return decl
      end if
      sequence args = s[4]
      for i = 1 to length(args) do
        if pos = args[i][3] then
          return VAR_DECL
        end if
      end for
      decl = decl_kind(s, 7, pos)
      if decl then
        return decl
      end if
      
    elsif decl = VAR_DECL then
      -- {VAR_DECL, "type", pos, {"name", pos, scope-start, [expr]}...}
      for i = 4 to length(s) do
        if pos = s[i][2] then
          return decl
        end if
      end for
      
    elsif decl = CONST_DECL then
      -- {CONST_DECL, {"name", pos, scope-start, expr}... }
      for i = 2 to length(s) do
        if pos = s[i][2] then
          return decl
        end if
      end for
      
    elsif decl = WHILE then
      -- {WHILE, expr, scope-start, scope-end, stmts...}
      if pos >= s[3] and pos <= s[4] then
        decl = decl_kind(s, 5, pos)
        if decl then
          return decl
        end if
      end if
      
    elsif decl = IF then
      -- {IF, expr, {scope-start, scope-end, stmts...}, 
      --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
      --     [{scope-start, scope-end, else-stmts...}]}
      decl = 0
      for i = 2 to length(s) by 2 do
        if i = length(s) then
          if pos >= s[i][1] and pos <= s[i][2] then
            decl = decl_kind(s[i], 3, pos)
          end if
        else
          if pos >= s[i+1][1] and pos <= s[i+1][2] then
            decl = decl_kind(s[i+1], 3, pos)
          end if
        end if
        if decl then
          return decl
        end if
      end for

    elsif decl = FOR then
      -- {FOR, "name", pos, expr, expr, by, scope-start, scope-end, stmts...}
      if pos = s[3] then
        return decl
      end if
      if pos >= s[7] and pos <= s[8] then
        decl = decl_kind(s, 9, pos)
        if decl then
          return decl
        end if
      end if

    elsif decl = ENUM_DECL then
      -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
      --             {"name", pos, scope-start, [expr]}...}
      if pos = s[3] then
        return TYPE_DECL
      end if
      for i = 6 to length(s) do
        if pos = s[i][2] then
          return CONST_DECL
        end if
      end for

    elsif decl = SWITCH then
      -- {SWITCH, expr, bool-fallthru, label-string,
      --   [{case-values...}, {scope-start, scope-end, stmts...},]... }
      --  ("case else" will have case-values={} )
      for i = 6 to length(s) by 2 do
        if pos >= s[i][1] and pos <= s[i][2] then
          decl = decl_kind(s[i], 3, pos)
          if decl then
            return decl
          end if
        end if
      end for
    end if
  end for
  return 0
end function

-- returns the decl kind if pos in scope of loc d, otherwise 0
function decl_check(sequence ast, object d, integer pos, integer filter)
  sequence s
  if sequence(d) then  
    -- variable, constant, enum value or for-variable declaration
    s = ast[d[1]]
  else
    -- function, procedure, type or enum-type declaration
    s = ast[d]
  end if
  -- get scope modifier bits
  integer prefix = power(2, find(s[1], {GLOBAL, PUBLIC, EXPORT}))
  if and_bits(prefix, filter) = 0 then
    return 0
  end if
  if prefix > 1 then
    s = s[2..$] -- remove scope modifier
  end if
  if atom(d) then
    return s[1]
  end if
  -- d: { ast-index, pos, scope-start, [scope-end] }
  if s[1] = VAR_DECL or s[1] = CONST_DECL or s[1] = ENUM_DECL then
    -- top level always in scope
    if and_bits(filter, FILTER_LOCAL) and cur_sub = 0 and pos < d[3] and cur_ast[1] = d[1] then
      -- euphoria currently doesn't allow top-level forward references in the same file
      return 0
    end if
    return s[1]
  end if
  if and_bits(filter, FILTER_LOCAL) and pos >= d[3] and (length(d) < 4 or pos <= d[4]) then
    -- in scope
    return decl_kind({s}, 1, d[2])
  end if
  return 0
end function

-- returns 1 if the type of declaration "name" at pos is in the list of decls
-- otherwise 0
function check_name(sequence name, integer pos, sequence decls)
  integer ns = find(':', name)
  integer first = 1, last = length(cur_ast)
  if ns then
    -- search includes with "as"
    last = find(name[1..ns-1], cur_namespace)
    if last then
      first = last
    else
      -- search includes with namespaces
      for i = 1 to length(cur_ast) do
        integer cache_idx = cur_ast[i]
        sequence ast = cache[cache_idx]
        if length(ast) >= 3 and ast[3][1] = NAMESPACE and equal(ast[3][2], name[1..ns-1]) then
          first = i
          last = i
          exit
        end if
      end for
    end if
    if last then
      name = name[ns+1..$]
    end if
  end if
  for j = first to last do
    integer cache_idx = cur_ast[j]
    sequence entries = map:get(maps[cache_idx], name, {})
    sequence ast = cache[cache_idx]
    integer filter = cur_scope[j]
    for i = 1 to length(entries) do
      integer decl = decl_check(ast, entries[i], pos, filter)
      if find(decl, decls) then 
        return 1
      end if
    end for
  end for
  sequence sub_decls = {PROC_DECL, FUNC_DECL, TYPE_DECL}
  -- check builtins
  for i = 1 to length(builtins) do
    if equal(builtins[i][2], name) then
      return find(sub_decls[find(builtins[i][1], {P, F, T})], decls)
    end if
  end for
  return 0
end function


-- scan for variables only, which may be used for assignment
procedure check_var(sequence name, integer pos)
  if not check_name(name, pos, {VAR_DECL}) then
    check_result &= {pos, length(name), "variable '"&name&"' has not been declared"}
  end if
end procedure

-- scan for variables, constants, enum values, or for-variables
procedure check_identifier(sequence name, integer pos)
  if not check_name(name, pos, {VAR_DECL, CONST_DECL, ENUM_DECL, FOR}) then
    check_result &= {pos, length(name), "identifier '"&name&"' has not been declared"}
  end if
end procedure

-- scan for functions or types, used for function call
procedure check_func(sequence name, integer pos)
  if not check_name(name, pos, {FUNC_DECL, TYPE_DECL, ENUM_DECL}) then
    check_result &= {pos, length(name), "function '"&name&"' has not been declared"}
  end if
end procedure

-- scan for types or typed enum, used for variable declaration
procedure check_type(sequence name, integer pos)
  if not check_name(name, pos, {TYPE_DECL, ENUM_DECL}) then
    check_result &= {pos, length(name), "type '"&name&"' has not been declared"}
  end if
end procedure

constant proc_list = choose(OE4, {PROC_DECL, FUNC_DECL, TYPE_DECL, ENUM_DECL}, {PROC_DECL})

-- scan for procedures (OE4: or functions or types)
procedure check_proc(sequence name, integer pos)
  if not check_name(name, pos, proc_list) then
    check_result &= {pos, length(name), "procedure '"&name&"' has not been declared"}
  end if
end procedure

procedure check_expr(sequence expr)
  integer decl

  if length(expr) = 0 then return end if

  decl = expr[1]
  if decl = VARIABLE then
    -- {VARIABLE, "name", pos}
    check_identifier(expr[2], expr[3])

  elsif decl = FUNC then
    -- {FUNC, "name", pos, [args...]}
    check_func(expr[2], expr[3])
    for i = 4 to length(expr) do
      check_expr(expr[i])
    end for

  elsif find(decl, {ADD, SUB, MUL, DIV, NEG, NOT, GT, LT, GTE, LTE, EQ,
                    NEQ, OR, XOR, AND, SUBSCRIPT, CAT, SLICE, SEQ}) then
    for i = 2 to length(expr) do
      check_expr(expr[i])
    end for

  elsif decl = SYNTAX_ERROR then
    -- {SYNTAX_ERROR, pos, len, "message"}
    check_result &= expr[2..4]
  
  end if
end procedure

-- scan "name" at pos for redefinitions
procedure check_redefinition(sequence name, integer pos)
  integer cache_idx = cur_ast[1]
  sequence ast = cache[cache_idx]
  sequence entries = map:get(maps[cache_idx], name, {})

  for i = 1 to length(entries) do
    object d = entries[i]
    if atom(d) then
      sequence s = ast[d]
      -- d: ast-index (func/proc/type/enum-type)
      if not cur_sub then
        integer n = prefixed(s)
        if not find(s[n+1], {FUNC_DECL, PROC_DECL, TYPE_DECL, ENUM_DECL}) then
          printf(1, "%s %d %d\n", {name, s[n+1], d})
          ? entries
        elsif n+3 <= length(s) and s[n+3] < pos then
          check_result &= {pos, length(name), "attempt to redefine '"&name&"'"}
          return
        end if
      end if
    elsif d[2] < pos then
      -- d: {ast-index, pos, scope-start, [scope-end]}
      sequence s = ast[d[1]]
      integer top_level = 1
      integer n = prefixed(s)
      if find(s[n+1], {FUNC_DECL, PROC_DECL, TYPE_DECL}) and s[n+3] != d[2] then
        top_level = 0
      end if
      if cur_sub != top_level and decl_check(ast, d, pos, FILTER_LOCAL) then
        check_result &= {pos, length(name), "attempt to redefine '"&name&"'"}    
        return
      end if
    end if
  end for
end procedure

procedure check_include(sequence s, integer filter)
  integer n = s[1] != INCLUDE
  integer cache_idx = s[n+2]
  integer cur_idx = find(cache_idx, cur_ast)
  object ns = 0
  if n+4 <= length(s) and and_bits(filter, FILTER_EXPORT) then
    ns = s[n+4]  -- namespace
  end if
  if cur_idx then
    cur_scope[cur_idx] = or_bits(cur_scope[cur_idx], filter)
    if not atom(ns) then
      cur_namespace[cur_idx] = ns
    end if
    return
  end if
  check_cache_timestamp(cache_idx)
  cur_ast = append(cur_ast, cache_idx)
  cur_scope = append(cur_scope, filter)
  cur_namespace = append(cur_namespace, ns)
  
  sequence ast = cache[cache_idx]
  for i = 3 to length(ast) do
    s = ast[i]
    if s[1] = INCLUDE then
      if and_bits(filter, FILTER_LOCAL) then
        check_include(s, FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT)
      else
        check_include(s, FILTER_GLOBAL)
      end if
    elsif s[1] = PUBLIC and s[2] = INCLUDE then
      if and_bits(filter, FILTER_LOCAL) then
        check_include(s, FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT)
      else
        check_include(s, and_bits(filter, FILTER_GLOBAL+FILTER_PUBLIC))
      end if
    end if
  end for
end procedure

procedure check_ast(sequence ast, integer start_idx)

  for j = start_idx to length(ast) do
    sequence s = ast[j]
    integer n = prefixed(s)
    integer decl = s[n+1]

    if decl = INCLUDE then
      -- {INCLUDE, includes-idx, scope-start, ["namespace"]}
      --check_include(s, FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT)

    elsif decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      sequence args = s[n+4]
      check_redefinition(s[n+2], s[n+3])
      cur_sub = 1
      for i = 1 to length(args) do
        check_redefinition(args[i][2], args[i][3])
        if length(args[i]) >= 5 then
          check_expr(args[i][5])
        end if
      end for
      check_ast(s, n+7)
      cur_sub = 0

    elsif decl = PROC then
      -- {PROC, "name", pos, [args...]}
      check_proc(s[n+2], s[n+3])
      for i = n+4 to length(s) do
        check_expr(s[i])
      end for

    elsif decl = VAR_DECL then
      -- {VAR_DECL, "type", pos, {"name", pos, scope-start, [expr]}...}
      check_type(s[n+2], s[n+3])
      for i = n+4 to length(s) do
        check_redefinition(s[i][1], s[i][2])
        if length(s[i]) >= 4 then
          check_expr(s[i][4])
        end if
      end for
      
    elsif decl = CONST_DECL then
      -- {CONST_DECL, {"name", pos, scope-start, expr}... }
      for i = n+2 to length(s) do
        check_redefinition(s[i][1], s[i][2])
        check_expr(s[i][4])
      end for
      
    elsif decl = WHILE then
      -- {WHILE, expr, scope-start, scope-end, stmts...}
      check_expr(s[n+2])
      check_ast(s, n+5)
      
    elsif decl = IF then
      -- {IF, expr, {scope-start, scope-end, stmts...}, 
      --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
      --     [{scope-start, scope-end, else-stmts...}]}
      for i = n+2 to length(s) by 2 do
        if i = length(s) then
          check_ast(s[i], 3)
        else
          check_expr(s[i])
          check_ast(s[i+1], 3)
        end if
      end for

    elsif decl = FOR then
      -- {FOR, "name", pos, expr, expr, by, scope-start, scope-end, stmts...}
      check_redefinition(s[n+2], s[n+3])
      check_expr(s[n+4]) -- first
      check_expr(s[n+5]) -- last
      check_expr(s[n+6]) -- by
      check_ast(s, n+9)

    elsif decl = ENUM_DECL then
      -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
      --             {"name", pos, scope-start, [expr]}...}
      if length(s[n+2]) then
        check_redefinition(s[n+2], s[n+3])
      end if
      check_expr(s[n+5])
      for i = n+6 to length(s) do
        check_redefinition(s[i][1], s[i][2])
        if length(s[i]) >= 4 then
          check_expr(s[i][4])
        end if
      end for

    elsif decl = SWITCH then
      -- {SWITCH, expr, bool-fallthru, label-string,
      --   [{case-values...}, {scope-start, scope-end, stmts...},]... }
      --  ("case else" will have case-values={} )
      check_expr(s[n+2])
      for i = n+6 to length(s) by 2 do
        check_ast(s[i], 3)
      end for

    elsif find(decl, {ASSIGN, SUB_ASSIGN, SUB_ADDTO, SUB_SUBTO, SUB_MULTO,
                      SUB_DIVTO, SUB_CATTO, SLICE_ASSIGN, SLICE_ADDTO,
                      SLICE_SUBTO, SLICE_MULTO, SLICE_DIVTO, SLICE_CATTO}) then
      -- {ASSIGN, "name", pos, expr}
      -- {SUB_ASSIGN, "name", pos, index-expr..., expr}
      -- {SLICE_ASSIGN, "name", pos, index-expr..., start-expr, end-expr, expr}
      check_var(s[n+2], s[n+3])
      for i = n+4 to length(s) do
        check_expr(s[i])
      end for

    elsif decl = SEQ_ASSIGN then
      -- {SEQ_ASSIGN, ["name1", pos1,]... expr}
      for i = n+2 to length(s)-1 by 2 do
        check_var(s[i], s[i+1])
      end for
      check_expr(s[$])
      
    elsif decl = QPRINT then
      check_expr(s[2])

    elsif decl = SYNTAX_ERROR then
      -- {SYNTAX_ERROR, pos, len, "message"}
      check_result &= s[2..4]
    end if

  end for
end procedure

-- returns sequence of error positions, lengths, and messages:
--  {pos1, len1, msg1, pos2, len2, msg2, ...}
global function parse_errors(sequence source_text, sequence file_name)
  integer cache_idx
  sequence result, ast

  file_name = canonical_path(file_name, 0, CORRECT)
  ast = parse(source_text, file_name)
  cache_idx = cache_entry(file_name)
  cur_ast = {}
  cur_scope = {}
  cur_namespace = {}
  -- check includes up front, so forward references work
  check_include({INCLUDE, cache_idx}, FILTER_ALL)
  check_ast(ast, 3)
  result = check_result
  cur_ast = {}
  cur_scope = {}
  cur_namespace = {}
  check_result = {}
  return result
end function
