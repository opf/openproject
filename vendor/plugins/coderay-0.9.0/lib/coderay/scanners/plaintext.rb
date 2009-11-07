module CodeRay
module Scanners

  class Plaintext < Scanner

    register_for :plaintext, :plain
    title 'Plain text'
    
    include Streamable
    
    KINDS_NOT_LOC = [:plain]
    
    def scan_tokens tokens, options
      text = (scan_until(/\z/) || '')
      tokens << [text, :plain]
    end

  end

end
end
