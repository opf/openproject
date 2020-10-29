# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class FrenchYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :fr
    Stringex::Localization.locale = :fr
  end

  {
    "foo & bar" => "foo et bar",
    "AT&T" => "AT et T",
    "99° est normal" => "99 degrés est normal",
    "4 ÷ 2 is 2" => "4 divisé par 2 is 2",
    "webcrawler.com" => "webcrawler point com",
    "Well..." => "Well point point point",
    "x=1" => "x égal 1",
    "a #2 pencil" => "a numéro 2 pencil",
    "100%" => "100 pourcent",
    "cost+tax" => "cost plus tax",
    "batman/robin fan fiction" => "batman slash robin fan fiction",
    "dial *69" => "dial étoile 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 livres",
    "$100" => "100 dollars",
    "$19.99" => "19 dollars 99 cents",
    "£100" => "100 livres",
    "£19.99" => "19 livres 99 pennies",
    "€100" => "100 euros",
    "€19.99" => "19 euros 99 cents",
    "¥1000" => "1000 yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea et Sympathy",
    "10&cent;" => "10 cents",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 degrés is fine",
    "10&divide;5" => "10 divisé par 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "un demi ounce of gold",
    "1 et &frac14; d'once de platinium" => "1 et un quart d'once de platinium",
    "9 et &frac34; d'once de platinium" => "9 et trois quarts d'once de platinium",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "livres 100",
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
    "&frac12;" => "un demi",
    "½" => "un demi",
    "&#189;" => "un demi",
    "⅓" => "un tiers",
    "&#8531;" => "un tiers",
    "⅔" => "deux tiers",
    "&#8532;" => "deux tiers",
    "&frac14;" => "un quart",
    "¼" => "un quart",
    "&#188;" => "un quart",
    "&frac34;" => "trois quarts",
    "¾" => "trois quarts",
    "&#190;" => "trois quarts",
    "⅕" => "un cinquième",
    "&#8533;" => "un cinquième",
    "⅖" => "deux cinquièmes",
    "&#8534;" => "deux cinquièmes",
    "⅗" => "trois cinquièmes",
    "&#8535;" => "trois cinquièmes",
    "⅘" => "quatre cinquièmes",
    "&#8536;" => "quatre cinquièmes",
    "⅙" => "un sixième",
    "&#8537;" => "un sixième",
    "⅚" => "cinq sixièmes",
    "&#8538;" => "cinq sixièmes",
    "⅛" => "un huitième",
    "&#8539;" => "un huitième",
    "⅜" => "trois huitièmes",
    "&#8540;" => "trois huitièmes",
    "⅝" => "cinq huitièmes",
    "&#8541;" => "cinq huitièmes",
    "⅞" => "sept huitièmes",
    "&#8542;" => "sept huitièmes"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
