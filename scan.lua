require 'define'

function node_new(parent, kind)
  local node = {};
  node.parent = parent;
  node.kind = kind;
  node.front = nil;
  node.back = nil;
  node.later = nil;
  return node;
end

function raise(tok, str, msg)
  local line = 1;
  local start = 0;
  local ending = 1;
  local c = str:sub(ending, ending);
  while true do
    if ending == tok.start then
      while c ~= '\0' and c ~= '\n' do
        ending = ending + 1;
        c = str:sub(ending, ending);
      end
      break;
    end
    if c == '\0' then
      break;
    end
    if c == '\n' then
      start = ending;
      line = line + 1;
    end
    ending = ending + 1;
    c = str:sub(ending, ending);
  end
  io.write(string.format("In source file:%d:%d: error: %s%s\n", line, tok.start - start, msg, str:sub(start + 1, ending - 1)));
  for i = start + 1, tok.start - 1 do
    io.write(' ');
  end
  io.write("^-----\n");
end

function scan(str, s)
  -- s: start
  -- e: end

  -- ignore '\n', '\t', '\r', ' '
  local c = str:sub(s, s);
  local e;
  while c == ' '  or
    c == '\t' or
    c == '\r' or
    c == '\n' do
    s = s + 1;
    c = str:sub(s, s);
  end
  e = s;

  if c >= '1' and c <= '9' then
    e = e + 1;
    c = str:sub(e, e);
    while c >= '0' and
      c <= '9' do
      e = e + 1;
      c = str:sub(e, e);
    end
    return TOK_NUM, s, e;
  elseif c == '0' then
    e = e + 1;
    c = str:sub(e, e);
    if c < '0' or c > '9' then
      return TOK_NUM, s, e;
    else
      return TOK_NIL, s, e;
    end
  elseif c == '#' then
    e = e + 1;
    c = str:sub(e, e);
    if c == 't' or c == 'f' then
      e = e + 1;
      c = str:sub(e, e);
      if not (c >= '0' and c <= '9' or
        c >= 'a' and c <= 'z' or
        c >= 'A' and c <= 'Z') then
        return TOK_SYM, s, e;
      end
    end
    while c >= '0' and c <= '9' or
      c >= 'a' and c <= 'z' or
      c >= 'A' and c <= 'Z' do
      e = e + 1;
      c = str:sub(e, e);
    end
    return TOK_NIL, s, e;
  elseif c == '(' then
    e = e + 1;
    return TOK_LP, s, e;
  elseif c == ')' then
    e = e + 1;
    return TOK_RP, s, e;
  elseif c == '\0'  then
    e = e + 1;
    return TOK_EOF, s, e;
  elseif c >= 'a' and c <= 'z' or c >= 'A' and c <= 'Z' then
    e = e + 1;
    c = str:sub(e, e);
    while c >= 'a' and c <= 'z' or
          c >= 'A' and c <= 'Z' or
          c >= '0' and c <= '9' or
          c == '-' do
      e = e + 1;
      c = str:sub(e, e);
    end
    return TOK_ID, s, e;
  elseif c == '<' or
         c == '>' or
         c == '=' or
         c == '+' or
         c == '-' or
         c == '*' or
         c == '/' then
    if c == '-' then
      e = e + 1;
      c = str:sub(e, e);
      if c >= '0' and c <= '9' then
        while c >= '0' and c <= '9' do
          e = e + 1;
          c = str:sub(e, e);
        end
        return TOK_NUM, s, e;
      else
        return TOK_ID, s, e;
      end
    end
    e = e + 1;
    return TOK_ID, s, e;
  else 
    e = e + 1;
    return TOK_NIL, s, e;
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
  };
  return names[kind];
end

function node_dump(root, str)
  local stack = {};
  local indent = 0;
  local node;
  stack[1] = root;
  ::continue::
  while #stack > 0 do
    node = table.remove(stack);
    if node == 1 then
      table.remove(stack);
      indent = indent - 1;
      goto continue;
    end
    for i = 1, indent do
      io.write(' ');
    end
    if node.kind == NOD_NIL then
    elseif node.kind == NOD_NUM or
      node.kind == NOD_SYM or
      node.kind == NOD_ID then
      io.write(string.format("%s ", str:sub(node.tok.start, node.tok.ending - 1)));
    elseif node.kind == NOD_INT then
      io.write(string.format("%d ", node.val));
    elseif node.kind == NOD_BOL then
      io.write(string.format("%s ", tostring(node.val)));
    elseif node.kind == NOD_VAR then
      io.write(string.format("(%d %d) ", node.val.env, node.val.off));
    elseif node.kind == NOD_DEF then
      local def = node.val;
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
    elseif node.kind >= 9 or node.kind <= 24 then
    else
      print("? ");
    end
    io.write(string.format("%s%s%s %s%s%s\n", COL_GREEN, nodtoa(node.kind), COL_RST, COL_MAGENTA, node, COL_RST));
    local size = 0;
    local later = node.front;
    while true do
      if later == nil then
        break;
      end
      size = size + 1;
      later = later.later;
    end
    stack[#stack + 1] = node;
    stack[#stack + 1] = 1;
    node = node.front;
    for i = #stack + size, #stack + 1, -1 do
      stack[i] = node;
      node = node.later;
    end
    indent = indent + 1;
  end
end

function map_init(map, prev)
  map.prev = prev;
  map.set = {};
  map.set.len = 0;
end

function map_get(map, tok, var, str)
  local i = 0;
  local sub = str:sub(tok.start, tok.ending - 1);
  while map ~= nil do
    if map.set[sub] then
      if var then
        var.env = i;
        var.off = map.set[sub];
      end
      return 1;
    end
    map = map.prev;
    i = i + 1;
  end
  return nil;
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

function map_dump(map)
  local i = 0;
  while map do
    io.write(string.format("--- scope %d---\n", i));
    io.write(string.format("  variables: %s\n", map.set.len));
    map = map.prev;
    i = i + 1;
  end
end

function unary(parent, prev, kind, str)
  local tok = parent.tok;
  local node = parent.front;
  if not node.later or node.later.later then
    raise(tok, str, "the unary operation require one operand\n");
    return 1;
  end
  if variables(node.later, prev, str) then
    return 1;
  end
  parent.kind = kind;
  return nil;
end

function binary(parent, prev, kind, multi, str)
  local tok = parent.tok;
  local node = parent.front;
  if not node.later or not node.later.later then
    raise(tok, str, "the binary operation require at less two operand\n");
    return 1;
  end
  if node.later.later.later and not multi then
    raise(tok, str, "the binary operation require only two operand\n");
    return 1;
  end
  if variables(node.later, prev, str) then
    return 1;
  end
  parent.kind = kind;
  return nil;
end

function variables(node, prev, str)
  while node ~= nil do
    if node.kind == NOD_NIL then
      if semantic(node, prev, str) then
        return 1;
      end
    elseif node.kind == NOD_NUM then
      node.val = tonumber(str:sub(node.tok.start, node.tok.ending - 1));
      node.kind = NOD_INT;
    elseif node.kind == NOD_SYM then
      node.val = str:sub(node.tok.start, node.tok.ending - 1) == "#t";
      node.kind = NOD_BOL;
    elseif node.kind == NOD_ID then
      local tok = node.tok;
      local var = {};
      if not map_get(prev, tok, var, str) then
        raise(tok, str, string.format("variable %s is undefined\n", str:sub(tok.start, tok.ending - 1)));
        return 1;
      end
      node.val = var;
      node.kind = NOD_VAR;
    end
    node = node.later;
  end
  return nil;
end

function tokcmp(tok_a, str_b, str)
  local sub = str:sub(tok_a.start, tok_a.ending - 1);
  return sub == str_b;
end

function semantic(parent, prev, str)
  local node = parent.front;
  local ptok = parent.tok;
  if node == nil then
    raise(ptok, str, "empty list is not allowed\n");
    return 1;
  elseif node.kind == NOD_NIL then
    if semantic(node, prev, str) or
      variables(node.later, prev, str) then
      return 1;
    end
    parent.kind = NOD_FUN;
    return nil;
  elseif node.kind == NOD_NUM then
    raise(ptok, str, "integer is not a function\n");
    return 1;
  elseif node.kind == NOD_SYM then
    raise(ptok, str, "boolen is not a function\n");
    return 1;
  elseif node.kind == NOD_ID then
    local tok = node.tok;
    local var = {};
    if map_get(prev, tok, var, str) then
      if variables(node.later, prev, str) then
        return 1;
      end
      node.kind = NOD_VAR;
      node.val = var;
      parent.kind = NOD_FUN;
      return nil;
    elseif tokcmp(tok, "fun", str) then
      if node.later == nil then
        return 1;
      end
      local arg = node.later.front;
      while arg ~= nil do
        if arg.kind ~= NOD_ID then
          raise(arg.tok, str, "only named parameters are allowed\n");
          return 1;
        end
        arg = arg.later;
      end
      local map = {};
      map_init(map);
      local args = {};  -- array
      arg = node.later.front;
      while arg ~= nil do
        local t = arg.tok;
        if map_get(map, t, nil, str) then
          raise(t, str, "parameter names are duplicated\n");
          return 1;
        end
        local v = {};
        map_set(map, t, v, str);
        args[#args + 1] = v.off;
        arg = arg.later;
      end
      map.prev = prev;
      if variables(node.later.later, map, str) then
        return 1;
      end
      parent.val = {};
      parent.val.args = args;
      parent.val.env = map.set.len;
      parent.kind = NOD_DEF;
      return nil;
    elseif tokcmp(tok, "define", str) then
      local name = node.later;
      if name.kind ~= NOD_ID then
        raise(ptok, str, "variable name is empty\n");
        return 1;
      end
      local ntok = name.tok;
      if name.kind ~= NOD_ID then
        raise(ntok, str, "variable name is not allowed\n");
        return 1;
      end
      local value = name.later;
      if not value then
        raise(ptok, str, "variable value is empty\n");
        return 1;
      end
      if value.later then
        raise(vtok, str, "multiple variable values is not allowed\n");
        return 1;
      end
      local name_var = {};
      map_set(prev, ntok, name_var, str);
      if variables(value, prev, str) then
        return 1;
      end
      name.kind = NOD_VAR;
      name.val = name_var;
      parent.kind = NOD_SET;
      return nil;
    elseif tokcmp(tok, "if", str) then
      local cond = node.later;
      if not cond then
        raise(ptok, str, "the condition is empty\n");
        return 1;
      end
      local if_stmt = cond.later;
      if not if_stmt then
        raise(ptok, str, "the if-statment is empty\n");
        return 1;
      end
      local else_stmt = if_stmt.later;
      if not else_stmt then
        raise(ptok, str, "the else-statment is empty\n");
        return 1;
      end
      if variables(cond, prev, str) then
        return 1;
      end
      parent.kind = NOD_IF;
      return nil;
    elseif tokcmp(tok, "<", str) then
      return binary(parent, prev, NOD_LT, nil, str);
    elseif tokcmp(tok, ">", str) then
      return binary(parent, prev, NOD_GT, nil, str);
    elseif tokcmp(tok, "=", str) then
      return binary(parent, prev, NOD_EQ, nil, str);
    elseif tokcmp(tok, "+", str) then
      return binary(parent, prev, NOD_ADD, 1, str);
    elseif tokcmp(tok, "-", str) then
      return binary(parent, prev, NOD_SUB, nil, str);
    elseif tokcmp(tok, "*", str) then
      return binary(parent, prev, NOD_MUL, 1, str);
    elseif tokcmp(tok, "/", str) then
      return binary(parent, prev, NOD_DIV, nil, str);
    elseif tokcmp(tok, "mod", str) then
      return binary(parent, prev, NOD_MOD, nil, str);
    elseif tokcmp(tok, "and", str) then
      return binary(parent, prev, NOD_AND, 1, str);
    elseif tokcmp(tok, "or", str) then
      return binary(parent, prev, NOD_OR, 1, str);
    elseif tokcmp(tok, "not", str) then
      return unary(parent, prev, NOD_NOT, str);
    elseif tokcmp(tok, "print-num", str) then
      if not node.later then
        raise(ptok, str, "the parameter of print-num is empty\n");
        return 1;
      end
      if node.later.later then
        local vtok = node.later.later.tok;
        raise(vtok, str, "only one parameter of print-num is allowed\n");
        return 1;
      end
      if variables(node.later, prev, str) then
        return 1;
      end
      parent.kind = NOD_PRN;
      return nil;
    elseif tokcmp(tok, "print-bool", str) then
      if not node.later then
        raise(ptok, str, "the parameter of print-bool is empty\n");
        return 1;
      end
      if node.later.later then
        raise(vtok, str, "only one parameter of print-bool is allowed\n");
        return 1;
      end
      if variables(node.later, prev, str) then
        return 1;
      end
      parent.kind = NOD_PRB;
      return nil;
    else
      raise(tok, str, "variable %.*s undifined\n");
      return 1;
    end
  else
    return 1;
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
    env.locs[i] = {};
    env.locs[i].obj = {};
    env.locs[i].obj.kind = OBJ_NIL;
  end
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
  local tok, s, e = scan(str, start);
  if tok ~= id then
    return s, 1;
  end
  local node = node_new(nil, NOD_NIL);
  node.parent = parent;
  node.kind = kind;
  node.tok = {};
  node.tok.start = s;
  node.tok.ending = e;
  node.tok.id = tok;
  if parent.front == nil then
    parent.front = node;
    parent.back = node;
  else
    parent.back.later = node;
    parent.back = node;
  end
  return e, nil;
end

function match(str, start, expected)
  local actual, s, e = scan(str, start)
  if actual ~= expected then
    return start, 1
  end
  return e, nil
end

function syntax_error()
  print('hello world !');
end

function parse(str, start, parent)
  local tok, s = scan(str, start);  -- peek
  if tok == TOK_LP then
    start, err = fetch(str, start, TOK_LP, parent, NOD_NIL);
    if err then
      return start, 1;
    end
    local node = parent.back;
    while true do
      tok, s = scan(str, start); --peek
      _, s, e = scan(str, start); --peek
      if tok == TOK_RP then
        break;
      end
      if tok == TOK_LP then
        start, err = parse(str, start, node);
        if err then
          return start, 1;
        end
      elseif tok == TOK_NUM then
        start, err = fetch(str, start, TOK_NUM, node, NOD_NUM);
        if err then
          return start, 1;
        end
      elseif tok == TOK_SYM then
        start, err = fetch(str, start, TOK_SYM, node, NOD_SYM);
        if err then
          return start, 1;
        end
      elseif tok == TOK_ID then
        start, err = fetch(str, start, TOK_ID, node, NOD_ID);
        if err then
          return start, 1;
        end
      else
        syntax_error();
        return start, 1;
      end
    end
    start, err = match(str, start, TOK_RP);
    if err then
      return start, 1;
    end
    return start, nil;
  elseif tok == TOK_EOF then
    return start, nil;
  else 
    syntax_error();
    return start, 1;
  end
end

function lt(a, b, ret)   ret.val = a < b;             end
function gt(a, b, ret)   ret.val = a > b;             end
function eq(a, b, ret)   ret.val = a == b;            end
function add(a, b, ret)  ret.val = a + b;             end
function sub(a, b, ret)  ret.val = a - b;             end
function mul(a, b, ret)  ret.val = a * b;             end
function div(a, b, ret)  ret.val = math.floor(a / b); end
function mod(a, b, ret)  ret.val = a % b;             end
function and_(a, b, ret) ret.val = a and b;           end
function or_(a, b, ret)  ret.val = a or b;            end
function not_(a, ret)    ret.val = not a;             end

function calc(parent, prev, stack, cb, tokin, tokout, unary, str, obj)
  local ptok = parent.tok;
  local node = parent.front.later;
  local a = {};
  if eval(node, prev, stack, str, a) then
    return 1;
  end
  local atok = node.tok;
  if a.kind ~= tokin then
    local msg = tokin == OBJ_INT and "integer" or "boolen";
    raise(atok, str, "variables is not " .. msg .. "\n");
    return 1;
  end
  while true do
    node = node.later;
    if not node then
      break;
    end
    local b = {};
    if eval(node, prev, stack, str, b) then
      return 1;
    end
    local btok = node.tok;
    if b.kind ~= tokin then
      local msg = tokin == OBJ_INT and "integer" or "boolen";
      raise(btok, str, "variables is not " .. msg .. "\n");
      return 1;
    end
    cb(a.val, b.val, a);
  end
  if unary then
    cb(a.val, a);
  end
  obj.val = a.val;
  obj.kind = tokout;
  return nil;
end

function eval(parent, prev, stack, str, obj)
  if parent.kind == NOD_INT then
    obj.val = parent.val;
    obj.kind = OBJ_INT;
    return nil;
  elseif parent.kind == NOD_BOL then
    obj.val = parent.val;
    obj.kind = OBJ_BOL;
    return nil;
  elseif parent.kind == NOD_VAR then
    env_get(prev, parent.val, obj);
    return nil;
  elseif parent.kind == NOD_DEF then
    obj.val = {};
    obj.val.env = prev;
    obj.val.node = parent;
    obj.kind = OBJ_FUN;
    return nil;
  elseif parent.kind == NOD_FUN then
    local caller = parent.front;
    local o = {};
    if eval(caller, prev, stack, str, o) then
      return 1;
    end
    local ctok = caller.tok;
    if o.kind ~= OBJ_FUN then
      raise(ctok, str, "variable is not function\n");
      return 1;
    end
    local fun = o.val;
    local callee = fun.node;
    local def = callee.val;
    local len = 0;
    --o(n)
    def.len = 0;
    for k, v in pairs(def.args) do
      def.len = def.len + 1;
    end
    --o(n)
    local arg = caller.later;
    while arg do
      arg = arg.later;
      len = len + 1;
    end
    local ptok = parent.tok;
    if len ~= def.len then
      raise(ptok, str, "parameters length do not match\n");
      return 1;
    end
    local env = env_new(fun.env, stack, def.env);
    local params = callee.front.later;
    local arg = caller.later;
    for i = 1, def.len do
      local ret = {};
      if eval(arg, prev, env, str, ret) then
        return 1;
      end
      local var = {};
      var.env = 0;
      var.off = def.args[i];
      env_set(env, var, ret);
      arg = arg.later;
    end
    obj.kind = OBJ_NIL;
    local stmt = params.later;
    while stmt do
      if eval(stmt, env, env, str, obj) then
        return 1;
      end
      stmt = stmt.later;
    end
    return nil;
  elseif parent.kind == NOD_SET then
    local name = parent.front.later;
    local o = {};
    if eval(name.later, prev, stack, str, o) then
      return 1;
    end
    env_set(prev, name.val, o);
    obj.kind = OBJ_NIL;
    return nil;
  elseif parent.kind == NOD_IF then
    local cond = parent.front.later;
    local o = {};
    if eval(cond, prev, stack, str, o) then
      return 1;
    end
    local tok = cond.tok;
    if o.kind ~= OBJ_BOL then
      raise(tok, str, "variables is not boolean\n");
      return 1;
    end
    local stmt = o.val and cond.later or cond.later.later;
    if eval(stmt, prev, stack, str, obj) then
      return 1;
    end
    local stok = stmt.tok;
    if obj.kind == OBJ_NIL then
      raise(stok, str, "the return value of if-else statement is nil\n");
      return 1;
    end
    return nil;
  elseif parent.kind == NOD_LT then
    return calc(parent, prev, stack, lt, OBJ_INT, OBJ_BOL, nil, str, obj);
  elseif parent.kind == NOD_GT then
    return calc(parent, prev, stack, gt, OBJ_INT, OBJ_BOL, nil, str, obj);
  elseif parent.kind == NOD_EQ then
    return calc(parent, prev, stack, eq, OBJ_INT, OBJ_BOL, nil, str, obj);
  elseif parent.kind == NOD_ADD then
    return calc(parent, prev, stack, add, OBJ_INT, OBJ_INT, nil, str, obj);
  elseif parent.kind == NOD_SUB then
    return calc(parent, prev, stack, sub, OBJ_INT, OBJ_INT, nil, str, obj);
  elseif parent.kind == NOD_MUL then
    return calc(parent, prev, stack, mul, OBJ_INT, OBJ_INT, nil, str, obj);
  elseif parent.kind == NOD_DIV then
    return calc(parent, prev, stack, div, OBJ_INT, OBJ_INT, nil, str, obj);
  elseif parent.kind == NOD_MOD then
    return calc(parent, prev, stack, mod, OBJ_INT, OBJ_INT, nil, str, obj);
  elseif parent.kind == NOD_AND then
    return calc(parent, prev, stack, and_, OBJ_BOL, OBJ_BOL, nil, str, obj);
  elseif parent.kind == NOD_OR then
    return calc(parent, prev, stack, or_, OBJ_BOL, OBJ_BOL, nil, str, obj);
  elseif parent.kind == NOD_NOT then
    return calc(parent, prev, stack, not_, OBJ_BOL, OBJ_BOL, 1, str, obj);
  elseif parent.kind == NOD_PRN then
    local num = parent.front.later;
    local o = {};
    if eval(num, prev, stack, str, o) then
      return 1
    end
    local tok = num.tok;
    if o.kind ~= OBJ_INT then
      raise(tok, str, "the argument of print-num is not integer\n");
      return 1;
    end
    obj.kind = OBJ_NIL;
    print(o.val);
    return nil;
  elseif parent.kind == NOD_PRB then
    local num = parent.front.later;
    local o = {};
    if eval(num, prev, stack, str, o) then
      return 1;
    end
    local tok = num.tok;
    if o.kind ~= OBJ_BOL then
      raise(tok, str, "the argument of print-bool is not boolen\n");
      return 1;
    end
    print(o.val and "#t" or "#f");
  else
    return 1;
  end
end

function start()
  local start = 1;
  local ret = 1;
  local file;
  local str;
  local parent = node_new(nil, NOD_NIL);
  local map = {};
  local node;
  local env;
  parent.tok = {};
  parent.tok.start = 0;
  parent.tok.ending = 1;
  parent.tok.id = TOK_NIL;
  map_init(map);
  file = io.open(arg[1], r);
  if (file == nil) then
    goto exit;
  end

  str = file:read("*all");
  str = str..'\0';
  while scan(str, start) ~= TOK_EOF do
    local s, err = parse(str, start, parent);
    if err then
      goto close_file;
    end
    start = s;
  end

  --node_dump(parent, str)
  node = parent.front;
  env = env_new(nil, nil, 0);
  while node ~= nil do
    if semantic(node, map, str) or env_add(env, map.set.len) then
      return 1
    end
    node = node.later;
  end
  --node_dump(parent, str);
  node = parent.front;
  while node do
    local o = {};
    if eval(node, env, env, str, o) then
      return 1;
    end
    node = node.later;
  end
  ret = nil;
  ::close_file::
  file:close();
  ::exit::
  return ret;
end

os.exit(start());

--[[
local str = arg[1]..'\0'
local start = 1
repeat
  local tok, s, e = parse(str, start, parent)
  print(str:sub(s, e - 1), tok, s, e)
  start = e
until tok == tok_eof
]]--

