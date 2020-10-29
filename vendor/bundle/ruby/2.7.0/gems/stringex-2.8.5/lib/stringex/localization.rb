# encoding: UTF-8

require 'stringex/localization/converter'
require 'stringex/localization/default_conversions'
require 'stringex/localization/backend/base'
require 'stringex/localization/backend/internal'
require 'stringex/localization/backend/i18n'

module Stringex
  module Localization
    include DefaultConversions

    class << self
      def backend
        @backend ||= i18n_present? ? Backend::I18n : Backend::Internal
      end

      def backend=(sym_or_class)
        if sym_or_class.is_a?(Symbol)
          @backend = case sym_or_class
          when :internal
            Backend::Internal
          when :i18n
            ensure_i18n!
            Backend::I18n
          else
            raise "Invalid backend :#{sym_or_class}"
          end
        else
          @backend = sym_or_class
        end
      end

      def store_translations(locale, scope, data)
        backend.store_translations(locale, scope, data)
      end

      def translate(scope, key, options = {})
        return if key == "." # I18n doesn't support dots as translation keys so we don't either

        locale = options[:locale] || self.locale

        translation = initial_translation(scope, key, locale)

        return translation unless translation.nil?

        if locale != default_locale
          translate scope, key, options.merge(locale: default_locale)
        else
          default_conversion(scope, key) || options[:default]
        end
      end

      def locale
        backend.locale
      end

      def locale=(new_locale)
        backend.locale = new_locale
      end

      def default_locale
        backend.default_locale
      end

      def default_locale=(new_locale)
        backend.default_locale = new_locale
      end

      def with_locale(new_locale, &block)
        new_locale = default_locale if new_locale == :default
        backend.with_locale new_locale, &block
      end

      def with_default_locale(&block)
        with_locale default_locale, &block
      end

      def reset!
        backend.reset!
        @backend = nil
      end

      def convert(string, options = {}, &block)
        converter = Converter.new(string, options)
        converter.instance_exec(&block)
        converter.smart_strip!
        converter.string
      end

    private

      def initial_translation(scope, key, locale)
        backend.initial_translation(scope, key, locale)
      end

      def default_conversion(scope, key)
        return unless DefaultConversions.respond_to?(scope)
        DefaultConversions.send(scope)[key]
      end

      def i18n_present?
        defined?(I18n) && I18n.respond_to?(:translate)
      end

      def ensure_i18n!
        raise Backend::I18nNotDefined unless defined?(I18n)
        raise Backend::I18nMissingTranslate unless I18n.respond_to?(:translate)
      end
    end
  end
end
