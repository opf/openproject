# encoding: utf-8
module CodeRay
module Scanners

  # This scanner is really complex, since Ruby _is_ a complex language!
  #
  # It tries to highlight 100% of all common code,
  # and 90% of strange codes.
  #
  # It is optimized for HTML highlighting, and is not very useful for
  # parsing or pretty printing.
  #
  # For now, I think it's better than the scanners in VIM or Syntax, or
  # any highlighter I was able to find, except Caleb's RubyLexer.
  #
  # I hope it's also better than the rdoc/irb lexer.
  class Ruby < Scanner

    include Streamable

    register_for :ruby
    file_extension 'rb'

    helper :patterns
    
    if not defined? EncodingError
      EncodingError = Class.new Exception
    end

  private
    def scan_tokens tokens, options
      if string.respond_to?(:encoding)
        unless string.encoding == Encoding::UTF_8
          self.string = string.encode Encoding::UTF_8,
            :invalid => :replace, :undef => :replace, :replace => '?'
        end
        unicode = false
      else
        unicode = exist?(/[^\x00-\x7f]/)
      end
      
      last_token_dot = false
      value_expected = true
      heredocs = nil
      last_state = nil
      state = :initial
      depth = nil
      inline_block_stack = []
      
      
      patterns = Patterns  # avoid constant lookup
      
      until eos?
        match = nil
        kind = nil

        if state.instance_of? patterns::StringState
# {{{
          match = scan_until(state.pattern) || scan_until(/\z/)
          tokens << [match, :content] unless match.empty?
          break if eos?

          if state.heredoc and self[1]  # end of heredoc
            match = getch.to_s
            match << scan_until(/$/) unless eos?
            tokens << [match, :delimiter]
            tokens << [:close, state.type]
            state = state.next_state
            next
          end

          case match = getch

          when state.delim
            if state.paren
              state.paren_depth -= 1
              if state.paren_depth > 0
                tokens << [match, :nesting_delimiter]
                next
              end
            end
            tokens << [match, :delimiter]
            if state.type == :regexp and not eos?
              modifiers = scan(/#{patterns::REGEXP_MODIFIERS}/ox)
              tokens << [modifiers, :modifier] unless modifiers.empty?
            end
            tokens << [:close, state.type]
            value_expected = false
            state = state.next_state

          when '\\'
            if state.interpreted
              if esc = scan(/ #{patterns::ESCAPE} /ox)
                tokens << [match + esc, :char]
              else
                tokens << [match, :error]
              end
            else
              case m = getch
              when state.delim, '\\'
                tokens << [match + m, :char]
              when nil
                tokens << [match, :error]
              else
                tokens << [match + m, :content]
              end
            end

          when '#'
            case peek(1)
            when '{'
              inline_block_stack << [state, depth, heredocs]
              value_expected = true
              state = :initial
              depth = 1
              tokens << [:open, :inline]
              tokens << [match + getch, :inline_delimiter]
            when '$', '@'
              tokens << [match, :escape]
              last_state = state  # scan one token as normal code, then return here
              state = :initial
            else
              raise_inspect 'else-case # reached; #%p not handled' % peek(1), tokens
            end

          when state.paren
            state.paren_depth += 1
            tokens << [match, :nesting_delimiter]

          when /#{patterns::REGEXP_SYMBOLS}/ox
            tokens << [match, :function]

          else
            raise_inspect 'else-case " reached; %p not handled, state = %p' % [match, state], tokens

          end
          next
# }}}
        else
# {{{
          if match = scan(/[ \t\f]+/)
            kind = :space
            match << scan(/\s*/) unless eos? || heredocs
            value_expected = true if match.index(?\n)
            tokens << [match, kind]
            next
            
          elsif match = scan(/\\?\n/)
            kind = :space
            if match == "\n"
              value_expected = true
              state = :initial if state == :undef_comma_expected
            end
            if heredocs
              unscan  # heredoc scanning needs \n at start
              state = heredocs.shift
              tokens << [:open, state.type]
              heredocs = nil if heredocs.empty?
              next
            else
              match << scan(/\s*/) unless eos?
            end
            tokens << [match, kind]
            next
          
          elsif bol? && match = scan(/\#!.*/)
            tokens << [match, :doctype]
            next
            
          elsif match = scan(/\#.*/) or
            ( bol? and match = scan(/#{patterns::RUBYDOC_OR_DATA}/o) )
              kind = :comment
              tokens << [match, kind]
              next

          elsif state == :initial

            # IDENTS #
            if match = scan(unicode ? /#{patterns::METHOD_NAME}/uo :
                                      /#{patterns::METHOD_NAME}/o)
              if last_token_dot
                kind = if match[/^[A-Z]/] and not match?(/\(/) then :constant else :ident end
              else
                if value_expected != :expect_colon && scan(/:(?= )/)
                  tokens << [match, :key]
                  match = ':'
                  kind = :operator
                else
                  kind = patterns::IDENT_KIND[match]
                  if kind == :ident
                    if match[/\A[A-Z]/] and not match[/[!?]$/] and not match?(/\(/)
                      kind = :constant
                    end
                  elsif kind == :reserved
                    state = patterns::DEF_NEW_STATE[match]
                    value_expected = :set if patterns::KEYWORDS_EXPECTING_VALUE[match]
                  end
                end
              end
              value_expected = :set if check(/#{patterns::VALUE_FOLLOWS}/o)
            
            elsif last_token_dot and match = scan(/#{patterns::METHOD_NAME_OPERATOR}|\(/o)
              kind = :ident
              value_expected = :set if check(unicode ? /#{patterns::VALUE_FOLLOWS}/uo :
                                                       /#{patterns::VALUE_FOLLOWS}/o)

            # OPERATORS #
            elsif not last_token_dot and match = scan(/ \.\.\.? | (?:\.|::)() | [,\(\)\[\]\{\}] | ==?=? /x)
              if match !~ / [.\)\]\}] /x or match =~ /\.\.\.?/
                value_expected = :set
              end
              last_token_dot = :set if self[1]
              kind = :operator
              unless inline_block_stack.empty?
                case match
                when '{'
                  depth += 1
                when '}'
                  depth -= 1
                  if depth == 0  # closing brace of inline block reached
                    state, depth, heredocs = inline_block_stack.pop
                    heredocs = nil if heredocs && heredocs.empty?
                    tokens << [match, :inline_delimiter]
                    kind = :inline
                    match = :close
                  end
                end
              end

            elsif match = scan(/ ['"] /mx)
              tokens << [:open, :string]
              kind = :delimiter
              state = patterns::StringState.new :string, match == '"', match  # important for streaming

            elsif match = scan(unicode ? /#{patterns::INSTANCE_VARIABLE}/uo :
                                         /#{patterns::INSTANCE_VARIABLE}/o)
              kind = :instance_variable

            elsif value_expected and match = scan(/\//)
              tokens << [:open, :regexp]
              kind = :delimiter
              interpreted = true
              state = patterns::StringState.new :regexp, interpreted, match

            # elsif match = scan(/[-+]?#{patterns::NUMERIC}/o)
            elsif match = value_expected ? scan(/[-+]?#{patterns::NUMERIC}/o) : scan(/#{patterns::NUMERIC}/o)
              kind = self[1] ? :float : :integer

            elsif match = scan(unicode ? /#{patterns::SYMBOL}/uo :
                                         /#{patterns::SYMBOL}/o)
              case delim = match[1]
              when ?', ?"
                tokens << [:open, :symbol]
                tokens << [':', :symbol]
                match = delim.chr
                kind = :delimiter
                state = patterns::StringState.new :symbol, delim == ?", match
              else
                kind = :symbol
              end

            elsif match = scan(/ -[>=]? | [+!~^]=? | [*|&]{1,2}=? | >>? /x)
              value_expected = :set
              kind = :operator

            elsif value_expected and match = scan(unicode ? /#{patterns::HEREDOC_OPEN}/uo :
                                                            /#{patterns::HEREDOC_OPEN}/o)
              indented = self[1] == '-'
              quote = self[3]
              delim = self[quote ? 4 : 2]
              kind = patterns::QUOTE_TO_TYPE[quote]
              tokens << [:open, kind]
              tokens << [match, :delimiter]
              match = :close
              heredoc = patterns::StringState.new kind, quote != '\'', delim, (indented ? :indented : :linestart )
              heredocs ||= []  # create heredocs if empty
              heredocs << heredoc

            elsif value_expected and match = scan(/#{patterns::FANCY_START_CORRECT}/o)
              kind, interpreted = *patterns::FancyStringType.fetch(self[1]) do
                raise_inspect 'Unknown fancy string: %%%p' % k, tokens
              end
              tokens << [:open, kind]
              state = patterns::StringState.new kind, interpreted, self[2]
              kind = :delimiter

            elsif value_expected and match = scan(unicode ? /#{patterns::CHARACTER}/uo :
                                                            /#{patterns::CHARACTER}/o)
              kind = :integer

            elsif match = scan(/ [\/%]=? | <(?:<|=>?)? | [?:;] /x)
              value_expected = :set
              kind = :operator

            elsif match = scan(/`/)
              if last_token_dot
                kind = :operator
              else
                tokens << [:open, :shell]
                kind = :delimiter
                state = patterns::StringState.new :shell, true, match
              end

            elsif match = scan(unicode ? /#{patterns::GLOBAL_VARIABLE}/uo :
                                         /#{patterns::GLOBAL_VARIABLE}/o)
              kind = :global_variable

            elsif match = scan(unicode ? /#{patterns::CLASS_VARIABLE}/uo :
                                         /#{patterns::CLASS_VARIABLE}/o)
              kind = :class_variable

            else
              if !unicode && !string.respond_to?(:encoding)
                # check for unicode
                debug, $DEBUG = $DEBUG, false
                begin
                  if check(/./mu).size > 1
                    # seems like we should try again with unicode
                    unicode = true
                  end
                rescue
                  # bad unicode char; use getch
                ensure
                  $DEBUG = debug
                end
                next if unicode
              end
              kind = :error
              match = scan(unicode ? /./mu : /./m)

            end

          elsif state == :def_expected
            state = :initial
            if scan(/self\./)
              tokens << ['self', :pre_constant]
              tokens << ['.', :operator]
            end
            if match = scan(unicode ? /(?>#{patterns::METHOD_NAME_EX})(?!\.|::)/uo :
                                      /(?>#{patterns::METHOD_NAME_EX})(?!\.|::)/o)
              kind = :method
            else
              next
            end

          elsif state == :module_expected
            if match = scan(/<</)
              kind = :operator
            else
              state = :initial
              if match = scan(unicode ? /(?:#{patterns::IDENT}::)*#{patterns::IDENT}/uo :
                                        /(?:#{patterns::IDENT}::)*#{patterns::IDENT}/o)
                kind = :class
              else
                next
              end
            end

          elsif state == :undef_expected
            state = :undef_comma_expected
            if match = scan(unicode ? /#{patterns::METHOD_NAME_EX}/uo :
                                      /#{patterns::METHOD_NAME_EX}/o)
              kind = :method
            elsif match = scan(unicode ? /#{patterns::SYMBOL}/uo :
                                         /#{patterns::SYMBOL}/o)
              case delim = match[1]
              when ?', ?"
                tokens << [:open, :symbol]
                tokens << [':', :symbol]
                match = delim.chr
                kind = :delimiter
                state = patterns::StringState.new :symbol, delim == ?", match
                state.next_state = :undef_comma_expected
              else
                kind = :symbol
              end
            else
              state = :initial
              next
            end

          elsif state == :alias_expected
            match = scan(unicode ? /(#{patterns::METHOD_NAME_OR_SYMBOL})([ \t]+)(#{patterns::METHOD_NAME_OR_SYMBOL})/uo :
                                   /(#{patterns::METHOD_NAME_OR_SYMBOL})([ \t]+)(#{patterns::METHOD_NAME_OR_SYMBOL})/o)
            
            if match
              tokens << [self[1], (self[1][0] == ?: ? :symbol : :method)]
              tokens << [self[2], :space]
              tokens << [self[3], (self[3][0] == ?: ? :symbol : :method)]
            end
            state = :initial
            next

          elsif state == :undef_comma_expected
            if match = scan(/,/)
              kind = :operator
              state = :undef_expected
            else
              state = :initial
              next
            end

          end
# }}}
          
          unless kind == :error
            if value_expected = value_expected == :set
              value_expected = :expect_colon if match == '?' || match == 'when'
            end
            last_token_dot = last_token_dot == :set
          end
          
          if $CODERAY_DEBUG and not kind
            raise_inspect 'Error token %p in line %d' %
              [[match, kind], line], tokens, state
          end
          raise_inspect 'Empty token', tokens unless match

          tokens << [match, kind]

          if last_state
            state = last_state
            last_state = nil
          end
        end
      end

      inline_block_stack << [state] if state.is_a? patterns::StringState
      until inline_block_stack.empty?
        this_block = inline_block_stack.pop
        tokens << [:close, :inline] if this_block.size > 1
        state = this_block.first
        tokens << [:close, state.type]
      end

      tokens
    end

  end

end
end

# vim:fdm=marker
