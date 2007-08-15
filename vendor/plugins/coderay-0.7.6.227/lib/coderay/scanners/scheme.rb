module CodeRay
  module Scanners

    # Scheme scanner for CodeRay (by closure).
    # Thanks to murphy for putting CodeRay into public.
    class Scheme < Scanner
      
      register_for :scheme
      file_extension :scm

      CORE_FORMS = %w[
        lambda let let* letrec syntax-case define-syntax let-syntax
        letrec-syntax begin define quote if or and cond case do delay
        quasiquote set! cons force call-with-current-continuation call/cc
      ]

      IDENT_KIND = CaseIgnoringWordList.new(:ident).
        add(CORE_FORMS, :reserved)
      
      #IDENTIFIER_INITIAL = /[a-z!@\$%&\*\/\:<=>\?~_\^]/i
      #IDENTIFIER_SUBSEQUENT = /#{IDENTIFIER_INITIAL}|\d|\.|\+|-/
      #IDENTIFIER = /#{IDENTIFIER_INITIAL}#{IDENTIFIER_SUBSEQUENT}*|\+|-|\.{3}/
      IDENTIFIER = /[a-zA-Z!@$%&*\/:<=>?~_^][\w!@$%&*\/:<=>?~^.+\-]*|[+-]|\.\.\./
      DIGIT = /\d/
      DIGIT10 = DIGIT
      DIGIT16 = /[0-9a-f]/i
      DIGIT8 = /[0-7]/
      DIGIT2 = /[01]/
      RADIX16 = /\#x/i
      RADIX8 = /\#o/i
      RADIX2 = /\#b/i
      RADIX10 = /\#d/i
      EXACTNESS = /#i|#e/i
      SIGN = /[\+-]?/
      EXP_MARK = /[esfdl]/i
      EXP = /#{EXP_MARK}#{SIGN}#{DIGIT}+/
      SUFFIX = /#{EXP}?/
      PREFIX10 = /#{RADIX10}?#{EXACTNESS}?|#{EXACTNESS}?#{RADIX10}?/
      PREFIX16 = /#{RADIX16}#{EXACTNESS}?|#{EXACTNESS}?#{RADIX16}/
      PREFIX8 = /#{RADIX8}#{EXACTNESS}?|#{EXACTNESS}?#{RADIX8}/
      PREFIX2 = /#{RADIX2}#{EXACTNESS}?|#{EXACTNESS}?#{RADIX2}/
      UINT10 = /#{DIGIT10}+#*/
      UINT16 = /#{DIGIT16}+#*/
      UINT8 = /#{DIGIT8}+#*/
      UINT2 = /#{DIGIT2}+#*/
      DECIMAL = /#{DIGIT10}+#+\.#*#{SUFFIX}|#{DIGIT10}+\.#{DIGIT10}*#*#{SUFFIX}|\.#{DIGIT10}+#*#{SUFFIX}|#{UINT10}#{EXP}/
      UREAL10 = /#{UINT10}\/#{UINT10}|#{DECIMAL}|#{UINT10}/
      UREAL16 = /#{UINT16}\/#{UINT16}|#{UINT16}/
      UREAL8 = /#{UINT8}\/#{UINT8}|#{UINT8}/
      UREAL2 = /#{UINT2}\/#{UINT2}|#{UINT2}/
      REAL10 = /#{SIGN}#{UREAL10}/
      REAL16 = /#{SIGN}#{UREAL16}/
      REAL8 = /#{SIGN}#{UREAL8}/
      REAL2 = /#{SIGN}#{UREAL2}/
      IMAG10 = /i|#{UREAL10}i/
      IMAG16 = /i|#{UREAL16}i/
      IMAG8 = /i|#{UREAL8}i/
      IMAG2 = /i|#{UREAL2}i/
      COMPLEX10 = /#{REAL10}@#{REAL10}|#{REAL10}\+#{IMAG10}|#{REAL10}-#{IMAG10}|\+#{IMAG10}|-#{IMAG10}|#{REAL10}/
      COMPLEX16 = /#{REAL16}@#{REAL16}|#{REAL16}\+#{IMAG16}|#{REAL16}-#{IMAG16}|\+#{IMAG16}|-#{IMAG16}|#{REAL16}/
      COMPLEX8 = /#{REAL8}@#{REAL8}|#{REAL8}\+#{IMAG8}|#{REAL8}-#{IMAG8}|\+#{IMAG8}|-#{IMAG8}|#{REAL8}/
      COMPLEX2 = /#{REAL2}@#{REAL2}|#{REAL2}\+#{IMAG2}|#{REAL2}-#{IMAG2}|\+#{IMAG2}|-#{IMAG2}|#{REAL2}/
      NUM10 = /#{PREFIX10}?#{COMPLEX10}/
      NUM16 = /#{PREFIX16}#{COMPLEX16}/
      NUM8 = /#{PREFIX8}#{COMPLEX8}/
      NUM2 = /#{PREFIX2}#{COMPLEX2}/
      NUM = /#{NUM10}|#{NUM16}|#{NUM8}|#{NUM2}/
    
    private
      def scan_tokens tokens,options
        
        state = :initial
        ident_kind = IDENT_KIND
        
        until eos?
          kind = match = nil
          
          case state
          when :initial
            if scan(/ \s+ | \\\n /x)
              kind = :space
            elsif scan(/['\(\[\)\]]|#\(/)
              kind = :operator_fat
            elsif scan(/;.*/)
              kind = :comment
            elsif scan(/#\\(?:newline|space|.?)/)
              kind = :char
            elsif scan(/#[ft]/)
              kind = :pre_constant
            elsif scan(/#{IDENTIFIER}/o)
              kind = ident_kind[matched]
            elsif scan(/\./)
              kind = :operator
            elsif scan(/"/)
              tokens << [:open, :string]
              state = :string
              tokens << ['"', :delimiter]
              next
            elsif scan(/#{NUM}/o) and not matched.empty?
              kind = :integer
            elsif getch
              kind = :error
            end
            
          when :string
            if scan(/[^"\\]+/) or scan(/\\.?/)
              kind = :content
            elsif scan(/"/)
              tokens << ['"', :delimiter]
              tokens << [:close, :string]
              state = :initial
              next
            else
              raise_inspect "else case \" reached; %p not handled." % peek(1),
                tokens, state
            end
            
          else
            raise "else case reached"
          end
          
          match ||= matched
          if $DEBUG and not kind
            raise_inspect 'Error token %p in line %d' %
            [[match, kind], line], tokens
          end
          raise_inspect 'Empty token', tokens, state unless match
          
          tokens << [match, kind]
          
        end  # until eos
        
        if state == :string
          tokens << [:close, :string]
        end
        
        tokens
        
      end #scan_tokens
    end #class
  end #module scanners
end #module coderay