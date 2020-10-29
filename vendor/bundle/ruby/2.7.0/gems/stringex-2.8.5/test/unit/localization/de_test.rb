# encoding: UTF-8

require 'test_helper'
require 'i18n'
require 'stringex'

class GermanYAMLLocalizationTest < Test::Unit::TestCase
  def setup
    Stringex::Localization.reset!
    Stringex::Localization.backend = :i18n
    Stringex::Localization.backend.load_translations :de
    Stringex::Localization.locale = :de
  end

  {
    "foo & bar" => "foo und bar",
    "AT&T" => "AT und T",
    "99° sind normal" => "99 Grad sind normal",
    "4 ÷ 2 ist 2" => "4 geteilt durch 2 ist 2",
    "webcrawler.com" => "webcrawler Punkt com",
    "Nun..." => "Nun Punkt Punkt Punkt",
    "x=1" => "x gleich 1",
    "Ein #2 Stift" => "Ein Nummer 2 Stift",
    "100%" => "100 Prozent",
    "Kosten+Steuern" => "Kosten plus Steuern",
    "Batman/Robin Fan Fiction" => "Batman Strich Robin Fan Fiction",
    "Wähle *69" => "Wähle Stern 69",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_character_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "¤20" => "20 Euro",
    "$100" => "100 Dollar",
    "$19.99" => "19 Dollar 99 Cent",
    "£100" => "100 Pfund",
    "£19.99" => "19 Pfund 99 Pence",
    "€100" => "100 Euro",
    "€19.99" => "19 Euro 99 Cent",
    "¥1000" => "1000 Yen"
  }.each do |original, converted|
    define_method "test_currency_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_characters
    end
  end

  {
    "Hennes &amp; Mauritz" => "Hennes und Mauritz",
    "10&cent;" => "10 Cent",
    "&copy;2000" => "(C)2000",
    "98&deg; sind ok" => "98 Grad sind ok",
    "10&divide;5" => "10 geteilt durch 5",
    "&quot;zitiert&quot;" => '"zitiert"',
    "Fortsetzung folgt&hellip;" => "Fortsetzung folgt...",
    "2000&ndash;2004" => "2000-2004",
    "Ich wünschte&mdash;oh, ach nichts" => "Ich wünschte--oh, ach nichts",
    "&frac12; Unze Gold" => "halbe(r) Unze Gold",
    "1 und &frac14; Unzen Silber" => "1 und ein Viertel Unzen Silber",
    "9 und &frac34; Unzen Platin" => "9 und drei Viertel Unzen Platin",
    "3&gt;2" => "3>2",
    "2&lt;3" => "2<3",
    "zwei&nbsp;Worte" => "zwei Worte",
    "100&pound;" => "100 Pfund",
    "Walmart&reg;" => "Walmart(R)",
    "&apos;einfach zitiert&apos;" => "'einfach zitiert'",
    "2&times;4" => "2x4",
    "Programming&trade;" => "Programming(TM)",
    "20000&yen;" => "20000 Yen",
    " i leave whitespace on ends unchanged " => " i leave whitespace on ends unchanged "
  }.each do |original, converted|
    define_method "test_html_entity_conversion: '#{original}'" do
      assert_equal converted, original.convert_miscellaneous_html_entities
    end
  end

  {
    "&frac12;" => "halbe(r)",
    "½" => "halbe(r)",
    "&#189;" => "halbe(r)",
    "⅓" => "ein Drittel",
    "&#8531;" => "ein Drittel",
    "⅔" => "zwei Drittel",
    "&#8532;" => "zwei Drittel",
    "&frac14;" => "ein Viertel",
    "¼" => "ein Viertel",
    "&#188;" => "ein Viertel",
    "&frac34;" => "drei Viertel",
    "¾" => "drei Viertel",
    "&#190;" => "drei Viertel",
    "⅕" => "ein Fünftel",
    "&#8533;" => "ein Fünftel",
    "⅖" => "zwei Fünftel",
    "&#8534;" => "zwei Fünftel",
    "⅗" => "drei Fünftel",
    "&#8535;" => "drei Fünftel",
    "⅘" => "vier Fünftel",
    "&#8536;" => "vier Fünftel",
    "⅙" => "ein Sechstel",
    "&#8537;" => "ein Sechstel",
    "⅚" => "fünf Sechstel",
    "&#8538;" => "fünf Sechstel",
    "⅛" => "ein Achtel",
    "&#8539;" => "ein Achtel",
    "⅜" => "drei Achtel",
    "&#8540;" => "drei Achtel",
    "⅝" => "fünf Achtel",
    "&#8541;" => "fünf Achtel",
    "⅞" => "sieben Achtel",
    "&#8542;" => "sieben Achtel"
  }.each do |original, converted|
    define_method "test_vulgar_fractions_conversion: #{original}" do
      assert_equal converted, original.convert_vulgar_fractions
    end
  end
end
