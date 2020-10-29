require "test_helper"
require 'stringex'

class LocalizationI18nFailureTest < Test::Unit::TestCase
  def setup
    alias_i18n
    Stringex::Localization.reset!
  end

  def test_loading_i18n_backend_fails_if_no_i18n_module
    assert_raise(Stringex::Localization::Backend::I18nNotDefined) do
      Stringex::Localization.backend = :i18n
    end
  ensure
    unalias_i18n
  end

  def test_loading_i18n_backend_fails_if_i18n_defined_without_translate
    Object.send :const_set, :I18n, Module.new

    assert_raise(Stringex::Localization::Backend::I18nMissingTranslate) do
      Stringex::Localization.backend = :i18n
    end
  ensure
    Object.send :remove_const, :I18n
    unalias_i18n
  end

private

  def alias_i18n
    Object.send :const_set, :I18nBackup, I18n
    Object.send :remove_const, :I18n
  end

  def unalias_i18n
    Object.send :const_set, :I18n, I18nBackup
    Object.send :remove_const, :I18nBackup
  end
end
