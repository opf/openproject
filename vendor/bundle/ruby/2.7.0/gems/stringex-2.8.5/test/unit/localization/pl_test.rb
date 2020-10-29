# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class PolishYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :pl
    Stringex::Localization.locale = :pl
  end

  {
    "foo & bar" => "foo i bar",
    "AT&T" => "AT i T",
    "99° is normal" => "99 stopni is normal",
    "4 ÷ 2 is 2" => "4 podzielone przez 2 is 2",
    "webcrawler.com" => "webcrawler kropka com",
    "Well..." => "Well kropka kropka kropka",
    "x=1" => "x równy 1",
    "a #2 pencil" => "a numer 2 pencil",
    "100%" => "100 procent",
    "cost+tax" => "cost plus tax",
    "batman/robin fan fiction" => "batman ukośnik robin fan fiction",
    "dial *69" => "dial gwiazdka 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 złotych",
    "$100" => "100 dolarów",
    "$19.99" => "19 dolarów 99 centów",
    "£100" => "100 funtów",
    "£19.99" => "19 funtów 99 pensów",
    "€100" => "100 euro",
    "€19.99" => "19 euro 99 centów",
    "¥1000" => "1000 jenów"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea i Sympathy",
    "10&cent;" => "10 centów",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 stopni is fine",
    "10&divide;5" => "10 podzielone przez 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "pół ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and jedna czwarta ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and trzy czwarte ounces of platinum",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "funtów 100",
    "Walmart&reg;" => "Walmart(r)",
    "&apos;single quoted&apos;" => "'single quoted'",
    "2&times;4" => "2x4",
    "Programming&trade;" => "Programming(TM)",
    "&yen;20000" => "jen 20000",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_html_entity_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_html_entities
    end
  end

  {
    "&frac12;" => "pół",
    "½" => "pół",
    "&#189;" => "pół",
    "⅓" => "jedna trzecia",
    "&#8531;" => "jedna trzecia",
    "⅔" => "dwie trzecie",
    "&#8532;" => "dwie trzecie",
    "&frac14;" => "jedna czwarta",
    "¼" => "jedna czwarta",
    "&#188;" => "jedna czwarta",
    "&frac34;" => "trzy czwarte",
    "¾" => "trzy czwarte",
    "&#190;" => "trzy czwarte",
    "⅕" => "jedna piąta",
    "&#8533;" => "jedna piąta",
    "⅖" => "dwie piąte",
    "&#8534;" => "dwie piąte",
    "⅗" => "trzy piąte",
    "&#8535;" => "trzy piąte",
    "⅘" => "cztery piąte",
    "&#8536;" => "cztery piąte",
    "⅙" => "jedna szósta",
    "&#8537;" => "jedna szósta",
    "⅚" => "pięć szóstych",
    "&#8538;" => "pięć szóstych",
    "⅛" => "jedna ósma",
    "&#8539;" => "jedna ósma",
    "⅜" => "trzy ósme",
    "&#8540;" => "trzy ósme",
    "⅝" => "pięć ósmych",
    "&#8541;" => "pięć ósmych",
    "⅞" => "siedem ósmych",
    "&#8542;" => "siedem ósmych"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
