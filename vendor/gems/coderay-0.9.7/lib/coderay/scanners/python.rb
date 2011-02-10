module CodeRay
module Scanners
  
  # Bases on pygments' PythonLexer, see
  # http://dev.pocoo.org/projects/pygments/browser/pygments/lexers/agile.py.
  class Python < Scanner
    
    include Streamable
    
    register_for :python
    file_extension 'py'
    
    KEYWORDS = [
      'and', 'as', 'assert', 'break', 'class', 'continue', 'def',
      'del', 'elif', 'else', 'except', 'finally', 'for',
      'from', 'global', 'if', 'import', 'in', 'is', 'lambda', 'not',
      'or', 'pass', 'raise', 'return', 'try', 'while', 'with', 'yield',
      'nonlocal',  # new in Python 3
    ]
    
    OLD_KEYWORDS = [
      'exec', 'print',  # gone in Python 3
    ]
    
    PREDEFINED_METHODS_AND_TYPES = %w[
      __import__ abs all any apply basestring bin bool buffer
      bytearray bytes callable chr classmethod cmp coerce compile
      complex delattr dict dir divmod enumerate eval execfile exit
      file filter float frozenset getattr globals hasattr hash hex id
      input int intern isinstance issubclass iter len list locals
      long map max min next object oct open ord pow property range
      raw_input reduce reload repr reversed round set setattr slice
      sorted staticmethod str sum super tuple type unichr unicode
      vars xrange zip
    ]
    
    PREDEFINED_EXCEPTIONS = %w[
      ArithmeticError AssertionError AttributeError
      BaseException DeprecationWarning EOFError EnvironmentError
      Exception FloatingPointError FutureWarning GeneratorExit IOError
      ImportError ImportWarning IndentationError IndexError KeyError
      KeyboardInterrupt LookupError MemoryError NameError
      NotImplemented NotImplementedError OSError OverflowError
      OverflowWarning PendingDeprecationWarning ReferenceError
      RuntimeError RuntimeWarning StandardError StopIteration
      SyntaxError SyntaxWarning SystemError SystemExit TabError
      TypeError UnboundLocalError UnicodeDecodeError
      UnicodeEncodeError UnicodeError UnicodeTranslateError
      UnicodeWarning UserWarning ValueError Warning ZeroDivisionError
    ]
    
    PREDEFINED_VARIABLES_AND_CONSTANTS = [
      'False', 'True', 'None', # "keywords" since Python 3
      'self', 'Ellipsis', 'NotImplemented',
    ]
    
    IDENT_KIND = WordList.new(:ident).
      add(KEYWORDS, :keyword).
      add(OLD_KEYWORDS, :old_keyword).
      add(PREDEFINED_METHODS_AND_TYPES, :predefined).
      add(PREDEFINED_VARIABLES_AND_CONSTANTS, :pre_constant).
      add(PREDEFINED_EXCEPTIONS, :exception)
    
    NAME = / [^\W\d] \w* /x
    ESCAPE = / [abfnrtv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
    UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} | N\{[-\w ]+\} /x
    
    OPERATOR = /
      \.\.\. |          # ellipsis
      \.(?!\d) |        # dot but not decimal point
      [,;:()\[\]{}] |   # simple delimiters
      \/\/=? | \*\*=? | # special math
      [-+*\/%&|^]=? |   # ordinary math and binary logic
      [~`] |            # binary complement and inspection
      <<=? | >>=? | [<>=]=? | !=  # comparison and assignment
    /x
    
    STRING_DELIMITER_REGEXP = Hash.new do |h, delimiter|
      h[delimiter] = Regexp.union delimiter
    end
    
    STRING_CONTENT_REGEXP = Hash.new do |h, delimiter|
      h[delimiter] = / [^\\\n]+? (?= \\ | $ | #{Regexp.escape(delimiter)} ) /x
    end
    
    DEF_NEW_STATE = WordList.new(:initial).
      add(%w(def), :def_expected).
      add(%w(import from), :include_expected).
      add(%w(class), :class_expected)
    
    DESCRIPTOR = /
      #{NAME}
      (?: \. #{NAME} )*
      | \*
    /x
    
    def scan_tokens tokens, options
      
      state = :initial
      string_delimiter = nil
      string_raw = false
      import_clause = class_name_follows = last_token_dot = false
      unicode = string.respond_to?(:encoding) && string.encoding.name == 'UTF-8'
      from_import_state = []
      
      until eos?
        
        kind = nil
        match = nil
        
        if state == :string
          if scan(STRING_DELIMITER_REGEXP[string_delimiter])
            tokens << [matched, :delimiter]
            tokens << [:close, :string]
            state = :initial
            next
          elsif string_delimiter.size == 3 && scan(/\n/)
            kind = :content
          elsif scan(STRING_CONTENT_REGEXP[string_delimiter])
            kind = :content
          elsif !string_raw && scan(/ \\ #{ESCAPE} /ox)
            kind = :char
          elsif scan(/ \\ #{UNICODE_ESCAPE} /ox)
            kind = :char
          elsif scan(/ \\ . /x)
            kind = :content
          elsif scan(/ \\ | $ /x)
            tokens << [:close, :string]
            kind = :error
            state = :initial
          else
            raise_inspect "else case \" reached; %p not handled." % peek(1), tokens, state
          end
        
        elsif match = scan(/ [ \t]+ | \\\n /x)
          tokens << [match, :space]
          next
        
        elsif match = scan(/\n/)
          tokens << [match, :space]
          state = :initial if state == :include_expected
          next
        
        elsif match = scan(/ \# [^\n]* /mx)
          tokens << [match, :comment]
          next
        
        elsif state == :initial
          
          if scan(/#{OPERATOR}/o)
            kind = :operator
          
          elsif match = scan(/(u?r?|b)?("""|"|'''|')/i)
            tokens << [:open, :string]
            string_delimiter = self[2]
            string_raw = false
            modifiers = self[1]
            unless modifiers.empty?
              string_raw = !!modifiers.index(?r)
              tokens << [modifiers, :modifier]
              match = string_delimiter
            end
            state = :string
            kind = :delimiter
          
          # TODO: backticks
          
          elsif match = scan(unicode ? /#{NAME}/uo : /#{NAME}/o)
            kind = IDENT_KIND[match]
            # TODO: keyword arguments
            kind = :ident if last_token_dot
            if kind == :old_keyword
              kind = check(/\(/) ? :ident : :keyword
            elsif kind == :predefined && check(/ *=/)
              kind = :ident
            elsif kind == :keyword
              state = DEF_NEW_STATE[match]
              from_import_state << match.to_sym if state == :include_expected
            end
          
          elsif scan(/@[a-zA-Z0-9_.]+[lL]?/)
            kind = :decorator
          
          elsif scan(/0[xX][0-9A-Fa-f]+[lL]?/)
            kind = :hex
          
          elsif scan(/0[bB][01]+[lL]?/)
            kind = :bin
          
          elsif match = scan(/(?:\d*\.\d+|\d+\.\d*)(?:[eE][+-]?\d+)?|\d+[eE][+-]?\d+/)
            kind = :float
            if scan(/[jJ]/)
              match << matched
              kind = :imaginary
            end
          
          elsif scan(/0[oO][0-7]+|0[0-7]+(?![89.eE])[lL]?/)
            kind = :oct
          
          elsif match = scan(/\d+([lL])?/)
            kind = :integer
            if self[1] == nil && scan(/[jJ]/)
              match << matched
              kind = :imaginary
            end
          
          else
            getch
            kind = :error
          
          end
            
        elsif state == :def_expected
          state = :initial
          if match = scan(unicode ? /#{NAME}/uo : /#{NAME}/o)
            kind = :method
          else
            next
          end
        
        elsif state == :class_expected
          state = :initial
          if match = scan(unicode ? /#{NAME}/uo : /#{NAME}/o)
            kind = :class
          else
            next
          end
          
        elsif state == :include_expected
          if match = scan(unicode ? /#{DESCRIPTOR}/uo : /#{DESCRIPTOR}/o)
            kind = :include
            if match == 'as'
              kind = :keyword
              from_import_state << :as
            elsif from_import_state.first == :from && match == 'import'
              kind = :keyword
              from_import_state << :import
            elsif from_import_state.last == :as
              # kind = match[0,1][unicode ? /[[:upper:]]/u : /[[:upper:]]/] ? :class : :method
              kind = :ident
              from_import_state.pop
            elsif IDENT_KIND[match] == :keyword
              unscan
              match = nil
              state = :initial
              next
            end
          elsif match = scan(/,/)
            from_import_state.pop if from_import_state.last == :as
            kind = :operator
          else
            from_import_state = []
            state = :initial
            next
          end
          
        else
          raise_inspect 'Unknown state', tokens, state
          
        end
        
        match ||= matched
        if $CODERAY_DEBUG and not kind
          raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens, state
        end
        raise_inspect 'Empty token', tokens, state unless match
        
        last_token_dot = match == '.'
        
        tokens << [match, kind]
        
      end
      
      if state == :string
        tokens << [:close, :string]
      end
      
      tokens
    end
    
  end
  
end
end
