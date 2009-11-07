module CodeRay
module Encoders
  
  # = JSON Encoder
  class JSON < Encoder
    
    register_for :json
    FILE_EXTENSION = 'json'
    
  protected
    def compile tokens, options
      require 'json'
      @out = tokens.to_a.to_json
    end
    
  end
  
end
end
