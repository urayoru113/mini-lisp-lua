require 'define'

function scan(str, postart)
  --read '\n', '\t', ' '
  while true do
    if read(str, postart) == '\n' then
      postart = postart + 1
    else break end
  end
  if read(str, postart) == ' '  or
     read(str, postart) == '\t' or
     read(str, postart) == '\r' then
     postart = postart + 1
  end

  local r = read(str, postart)
  local ponum = 1

  if r >= '1' and r <= '9' then
    while read(str, postart + ponum) >= '0' and
          read(str, postart + ponum) <= '9' do
          ponum = ponum + 1
    end
    return TOK.NUM, postart, ponum
  elseif r == '0' and
         read(str, postart + ponum) < '0' and
         read(str, postart + ponum) > '9' then
    return TOK.NUM, postart, ponum
  elseif r == '#' then
    r = read(str, postart + ponum) 
    if r == 't' or r == 'f' then
      ponum = ponum + 1
      r = read(str, postart + ponum)
      if not (r >= '0' and r <= '9' or
              r >= 'a' and r <= 'z' or
              r >= 'A' and r <= 'Z') then
        return TOK.SYM, postart, ponum
      end
    end
    while r >= '0' and r <= '9' or
          r >= 'a' and r <= 'z' or
          r >= 'A' and r <= 'Z' do
          ponum = ponum + 1
          r = read(str, postart + ponum)
    end
    return TOK.NIL, postart, ponum
  elseif r == '(' then
    return TOK.LPAREN, postart, ponum
  elseif r == ')' then
    return TOK.RPAREN, postart, ponum
  elseif r == ''  then
    return TOK.EOF, postart, ponum
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

function parse(str, postart)
  tok = 0
  ponum = 0
  str = arg[1]
  while read(str, postart + ponum) ~= '' do
    tok, postart, ponum = scan(str, postart)
    print(str:sub(postart, postart + ponum - 1))
    print(tok,postart, ponum,'\n')
    postart = postart + ponum
    ponum = 0
  end
  if tok == TOK.LPARENT then
  end
end

function start()
  local file = io.open('test.txt', r)
  local postart = 1
  local str = file:read("*all")
  parse(str, postart)
  file:close()
end

start();
--f = io.open('test.txt', r):read("*all")
