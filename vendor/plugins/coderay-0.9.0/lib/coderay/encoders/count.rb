module CodeRay
module Encoders

  class Count < Encoder

    include Streamable
    register_for :count

    protected

    def setup options
      @out = 0
    end

    def token text, kind
      @out += 1
    end
  end

end
end
