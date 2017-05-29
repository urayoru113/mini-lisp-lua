require 'define'

function scan(str, s)
  -- s: start
  -- e: end

  -- ignore '\n', '\t', '\r', ' '
  local c = str:sub(s, s)
  local e
  while c == ' '  or
    c == '\t' or
    c == '\r' or
    c == '\n' do
    s = s + 1
    c = str:sub(s, s)
  end
  e = s

  if c >= '1' and c <= '9' then
    e = e + 1
    c = str:sub(e, e)
    while c >= '0' and
      c <= '9' do
      e = e + 1
      c = str:sub(e, e)
    end
    return TOK_NUM, s, e
  elseif c == '0' then
    e = e + 1
    c = str:sub(e, e)
    if c < '0' and
      c > '9' then
      return TOK_NUM, s, e
    else
      return TOK_NIL, s, e
    end
  elseif c == '#' then
    e = e + 1
    c = str:sub(e, e)
    if c == 't' or c == 'f' then
      e = e + 1
      c = str:sub(e, e)
      if not (c >= '0' and c <= '9' or
        c >= 'a' and c <= 'z' or
        c >= 'A' and c <= 'Z') then
        return TOK_SYM, s, e
      end
    end
    while c >= '0' and c <= '9' or
      c >= 'a' and c <= 'z' or
      c >= 'A' and c <= 'Z' do
      e = e + 1
      c = str:sub(e, e)
    end
    return TOK_NIL, s, e
  elseif c == '(' then
    e = e + 1
    return TOK_LP, s, e
  elseif c == ')' then
    e = e + 1
    return TOK_RP, s, e
  elseif c == '\0'  then
    e = e + 1
    return TOK_EOF, s, e
  elseif c >= 'a' and c <= 'z' or c >= 'A' and c <= 'Z' then
    e = e + 1
    c = str:sub(e, e)
    while c >= 'a' and c <= 'z' or
          c >= 'A' and c <= 'Z' or
          c >= '0' and c <= '9' or
          c == '-' do
      e = e + 1
          c = str:sub(e, e)
    end
    return TOK_ID, s, e 
  elseif c == '<' or
         c == '>' or
         c == '=' or
         c == '+' or
         c == '-' or
         c == '*' or
         c == '/' then
    if c == '-' then
      e = e + 1
      c = str:sub(e, e)
      if c >= '0' and c <= '9' then
        while c >= '0' and c <= '9' do
          e = e + 1
          c = str:sub(e, e)
        end
        return TOK_NUM, s, e
      else
        e = e + 1
        return TOK_ID, s, e
      end
      e = e + 1
      return TOK_ID, s, e 
    end
    e = e + 1
    return TOK_ID, s, e
  else 
    e = e + 1
    return TOK_NIL, s, e
  end
end

function fetch(str, start, id, parent, kind)
  local tok, s, e = scan(str, start)
  if tok ~= id then
    return s, 1
  end
  local node = {}
  node.parent = parent
  node.kind = kind
  if parent.front == nil then
    parent.front = node
    parent.back = node
  else
    parent.back.later = node
    parent.back = node
  end
  return e, nil
end

function match(str, start, expected)
  local actual, s, e = scan(str, start)
  if actual ~= expected then
    return start, 1
  end
  return e, nil
end

function syntax_error()
  print('hello world !')
end

function parse(str, start, parent)
  local tok, start = scan(str, start)  -- peek
  if tok == TOK_LP then
    start, err = fetch(str, start, TOK_LP, parent, NOD_NIL)
    if err then
      return 1
    end
    local node = parent.back
    tok, start = scan(str, start) --peek
    while tok ~= TOK_RP do
      if tok == TOK_LP then
        if parse(str, start, parent) then
          return 1
        end
      elseif tok == TOK_NUM then
        start, err = fetch(str, start, TOK_NUM, parent, NOD_NUM)
        if err then
          return 1
        end
      elseif tok == TOK_SYM then
        start, err = fetch(str, start, TOK_SYM, parent, NOD_SYM)
        if err then
          return 1
        end
      elseif tok == TOK_ID then
        start, err = fetch(str, start, TOK_ID, parent, NOD_ID)
        if err then
          return 1
        end
      else
        syntax_error()
        return 1
      end
      tok, start = scan(str, start)
    end
    start, err = match(str, start, TOK_RP)
    if err then
      return 1
    end
    return start, nil
  elseif tok == TOK_EOF then
    return start, nil
  else 
    syntax_error()
    return 1
  end
end

function start()
  local start = 1
  local ret = 1
  local file  
  local str
  local node = {}
  node.kind = TOK_NIL
  file = io.open('test.txt', r)
  if (file == nil) then
    goto exit;
  end

  str = file:read("*all")
  str = str..'\0'
  while scan(str, start) ~= TOK_EOF do
    local s, err =  parse(str, start, node)
    if err then
      goto close_file
    end
    start = s
  end

  ret = nil
  ::close_file::
  file:close()
  ::exit::
  return ret
end

os.exit(start())


--[[
local str = arg[1]..'\0'
local start = 1
repeat
  local tok, s, e = parse(str, start, node)
  print(str:sub(s, e - 1), tok, s, e)
  start = e
until tok == tok_eof
]]--

