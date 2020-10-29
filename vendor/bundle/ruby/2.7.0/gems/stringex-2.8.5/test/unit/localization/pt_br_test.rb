# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class BrazilianYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :'pt-BR'
    Stringex::Localization.locale = :'pt-BR'
  end

  {
    "foo & bar" => "foo e bar",
    "AT&T" => "AT e T",
    "99° is normal" => "99 graus is normal",
    "4 ÷ 2 is 2" => "4 dividido por 2 is 2",
    "webcrawler.com" => "webcrawler ponto com",
    "Well..." => "Well reticências",
    "x=1" => "x igual à 1",
    "a #2 pencil" => "a número 2 pencil",
    "100%" => "100 porcento",
    "cost+tax" => "cost mais tax",
    "batman/robin fan fiction" => "batman barra robin fan fiction",
    "dial *69" => "dial estrela 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 reais",
    "$100" => "100 dólares",
    "$19.99" => "19 dólares 99 cents",
    "£100" => "100 libras",
    "£19.99" => "19 libras 99 centavos",
    "€100" => "100 euros",
    "€19.99" => "19 euros 99 cents",
    "¥1000" => "1000 yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Tea &amp; Sympathy" => "Tea e Sympathy",
    "10&cent;" => "10 centavos",
    "&copy;2000" => "(c)2000",
    "98&deg; is fine" => "98 graus is fine",
    "10&divide;5" => "10 dividido por 5",
    "&quot;quoted&quot;" => '"quoted"',
    "to be continued&hellip;" => "to be continued...",
    "2000&ndash;2004" => "2000-2004",
    "I wish&mdash;oh, never mind" => "I wish--oh, never mind",
    "&frac12; ounce of gold" => "metade ounce of gold",
    "1 and &frac14; ounces of silver" => "1 and um quarto ounces of silver",
    "9 and &frac34; ounces of platinum" => "9 and três quartos ounces of platinum",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "two&nbsp;words" => "two words",
    "&pound;100" => "libras 100",
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
    "&frac12;" => "metade",
    "½" => "metade",
    "&#189;" => "metade",
    "⅓" => "um terço",
    "&#8531;" => "um terço",
    "⅔" => "dois terços",
    "&#8532;" => "dois terços",
    "&frac14;" => "um quarto",
    "¼" => "um quarto",
    "&#188;" => "um quarto",
    "&frac34;" => "três quartos",
    "¾" => "três quartos",
    "&#190;" => "três quartos",
    "⅕" => "um quinto",
    "&#8533;" => "um quinto",
    "⅖" => "dois quintos",
    "&#8534;" => "dois quintos",
    "⅗" => "três quintos",
    "&#8535;" => "três quintos",
    "⅘" => "quatro quintos",
    "&#8536;" => "quatro quintos",
    "⅙" => "um sexto",
    "&#8537;" => "um sexto",
    "⅚" => "cinco sextos",
    "&#8538;" => "cinco sextos",
    "⅛" => "um oitavo",
    "&#8539;" => "um oitavo",
    "⅜" => "três oitavos",
    "&#8540;" => "três oitavos",
    "⅝" => "cinco oitavos",
    "&#8541;" => "cinco oitavos",
    "⅞" => "sete oitavos",
    "&#8542;" => "sete oitavos"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
