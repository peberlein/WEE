-- parser.e
-- 
-- Copyright (c) 2014 Pete Eberlein
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

constant 
    OE4 = 1, -- enable OpenEuphoria 4 syntax
    ERROR_ABORT = 0, -- enable abort on errors?
    ERROR_PRINT = 0  -- enable printing errors?
sequence defined_words
defined_words = {"OE", "OE4"}
if platform() = WIN32 then
  defined_words &= {"WINDOWS"}
elsif platform() = LINUX then
  defined_words &= {"LINUX"}
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

-- ast node types that are not opcodes
global constant
  VAR_DECL = 256, -- {VAR_DECL, "type", {"name", pos, scope-start, [expr]}...}
  ASSIGN = 257,   -- {ASSIGN, "name", expr}
  FUNC = 258,     -- {FUNC, "name", [args...]}
  PROC = 259,     -- {PROC, "name", [args...]}
  VARIABLE = 260,
  SUBSCRIPT = 261, -- {SUBSCRIPT, expr, index-expr}
  SLICE = 262,     -- {SLICE, expr, start-expr, end-expr}
  CONST_DECL = 263, -- {CONST_DECL, {"name", pos, scope-start, expr}... }
  CAT = 264,
  RETURN = 265, -- {RETURN, [expr]}
  EXIT = 266,   -- {EXIT}
  SEQ = 267,    -- {SEQ, [expr,]...}
  INTEGER = 268,
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
  ADDTO = 277,     -- {ADDTO, "name", expr}
  SUBTO = 278,
  MULTO = 279,
  DIVTO = 280,
  CATTO = 281,
  STRING = 282,
  SUB_ASSIGN = 283, -- {SUB_ASSIGN, {index-expr...}, expr}
  SUB_ADDTO = 294,
  SUB_SUBTO = 295,
  SUB_MULTO = 296,
  SUB_DIVTO = 297,
  SUB_CATTO = 298,
  SLICE_ASSIGN = 299, -- {SLICE_ASSIGN, [index-expr...], start-expr, end-expr, expr}
  SLICE_ADDTO = 300,
  SLICE_SUBTO = 301,
  SLICE_MULTO = 302,
  SLICE_DIVTO = 303,
  SLICE_CATTO = 304,
  SEQ_LEN = 305, -- {SEQ_LEN}, shorthand for length of enclosing sequence
  ENUM_DECL = 306, -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
                  --             {"name", pos, scope-start, [expr]}...}
  INCLUDE = 307, -- {INCLUDE, includes-idx, ["namespace"]}
  GLOBAL = 308,    -- {GLOBAL, decl...}
  PUBLIC = 309,    -- {PUBLIC, decl...}
  EXPORT = 310,    -- {EXPORT, decl...}
  NAMESPACE = 311, -- {NAMESPACE, "name"}
  IFDEF = 312,     -- same layout as IF
  ELSEDEF = 313,
  SWITCH = 314,  -- {SWITCH, expr, bool-fallthru, label-string,
                 --   [{case-values...}, {scope-start, scope-end, stmts...},]... }
                 --  ("case else" with have case-values={} )
  BREAK = 315,    -- {BREAK, [label-string]}
  CONTINUE = 316, -- {CONTINUE, [label-string]}
  DEFAULT = 317,  -- {DEFAULT}, used for default arguments in subroutine calls
  ENTRY = 318,    -- {ENTRY}, used with while loops
  GOTO = 319      -- {GOTO, "label"}

global constant ast_names = { "var_decl", "assign", "func", "proc", "variable",
"subscript", "slice", "const_decl", "not", "mul", "div", "add", "sub",
"cat", "lt", "gt", "lte", "gte", "eq", "neq", "and", "or", "xor",
"seq", "integer", "while", "if", "for", "proc", "func_decl",
"proc_decl", "elsif", "else", "qprint", "addto", "subto", 
"multo", "divto", "catto", "string" }

sequence cache
-- { {"path", timestamp, stmts...} ...}
cache = {}

sequence types

sequence keywords
keywords = {"global", "function", "procedure", "type", "end", "if", "then",
            "else", "elsif", "for", "to", "by", "while", "do", "include", 
            "with", "without"}
if OE4 then
  keywords &= {"enum", "label", "break", "case", "fallthru", "routine"}
  -- "namespace" is not a reserved word, since it can be used as an identifier
end if

-- returns text from file, else -1
function read_file(sequence filename)
  integer f
  object line
  sequence text

  f = open(filename, "rb")
  if f = -1 then
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

sequence text, source_filename, tok
text = ""
source_filename = "<none>"
tok = ""

integer idx, tok_idx, ifdef_ok
idx = 1
tok_idx = 1


-- prints an error message indicated at tok_idx
procedure error(sequence msg)
  integer line, start
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
    error("expected '" & try & "', saw '"&tok&"'")
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
  integer c
  c = text[idx]
  if c = '\n' or c = '\r' then
    error("unterminated character literal")
  end if
  idx += 1
  if c = '\\' then
    if idx <= length(text) then
      c = escape_character(text[idx])
      idx += 1
    end if
  end if
  if idx > length(text) then
    error("unexpected end of file")
  end if
  if text[idx] != '\'' then
    tok_idx = idx
    error("expected '''")
  end if
  idx += 1
  return c
end function

function filename()
  sequence s
  s = ""
  skip_whitespace()
  while idx <= length(text) and not find(text[idx], "\t\r\n ") do
    s &= text[idx]
    idx += 1
  end while
  return s
end function



constant 
  SLASH = '/' + ('\\' - '/') * (platform() = WIN32),
  DOTDOT = SLASH & ".." & SLASH

function get_path_directory(sequence path)
  for i = length(path) to 1 by -1 do
    if path[i] = '\\' or path[i] = '/' then
      return path[1..i]
    end if
  end for
  return ""
end function

function get_basename(sequence path)
  for i = length(path)-1 to 1 by -1 do
    if path[i] = '\\' or path[i] = '/' then
      return path[i+1..$]
    end if
  end for
  return ""
end function


sequence include_dir
constant cmd = command_line()
include_dir = get_path_directory(cmd[1])
if equal(get_basename(include_dir), "bin" & SLASH) then
    include_dir = include_dir[1..$-4]
end if
include_dir &= "include" & SLASH

function convert_path_separators(sequence filename)
  integer x

  -- convert path separators
  for i = 1 to length(filename) do
    if filename[i] = '/' or filename[i] = '\\' then
      filename[i] = SLASH
    end if
  end for
  -- remove "dir/../" patterns
  x = match(DOTDOT, filename)
  while x do
      for i = x - 1 to 1 by -1 do
          if filename[i] = SLASH then
              filename = filename[1..i] & filename[x+4..$]
              exit
          end if
      end for
      x = match(DOTDOT, filename)
  end while
  return filename
end function


-- returns a unique timestamp for filename, or -1 if doesn't exist
global function get_timestamp(sequence filename)
  object info
  info = dir(filename)
  if atom(info) or length(info) = 0 or length(info[1]) < 9 then
    return -1
  end if
  info = info[1]
  -- timestamp is meaningless (unlike seconds since epoch)
  -- just needs to be unique so we can tell if a file was changed.
  -- there will be gaps since not all months have 31 days.
  return info[D_SECOND] + 60 * (
         info[D_MINUTE] + 60 * (
         info[D_HOUR] + 24 * (
         info[D_DAY] + 31 * (
         info[D_MONTH] + 12 *
         info[D_YEAR]))))
end function

--function uppercase(sequence s)
--  for i = 1 to length(s) do
--    if s[i] >= 'a' and s[i] <= 'z' then
--      s[i] += 'A'-'a'
--    end if
--  end for
--  return s
--end function

-- returns index of new/existing cache entry, or -1 if not found
function cache_entry(sequence filename)
  object tmp

  for i = 1 to length(cache) do
    if equal(cache[i][1], filename) then
      return i
    end if
  end for
  cache = append(cache, {filename, 0})
  return length(cache)
end function

-- returns -1 if not found, 
-- or positive integer if cache entry exists and is unchanged
-- or sequence "state" to be passed to end_include
function include_file(sequence filename)
  sequence state, tmp
  integer i
  atom ts

  filename = convert_path_separators(filename)
  tmp = get_path_directory(source_filename) & filename
  ts = get_timestamp(tmp)
  if ts = -1 then
    -- TODO: get EUDIR environment variable
    -- tmp = get_env("EUDIR") & filename
    -- ts = get_timestamp(tmp)
  end if
  if ts = -1 then
    tmp = filename
    ts = get_timestamp(tmp)
  end if
  if ts = -1 and match(include_dir, filename) = 0 then
    tmp = include_dir & filename
    ts = get_timestamp(tmp)
  end if
  if ts = -1 then 
    return -1 -- file not found
  end if

  filename = tmp
  i = cache_entry(filename)
  if cache[i][2] = ts then
     return i -- file unchanged
  end if
  cache[i][2] = ts

  state = {text, source_filename, idx, tok_idx, tok, i}
  -- TODO: need to check other paths for include files
  source_filename = filename
  text = read_file(filename)
--printf(1, "including %s, length %d\n", {source_filename, length(text)})
  idx = 1
  tok_idx = 1
  tok = ""
  return state
end function

function end_include(sequence state, sequence ast)
  -- restore the previous state
  text = state[1]
  source_filename = state[2]
  idx = state[3]
  tok_idx = state[4]
  tok = state[5]
  -- store the included ast
  cache[state[6]] &= ast[3..$]
--printf(1, "end_include %s, ast length %d\n", {cache[state[6]][1], length(ast)})
  return state[6]
end function


function to_integer(sequence s)
  atom x
  integer base, start

  x = 0
  base = 10
  start = 1

  if s[1] = '#' then
    base = 16
    start = 2
  elsif OE4 and length(s) >= 2 and s[1] = '0' then
    if s[2] = 'b' then
      base = 2
      start = 2
    elsif s[2] = 'x' then
      base = 16
      start = 2
    elsif s[2] = 'o' then
      base = 8
      start = 2
    end if
  end if

  for i = start to length(s) do
    if s[i] != '_' then
      x = x * base + s[i] - '0'
      if s[i] >= 'A' then
        x += 10 - 'A'
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
    e = {VARIABLE, get_token()}
    --printf(1, "identifier %s\n", {e[2]})
    if token("(") then
      -- function call
      if not token(")") then
        e[1] = FUNC
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
    error("expected expression")
  elsif length(tok) and (isnum(tok[1]) or tok[1] = '#' or tok[1] = '.') then
    e = {INTEGER, to_integer(get_token())}
  elsif token("-") then
    e = {NEG, expr(depth)}
    if e[2][1] = INTEGER then
      e = {INTEGER, -e[2][2]}
    end if
  elsif token("+") then
    e = expr(depth)
  elsif token("\"") then
    e = {STRING, string_literal()}
  elsif OE4 and token("`") then
    e = {STRING, multiline_string_literal()}
  elsif token("'") then
    e = {INTEGER, character_literal()}
  elsif token("$") then
    e = {SEQ_LEN}
  else
    error("expected expression  tok="&tok)
    e = {}
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
  result = {VAR_DECL, get_token()}
  while identifier() do
    tmp = {get_token(), tok_idx, 0}
    if OE4 and token("=") then
      tmp = append(tmp, expr(1))
    end if
    tmp[3] = tok_idx -- scope-start
    result = append(result, tmp)
    if not token(",") or (OE4 and token("$")) then
      return result
    end if
  end while

  tok = result[2]
  idx = save_idx
  return {}
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
  error("expected constant name")
  return result
end function

function assignment_or_procedure_call()
  sequence result, ops
  integer ok

  if not identifier() then
    return {}
  end if
  
  result = {0, get_token()}
  if token("(") then
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
  end if
  if token("[") then
    ops = {SUB_ASSIGN, SUB_ADDTO, SUB_SUBTO, SUB_MULTO, SUB_DIVTO, SUB_CATTO}
    tok = "["
    result &= {{}}
    while token("[") do
      result[3] = append(result[3], expr(1))
      if token("..") then
        result[3] = append(result[3], expr(1))
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
    return {}
  end if
  return append(result, expr(1))
end function

function subroutine_declaration(integer subroutine)
  sequence result, args, tmp
  if not identifier() then
    error("expected subroutine name")
  end if
  result = {subroutine, get_token(), tok_idx}
  expect("(")
  args = {}
  while not token(")") do
    if length(args) and not token(",") then
      error("expected ',' or ')'")
    end if
    if identifier() then
      tmp = {get_token(), 0, 0, 0}
    else
      error("expected type name")
      exit
    end if
    if identifier() then
      tmp[2] = get_token()
      tmp[3] = tok_idx
    else
      error("expected argument name")
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

  result = {ENUM_DECL, "", 0, '+', {INTEGER, 1}}
  if token("type") then
    if identifier() then
      result[2] = get_token()
      result[3] = tok_idx
      types = append(types, result[2])
    else
      error("expected enum type name")
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
    tmp[3] = tok_idx
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
    if not identifier() then
      error("expected for variable name")
    end if
    result = {FOR, get_token(), tok_idx}
    expect("=")
    result = append(result, expr(1))
    expect("to")
    result = append(result, expr(1))
    if token("by") then
      result = append(result, expr(1))
    else
      result = append(result, {INTEGER, 1})
    end if
    if OE4 and token("label") then
        if token("\"") and length(string_literal()) then
        else
            error("expected label string")
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
    if token("(") then
      while tok_idx < length(text) and not token(")") do
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
    error("unknown without option")
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
      error("end was not expected here")
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
            error("expected label string")
        end if
      end if
      expect("do")
      s &= statements(WHILE, sub)
      expect("while")

    elsif OE4 and token("entry") then
      s = {ENTRY}

    elsif token("for") then
      s = for_declaration()
      s &= statements(FOR, sub)
      expect("for")

    elsif token("exit") then
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
      if not identifier() then error("expected identifier") end if
      saved_ifdef_ok = ifdef_ok
      ifdef_ok = ifdef_reduce(expr(1)) and saved_ifdef_ok
      expect("then")
      s = choose(ifdef_ok, statements(IFDEF, sub), {})
      while token("elsifdef") do
        if not identifier() then error("expected identifier") end if
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
            error("expected label string")
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
        if sequence(state) then
          --s = source_filename
          --printf(1, "start parsing %s\n", {s})
          state = end_include(state, statements(NONE, 0))
          --printf(1, "done parsing %s, state=%d\n  resuming %s\n", {s, state, source_filename})
        end if
        s = {INCLUDE, state}
      end if
      if prefix = PUBLIC then
        --puts(1, "public include next_token="&tok&"\n")
        s = PUBLIC & s
        prefix = 0
      end if
      if OE4 and token("as") then
        if not identifier() then error("expected identifier") end if
        s = append(s, get_token())
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
      types = append(types, s[2])
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
  end while
  if mode != NONE and idx > length(text) then
    error("unexpected end of input")
  end if
  ast[2] = idx -- scope-end
  return ast
end function

global function parse(sequence source_text, sequence file_name)
  integer i
  sequence ast

  i = cache_entry(file_name)

  source_filename = file_name
  text = source_text
  idx = 1
  tok_idx = 1
  tok = ""
  types = {
    "object",
    "integer",
    "atom",
    "sequence"
  }
  ifdef_ok = 1

  ast = statements(NONE, 0)
  cache[i] = cache[i][1..2] & ast[3..$]
  return ast
end function

global function parse_file(sequence filename)
  return parse(read_file(filename), filename)
end function

-- during get_decls we might need to reparse a file if its timestamp changed
procedure check_cache_timestamp(integer idx)
    sequence ast, filename
    atom ts
    filename = cache[idx][1]
    ts = get_timestamp(filename)
    if cache[idx][2] != ts then
        cache[idx][2] = ts
        ast = parse_file(filename)
        ast[1] = filename
        ast[2] = ts
        cache[idx] = ast
    end if
end procedure


sequence include_ids, include_flags
constant
  FILTER_LOCAL = 1,
  FILTER_GLOBAL = 2,
  FILTER_PUBLIC = 4,
  FILTER_EXPORT = 8,
  FILTER_INCLUDE = 16,
  FILTER_INCLUDE_AS = 32,
  FILTER_ALL = 63



  
function get_include_filter(sequence s, sequence namespace, integer filter, integer prefix)
    integer idx, include_filter

    idx = s[2] -- cache[] index
    if length(namespace) then
      --if length(s) >= 3 then
      --    printf(1, "filter=%x namespace=%s include as %s\n", {filter, namespace, s[3]})
      --end if
      if and_bits(filter, FILTER_INCLUDE_AS) and length(s) >= 3 and equal(s[3], namespace) then
        -- top-level and matched "include as"
        include_filter = FILTER_GLOBAL + FILTER_PUBLIC + FILTER_EXPORT
      elsif and_bits(filter, FILTER_PUBLIC) and prefix = FILTER_PUBLIC then
        -- a public include from nested include
        include_filter = FILTER_GLOBAL + FILTER_PUBLIC
      elsif length(cache[idx]) >= 3 and 
            equal(cache[idx][3], {NAMESPACE, namespace}) then
        -- include has same namespace
        include_filter = FILTER_GLOBAL + FILTER_PUBLIC * (and_bits(filter, FILTER_LOCAL) != 0)
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
	
  
-- to prevent recursion, symbols may be included from a file
-- only once for each type of flag: global, public, export

-- namespace matches:
--  top-level file has same namespace
--  top-level file has include as same namespace
--  included file has same namespace
--  included file is publicly included by file with same namespace

-- get a list of declarations from ast in scope at pos
-- returns {"name1", pos1, "name2", pos2...}
--  pos may be be an integer for the position in the current file,
--  or {pos, "include-path"} for included files.

function get_decls(sequence ast, integer pos, sequence namespace, integer filter)
  sequence result, s
  integer x, decl, prefix, include_filter

  if length(namespace) and (length(ast) < 3 or not equal(ast[3], {NAMESPACE, namespace})) then
      filter = and_bits(filter, FILTER_INCLUDE)
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
    if and_bits(prefix, filter) = 0 then
      -- the scope modifier didn't pass the filter
      -- but we also need to check the include filter
      if decl != INCLUDE or and_bits(filter, FILTER_INCLUDE) = 0 then
        decl = 0
      end if
    end if

    if decl = NAMESPACE then
      -- {NAMESPACE, "namespace"}
      if and_bits(filter, FILTER_LOCAL) and length(namespace) and 
         length(s) >= 2 and not equal(namespace, s[2]) then
         -- namespace doesn't match
         filter = and_bits(filter, FILTER_INCLUDE + FILTER_INCLUDE_AS)
         if filter = 0 then
             return {}
         end if
      end if
    
    elsif decl = INCLUDE then
      -- {INCLUDE, includes-index, ["namespace"]}
      x = s[2]
      --printf(1, "include %s filter=%x\n", {cache[x][1], filter})
      if x != -1 then
        include_filter = get_include_filter(s, namespace, filter, prefix)
        if include_filter != -1 then
          check_cache_timestamp(x)
          s = get_decls(cache[x], 0, namespace, include_filter)
          --printf(1, "%s: %d\n", {cache[x][1], length(cache[x])})
          for j = 2 to length(s) by 2 do
            --printf(1, "%s: %d\n", {s[j-1], s[j]})
            if not sequence(s[j]) then
              s[j] = {cache[x][1], s[j]} -- is {filename, pos}
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
          result &= {s[j][1], s[j][2]}
        end if
      end for

    elsif decl = VAR_DECL then
      -- {VAR_DECL, "type", {"name", pos, scope-start, [expr]}...}
      --printf(1, s[2] & "\n", {})
      for j = 3 to length(s) do
        --printf(1, "  %s: %d\n", {s[j][1], s[j][2]})
        if length(s[j]) >= 3 and (pos >= s[j][3] or filter) then -- in scope?
          result &= {s[j][1], s[j][2]}
        end if
      end for

    elsif decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      if decl = FUNC_DECL then
        --printf(1, "function %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
      elsif decl = PROC_DECL then
        --printf(1, "procedure %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
      elsif decl = TYPE_DECL then
        --printf(1, "type %s: %d  scope=%d..%d\n", {s[2], s[3], s[5], s[6]})
      end if
      result &= {s[2], s[3]}
      if length(s) >= 6 and pos >= s[5] and pos <= s[6] then -- in scope?
        for j = 1 to length(s[4]) do -- display arguments
          if length(s[4][j]) >= 4 and pos >= s[4][j][4] then
            --printf(1, "  %s %s: %d\n", {s[4][j][1], s[4][j][2], s[4][j][3]})
            result &= {s[4][j][2], s[4][j][3]}
          end if
        end for
        result &= get_decls(s[5..$], pos, namespace, filter)
      end if

    elsif decl = FOR then
      -- {FOR, name, pos, expr, expr, by, scope-start, scope-end, stmts...}
      if length(s) >= 8 and pos >= s[7] and pos <= s[8] then -- in scope?
        --printf(1, "for %s: %d\n", {s[2], s[3]})
        result &= {s[2], s[3]}
        result &= get_decls(s[7..$], pos, namespace, filter)
      end if

    elsif decl = WHILE then
      -- {WHILE, expr, scope-start, scope-end, stmts...}
      if length(s) >= 4 and pos >= s[3] and pos <= s[4] then -- in scope?
        result &= get_decls(s[3..$], pos, namespace, filter)
      end if

    elsif decl = IF then
      -- {IF, expr, {scope-start, scope-end, stmts...}, 
      --     [expr, {scope-start, scope-end, elsif-stmts...},]... 
      --     [{scope-start, scope-end, else-stmts...}]}
      for j = 2 to length(s) by 2 do
        x = (j != length(s))
        if length(s[j+x]) >= 2 and pos >= s[j+x][1] and pos <= s[j+x][2] then -- in scope?
          result &= get_decls(s[j+x], pos, namespace, filter)
        end if
      end for

    elsif decl = ENUM_DECL then
      -- {ENUM_DECL, "typename"|"", pos, '+'|'-'|'*'|'/', expr,
      --             {"name", pos, scope-start, [expr]}...}
      if length(s[2]) then -- has typename
        result &= {s[2], s[3]}
      end if
      for j = 6 to length(s) do
        if length(s[j]) >= 3 and pos >= s[j][3] then -- in scope?
          result &= {s[j][1], s[j][2]}
        end if
      end for

    end if
  end for
  return result
end function

global function get_declarations(sequence ast, integer pos, sequence namespace)
  include_ids = {}
  include_flags = {}
  return get_decls(ast, pos, namespace, FILTER_ALL)
end function

global function get_subroutines(sequence ast)
  sequence result, s
  integer decl

  result = {}
  for i = 3 to length(ast) do
    s = ast[i]

    if find(s[1], {GLOBAL, PUBLIC, EXPORT}) then
      s = s[2..$] -- remove prefix      
    end if
    decl = s[1]

    if decl = FUNC_DECL or decl = PROC_DECL or decl = TYPE_DECL then
      -- {FUNC_DECL, "name", pos,
      --   {{"arg-type", "arg-name", pos, scope-start, [expr]}...}, 
      --    scope-start, scope-end, stmts...}
      result &= {s[2], s[3]}
    end if
  end for
  return result
end function

constant builtins = {
{"function", "abort", "integer", "errcode", 0},
{"function", "and_bits", "object", "a", 0, "object", "b", 0},
{"function", "append", "sequence", "target", 0, "object", "x", 0},
{"function", "arctan", "object", "tangent", 0},
{"type", "atom", "object", "x", 0},
{"function", "c_func", "integer", "rid", 0, "sequence", "args", 1},
{"procedure", "c_proc", "integer", "rid", 0, "sequence", "args", 1},
{"function", "call", "integer", "id", 0, "sequence", "args", 1},
{"function", "call_func", "integer", "id", 0, "sequence", "args", 1},
{"procedure", "call_proc", "integer", "id", 0, "sequence", "args", 1},
{"procedure", "clear_screen"},
{"procedure", "close", "atom", "fn", 0},
{"function", "command_line"},
{"function", "compare", "object", "compared", 0, "object", "reference", 0},
{"function", "cos", "object", "angle", 0},
{"function", "date"},
{"procedure", "delete", "object", "x", 0},
{"function", "delete_routine", "object", "x", 0, "integer", "rid", 0},
{"function", "equal", "object", "left", 0, "object", "right", 0},
{"function", "find", "object", "needle", 0, "sequence", "haystack", 0, "integer", "start", 1},
{"function", "floor", "object", "value", 0},
{"function", "get_key"},
{"function", "getc", "integer", "fn", 0},
{"function", "getenv", "sequence", "var_name", 0},
{"function", "gets", "integer", "fn", 0},
{"function", "hash", "object", "source", 0, "atom", "algo", 0},
{"function", "head", "sequence", "source", 0, "atom", "size", 1},
{"function", "include_paths", "integer", "convert", 0},
{"function", "insert", "sequence", "target", 0, "object", "what", 0, "integer", "index", 0},
{"type", "integer", "object", "x", 0},
{"function", "length", "object", "target", 0},
{"function", "log", "object", "value", 0},
{"function", "machine_func", "integer", "machine_id", 0, "object", "args", 1},
{"procedure", "machine_proc", "integer", "machine_id", 0, "object", "args", 1},
{"function", "match", "sequence", "needle", 0, "sequence", "haystack", 0, "integer", "start", 1},
{"procedure", "mem_copy", "atom", "destination", 0, "atom", "origin", 0, "integer", "len", 0},
{"procedure", "mem_set", "atom", "destination", 0, "integer", "byte_value", 0, "integer", "how_many", 0},
{"function", "not_bits", "object", "a", 0},
{"type", "object", "object", "x", 0},
{"function", "open", "sequence", "path", 0, "sequence", "mode", 0, "integer", "cleanup", 1},
{"function", "option_switches"},
{"function", "or_bits", "object", "a", 0, "object", "b", 0},
{"function", "peek", "object", "addr_n_length", 0},
{"function", "peek2s", "object", "addr_n_length", 0},
{"function", "peek2u", "object", "addr_n_length", 0},
{"function", "peek4s", "object", "addr_n_length", 0},
{"function", "peek4u", "object", "addr_n_length", 0},
{"function", "peek_string", "atom", "addr", 0},
{"function", "peeks", "object", "addr_n_length", 0},
{"function", "pixel"},
{"function", "platform"},
{"procedure", "poke", "atom", "addr", 0, "object", "x", 0},
{"procedure", "poke2", "atom", "addr", 0, "object", "x", 0},
{"procedure", "poke4", "atom", "addr", 0, "object", "x", 0},
{"procedure", "position", "integer", "row", 0, "integer", "column", 0},
{"function", "power", "object", "base", 0, "object", "exponent", 0},
{"function", "prepend", "sequence", "target", 0, "object", "x", 0},
{"procedure", "print", "integer", "fn", 0, "object", "x", 0},
{"procedure", "printf", "integer", "fn", 0, "sequence", "format", 0, "object", "values", 0},
{"procedure", "puts", "integer", "fn", 0, "object", "text", 0},
{"function", "rand", "object", "maximum", 0},
{"function", "remainder", "object", "dividend", 0, "object", "divisor", 0},
{"function", "remove", "sequence", "target", 0, "atom", "start", 0, "atom", "stop", 1},
{"function", "repeat", "object", "item", 0, "atom", "count", 0},
{"function", "replace", "sequence", "target", 0, "object", "replacement", 0, "integer", "start", 0, "integer", "stop", 1},
{"function", "routine_id", "sequence", "routine_name", 0},
{"type", "sequence", "object", "x", 0},
{"function", "sin", "object", "angle", 0},
{"function", "splice", "sequence", "target", 0, "object", "what", 0, "integer", "index", 0},
{"function", "sprintf", "sequence", "format", 0, "object", "values", 0},
{"function", "sqrt", "object", "value", 0},
{"procedure", "system", "sequence", "command", 0, "integer", "mode", 1},
{"function", "system_exec", "sequence", "command", 0, "integer", "mode", 1},
{"function", "tail", "sequence", "source", 0, "atom", "size", 1},
{"function", "tan", "object", "angle", 0},
{"procedure", "task_clock_start"},
{"procedure", "task_clock_stop"},
{"function", "task_create", "integer", "rid", 0, "sequence", "args", 0},
{"function", "task_list"},
{"function", "task_schedule", "atom", "task_id", 0, "object", "schedule", 0},
{"function", "task_self"},
{"function", "task_schedule", "atom", "task_id", 0},
{"function", "task_suspend", "atom", "task_id", 0},
{"function", "task_yield"},
{"function", "time"},
{"procedure", "trace", "integer", "mode", 0},
{"function", "xor_bits", "object", "a", 0, "object", "b", 0}
}

global function get_builtins()
  sequence s
  s = {}
  for i = 1 to length(builtins) do
    if i != 1 then s &= ' ' end if
    s &= builtins[i][2]
  end for
  return s
end function


-- returns {{"subroutine-type", "name", ["arg1-type", "arg1-name", is_default]... }... }
function get_args(sequence ast, sequence word, sequence namespace, integer filter)
  sequence result, s
  integer x, decl, prefix, include_filter

  if and_bits(filter, FILTER_INCLUDE) = 0 and length(namespace) and 
     length(ast) >= 3 and (ast[3][1] != NAMESPACE or not equal(namespace, ast[3][2])) then
     return {}  -- no namespace or mismatch
  end if

  result = {}
  for i = 3 to length(ast) do
    s = ast[i]

    prefix = power(2, find(s[1], {GLOBAL, PUBLIC, EXPORT}))
    if prefix > 1 then
      s = s[2..$] -- remove prefix      
    end if
    decl = s[1]
    if and_bits(filter, prefix) = 0 and s[1] != INCLUDE then
      decl = 0
    end if

    if decl = NAMESPACE then
      -- {NAMESPACE, "namespace"}
      if and_bits(filter, FILTER_LOCAL) and length(namespace) and 
         length(s) >= 2 and not equal(namespace, s[2]) then
        filter = 0  -- namespace doesn't match
      end if
    
    elsif decl = INCLUDE then
      -- {INCLUDE, includes-index, ["namespace"]}
      x = s[2]
      if x != -1 and and_bits(filter, FILTER_INCLUDE) then
        include_filter = get_include_filter(s, namespace, filter, prefix)
        if include_filter != -1 then
          result &= get_args(cache[x], word, namespace, include_filter)
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

-- returns {["subroutine-type", {["arg1-type", "arg1-name", has-default]...}, ]...}
global function get_subroutine_arguments(sequence ast, sequence word, sequence namespace)
  include_ids = {}
  include_flags = {}
  return get_args(ast, word, namespace, FILTER_ALL)
end function



-- returns {word, namespace, start, end} otherwise {""}
global function word_pos(sequence text, integer pos)
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


sequence suggested_includes, suggested_word, suggested_namespace

function walk_include(sequence path_name, sequence dirent)
    object state
    sequence decls

    path_name &= SLASH & dirent[D_NAME]
    if length(path_name) < 2 or (path_name[$] != 'e' and path_name[$] != 'E') or path_name[$-1] != '.' then
      -- path_name doesn't end with .e or .E
      return 0
    end if
    state = include_file(path_name)
    if sequence(state) then
        state = end_include(state, statements(NONE, 0))
    end if
    if state > 0 then
      decls = get_decls(cache[state], 0, suggested_namespace, 
                        FILTER_GLOBAL+FILTER_PUBLIC+FILTER_EXPORT)
      for i = 1 to length(decls) by 2 do
        if length(decls[i]) >= length(suggested_word) and 
           equal(decls[i][1..length(suggested_word)], suggested_word) then
          --puts(1, dirent[D_NAME]&" matched!\n")
          suggested_includes &= {decls[i] & " --include "&path_name[length(include_dir)+1..$], 0}
                                 -- {decls[i+1], cache[state][1]}} -- this needs work
        end if
      end for
    end if

    return 0 -- keep searching all files
end function

constant walk_include_id = routine_id("walk_include")

-- returns a list of include files which contain a declaration decl
global function suggest_includes(sequence word, sequence namespace)
  suggested_includes = {}
  suggested_word = word
  suggested_namespace = namespace
  --puts(1, "include_dir="&include_dir&"\n")
  if walk_dir(include_dir, walk_include_id, 1) then
  end if
  return suggested_includes
end function

-- parse argument expressions, returning the last argument position
global function parse_argument_position(sequence source_text)
  integer arg
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
    e = expr(1)
    --? {e, tok, tok_idx}
    if length(e) = 0 and length(tok) = 0 then
	return arg
    end if
  end for
  printf(1, "stuck parsing argument position for \"%s\"\n", {text})
  ? e
  ? tok
  return arg
end function

