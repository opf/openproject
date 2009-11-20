module CodeRay
module Scanners

  class Plaintext < Scanner

    register_for :plaintext, :plain
    
    include Streamable

    def scan_tokens tokens, options
      text = (scan_until(/\z/) || '')
      tokens << [text, :plain]
    end

  end

end
end
