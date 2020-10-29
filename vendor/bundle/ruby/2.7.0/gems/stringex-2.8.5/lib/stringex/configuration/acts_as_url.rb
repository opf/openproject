module Stringex
  module Configuration
    class ActsAsUrl < Base
      def initialize(options = {})
        if options[:scope]
          options[:scope_for_url] = options.delete(:scope)
        end
        super
      end

      def string_extensions_settings
        [
          :allow_slash,
          :exclude,
          :force_downcase,
          :limit,
          :replace_whitespace_with,
          :truncate_words
        ].inject(Hash.new){|m, x| m[x] = settings.send(x); m}
      end

      def self.settings
        @settings
      end

    private

      def default_settings
        self.class.default_settings
      end

      def self.default_settings
        @default_settings ||= {
          allow_duplicates: false,
          callback_method: :before_validation,
          duplicate_count_separator: "-",
          enforce_uniqueness_on_sti_base_class: false,
          only_when_blank: false,
          scope_for_url: nil,
          sync_url: false,
          url_attribute: "url",
          blacklist: %w[new],
          blacklist_policy: lambda { |instance, url|
            "#{url}-#{instance.class.to_s.downcase}"
          }
        }.merge(Stringex::Configuration::StringExtensions.new.default_settings)
      end
    end
  end
end
