# encoding: UTF-8

require "test/unit"
require "stringex"
require File.join(File.expand_path(File.dirname(__FILE__)), "codepoint_test_helper.rb")
include CodepointTestHelper

class BasicGreekTest < Test::Unit::TestCase
  # This test suite is just regression test and debugging
  # to better transliterate the Basic Latin Unicode codepoints
  #
  # http://unicode.org/charts/
  # http://unicode.org/charts/PDF/U0000.pdf

  # NOTE: I can't figure out how to test control characters.
  # Get weird results trying to pack them to unicode.

  def test_greek_letters
    {
      "Α" => "A",
      "Ά" => "A",
      "Β" => "B",
      "Γ" => "G",
      "Δ" => "D",
      "Ε" => "E",
      "Έ" => "E",
      "Ζ" => "Z",
      "Η" => "H",
      "Θ" => "Th",
      "Ι" => "I",
      "Ί" => "I",
      "Ϊ" => "I",
      "Κ" => "K",
      "Λ" => "L",
      "Μ" => "M",
      "Ν" => "N",
      "Ξ" => "Ks",
      "Ο" => "O",
      "Ό" => "O",
      "Π" => "P",
      "Ρ" => "R",
      "Σ" => "S",
      "Τ" => "T",
      "Υ" => "Y",
      "Ϋ" => "Y",
      "Ύ" => "Y",
      "Φ" => "Ph",
      "Χ" => "X",
      "Ψ" => "Ps",
      "Ω" => "O",
      "Ώ" => "O",
      "α" => "a",
      "ά" => "a",
      "β" => "b",
      "γ" => "g",
      "δ" => "d",
      "ε" => "e",
      "έ" => "e",
      "ζ" => "z",
      "η" => "i",
      "ή" => "i",
      "θ" => "th",
      "ι" => "i",
      "ί" => "i",
      "ϊ" => "i",
      "ΐ" => "i",
      "κ" => "k",
      "λ" => "l",
      "μ" => "m",
      "ν" => "n",
      "ξ" => "ks",
      "ο" => "o",
      "ό" => "o",
      "π" => "p",
      "ρ" => "r",
      "σ" => "s",
      "ς" => "s",
      "τ" => "t",
      "υ" => "u",
      "ύ" => "u",
      "ϋ" => "u",
      "ΰ" => "u",
      "φ" => "ph",
      "χ" => "x",
      "ψ" => "ps",
      "ω" => "o",
      "ώ" => "o"
    }.each do |letter, ascii|
      assert_equal letter.to_ascii, ascii
    end
  end


  def test_greek_words
    {
      "Καλημέρα" => "Kalimera",
      "Προϊόν" => "Proion",
      "Θαλασσογραφία" => "Thalassographia",
      "Να μας πάρεις μακριά" => "Na mas pareis makria",
      "να μας πας στα πέρα μέρη" => "na mas pas sta pera meri",
      "φύσα θάλασσα πλατιά" => "phusa thalassa platia",
      "φύσα αγέρι φύσα αγέρι" => "phusa ageri phusa ageri",
      "Αν θέλεις να λέγεσαι άνθρωπος" => "An theleis na legesai anthropos",
      "δεν θα πάψεις ούτε στιγμή ν΄αγωνίζεσαι για την ειρήνη και" => "den tha papseis oute stigmi nagonizesai gia tin eirini kai",
      "για το δίκαιο." => "gia to dikaio.",
      "Θα βγείς στους δρόμους, θα φωνάξεις, τα χείλια σου θα" => "Tha bgeis stous dromous, tha phonakseis, ta xeilia sou tha",
      "ματώσουν απ΄τις φωνές" => "matosoun aptis phones",
      "το πρόσωπό σου θα ματώσει από τις σφαίρες – μα ούτε βήμα πίσω." => "to prosopo sou tha matosei apo tis sphaires -- ma oute bima piso.",
    }.each do |letter, ascii|
      assert_equal letter.to_ascii, ascii
    end
  end
end
