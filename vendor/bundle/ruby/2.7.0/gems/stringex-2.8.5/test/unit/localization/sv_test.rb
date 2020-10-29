# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class SwedishYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :sv
    Stringex::Localization.locale = :sv
  end

  {
    "foo & bar" => "foo och bar",
    "AT&T" => "AT och T",
    "99° is normal" => "99 grader is normal",
    "4 ÷ 2 is 2" => "4 delat med 2 is 2",
    "webcrawler.com" => "webcrawler punkt com",
    "Well..." => "Well punkt punkt punkt",
    "x=1" => "x lika med 1",
    "a #2 pencil" => "a nummer 2 pencil",
    "100%" => "100 procent",
    "cost+tax" => "cost plus tax",
    "batman/robin fan fiction" => "batman slash robin fan fiction",
    "dial *69" => "dial stjärna 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 kronor",
    "$100" => "100 dollar",
    "$19.99" => "19 dollar 99 cent",
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
    "Tea &amp; Sympathy" => "Tea och Sympathy",
    "10&cent;" => "10 cents",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 grader is fine",
    "10&divide;5" => "10 delat med 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "halv ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and en fjärdedel ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and tre fjärdedelar ounces of platinum",
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
    "⅔" => "två tredjedelar",
    "&#8532;" => "två tredjedelar",
    "&frac14;" => "en fjärdedel",
    "¼" => "en fjärdedel",
    "&#188;" => "en fjärdedel",
    "&frac34;" => "tre fjärdedelar",
    "¾" => "tre fjärdedelar",
    "&#190;" => "tre fjärdedelar",
    "⅕" => "en femtedel",
    "&#8533;" => "en femtedel",
    "⅖" => "två femtedelar",
    "&#8534;" => "två femtedelar",
    "⅗" => "tre femtedelar",
    "&#8535;" => "tre femtedelar",
    "⅘" => "fyra femtedelar",
    "&#8536;" => "fyra femtedelar",
    "⅙" => "en sjättedel",
    "&#8537;" => "en sjättedel",
    "⅚" => "fem sjättedelar",
    "&#8538;" => "fem sjättedelar",
    "⅛" => "en åttondel",
    "&#8539;" => "en åttondel",
    "⅜" => "tre åttondelar",
    "&#8540;" => "tre åttondelar",
    "⅝" => "fem åttondelar",
    "&#8541;" => "fem åttondelar",
    "⅞" => "sju åttondelar",
    "&#8542;" => "sju åttondelar"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
