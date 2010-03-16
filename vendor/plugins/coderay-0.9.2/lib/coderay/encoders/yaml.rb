module CodeRay
module Encoders

  # = YAML Encoder
  #
  # Slow.
  class YAML < Encoder

    register_for :yaml

    FILE_EXTENSION = 'yaml'

  protected
    def compile tokens, options
      require 'yaml'
      @out = tokens.to_a.to_yaml
    end

  end

end
end
