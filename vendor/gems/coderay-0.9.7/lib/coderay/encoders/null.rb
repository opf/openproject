module CodeRay
module Encoders

  # = Null Encoder
  #
  # Does nothing and returns an empty string.
  class Null < Encoder

    include Streamable
    register_for :null

    # Defined for faster processing
    def to_proc
      proc {}
    end

  protected

    def token(*)
      # do nothing
    end

  end

end
end
