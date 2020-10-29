# encoding: UTF-8

require 'test_helper'
require 'stringex'

class DefaultLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :internal
  end

  {
    "foo & bar" => "foo and bar",
    "AT&T" => "AT and T",
    "99° is normal" => "99 degrees is normal",
    "4 ÷ 2 is 2" => "4 divided by 2 is 2",
    "webcrawler.com" => "webcrawler dot com",
    "Well..." => "Well dot dot dot",
    "x=1" => "x equals 1",
    "a #2 pencil" => "a number 2 pencil",
    "100%" => "100 percent",
    "cost+tax" => "cost plus tax",
    "batman/robin fan fiction" => "batman slash robin fan fiction",
    "dial *69" => "dial star 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 dollars",
    "$100" => "100 dollars",
    "$19.99" => "19 dollars 99 cents",
    "£100" => "100 pounds",
    "£19.99" => "19 pounds 99 pence",
    "€100" => "100 euros",
    "€19.99" => "19 euros 99 cents",
    "¥1000" => "1000 yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea and Sympathy",
    "10&cent;" => "10 cents",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 degrees is fine",
    "10&divide;5" => "10 divided by 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "half ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and one fourth ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and three fourths ounces of platinum",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "pounds 100",
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
    "&frac12;" => "half",
    "½" => "half",
    "&#189;" => "half",
    "⅓" => "one third",
    "&#8531;" => "one third",
    "⅔" => "two thirds",
    "&#8532;" => "two thirds",
    "&frac14;" => "one fourth",
    "¼" => "one fourth",
    "&#188;" => "one fourth",
    "&frac34;" => "three fourths",
    "¾" => "three fourths",
    "&#190;" => "three fourths",
    "⅕" => "one fifth",
    "&#8533;" => "one fifth",
    "⅖" => "two fifths",
    "&#8534;" => "two fifths",
    "⅗" => "three fifths",
    "&#8535;" => "three fifths",
    "⅘" => "four fifths",
    "&#8536;" => "four fifths",
    "⅙" => "one sixth",
    "&#8537;" => "one sixth",
    "⅚" => "five sixths",
    "&#8538;" => "five sixths",
    "⅛" => "one eighth",
    "&#8539;" => "one eighth",
    "⅜" => "three eighths",
    "&#8540;" => "three eighths",
    "⅝" => "five eighths",
    "&#8541;" => "five eighths",
    "⅞" => "seven eighths",
    "&#8542;" => "seven eighths"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
