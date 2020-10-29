module Stringex
  module Localization
    module Backend
      class Internal < Base
        DEFAULT_LOCALE = :en

        class << self
          def locale
            @locale || default_locale
          end

          def locale=(new_locale)
            @locale = new_locale.to_sym
          end

          def default_locale
            @default_locale || DEFAULT_LOCALE
          end

          def default_locale=(new_locale)
            @default_locale = @locale = new_locale.to_sym
          end

          def with_locale(new_locale, &block)
            original_locale = locale
            self.locale = new_locale
            yield
            self.locale = original_locale
          end

          def translations
            # Set up hash like translations[:en][:transliterations]["é"]
            @translations ||= Hash.new { |k, v| k[v] = Hash.new({}) }
          end

          def store_translations(locale, scope, data)
            self.translations[locale.to_sym][scope.to_sym] = Hash[data.map { |k, v| [k.to_sym, v] }] # Symbolize keys
          end

          def initial_translation(scope, key, locale)
            translations[locale][scope][key.to_sym]
          end
        end
      end
    end
  end
end