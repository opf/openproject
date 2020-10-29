module Stringex
  module Localization
    module Backend
      class I18n < Base
        LOAD_PATH_BASE = File.join(File.expand_path(File.dirname(__FILE__)), '..', '..', '..', '..', 'locales')

        class << self
          def reset!
            super
            @locale = nil
            ::I18n.reload! if defined?(::I18n) && ::I18n.respond_to?(:reload!)
          end

          def locale
            @locale || ::I18n.locale
          end

          def locale=(new_locale)
            @locale = new_locale
          end

          def default_locale
            ::I18n.default_locale
          end

          def default_locale=(new_locale)
            ::I18n.default_locale = new_locale
          end

          def with_locale(new_locale, &block)
            ::I18n.with_locale new_locale, &block
          end

          def store_translations(locale, scope, data)
            ::I18n.backend.store_translations(locale, {stringex: {scope => data}})
            reset_translations_cache
          end

          def translations
            # Set up hash like translations[:en][:transliterations]["é"]
            @translations ||= Hash.new { |hsh, locale| hsh[locale] = Hash.new({}).merge(i18n_translations_for(locale)) }
          end

          def initial_translation(scope, key, locale)
            translations[locale][scope][key.to_sym]
          end

          def load_translations(locale = nil)
            locale ||= self.locale
            ::I18n.load_path |= Dir[File.join(LOAD_PATH_BASE, "#{locale}.yml")]
            ::I18n.backend.load_translations
            reset_translations_cache
          end

          def i18n_translations_for(locale)
            ensure_locales_enforced_or_not
            ::I18n.translate("stringex", locale: locale, default: {})
          end

          def reset_translations_cache
            @translations = nil
          end

          def ensure_locales_enforced_or_not
            return unless ::I18n.respond_to?(:enforce_available_locales)
            # Allow users to have set this to false manually but default to true
            return unless ::I18n.enforce_available_locales == nil
            ::I18n.enforce_available_locales = ::I18n.available_locales != []
          end
        end
      end

      class I18nNotDefined < RuntimeError
        def initialize
          super 'Stringex cannot use I18n backend: I18n is not defined'
        end
      end

      class I18nMissingTranslate < RuntimeError
        def initialize
          super 'Stringex cannot use I18n backend: I18n is defined but missing a translate method'
        end
      end
    end
  end
end
