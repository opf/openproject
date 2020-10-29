require "test_helper"
require 'stringex'
require 'i18n'

class LocalizationTest < Test::Unit::TestCase
  def setup
    I18n.locale = :en
    Stringex::Localization.reset!
  end

  def test_stores_translations
    Stringex::Localization.backend = :internal

    data = { one: "number one", two: "number two" }
    Stringex::Localization.store_translations :en, :test_store, data

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_store, key)
    end
  end

  def test_converts_translation_keys_to_symbols
    Stringex::Localization.backend = :internal

    data = { "one" => "number one", "two" => "number two" }
    Stringex::Localization.store_translations :en, :test_convert, data

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_convert, key)
      assert_equal value, Stringex::Localization.translate(:test_convert, key.to_sym)
    end
  end

  def test_can_translate
    Stringex::Localization.backend = :internal

    data = { one: "number one", two: "number two" }
    Stringex::Localization.store_translations :en, :test_translate, data

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_translate, key)
    end
  end

  def test_can_translate_when_given_string_as_key
    Stringex::Localization.backend = :internal

    data = { one: "number one", two: "number two" }
    Stringex::Localization.store_translations :en, :test_translate, data

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_translate, key.to_s)
    end
  end

  def test_returns_default_if_none_found
    Stringex::Localization.backend = :internal
    assert_equal "my default", Stringex::Localization.translate(:test_default, :nonexistent, default: "my default")
  end

  def test_returns_nil_if_no_default
    Stringex::Localization.backend = :internal
    assert_nil Stringex::Localization.translate(:test_no_default, :nonexistent)
  end

  def test_falls_back_to_default_locale
    Stringex::Localization.backend = :internal
    Stringex::Localization.default_locale = :es
    Stringex::Localization.locale = :da

    data = { "one" => "number one", "two" => "number two" }
    Stringex::Localization.store_translations :es, :test_default_locale, data

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_default_locale, key)
    end
  end

  def test_with_locale
    Stringex::Localization.backend = :internal
    Stringex::Localization.locale = :fr
    assert_equal :fr, Stringex::Localization.locale
    locale_set_in_block = nil
    Stringex::Localization.with_locale :da do
      locale_set_in_block = Stringex::Localization.locale
    end
    assert_equal :da, locale_set_in_block
    assert_equal :fr, Stringex::Localization.locale
  end

  def test_stores_translations_in_i18n
    Stringex::Localization.backend = :i18n

    data = { one: "number one", two: "number two" }
    Stringex::Localization.store_translations :en, :test_i18n_store, data

    data.each do |key, value|
      assert_equal value, I18n.translate("stringex.test_i18n_store.#{key}")
    end
  end

  def test_can_translate_using_i18n
    Stringex::Localization.backend = :i18n

    data = { one: "number one", two: "number two" }

    I18n.backend.store_translations :en, { stringex: { test_i18n_translation: data } }

    data.each do |key, value|
      assert_equal value, Stringex::Localization.translate(:test_i18n_translation, key)
    end
  end

  def test_allows_blank_translations
    [:internal, :i18n].each do |backend|
      Stringex::Localization.backend = backend

      assert_equal "Test blank", "Test&nbsp;blank".convert_miscellaneous_html_entities

      Stringex::Localization.store_translations :en, :html_entities, { nbsp: "" }
      assert_equal "Testblank", "Test&nbsp;blank".convert_miscellaneous_html_entities
    end
  end

  def test_assigns_locale_in_i18n_backend
    if other_locale = I18n.available_locales.find{|locale| ![:en, :de].include?(locale)}
      I18n.locale = :en
      Stringex::Localization.backend = :i18n

      assert_equal :en, Stringex::Localization.locale

      I18n.locale = other_locale
      assert_equal other_locale, Stringex::Localization.locale

      Stringex::Localization.locale = :de
      assert_equal :de, Stringex::Localization.locale
      assert_equal other_locale, I18n.locale

      Stringex::Localization.locale = nil
      assert_equal other_locale, Stringex::Localization.locale
      assert_equal other_locale, I18n.locale
    else
      flunk "No I18n locales are available except :de and :en so test will not work"
    end
  end

  def test_enforce_available_locales_default
    return unless I18n.respond_to?(:enforce_available_locales)
    Stringex::Localization.backend = :i18n
    assert_not_nil I18n.enforce_available_locales
    'Some String'.to_url
    assert_not_nil I18n.enforce_available_locales
  end

  def test_respects_user_enforce_available_locales_setting
    return unless I18n.respond_to?(:enforce_available_locales)
    Stringex::Localization.backend = :i18n
    I18n.enforce_available_locales = false
    'Some String'.to_url
    assert_equal false, I18n.enforce_available_locales
  end
end
