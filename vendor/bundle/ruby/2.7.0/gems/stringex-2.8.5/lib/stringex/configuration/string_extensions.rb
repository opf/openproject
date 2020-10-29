module Stringex
  module Configuration
    class StringExtensions < Base
      def default_settings
        self.class.default_settings
      end

      def self.default_settings
        @default_settings ||= {
          allow_slash: false,
          exclude: [],
          force_downcase: true,
          limit: nil,
          replace_whitespace_with: "-",
          truncate_words: true
        }
      end
    end
  end
end
