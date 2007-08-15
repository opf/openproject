module CodeRay
module Scanners

  module Ruby::Patterns  # :nodoc:

    RESERVED_WORDS = %w[
      and def end in or unless begin
      defined? ensure module redo super until
      BEGIN break do next rescue then
      when END case else for retry
      while alias class elsif if not return
      undef yield
    ]

    DEF_KEYWORDS = %w[ def ]
    UNDEF_KEYWORDS = %w[ undef ]
    MODULE_KEYWORDS = %w[class module]
    DEF_NEW_STATE = WordList.new(:initial).
      add(DEF_KEYWORDS, :def_expected).
      add(UNDEF_KEYWORDS, :undef_expected).
      add(MODULE_KEYWORDS, :module_expected)

    IDENTS_ALLOWING_REGEXP = %w[
      and or not while until unless if then elsif when sub sub! gsub gsub!
      scan slice slice! split
    ]
    REGEXP_ALLOWED = WordList.new(false).
      add(IDENTS_ALLOWING_REGEXP, :set)

    PREDEFINED_CONSTANTS = %w[
      nil true false self
      DATA ARGV ARGF __FILE__ __LINE__
    ]

    IDENT_KIND = WordList.new(:ident).
      add(RESERVED_WORDS, :reserved).
      add(PREDEFINED_CONSTANTS, :pre_constant)

    IDENT = /[a-z_][\w_]*/i

    METHOD_NAME = / #{IDENT} [?!]? /ox
    METHOD_NAME_OPERATOR = /
      \*\*?           # multiplication and power
      | [-+]@?        # plus, minus
      | [\/%&|^`~]    # division, modulo or format strings, &and, |or, ^xor, `system`, tilde
      | \[\]=?        # array getter and setter
      | << | >>       # append or shift left, shift right
      | <=?>? | >=?   # comparison, rocket operator
      | ===?          # simple equality and case equality
    /ox
    METHOD_NAME_EX = / #{IDENT} (?:[?!]|=(?!>))? | #{METHOD_NAME_OPERATOR} /ox
    INSTANCE_VARIABLE = / @ #{IDENT} /ox
    CLASS_VARIABLE = / @@ #{IDENT} /ox
    OBJECT_VARIABLE = / @@? #{IDENT} /ox
    GLOBAL_VARIABLE = / \$ (?: #{IDENT} | [1-9]\d* | 0\w* | [~&+`'=\/,;_.<>!@$?*":\\] | -[a-zA-Z_0-9] ) /ox
    PREFIX_VARIABLE = / #{GLOBAL_VARIABLE} |#{OBJECT_VARIABLE} /ox
    VARIABLE = / @?@? #{IDENT} | #{GLOBAL_VARIABLE} /ox

    QUOTE_TO_TYPE = {
      '`' => :shell,
      '/'=> :regexp,
    }
    QUOTE_TO_TYPE.default = :string

    REGEXP_MODIFIERS = /[mixounse]*/
    REGEXP_SYMBOLS = /[|?*+?(){}\[\].^$]/

    DECIMAL = /\d+(?:_\d+)*/
    OCTAL = /0_?[0-7]+(?:_[0-7]+)*/
    HEXADECIMAL = /0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*/
    BINARY = /0b[01]+(?:_[01]+)*/

    EXPONENT = / [eE] [+-]? #{DECIMAL} /ox
    FLOAT_SUFFIX = / #{EXPONENT} | \. #{DECIMAL} #{EXPONENT}? /ox
    FLOAT_OR_INT = / #{DECIMAL} (?: #{FLOAT_SUFFIX} () )? /ox
    NUMERIC = / [-+]? (?: (?=0) (?: #{OCTAL} | #{HEXADECIMAL} | #{BINARY} ) | #{FLOAT_OR_INT} ) /ox

    SYMBOL = /
      :
      (?:
        #{METHOD_NAME_EX}
      | #{PREFIX_VARIABLE}
      | ['"]
      )
    /ox

    # TODO investigste \M, \c and \C escape sequences
    # (?: M-\\C-|C-\\M-|M-\\c|c\\M-|c|C-|M-)? (?: \\ (?: [0-7]{3} | x[0-9A-Fa-f]{2} | . ) )
    # assert_equal(225, ?\M-a)
    # assert_equal(129, ?\M-\C-a)
    ESCAPE = /
        [abefnrstv]
      | M-\\C-|C-\\M-|M-\\c|c\\M-|c|C-|M-
      |  [0-7]{1,3}
      | x[0-9A-Fa-f]{1,2}
      | .
    /mx

    CHARACTER = /
      \?
      (?:
        [^\s\\]
      | \\ #{ESCAPE}
      )
    /mx

    # NOTE: This is not completely correct, but
    # nobody needs heredoc delimiters ending with \n.
    HEREDOC_OPEN = /
      << (-)?              # $1 = float
      (?:
        ( [A-Za-z_0-9]+ )  # $2 = delim
      |
        ( ["'`\/] )        # $3 = quote, type
        ( [^\n]*? ) \3     # $4 = delim
      )
    /mx

    RUBYDOC = /
      =begin (?!\S)
      .*?
      (?: \Z | ^=end (?!\S) [^\n]* )
    /mx

    DATA = /
      __END__$
      .*?
      (?: \Z | (?=^\#CODE) )
    /mx
    
    # Checks for a valid value to follow. This enables
    # fancy_allowed in method calls.
    VALUE_FOLLOWS = /
      \s+
      (?:
        [%\/][^\s=]
      |
        <<-?\S
      |
        #{CHARACTER}
      )
    /x

    RUBYDOC_OR_DATA = / #{RUBYDOC} | #{DATA} /xo

    RDOC_DATA_START = / ^=begin (?!\S) | ^__END__$ /x

    # FIXME: \s and = are only a workaround, they are still allowed
    # as delimiters.
    FANCY_START_SAVE = / % ( [qQwWxsr] | (?![a-zA-Z0-9\s=]) ) ([^a-zA-Z0-9]) /mx
    FANCY_START_CORRECT = / % ( [qQwWxsr] | (?![a-zA-Z0-9]) ) ([^a-zA-Z0-9]) /mx

    FancyStringType = {
      'q' => [:string, false],
      'Q' => [:string, true],
      'r' => [:regexp, true],
      's' => [:symbol, false],
      'x' => [:shell, true]
    }
    FancyStringType['w'] = FancyStringType['q']
    FancyStringType['W'] = FancyStringType[''] = FancyStringType['Q']

    class StringState < Struct.new :type, :interpreted, :delim, :heredoc,
      :paren, :paren_depth, :pattern, :next_state

      CLOSING_PAREN = Hash[ *%w[
        ( )
        [ ]
        < >
        { }
      ] ]

      CLOSING_PAREN.values.each { |o| o.freeze }  # debug, if I try to change it with <<
      OPENING_PAREN = CLOSING_PAREN.invert

      STRING_PATTERN = Hash.new { |h, k|
        delim, interpreted = *k
        delim_pattern = Regexp.escape(delim.dup)
        if closing_paren = CLOSING_PAREN[delim]
          delim_pattern << Regexp.escape(closing_paren)
        end


        special_escapes =
          case interpreted
          when :regexp_symbols
            '| ' + REGEXP_SYMBOLS.source
          when :words
            '| \s'
          end

        h[k] =
          if interpreted and not delim == '#'
            / (?= [#{delim_pattern}\\] | \# [{$@] #{special_escapes} ) /mx
          else
            / (?= [#{delim_pattern}\\] #{special_escapes} ) /mx
          end
      }

      HEREDOC_PATTERN = Hash.new { |h, k|
        delim, interpreted, indented = *k
        delim_pattern = Regexp.escape(delim.dup)
        delim_pattern = / \n #{ '(?>[\ \t]*)' if indented } #{ Regexp.new delim_pattern } $ /x
        h[k] =
          if interpreted
            / (?= #{delim_pattern}() | \\ | \# [{$@] ) /mx  # $1 set == end of heredoc
          else
            / (?= #{delim_pattern}() | \\ ) /mx
          end
      }

      def initialize kind, interpreted, delim, heredoc = false
        if heredoc
          pattern = HEREDOC_PATTERN[ [delim, interpreted, heredoc == :indented] ]
          delim  = nil
        else
          pattern = STRING_PATTERN[ [delim, interpreted] ]
          if paren = CLOSING_PAREN[delim]
            delim, paren = paren, delim
            paren_depth = 1
          end
        end
        super kind, interpreted, delim, heredoc, paren, paren_depth, pattern, :initial
      end
    end unless defined? StringState

  end

end
end
