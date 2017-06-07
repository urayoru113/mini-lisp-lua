require 'define'

function node_new(node)
  node.parent = nil
  node.front = nil
  node.back = nil
  node.later = nil
  node.kind = nil
  node.tok = {}
  node.tok.start = 0
  node.tok.ending = 1
  node.tok.id = nil
  node.val = {}
  node.val.i = nil
  node.val.v = {}
  node.val.d = {}
  node.val.v.env = nil
  node.val.v.off = nil
  node.val.d.arg = nil
  node.val.d.env = nil
end

function raise(tok, str, msg)
  io.write(string.format("error: %s    ----> %s\n",
                         msg, str:sub(tok.start, tok.ending - 1)))
end

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
  local node = {}
  node_new(node)
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
    if node.kind == NOD_NIL then
    elseif node.kind == NOD_NUM or
      node.kind == NOD_SYM or
      node.kind == NOD_ID then
      io.write(string.format("%s ", str:sub(node.tok.start, node.tok.ending - 1)))
    elseif node.kind == NOD_INT then
      io.write(string.format("%d ", node.val.i))
    elseif node.kind == NOD_BOL then
      io.write(string.format("%s ", node.val.i))
    elseif node.kind == NOD_VAR then
      io.write(string.format("(%d %d) ", node.val.v.env, node.val.v.off))
    elseif node.kind == NOD_DEF then
      local def = node.val.d;
      local i = 1;
      local len = 0;
      local string = "(";
      for k, v in pairs(def.args) do
        len = len + 1;
      end
      for k, v in pairs(def.args) do
        string = string .. tostring(v);
        if i < len then
          string = string .. " ";
        end
        i = i + 1;
      end
      io.write(string .. ") ");
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

function map_init(map, prev)
  map.prev = prev;
  map.set = {};
  map.set.len = 0;
end

function map_get(map, tok, var, str)
  local i = 0
  local sub = str:sub(tok.start, tok.ending - 1)
  while map ~= nil do
    if map.set[sub] then
      if var then
        var.env = i
        var.off = map.set[sub]
      end
      return 1;
    end
    map = map.prev
    i = i + 1
  end
  return nil
end

function map_set(map, tok, var, str)
  if map_get(map, tok, var, str) then
    return nil;
  end
  local sub = str:sub(tok.start, tok.ending - 1);
  map.set.len = map.set.len + 1;
  map.set[sub] = map.set.len;
  if var then
    var.env = 0;
    var.off = map.set.len;
  end
  return nil;
end

function unary(parent, prev, kind, str)
  local tok = parent.tok
  local node = parent.front
  if not node.later or not node.later.later then
    raise(tok, str, "the unary operation require one operand\n")
    return 1
  end
  if variables(node.later, prev, str) then
    return 1
  end
end

function binary(parent, prev, kind, multi, str)
  local tok = parent.tok
  local node = parent.front
  if not node.later or not node.later.later then
    raise(tok, str, "the binary operation require at less two operand\n")
    return 1
  end
  if not node.later.later.later and not multi then
    raise(tok, str, "the binary operation require only two operand\n")
    return 1
  end
  if variables(node.later, prev, str) then
    return 1
  end
  parent.kind = kind
  return nil
end

function variables(node, prev, str)
  while node ~= nil do
    if node.kind == NOD_NIL then
      if semantic(node, prev, str) then
        return 1
      end
    elseif node.kind == NOD_NUM then
      node.val.i = tonumber(str:sub(node.tok.start, node.tok.ending - 1))
      node.kind = NOD_INT
    elseif node.kind == NOD_SYM then
      node.val.i = str:sub(node.tok.start, node.tok.ending - 1) == "#t"
                   and 1 or 0
      node.kind = NOD_BOL
    elseif node.kind == NOD_ID then
      local var = {}
      var.env = 0
      var.off = 0
      if not map_get(prev, node.tok, var, str) then
        return 1
      end
      node.val.v = var
      node.kind = NOD_VAR
    end
    node = node.later
  end
  return nil
end

function tokcmp(tok_a, str_b, str)
  local sub = str:sub(tok_a.start, tok_a.ending - 1)
  return sub == str_b
end

function semantic(parent, prev, str)
  local node = parent.front
  local ptok = parent.tok
  if node == nil then
    raise(ptok, str, "empty list is not allowed\n")
    return 1
  elseif node.kind == NOD_NIL then
    if semantic(node, prev, str) or
      variables(node.later, prev, str) then
      return 1
    end
    parent.kind = NOD_FUN
    return nil
  elseif node.kind == NOD_NUM then
    raise(ptok, str, "integer is not a function\n")
    return 1
  elseif node.kind == NOD_SYM then
    raise(ptok, str, "boolen is not a function\n")
    return 1
  elseif node.kind == NOD_ID then
    local tok = node.tok
    if map_get(prev, tok, node.val.v, str) then
      if variables(node.later, prev, str) then
        node.kind = NOD_VAR
        parent.kind = NOD_FUN
        return 1
      end
      return nil
    elseif tokcmp(tok, "fun", str) then
      if node.later == nil then
        return 1
      end
      local arg = node.later.front
      while arg ~= nil do
        if arg.kind ~= NOD_ID then
          raise(arg.tok, str, "only named parameters are allowed\n")
          return 1
        end
        arg = arg.later
      end
      local map = {}
      map_init(map);
      local args = {}  -- array
      arg = node.later.front
      while arg ~= nil do
        local t = arg.tok
        if map_get(map, t, nil, str) then
          raise(t, str, "parameter names are duplicated\n")
          return 1
        end
        local v = {};
        map_set(map, t, v, str)
        args[#args + 1] = v.off
        arg = arg.later
      end
      map.prev = prev
      if variables(node.later.later, map, str) then
        return 1
      end
      local def = parent.val.d
      def.args = args
      def.env = #map.set
      parent.kind = NOD_DEF
      return nil
    elseif tokcmp(tok, "define", str) then
      local name = node.later
      if name.kind ~= NOD_ID then
        raise(ptok, str, "variable name is empty\n")
        return 1
      end
      local ntok = name.tok
      if name.kind ~= NOD_ID then
        raise(ntok, str, "variable name is not allowed\n")
        return 1
      end
      local value = name.later
      if not value then
        raise(ptok, str, "variable value is empty\n")
        return 1
      end
      if value.later ~= nil then
        raise(vtok, str, "multiple variable values is not allowed\n")
        return 1
      end
      map_set(prev, ntok, name.val.v, str)
      if variables(value, prev, str) then
        return 1
      end
      name.kind = NOD_VAR
      parent.kind = NOD_SET
      return nil
    elseif tokcmp(tok, "if", str) then
      local cond = node.later
      if not cond then
        raise(ptok, str, "the condition is empty\n")
        return 1
      end
      local if_stmt = cond.later
      if not if_stmt then
        raise(ptok, str, "the if-statment is empty\n")
        return 1
      end
      local else_stmt = if_stmt.later
      if not else_stmt then
        raise(ptok, str, "the else-statment is empty\n")
        return 1
      end
      if variables(cond, prev, str) then
        return 1
      end
      parent.kind = NOD_IF
      return nil
    elseif tokcmp(tok, "<", str) then
      return binary(parent, prev, NOD_LT, nil, str)
    elseif tokcmp(tok, ">", str) then
      return binary(parent, prev, NOD_GT, nil, str)
    elseif tokcmp(tok, "=", str) then
      return binary(parent, prev, NOD_ET, nil, str)
    elseif tokcmp(tok, "+", str) then
      return binary(parent, prev, NOD_ADD, 1, str)
    elseif tokcmp(tok, "-", str) then
      return binary(parent, prev, NOD_SUB, nil, str)
    elseif tokcmp(tok, "*", str) then
      return binary(parent, prev, NOD_MUL, 1, str)
    elseif tokcmp(tok, "/", str) then
      return binary(parent, prev, NOD_DIV, nil, str)
    elseif tokcmp(tok, "mod", str) then
      return binary(parent, prev, NOD_MOD, nil, str)
    elseif tokcmp(tok, "and", str) then
      return binary(parent, prev, NOD_AND, 1, str)
    elseif tokcmp(tok, "or", str) then
      return binary(parent, prev, NOD_OR, 1, str)
    elseif tokcmp(tok, "not", str) then
      return unary(parent, prev, NOD_NOT, str)
    elseif tokcmp(tok, "print-num", str) then
      if not node.later then
        raise(ptok, str, "the parameter of print-num is empty\n")
        return 1
      end
      if node.later.later then
        local vtok = node.later.later.tok
        raise(vtok, str, "only one parameter of print-num is allowed\n")
        return 1
      end
      if variables(node.later, prev, str) then
        return 1
      end
      parend.kind = NOD_PRN
      return nil
    elseif tokcmp(tok, "print-bol", str) then
      if not node.later then
        raise(ptok, str, "the parameter of print-bool is empty\n")
        return 1
      end
      if node.later.later then
        raise(vtok, str, "only one parameter of print-bool is allowed\n")
        return 1
      end
      if variables(node.later, prev, str) then
        return 1
      end
      parent.kind = NOD_PRB
      return nil
    else
      raise(tok, str, "variable %.*s undifined\n")
      return 1
    end
  else
    return 1
  end
end

function env_new(prev, ret, len)
  local env = {};
  local locs = {};
  for i = 1, len do
    locs[i] = {};
    locs[i].obj = {};
    locs[i].obj.kind = OBJ_NIL;
  end
  env.ret = ret;
  env.prev = prev;
  env.locs = locs;
  return env;
end

function env_add(env, len)
  if len <= #env.locs then
    return;
  end
  for i = #env.locs + 1, len do
    print(env.locs[i]);
    env.locs[i] = {};
    env.locs[i].obj = {};
    env.locs[i].obj.kind = OBJ_NIL;
  end
  return;
end

function env_get(env, var, obj)
  for i = 1, var.env do
    env = env.prev;
  end
  obj.kind = env.locs[var.off].obj.kind;
  obj.val = env.locs[var.off].obj.val;
end

function env_set(env, var, obj)
  for i = 1, var.env do
    env = env.prev;
  end
  env.locs[var.off].obj.kind = obj.kind;
  env.locs[var.off].obj.val = obj.val;
end

function env_dump(env, ret)
  local i = 0;
  while env do
    io.write(string.format("--- scope %d --- %s\n", i, tostring(env)));
    io.write(string.format("  variables size: %d\n", #env.locs));
    env = ret and env.ret or env.prev;
    i = i + 1;
  end
  io.write("----------------\n");
end

function fetch(str, start, id, parent, kind)
  local tok, s, e = scan(str, start)
  if tok ~= id then
    return s, 1
  end
  local node = {}
  node_new(node)
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
  local map = {}
  local node = {}
  local env;
  node_new(parent)
  parent.kind = NOD_NIL
  parent.tok.start = 0
  parent.tok.ending = 1
  parent.tok.id = TOK_NIL
  map_init(map);
  file = io.open('test-fun.lsp', r)
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
  node_new(node)
  node = parent.front
  env = env_new(nil, nil, 0);
  while node ~= nil do
    if semantic(node, map, str) or env_add(env, map.set.len) then
      return 1
    end
    node = node.later
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

