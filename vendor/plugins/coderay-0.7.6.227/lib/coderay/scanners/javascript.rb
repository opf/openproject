# http://pastie.textmate.org/50774/
module CodeRay module Scanners
	
	class JavaScript < Scanner

		register_for :javascript
		
		RESERVED_WORDS = [
			'asm', 'break', 'case', 'continue', 'default', 'do', 'else',
			'for', 'goto', 'if', 'return', 'switch', 'while',
#			'struct', 'union', 'enum', 'typedef',
#			'static', 'register', 'auto', 'extern',
#			'sizeof',
      'typeof',
#			'volatile', 'const',  # C89
#			'inline', 'restrict', # C99			
			'var', 'function','try','new','in',
			'instanceof','throw','catch'
		]

		PREDEFINED_CONSTANTS = [
			'void', 'null', 'this',
			'true', 'false','undefined',
		]

		IDENT_KIND = WordList.new(:ident).
			add(RESERVED_WORDS, :reserved).
			add(PREDEFINED_CONSTANTS, :pre_constant)

		ESCAPE = / [rbfnrtv\n\\\/'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
		UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x

		def scan_tokens tokens, options

			state = :initial
			string_type = nil
			regexp_allowed = true

			until eos?

				kind = :error
				match = nil

				if state == :initial
					
					if scan(/ \s+ | \\\n /x)
						kind = :space
						
					elsif scan(%r! // [^\n\\]* (?: \\. [^\n\\]* )* | /\* (?: .*? \*/ | .* ) !mx)
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
						
					elsif match = scan(/ [$A-Za-z_][A-Za-z_0-9]* /x)
						kind = IDENT_KIND[match]
#						if kind == :ident and check(/:(?!:)/)
#							match << scan(/:/)
#							kind = :label
#						end
						regexp_allowed=false
						
					elsif match = scan(/["']/)
						tokens << [:open, :string]
            string_type = matched
						state = :string
						kind = :delimiter
						
#					elsif scan(/#\s*(\w*)/)
#						kind = :preprocessor  # FIXME multiline preprocs
#						state = :include_expected if self[1] == 'include'
#						
#					elsif scan(/ L?' (?: [^\'\n\\] | \\ #{ESCAPE} )? '? /ox)
#						kind = :char
				
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
				  elsif scan(/\\\/|\\\\/)
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
					elsif scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
						kind = :char
					elsif scan(/ \\ | $ /x)
						kind = :error
						state = :initial
					else
						raise "else case \" reached; %p not handled." % peek(1), tokens
					end
					
#				elsif state == :include_expected
#					if scan(/<[^>\n]+>?|"[^"\n\\]*(?:\\.[^"\n\\]*)*"?/)
#						kind = :include
#						state = :initial
#						
#					elsif match = scan(/\s+/)
#						kind = :space
#						state = :initial if match.index ?\n
#						
#					else
#						getch
#						
#					end
#					
				else
					raise 'else-case reached', tokens
					
				end
				
				match ||= matched
#				raise [match, kind], tokens if kind == :error
        
				tokens << [match, kind]
				
			end
		  tokens
			
		end

	end

end end