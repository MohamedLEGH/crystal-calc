# TODO: Write documentation for `Calc`
#module Calc
#  VERSION = "0.1.0"
  # TODO: Put your code here
#end

struct Token

  def initialize(type : String, value : String|Char)
    @type = type
    @value = value
  end

  def type : String
    return @type
  end

  def value : String|Char
    return @value
  end

  def inspect(io)
    io << "Token(" << @type << ", " << "'" << @value << "'" << ")"
  end

end



class Lexer

  def initialize(data : String)
    @data = Char::Reader.new(data)
    @tokens = [] of Token
    tokenize
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
    while @data.has_next?
      #puts "current = " , @data.current_char
      #puts "next = " , @data.peek_next_char
      i = @data.current_char
      case i
      when .number?
        @tokens << Token.new("NUMBER", digit_string)
      when '+'
        @tokens << Token.new("PLUS", i)
      when '-'
        @tokens << Token.new("MINUS", i)
      when '*'
        @tokens << Token.new("MULT", i)
      when '/'
        @tokens << Token.new("DIV", i)
      when '('
        @tokens << Token.new("LPAR", i)
      when ')'
        @tokens << Token.new("RPAR", i)
      when ' ', '\n', '\t'
      else
        @tokens << Token.new("OTHER", i)
      end
      @data.next_char
    end
  end

  def tokens
    return @tokens
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

class Num < AST
  @value : String|Char
  getter token
  getter value

  def initialize(token : Token)
    @token = token
    @value = token.value
  end

  def op
  return @token
  end

end



class Parser
  def initialize(tokens : Array(Token))
    @tokens = tokens
    @pos_token = 0
  end

  def get_current_token
    return @tokens[@pos_token]
  end

  def eat(type : String)
    token = get_current_token
    if token.type != type
      puts token
      raise Exception.new("Error in parsing")
    end
    @pos_token+=1
  end

  def factor : AST
    t = get_current_token
    eat("NUMBER")
    #a = t.to_i
    return Num.new(t)
  end

  def bracket_term : AST
    right = get_current_token.type
    if right=="LPAR"
      eat("LPAR")
      value = calculus
      eat("RPAR")
    elsif right=="NUMBER"
      value = factor
    else
      raise Exception.new("Error: Unexpected token in bracket : #{get_current_token}")
    end
    return value
  end

  def term : AST
    result_term = bracket_term
    while @pos_token<@tokens.size && ["MULT","DIV"].includes? get_current_token.type
      operand = get_current_token
      case operand.type
      when "MULT"
        eat("MULT")
        #result_term*=bracket_term
      when "DIV"
        eat("DIV")
        #result_term/=bracket_term
      end
        result_term = BinOp.new(left=result_term,op=operand,right=bracket_term)
    end
    return result_term
  end

  def calculus : AST
    result = term
    while @pos_token<@tokens.size && ["PLUS","MINUS"].includes? get_current_token.type
      operand = get_current_token
      case operand.type
      when "PLUS"
        eat("PLUS")
        #result +=term
      when "MINUS"
        eat("MINUS")
        #result -=term
      end
      result = BinOp.new(left=result,op=operand,right=term)
    end
    return result
  end

  def parse : AST
    @pos_token = 0
    val = calculus
    if @pos_token<@tokens.size
      raise Exception.new("Error: Unexpected token #{get_current_token}")
    end
    return val
  end
end

class Interpreter

  def initialize(ast : AST)
    @ast = ast
  end

  def interpret
    return visit(@ast)
  end

  def visit(node : BinOp)
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

  def visit(node : Num)
    return node.value.to_i
  end
end

while true
  print "calc > "
  a = gets
  if a # if a is a String
    if a.size>0
      lex = Lexer.new(a)
      sem = Parser.new(lex.tokens)
      ast = sem.parse
      vis = Interpreter.new(ast)
      result = vis.interpret
      puts result
    end
  else
    puts "\nGoodbye!"
    exit # just silently quit the program
  end
end

