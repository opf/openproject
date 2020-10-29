# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class DutchYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :nl
    Stringex::Localization.locale = :nl
  end

  {
    "foo & bar" => "foo en bar",
    "AT&T" => "AT en T",
    "99° is normaal" => "99 graden is normaal",
    "4 ÷ 2 is 2" => "4 gedeeld door 2 is 2",
    "webcrawler.com" => "webcrawler punt com",
    "Dus..." => "Dus punt punt punt",
    "x=1" => "x is 1",
    "Een potlood #2" => "Een potlood nummer 2",
    "100%" => "100 procent",
    "prijs+belasting" => "prijs plus belasting",
    "Batman/Robin fan fiction" => "Batman slash Robin fan fiction",
    "bel *69" => "bel ster 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 euro",
    "$100" => "100 dollar",
    "$19.99" => "19 dollar 99 cent",
    "£100" => "100 pond",
    "£19.99" => "19 pond 99 pence",
    "€100" => "100 euro",
    "€19.99" => "19 euro 99 cent",
    "¥1000" => "1000 yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Appels &amp; peren" => "Appels en peren",
    "10&cent;" => "10 cent",
    "&copy;2000" => "(c)2000",
    "98&deg; is acceptabel" => "98 graden is acceptabel",
    "10&divide;5" => "10 gedeeld door 5",
    "&quot;tussen aanhalingstekens&quot;" => '"tussen aanhalingstekens"',
    "wordt vervolgd&hellip;" => "wordt vervolgd...",
    "2000&ndash;2004" => "2000-2004",
    "Ik wil&mdash;oh, laat maar" => "Ik wil--oh, laat maar",
    "&frac12; ons goud" => "half ons goud",
    "1 en &frac14; ons zilver" => "1 en eenvierde ons zilver",
    "9 en &frac34; ons platina" => "9 en drievierde ons platina",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "twee&nbsp;woorden" => "twee woorden",
    "100&pound;" => "100 pond",
    "Walmart&reg;" => "Walmart(r)",
    "&apos;enkele aanhalingstekens&apos;" => "'enkele aanhalingstekens'",
    "2&times;4" => "2x4",
    "Programming&trade;" => "Programming(tm)",
    "20000&yen;" => "20000 yen",
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
    "⅓" => "eenderde",
    "&#8531;" => "eenderde",
    "⅔" => "tweederde",
    "&#8532;" => "tweederde",
    "&frac14;" => "eenvierde",
    "¼" => "eenvierde",
    "&#188;" => "eenvierde",
    "&frac34;" => "drievierde",
    "¾" => "drievierde",
    "&#190;" => "drievierde",
    "⅕" => "eenvijfde",
    "&#8533;" => "eenvijfde",
    "⅖" => "tweevijfde",
    "&#8534;" => "tweevijfde",
    "⅗" => "drievijfde",
    "&#8535;" => "drievijfde",
    "⅘" => "viervijfde",
    "&#8536;" => "viervijfde",
    "⅙" => "eenzesde",
    "&#8537;" => "eenzesde",
    "⅚" => "vijfzesde",
    "&#8538;" => "vijfzesde",
    "⅛" => "eenachtste",
    "&#8539;" => "eenachtste",
    "⅜" => "drieachtste",
    "&#8540;" => "drieachtste",
    "⅝" => "vijfachtste",
    "&#8541;" => "vijfachtste",
    "⅞" => "zevenachtste",
    "&#8542;" => "zevenachtste"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
