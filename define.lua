--

function creatEnumTable(tbl, index)
  local enumtbl = {}
  local enumindex = index or 0
  for i, v in pairs(tbl) do
    enumtbl[v] = enumindex + i
  end
  return enumtbl
end

function read(str, index)
  return str:sub(index, index)
end

TOK = {
 'NIL',
 'EOF',
 'NUM',
 'SYM',
 'ID',
 'LPAREN',
 'RPAREN'
}

NOD = {
  'NIL',
  'NUM',
  'INT',
  'SYM',
  'BOL', 
  'ID',
  'VAR',
  'DEF',
  'FUN',
  'SET', 
  'IF',
  'LT',
  'GT',
  'EQ',
  'ADD',
  'SUB',
  'MUL',
  'DIV',
  'MOD',
  'AND',
  'OR',
  'NOT', 
  'PRN',
  'PRB'
}

OBJ = {
  'NIL',
  'INT',
  'BOL',
  'FUN'
}

TOK = creatEnumTable(TOK)
NOD = creatEnumTable(NOD)
OBJ = creatEnumTable(OBJ)

function NODE()
  local NODE = {
    parent,
    left,
    right,
    typed
  }
  return NODE
end
