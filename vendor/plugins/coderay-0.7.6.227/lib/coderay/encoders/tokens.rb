module CodeRay
module Encoders

  # The Tokens encoder converts the tokens to a simple
  # readable format. It doesn't use colors and is mainly
  # intended for console output.
  #
  # The tokens are converted with Tokens.write_token.
  #
  # The format is:
  #
  #   <token-kind> \t <escaped token-text> \n
  #
  # Example:
  #
  #   require 'coderay'
  #   puts CodeRay.scan("puts 3 + 4", :ruby).tokens
  #
  # prints:
  #
  #   ident   puts
  #   space
  #   integer 3
  #   space
  #   operator        +
  #   space
  #   integer 4
  #
  class Tokens < Encoder

    include Streamable
    register_for :tokens

    FILE_EXTENSION = 'tok'

  protected
    def token text, kind
      @out << CodeRay::Tokens.write_token(text, kind)
    end

  end

end
end
