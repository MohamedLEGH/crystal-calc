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

  def type
    return @type
  end

  def value
    return @value
  end

  def inspect(io)
    io << "Token(" << @type << ", " << "'" << @value << "'" << ")"
  end

end



class Lexical

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

class Sementic
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

  def factor : Int32
    t = get_current_token.value
    eat("NUMBER")
    a = t.to_i
    return a
  end

def bracket_term : Int32
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


  def term : Int32
    result_term = bracket_term
    while @pos_token<@tokens.size && ["MULT","DIV"].includes? get_current_token.type
      case get_current_token.type
      when "MULT"
        eat("MULT")
        result_term*=bracket_term
      when "DIV"
        eat("DIV")
        result_term/=bracket_term
      end
    end
    return result_term
    end

  def computeSementic : Int32
    @pos_token = 0
    val = calculus
    if @pos_token<@tokens.size
      raise Exception.new("Error: Unexpected token #{get_current_token}")
    end
    return val
  end

  def calculus : Int32

    result = term
    while @pos_token<@tokens.size && ["PLUS","MINUS"].includes? get_current_token.type
      case get_current_token.type
      when "PLUS"
        eat("PLUS")
        result +=term
      when "MINUS"
        eat("MINUS")
        result -=term
      end
    end
    return result

  end
end

while true
  print "calc > "
  a = gets
  if a # if a is a String
    if a.size>0
      lex = Lexical.new(a)
      sem = Sementic.new(lex.tokens)
      result = sem.computeSementic
      puts result
    end
  else
    puts "\nGoodbye!"
    exit # just silently quit the program
  end
end

