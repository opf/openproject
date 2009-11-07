module CodeRay
module Encoders
  
  class Filter < Encoder
    
    register_for :filter
    
  protected
    def setup options
      @out = Tokens.new
    end
    
  end
  
end
end
