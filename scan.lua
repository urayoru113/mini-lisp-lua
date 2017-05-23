require 'define'

function scan(str, s)
  -- s: start
  -- e: end

  -- ignore '\n', '\t', ' '
  local c
  local e
  while 1 do
    c = str:sub(s, s)
    if c == '\n' then
      s = s + 1
    else
      break
    end
  end
  while c == ' '  or
    c == '\t' or
    c == '\r' do
    s = s + 1
    c = str:sub(s, s)
  end
  e = s + 1

  if c >= '1' and c <= '9' then
    c = str:sub(e, e)
    e = e + 1
    while c >= '0' and
      c <= '9' do
      c = str:sub(e, e)
      e = e + 1
    end
    return TOK_NUM, s, e
  elseif c == '0' then
    c = str:sub(e, e)
    e = e + 1
    if c < '0' and
      c > '9' then
      return TOK_NUM, s, e
    else
      return TOK_NIL, s, e
    end
  elseif c == '#' then
    c = str:sub(e, e)
    e = e + 1
    if c == 't' or c == 'f' then
      c = str:sub(e, e)
      e = e + 1
      if not (c >= '0' and c <= '9' or
        c >= 'a' and c <= 'z' or
        c >= 'A' and c <= 'Z') then
        return TOK_SYM, s, e
      end
    end
    while c >= '0' and c <= '9' or
      c >= 'a' and c <= 'z' or
      c >= 'A' and c <= 'Z' do
      c = str:sub(e, e)
      e = e + 1
    end
    return TOK_NIL, s, e
  elseif c == '(' then
    return TOK_LPAREN, s, e
  elseif r == ')' then
    return TOK_RPAREN, s, e
  elseif r == ''  then
    return TOK_EOF, s, e
  elseif r >= 'a' and r <= 'z' or r >= 'A' and r <= 'Z' then
    r = read(str, postart + ponum)
    while r >= 'a' and r <= 'z' or
          r >= 'A' and r <= 'Z' or
          r >= '0' and r <= '9' or
          r == '-' do
      ponum = ponum + 1
      r = read(str, postart + ponum)
    end
    return TOK.ID, postart, ponum
  elseif r == '<' or
         r == '>' or
         r == '=' or
         r == '+' or
         r == '-' or
         r == '*' or
         r == '/' then
    if r == '-' then
      r = read(str, postart + ponum)
      if r >= '0' and r <= '9' then
        while r >= '0' and r <= '9' do
          ponum = ponum + 1
          r = read(str, postart + ponum)
        end
        return TOK.NUM, postart, ponum
      else
        ponum = ponum + 1
        return TOK.ID, postart, ponum
      end
      return TOK.ID, postart, ponum
    end
    return TOK.ID, postart, ponum
  else 
    return TOK.NIL, postart, ponum
  end

end

function fetch(str, postart, ponum)
end

function match(str, start, expected)
  actual, s, e = scan(str, start)
  if actual ~= expected then
    return start, 1
  end
  return e, nil
end

function syntax_error()
  print('hello world !')
end

function parse(str, start, parent)
  node = parent.back
  while 1 do
    tok = scan(str, start)  -- peek
    if tok == NUM then
      start, err = fetch(str, start, TOK_NUM, node, NODE_NUM)
      if err then
        return 1
      end
      while 1 do
        tok = scan(str, start)
        if tok == ADD then
          start, err = match(str, start, ADD)
          if err then
            return 1
          end
          start, err = match(str, start, NUM)
          if err then
            return 1
          end
        elseif tok == EOF then
          return nil
        else
          syntax_error()
          return 1
        end
      end
      return nil
    else
      syntax_error()
      return 1
    end
  end
end

function start()
  local postart = 1
  local ret = 1
  local src -- haha c89 :)
  local dst
  local str
  src = io.open('test.txt', r)
  if (src == nil) then
    goto exit;
  end
  dst = io.open('test.txt', r)
  if (dst == nil) then
    goto close_src;
  end
  str, err = file:read("*all")
  if (err) then
    goto close_dst;
  end
  if parse(str, postart) then
    goto close_file
  end
  ret = nil
  ::close_dst::
  dst::close()
  ::close_src::
  src:close()
  ::exit::
  return ret
end

os.exit(start())
