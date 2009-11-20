module CodeRay module Scanners
	
	class PHP < Scanner

		register_for :php
		
		RESERVED_WORDS = [
          'and', 'or', 'xor', '__FILE__', 'exception', '__LINE__', 'array', 'as', 'break', 'case',
          'class', 'const', 'continue', 'declare', 'default',
          'die', 'do', 'echo', 'else', 'elseif',
          'empty', 'enddeclare', 'endfor', 'endforeach', 'endif',
          'endswitch', 'endwhile', 'eval', 'exit', 'extends',
          'for', 'foreach', 'function', 'global', 'if',
          'include', 'include_once', 'isset', 'list', 'new',
          'print', 'require', 'require_once', 'return', 'static',
          'switch', 'unset', 'use', 'var', 'while',
          '__FUNCTION__', '__CLASS__', '__METHOD__', 'final', 'php_user_filter',
          'interface', 'implements', 'extends', 'public', 'private',
          'protected', 'abstract', 'clone', 'try', 'catch',
          'throw', 'cfunction', 'old_function' 
		]

		PREDEFINED_CONSTANTS = [
			'null', '$this', 'true', 'false'
		]

		IDENT_KIND = WordList.new(:ident).
			add(RESERVED_WORDS, :reserved).
			add(PREDEFINED_CONSTANTS, :pre_constant)

		ESCAPE = / [\$\wrbfnrtv\n\\\/'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
		UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x

		def scan_tokens tokens, options

			state = :waiting_php
			string_type = nil
			regexp_allowed = true

			until eos?

				kind = :error
				match = nil

				if state == :initial
					
					if scan(/ \s+ | \\\n /x)
						kind = :space
						
				    elsif scan(/\?>/)
    				    kind = :char
    				    state = :waiting_php
						
					elsif scan(%r{ (//|\#) [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) }mx)
						kind = :comment
						regexp_allowed = false

					elsif match = scan(/ \# \s* if \s* 0 /x)
						match << scan_until(/ ^\# (?:elif|else|endif) .*? $ | \z /xm) unless eos?
						kind = :comment
						regexp_allowed = false

				  elsif regexp_allowed and scan(/\//)
				    tokens << [:open, :regexp]
				    state = :regex
						kind = :delimiter
						
					elsif scan(/ [-+*\/=<>?:;,!&^|()\[\]{}~%] | \.(?!\d) /x)
						kind = :operator
						regexp_allowed=true
						
					elsif match = scan(/ [$@A-Za-z_][A-Za-z_0-9]* /x)
						kind = IDENT_KIND[match]
						regexp_allowed=false
						
					elsif match = scan(/["']/)
						tokens << [:open, :string]
                        string_type = matched
						state = :string
						kind = :delimiter
				
					elsif scan(/0[xX][0-9A-Fa-f]+/)
						kind = :hex
						regexp_allowed=false
						
					elsif scan(/(?:0[0-7]+)(?![89.eEfF])/)
						kind = :oct
						regexp_allowed=false
						
					elsif scan(/(?:\d+)(?![.eEfF])/)
						kind = :integer
						regexp_allowed=false
						
					elsif scan(/\d[fF]?|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
						kind = :float
						regexp_allowed=false

					else
						getch
					end
					
				elsif state == :regex
					if scan(/[^\\\/]+/)
						kind = :content
				  elsif scan(/\\\/|\\/)
						kind = :content
				  elsif scan(/\//)
					  tokens << [matched, :delimiter]
				    tokens << [:close, :regexp]
				    state = :initial
				    next
				  else
				    getch
				    kind = :content
					end
				  
				elsif state == :string
					if scan(/[^\\"']+/)
						kind = :content
					elsif scan(/["']/)
						if string_type==matched
						  tokens << [matched, :delimiter]
						  tokens << [:close, :string]
						  state = :initial
						  string_type=nil
						  next
						else
						  kind = :content
						end
					elsif scan(/ \\ (?: \S ) /mox)
						kind = :char
					elsif scan(/ \\ | $ /x)
						kind = :error
						state = :initial
					else
						raise "else case \" reached; %p not handled." % peek(1), tokens
					end		
						
				elsif state == :waiting_php
                  if scan(/<\?php/m)
				    kind = :char
				    state = :initial
				  elsif scan(/[^<]+/)
				    kind = :comment
                  else
                    kind = :comment
                    getch
				  end
				else
					raise 'else-case reached', tokens
					
				end
				
				match ||= matched
        
				tokens << [match, kind]
				
			end
		  tokens
			
		end

	end

end end