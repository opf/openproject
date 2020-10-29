# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class DanishYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :da
    Stringex::Localization.locale = :da
  end

  {
    "foo & bar" => "foo og bar",
    "AT&T" => "AT og T",
    "99° is normal" => "99 grader is normal",
    "4 ÷ 2 is 2" => "4 divideret med 2 is 2",
    "webcrawler.com" => "webcrawler punktum com",
    "Well..." => "Well prik prik prik",
    "x=1" => "x lig med 1",
    "a #2 pencil" => "a nummer 2 pencil",
    "100%" => "100 procent",
    "cost+tax" => "cost plus tax",
    "batman/robin fan fiction" => "batman skråstreg robin fan fiction",
    "dial *69" => "dial stjerne 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 kroner",
    "$100" => "100 dollars",
    "$19.99" => "19 dollars 99 cents",
    "£100" => "100 pund",
    "£19.99" => "19 pund 99 pence",
    "€100" => "100 euro",
    "€19.99" => "19 euro 99 cent",
    "¥1000" => "1000 yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea og Sympathy",
    "10&cent;" => "10 cents",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 grader is fine",
    "10&divide;5" => "10 divideret med 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "halv ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and en fjerdedel ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and tre fjerdedele ounces of platinum",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "pund 100",
    "Walmart&reg;" => "Walmart(r)",
    "&apos;single quoted&apos;" => "'single quoted'",
    "2&times;4" => "2x4",
    "Programming&trade;" => "Programming(tm)",
    "&yen;20000" => "yen 20000",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_html_entity_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_html_entities
    end
  end

  {
    "&frac12;" => "halv",
    "½" => "halv",
    "&#189;" => "halv",
    "⅓" => "en tredjedel",
    "&#8531;" => "en tredjedel",
    "⅔" => "to tredjedele",
    "&#8532;" => "to tredjedele",
    "&frac14;" => "en fjerdedel",
    "¼" => "en fjerdedel",
    "&#188;" => "en fjerdedel",
    "&frac34;" => "tre fjerdedele",
    "¾" => "tre fjerdedele",
    "&#190;" => "tre fjerdedele",
    "⅕" => "en femtedel",
    "&#8533;" => "en femtedel",
    "⅖" => "to femtedele",
    "&#8534;" => "to femtedele",
    "⅗" => "tre femtedele",
    "&#8535;" => "tre femtedele",
    "⅘" => "fire femtedele",
    "&#8536;" => "fire femtedele",
    "⅙" => "en sjettedel",
    "&#8537;" => "en sjettedel",
    "⅚" => "fem sjettedele",
    "&#8538;" => "fem sjettedele",
    "⅛" => "en ottendedel",
    "&#8539;" => "en ottendedel",
    "⅜" => "tre ottendedele",
    "&#8540;" => "tre ottendedele",
    "⅝" => "fem ottendedele",
    "&#8541;" => "fem ottendedele",
    "⅞" => "syv ottendedele",
    "&#8542;" => "syv ottendedele"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
