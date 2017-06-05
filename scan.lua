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
        return TOK_ID, s, e
      end
    end
    e = e + 1
    return TOK_ID, s, e
  else 
    e = e + 1
    return TOK_NIL, s, e
  end
end

function nodtoa(kind)
  local names = {
    "NIL",
    "NUM",
    "INT",
    "SYM",
    "BOL",
    "ID",
    "VAR",
    "DEF",
    "FUN",
    "SET",
    "IF",
    "LT",
    "GT",
    "EQ",
    "ADD",
    "SUB",
    "MUL",
    "DIV",
    "MOD",
    "AND",
    "OR",
    "NOT",
    "PRN",
    "PRB"
  }
  return names[kind]
end

function node_dump(root, str)
  local stack = {}
  local indent = 0
  local node
  stack[1] = root
  ::continue::
  while #stack > 0 do
    node = table.remove(stack)
    if node == 1 then
      table.remove(stack)
      indent = indent - 1
      goto continue
    end
    for i = 1, indent do
      io.write(' ')
    end
    if node.kind == NOD_NIL or
      node.kind == NOD_NUM or
      node.kind == NOD_SYM or
      node.kind == NOD_ID then
      io.write(string.format("%d %d ", node.tok.start, node.tok.ending))
    elseif node.kind == NOD_INT then
      -- after semantic
    elseif node.kind == NOD_BOL then
      -- after semantic
    elseif node.kind == NOD_VAR then
      -- after semantic
    elseif node.kind == NOD_DEF then
      -- after semantic
    end
    io.write(string.format("%s%s%s %s%s%s\n", COL_GREEN, nodtoa(node.kind), COL_RST, COL_MAGENTA, node, COL_RST))
    local size = 0
    local later = node.front
    while true do
      if later == nil then
        break
      end
      size = size + 1
      later = later.later
    end
    stack[#stack + 1] = node
    stack[#stack + 1] = 1
    node = node.front
    for i = #stack + size, #stack + 1, -1 do
      stack[i] = node
      node = node.later
    end
    indent = indent + 1
  end
end

function semantic(parent)
  local node = parent.front
  if node == nil then
    return 1
  elseif node.kind == NOD_NIL then
    if semantic(node) or variables(node.later) then
      return 1
    end
    parent.kind = NOD_FUN
    return 0
  elseif node.kink == NOD_NUM then
    return 1
  elseif node.kind == NOD_SYM then
    return 1
  elseif node.kind == NOD_ID then
    
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
  node.tok = {}
  node.tok.start = s
  node.tok.ending = e
  node.tok.id = tok
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
  local tok, s = scan(str, start)  -- peek
  if tok == TOK_LP then
    start, err = fetch(str, start, TOK_LP, parent, NOD_NIL)
    if err then
      return start, 1
    end
    local node = parent.back
    while true do
      tok, s = scan(str, start) --peek
      if tok == TOK_RP then
        break
      end
      if tok == TOK_LP then
        start, err = parse(str, start, node)
        if err then
          return start, 1
        end
      elseif tok == TOK_NUM then
        start, err = fetch(str, start, TOK_NUM, node, NOD_NUM)
        if err then
          return start, 1
        end
      elseif tok == TOK_SYM then
        start, err = fetch(str, start, TOK_SYM, node, NOD_SYM)
        if err then
          return start, 1
        end
      elseif tok == TOK_ID then
        start, err = fetch(str, start, TOK_ID, node, NOD_ID)
        if err then
          return start, 1
        end
      else
        syntax_error()
        return start, 1
      end
    end
    start, err = match(str, start, TOK_RP)
    if err then
      return start, 1
    end
    return start, nil
  elseif tok == TOK_EOF then
    return start, nil
  else 
    syntax_error()
    return start, 1
  end
end

function start()
  local start = 1
  local ret = 1
  local file  
  local str
  local parent = {}
  parent.parent = nil
  parent.front = nil
  parent.back = nil
  parent.kind = NOD_NIL
  parent.tok = {}
  parent.tok.start = 0
  parent.tok.ending = 1
  parent.tok.id = TOK_NIL
  file = io.open('test.txt', r)
  if (file == nil) then
    goto exit
  end

  str = file:read("*all")
  str = str..'\0'
  while scan(str, start) ~= TOK_EOF do
    local s, err = parse(str, start, parent)
    if err then
      goto close_file
    end
    start = s
  end
  node_dump(parent, str)
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
  local tok, s, e = parse(str, start, parent)
  print(str:sub(s, e - 1), tok, s, e)
  start = e
until tok == tok_eof
]]--

