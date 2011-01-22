class VHDL < CodeRay::Scanners::Scanner

  register_for :vhdl

  RESERVED_WORDS = [
    'access','after','alias','all','assert','architecture','begin',
    'block','body','buffer','bus','case','component','configuration','constant',
    'disconnect','downto','else','elsif','end','entity','exit','file','for',
    'function','generate','generic','group','guarded','if','impure','in',
    'inertial','inout','is','label','library','linkage','literal','loop',
    'map','new','next','null','of','on','open','others','out','package',
    'port','postponed','procedure','process','pure','range','record','register',
    'reject','report','return','select','severity','signal','shared','subtype',
    'then','to','transport','type','unaffected','units','until','use','variable',
    'wait','when','while','with','note','warning','error','failure','and',
    'or','xor','not','nor',
    'array'
  ]

  PREDEFINED_TYPES = [
    'bit','bit_vector','character','boolean','integer','real','time','string',
    'severity_level','positive','natural','signed','unsigned','line','text',
    'std_logic','std_logic_vector','std_ulogic','std_ulogic_vector','qsim_state',
    'qsim_state_vector','qsim_12state','qsim_12state_vector','qsim_strength',
    'mux_bit','mux_vector','reg_bit','reg_vector','wor_bit','wor_vector'
  ]

  PREDEFINED_CONSTANTS = [

  ]

  IDENT_KIND = CodeRay::CaseIgnoringWordList.new(:ident).
    add(RESERVED_WORDS, :reserved).
    add(PREDEFINED_TYPES, :pre_type).
    add(PREDEFINED_CONSTANTS, :pre_constant)

  ESCAPE = / [rbfntv\n\\'"] | x[a-fA-F0-9]{1,2} | [0-7]{1,3} /x
  UNICODE_ESCAPE =  / u[a-fA-F0-9]{4} | U[a-fA-F0-9]{8} /x

  def scan_tokens tokens, options

    state = :initial

    until eos?

      kind = nil
      match = nil

      case state

      when :initial

        if scan(/ \s+ | \\\n /x)
          kind = :space

        elsif scan(/-- .*/x)
          kind = :comment

        elsif scan(/ [-+*\/=<>?:;,!&^|()\[\]{}~%]+ | \.(?!\d) /x)
          kind = :operator

        elsif match = scan(/ [A-Za-z_][A-Za-z_0-9]* /x)
          kind = IDENT_KIND[match.downcase]

        elsif match = scan(/[a-z]?"/i)
          tokens << [:open, :string]
          state = :string
          kind = :delimiter

        elsif scan(/ L?' (?: [^\'\n\\] | \\ #{ESCAPE} )? '? /ox)
          kind = :char

        elsif scan(/(?:\d+)(?![.eEfF])/)
          kind = :integer

        elsif scan(/\d[fF]?|\d*\.\d+(?:[eE][+-]?\d+)?[fF]?|\d+[eE][+-]?\d+[fF]?/)
          kind = :float

        else
          getch
          kind = :error

        end

      when :string
        if scan(/[^\\\n"]+/)
          kind = :content
        elsif scan(/"/)
          tokens << ['"', :delimiter]
          tokens << [:close, :string]
          state = :initial
          next
        elsif scan(/ \\ (?: #{ESCAPE} | #{UNICODE_ESCAPE} ) /mox)
          kind = :char
        elsif scan(/ \\ | $ /x)
          tokens << [:close, :string]
          kind = :error
          state = :initial
        else
          raise_inspect "else case \" reached; %p not handled." % peek(1), tokens
        end

      else
        raise_inspect 'Unknown state', tokens

      end

      match ||= matched
      if $DEBUG and not kind
        raise_inspect 'Error token %p in line %d' %
          [[match, kind], line], tokens
      end
      raise_inspect 'Empty token', tokens unless match

      tokens << [match, kind]

    end

    if state == :string
      tokens << [:close, :string]
    end

    tokens
  end

end
