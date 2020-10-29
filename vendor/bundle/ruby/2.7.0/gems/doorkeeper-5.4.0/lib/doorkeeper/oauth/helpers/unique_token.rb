# frozen_string_literal: true

module Doorkeeper
  module OAuth
    module Helpers
      # Default Doorkeeper token generator. Follows OAuth RFC and
      # could be customized using `default_generator_method` in
      # configuration.
      module UniqueToken
        def self.generate(options = {})
          # Access Token value must be 1*VSCHAR or
          # 1*( ALPHA / DIGIT / "-" / "." / "_" / "~" / "+" / "/" ) *"="
          #
          # @see https://tools.ietf.org/html/rfc6749#appendix-A.12
          # @see https://tools.ietf.org/html/rfc6750#section-2.1
          #
          generator = options.delete(:generator) || SecureRandom.method(default_generator_method)
          token_size = options.delete(:size) || 32
          generator.call(token_size)
        end

        # Generator method for default generator class (SecureRandom)
        #
        def self.default_generator_method
          Doorkeeper.config.default_generator_method
        end
      end
    end
  end
end
