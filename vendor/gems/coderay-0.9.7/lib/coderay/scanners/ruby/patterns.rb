# encoding: utf-8
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
    ALIAS_KEYWORDS = %w[ alias ]
    MODULE_KEYWORDS = %w[ class module ]
    DEF_NEW_STATE = WordList.new(:initial).
      add(DEF_KEYWORDS, :def_expected).
      add(UNDEF_KEYWORDS, :undef_expected).
      add(ALIAS_KEYWORDS, :alias_expected).
      add(MODULE_KEYWORDS, :module_expected)

    PREDEFINED_CONSTANTS = %w[
      nil true false self
      DATA ARGV ARGF
      __FILE__ __LINE__ __ENCODING__
    ]

    IDENT_KIND = WordList.new(:ident).
      add(RESERVED_WORDS, :reserved).
      add(PREDEFINED_CONSTANTS, :pre_constant)

    if /\w/u === '∑'
      # MRI 1.8.6, 1.8.7
      IDENT = /[^\W\d]\w*/
    else
      if //.respond_to? :encoding
        # MRI 1.9.1, 1.9.2
        IDENT = Regexp.new '[\p{L}\p{M}\p{Pc}\p{Sm}&&[^\x00-\x40\x5b-\x5e\x60\x7b-\x7f]][\p{L}\p{M}\p{N}\p{Pc}\p{Sm}&&[^\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]]*'
      else
        # JRuby, Rubinius
        IDENT = /[^\x00-\x40\x5b-\x5e\x60\x7b-\x7f][^\x00-\x2f\x3a-\x40\x5b-\x5e\x60\x7b-\x7f]*/
      end
    end

    METHOD_NAME = / #{IDENT} [?!]? /ox
    METHOD_NAME_OPERATOR = /
      \*\*?           # multiplication and power
      | [-+~]@?       # plus, minus, tilde with and without at sign
      | [\/%&|^`]     # division, modulo or format strings, and, or, xor, system
      | \[\]=?        # array getter and setter
      | << | >>       # append or shift left, shift right
      | <=?>? | >=?   # comparison, rocket operator
      | ===? | =~     # simple equality, case equality, match
      | ![~=@]?       # negation with and without at sign, not-equal and not-match
    /ox
    METHOD_NAME_EX = / #{IDENT} (?:[?!]|=(?!>))? | #{METHOD_NAME_OPERATOR} /ox
    INSTANCE_VARIABLE = / @ #{IDENT} /ox
    CLASS_VARIABLE = / @@ #{IDENT} /ox
    OBJECT_VARIABLE = / @@? #{IDENT} /ox
    GLOBAL_VARIABLE = / \$ (?: #{IDENT} | [1-9]\d* | 0\w* | [~&+`'=\/,;_.<>!@$?*":\\] | -[a-zA-Z_0-9] ) /ox
    PREFIX_VARIABLE = / #{GLOBAL_VARIABLE} | #{OBJECT_VARIABLE} /ox
    VARIABLE = / @?@? #{IDENT} | #{GLOBAL_VARIABLE} /ox

    QUOTE_TO_TYPE = {
      '`' => :shell,
      '/'=> :regexp,
    }
    QUOTE_TO_TYPE.default = :string

    REGEXP_MODIFIERS = /[mixounse]*/
    REGEXP_SYMBOLS = /[|?*+(){}\[\].^$]/

    DECIMAL = /\d+(?:_\d+)*/
    OCTAL = /0_?[0-7]+(?:_[0-7]+)*/
    HEXADECIMAL = /0x[0-9A-Fa-f]+(?:_[0-9A-Fa-f]+)*/
    BINARY = /0b[01]+(?:_[01]+)*/

    EXPONENT = / [eE] [+-]? #{DECIMAL} /ox
    FLOAT_SUFFIX = / #{EXPONENT} | \. #{DECIMAL} #{EXPONENT}? /ox
    FLOAT_OR_INT = / #{DECIMAL} (?: #{FLOAT_SUFFIX} () )? /ox
    NUMERIC = / (?: (?=0) (?: #{OCTAL} | #{HEXADECIMAL} | #{BINARY} ) | #{FLOAT_OR_INT} ) /ox

    SYMBOL = /
      :
      (?:
        #{METHOD_NAME_EX}
      | #{PREFIX_VARIABLE}
      | ['"]
      )
    /ox
    METHOD_NAME_OR_SYMBOL = / #{METHOD_NAME_EX} | #{SYMBOL} /ox

    SIMPLE_ESCAPE = /
        [abefnrstv]
      |  [0-7]{1,3}
      | x[0-9A-Fa-f]{1,2}
      | .?
    /mx
    
    CONTROL_META_ESCAPE = /
      (?: M-|C-|c )
      (?: \\ (?: M-|C-|c ) )*
      (?: [^\\] | \\ #{SIMPLE_ESCAPE} )?
    /mox
    
    ESCAPE = /
      #{CONTROL_META_ESCAPE} | #{SIMPLE_ESCAPE}
    /mox
    
    CHARACTER = /
      \?
      (?:
        [^\s\\]
      | \\ #{ESCAPE}
      )
    /mox

    # NOTE: This is not completely correct, but
    # nobody needs heredoc delimiters ending with \n.
    # Also, delimiters starting with numbers are allowed.
    # but they are more often than not a false positive.
    HEREDOC_OPEN = /
      << (-)?              # $1 = float
      (?:
        ( #{IDENT} )       # $2 = delim
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
    # value_expected in method calls without parentheses.
    VALUE_FOLLOWS = /
      (?>[ \t\f\v]+)
      (?:
        [%\/][^\s=]
      | <<-?\S
      | [-+] \d
      | #{CHARACTER}
      )
    /x
    KEYWORDS_EXPECTING_VALUE = WordList.new.add(%w[
      and end in or unless begin
      defined? ensure redo super until
      break do next rescue then
      when case else for retry
      while elsif if not return
      yield
    ])

    RUBYDOC_OR_DATA = / #{RUBYDOC} | #{DATA} /xo

    RDOC_DATA_START = / ^=begin (?!\S) | ^__END__$ /x

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

      CLOSING_PAREN.each { |k,v| k.freeze; v.freeze }  # debug, if I try to change it with <<
      OPENING_PAREN = CLOSING_PAREN.invert

      STRING_PATTERN = Hash.new do |h, k|
        delim, interpreted = *k
        delim_pattern = Regexp.escape(delim.dup)  # dup: workaround for old Ruby
        if closing_paren = CLOSING_PAREN[delim]
          delim_pattern = delim_pattern[0..-1] if defined? JRUBY_VERSION  # JRuby fix
          delim_pattern << Regexp.escape(closing_paren)
        end
        delim_pattern << '\\\\' unless delim == '\\'
        
        special_escapes =
          case interpreted
          when :regexp_symbols
            '| ' + REGEXP_SYMBOLS.source
          when :words
            '| \s'
          end
        
        h[k] =
          if interpreted and not delim == '#'
            / (?= [#{delim_pattern}] | \# [{$@] #{special_escapes} ) /mx
          else
            / (?= [#{delim_pattern}] #{special_escapes} ) /mx
          end
      end

      HEREDOC_PATTERN = Hash.new do |h, k|
        delim, interpreted, indented = *k
        delim_pattern = Regexp.escape(delim.dup)  # dup: workaround for old Ruby
        delim_pattern = / \n #{ '(?>[\ \t]*)' if indented } #{ Regexp.new delim_pattern } $ /x
        h[k] =
          if interpreted
            / (?= #{delim_pattern}() | \\ | \# [{$@] ) /mx  # $1 set == end of heredoc
          else
            / (?= #{delim_pattern}() | \\ ) /mx
          end
      end

      def initialize kind, interpreted, delim, heredoc = false
        if heredoc
          pattern = HEREDOC_PATTERN[ [delim, interpreted, heredoc == :indented] ]
          delim = nil
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
