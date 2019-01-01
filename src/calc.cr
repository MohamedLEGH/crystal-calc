
struct Token
  getter type
  getter value

  def initialize(type : String, value : String|Char)
    @type = type
    @value = value
  end

  def inspect(io)
    io << "Token(" << @type << ", " << "'" << @value << "'" << ")"
  end

end



class Lexer

  def initialize(data : String)
    @data = Char::Reader.new(data)
  end

  def digit_string : String
    num = ""
    num += @data.current_char
    while @data.peek_next_char.number?
      num += @data.next_char
    end
    return num
  end

  def tokenize
    tokens = [] of Token
    while @data.has_next?
      #puts "current = " , @data.current_char
      #puts "next = " , @data.peek_next_char
      i = @data.current_char
      case i
      when .number?
        tokens << Token.new("NUMBER", digit_string)
      when '+'
        tokens << Token.new("PLUS", i)
      when '-'
        tokens << Token.new("MINUS", i)
      when '*'
        tokens << Token.new("MULT", i)
      when '/'
        tokens << Token.new("DIV", i)
      when '('
        tokens << Token.new("LPAR", i)
      when ')'
        tokens << Token.new("RPAR", i)
      when ' ', '\n', '\t'
      else
        tokens << Token.new("OTHER", i)
      end
      @data.next_char
    end
    return tokens
  end

end

abstract class AST
end

class BinOp < AST
  getter op
  getter left
  getter right

  def initialize(left : AST, op : Token, right : AST)
  @left = left
  @token = @op = op
  @right = right
  end
end

class UnaryOp < AST
  getter op
  getter expr

  def initialize(op : Token, expr : AST)
    @token = @op = op
    @expr = expr
  end

end

class Num < AST
  @value : Int32
  getter token
  getter value

  def initialize(token : Token)
    @token = token
    @value = token.value.to_i
  end

end



class Parser
  def initialize(tokens : Array(Token))
    @tokens = tokens
    @pos_token = 0
  end

  def actual_token
    return @tokens[@pos_token]
  end

  def eat(type : String)
    token = actual_token
    if token.type != type
      puts token
      raise Exception.new("Error in parsing")
    end
    @pos_token+=1
  end

  def number : AST
    t = actual_token
    eat("NUMBER")
    return Num.new(t)
  end

  def bracket
    eat("LPAR")
    val = calculus
    eat("RPAR")
    return val
  end

  def factor : AST
    t = actual_token
    if t.type == "LPAR"
      value = bracket
    elsif t.type == "NUMBER"
      value = number
    elsif t.type == "PLUS"
      eat("PLUS")
      value = UnaryOp.new(t,factor)
    elsif t.type == "MINUS"
      eat("MINUS")
      value = UnaryOp.new(t,factor)
    else
      raise Exception.new("Error: Unexpected token in bracket : #{actual_token}")
    end
    return value
  end

  def term : AST
    result_term = factor
    while @pos_token<@tokens.size && ["MULT","DIV"].includes? actual_token.type
      operand = actual_token
      case operand.type
      when "MULT"
        eat("MULT")
      when "DIV"
        eat("DIV")
      end
        result_term = BinOp.new(left=result_term,op=operand,right=factor)
    end
    return result_term
  end

  def calculus : AST
    result = term
    while @pos_token<@tokens.size && ["PLUS","MINUS"].includes? actual_token.type
      operand = actual_token
      case operand.type
      when "PLUS"
        eat("PLUS")
      when "MINUS"
        eat("MINUS")
      end
      result = BinOp.new(left=result,op=operand,right=term)
    end
    return result
  end

  def parse : AST
    @pos_token = 0
    val = calculus
    if @pos_token<@tokens.size
      raise Exception.new("Error: Unexpected token #{actual_token}")
    end
    return val
  end
end

class Interpreter

  def initialize(ast : AST)
    @ast = ast
  end

  def interpret
    return visit(@ast).to_s
  end

  def visit(node : BinOp) : Int32
    case node.op.type
    when "PLUS"
      return visit(node.left) + visit(node.right)
    when "MINUS"
      return visit(node.left) - visit(node.right)
    when "MULT"
      return visit(node.left) * visit(node.right)
    when "DIV"
      return visit(node.left) / visit(node.right)
    else
      raise Exception.new("Error: Unexpected node #{node}")
    end
  end

  def visit(node : UnaryOp) : Int32
    case node.op.type
    when "PLUS"
      return visit(node.expr)
    when "MINUS"
      return -1*visit(node.expr)
    else
      raise Exception.new("Error: Unexpected node #{node}")
    end
  end

  def visit(node : Num) : Int32
    return node.value
  end
end

class InterpreterRPN < Interpreter
  def visit(node : BinOp)
    result = ""
    left = visit(node.left)
    result += left
    result += " "
    right = visit(node.right)
    result += right
    result += " "
    result += node.op.value
    return result
  end

  def visit(node : UnaryOp)
    result = ""
    case node.op.type
    when "PLUS"
      result += visit(node.expr)
    when "MINUS"
      result += "-"
      result += visit(node.expr)
    else
      raise Exception.new("Error: Unexpected node #{node}")
    end
    minuscount = result.count('-')
    result = result.delete('-')
    if minuscount%2 == 1
      result = '-' + result
    end
    return result
  end


  def visit(node : Num)
    return node.value.to_s
  end
end

class InterpreterLISP < Interpreter
  def visit(node : BinOp)
    result = "("
    result += node.op.value
    result += " "
    left = visit(node.left)
    result += left
    result += " "
    right = visit(node.right)
    result += right
    result += ")"
    return result
  end

  def visit(node : UnaryOp)
    result = ""
    case node.op.type
    when "PLUS"
      result += visit(node.expr)
    when "MINUS"
      result += "-"
      result += visit(node.expr)
    else
      raise Exception.new("Error: Unexpected node #{node}")
    end
    minuscount = result.count('-')
    result = result.delete('-')
    if minuscount%2 == 1
      result = '-' + result
    end
    return result
  end

  def visit(node : Num)
    return node.value.to_s
  end
end

while true
  print "calc > "
  a = gets
  if a # if a is a String
    if a.size>0
      lex = Lexer.new(a)
      list_tokens = lex.tokenize
      par = Parser.new(list_tokens)
      ast = par.parse
      i = Interpreter.new(ast)
      result = i.interpret
      puts result
      rpn = InterpreterRPN.new(ast)
      rpn_result = rpn.interpret
      puts rpn_result
      lisp = InterpreterLISP.new(ast)
      lisp_result = lisp.interpret
      puts lisp_result
    end
  else
    puts "\nGoodbye!"
    exit # just silently quit the program
  end
end

