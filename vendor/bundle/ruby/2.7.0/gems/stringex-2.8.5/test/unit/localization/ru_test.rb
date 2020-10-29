# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class RussianYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :ru
    Stringex::Localization.locale = :ru
  end

  {
    "foo & bar" => "foo и bar",
    "AT&T" => "AT и T",
    "99° is normal" => "99 градусов is normal",
    "4 ÷ 2 is 2" => "4 делить на 2 is 2",
    "webcrawler.com" => "webcrawler точка com",
    "Well..." => "Well многоточие",
    "x=1" => "x равно 1",
    "a #2 pencil" => "a номер 2 pencil",
    "100%" => "100 процентов",
    "cost+tax" => "cost плюс tax",
    "batman/robin fan fiction" => "batman слеш robin fan fiction",
    "dial *69" => "dial звезда 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 рубль",
    "$100" => "100 долларов",
    "$19.99" => "19 долларов 99 центов",
    "£100" => "100 фунтов",
    "£19.99" => "19 фунтов 99 пенсов",
    "€100" => "100 евро",
    "€19.99" => "19 евро 99 центов",
    "¥1000" => "1000 йен"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea и Sympathy",
    "10&cent;" => "10 центов",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 градусов is fine",
    "10&divide;5" => "10 делить на 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "половина ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and одна четверть ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and три четверти ounces of platinum",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "фунтов 100",
    "Walmart&reg;" => "Walmart(r)",
    "&apos;single quoted&apos;" => "'single quoted'",
    "2&times;4" => "2x4",
    "Programming&trade;" => "Programming(tm)",
    "&yen;20000" => "йен 20000",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_html_entity_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_html_entities
    end
  end

  {
    "&frac12;" => "половина",
    "½" => "половина",
    "&#189;" => "половина",
    "⅓" => "одна треть",
    "&#8531;" => "одна треть",
    "⅔" => "две трети",
    "&#8532;" => "две трети",
    "&frac14;" => "одна четверть",
    "¼" => "одна четверть",
    "&#188;" => "одна четверть",
    "&frac34;" => "три четверти",
    "¾" => "три четверти",
    "&#190;" => "три четверти",
    "⅕" => "одна пятая",
    "&#8533;" => "одна пятая",
    "⅖" => "две пятых",
    "&#8534;" => "две пятых",
    "⅗" => "три пятых",
    "&#8535;" => "три пятых",
    "⅘" => "четыре пятых",
    "&#8536;" => "четыре пятых",
    "⅙" => "одна шестая",
    "&#8537;" => "одна шестая",
    "⅚" => "пять шестых",
    "&#8538;" => "пять шестых",
    "⅛" => "одна восьмая",
    "&#8539;" => "одна восьмая",
    "⅜" => "три восьмых",
    "&#8540;" => "три восьмых",
    "⅝" => "пять восьмых",
    "&#8541;" => "пять восьмых",
    "⅞" => "семь восьмых",
    "&#8542;" => "семь восьмых"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end

  {
    "foo & bar" => "foo-i-bar",
    "AT&T" => "at-i-t",
    "99° is normal" => "99-ghradusov-is-normal",
    "4 ÷ 2 is 2" => "4-dielit-na-2-is-2",
    "webcrawler.com" => "webcrawler-tochka-com",
  }.each do |original, converted|
    define_method "test_character_conversion_to_url: '#{original}'" do
      assert_equal converted, original.to_url
    end
  end
end
