module OpenProject
  class Token
    module Armor
      class ParseError < StandardError; end

      MARKER = 'OPENPROJECT-EE TOKEN'

      class << self
        def header
          "-----BEGIN #{MARKER}-----"
        end

        def footer
          "-----END #{MARKER}-----"
        end

        def encode(data)
          ''.tap do |s|
            s << header << "\n"

            s << data.strip << "\n"

            s << footer
          end
        end

        def decode(data)
          match = data.match /#{header}\r?\n(.+?)\r?\n#{footer}/m
          if match.nil?
            raise ParseError, 'Failed to parse armored text.'
          end

          match[1]
        end
      end
    end
  end
end
