module CodeRay
module Encoders
  
  # Counts the LoC (Lines of Code). Returns an Integer >= 0.
  # 
  # Everything that is not comment, markup, doctype/shebang, or an empty line,
  # is considered to be code.
  # 
  # For example,
  # * HTML files not containing JavaScript have 0 LoC
  # * in a Java class without comments, LoC is the number of non-empty lines
  # 
  # A Scanner class should define the token kinds that are not code in the
  # KINDS_NOT_LOC constant.
  class LinesOfCode < Encoder
    
    register_for :lines_of_code
    
    NON_EMPTY_LINE = /^\s*\S.*$/
    
    def compile tokens, options
      kinds_not_loc = tokens.scanner.class::KINDS_NOT_LOC
      code = tokens.token_class_filter :exclude => kinds_not_loc
      @loc = code.text.scan(NON_EMPTY_LINE).size
    end
    
    def finish options
      @loc
    end
    
  end
  
end
end
