# encoding: UTF-8

require "test_helper"
require "stringex/unidecoder"

class UnidecoderTest < Test::Unit::TestCase
  # Silly phrases courtesy of Frank da Cruz
  # http://www.columbia.edu/kermit/utf8.html
  DONT_CONVERT = [
    "Vitrum edere possum; mihi non nocet.", # Latin
    "Je puis mangier del voirre. Ne me nuit.", # Old French
    "Kristala jan dezaket, ez dit minik ematen.", # Basque
    "Kaya kong kumain nang bubog at hindi ako masaktan.", # Tagalog
    "Ich kann Glas essen, ohne mir weh zu tun.", # German
    "I can eat glass and it doesn't hurt me.", # English
  ]
  CONVERT_PAIRS = {
    "Je peux manger du verre, ça ne me fait pas de mal." => # French
      "Je peux manger du verre, ca ne me fait pas de mal.",
    "Pot să mănânc sticlă și ea nu mă rănește." => # Romanian
      "Pot sa mananc sticla si ea nu ma raneste.",
    "Ég get etið gler án þess að meiða mig." => # Icelandic
      "Eg get etid gler an thess ad meida mig.",
    "Unë mund të ha qelq dhe nuk më gjen gjë." => # Albanian
      "Une mund te ha qelq dhe nuk me gjen gje.",
    "Mogę jeść szkło i mi nie szkodzi." => # Polish
      "Moge jesc szklo i mi nie szkodzi.",
    "Я могу есть стекло, оно мне не вредит." => # Russian
      "Ia moghu iest' stieklo, ono mnie nie vriedit.",
    "Мога да ям стъкло, то не ми вреди." => # Bulgarian
      "Mogha da iam stklo, to nie mi vriedi.",
    "ᛁᚳ᛫ᛗᚨᚷ᛫ᚷᛚᚨᛋ᛫ᛖᚩᛏᚪᚾ᛫ᚩᚾᛞ᛫ᚻᛁᛏ᛫ᚾᛖ᛫ᚻᛖᚪᚱᛗᛁᚪᚧ᛫ᛗᛖ᛬" => # Anglo-Saxon
      "ic.mag.glas.eotacn.ond.hit.ne.heacrmiacth.me:",
    "ὕαλον ϕαγεῖν δύναμαι· τοῦτο οὔ με βλάπτει" => # Classical Greek
      "ualon phagein dunamai; touto ou me blaptei",
    "मैं काँच खा सकता हूँ और मुझे उससे कोई चोट नहीं पहुंचती" => # Hindi
      "maiN kaaNc khaa sktaa huuN aur mujhe usse koii cott nhiiN phuNctii",
    "من می توانم بدونِ احساس درد شيشه بخورم" => # Persian
      "mn my twnm bdwni Hss drd shyshh bkhwrm",
    "أنا قادر على أكل الزجاج و هذا لا يؤلمن" => # Arabic
      "'n qdr 'l~ 'kl lzjj w hdh l yw'lmn",
    "אני יכול לאכול זכוכית וזה לא מזיק לי" => # Hebrew
      "ny ykvl lkvl zkvkyt vzh l mzyq ly",
    "ฉันกินกระจกได้ แต่มันไม่ทำให้ฉันเจ็บ" => # Thai
      "chankinkracchkaid aetmanaimthamaihchanecchb",
    "我能吞下玻璃而不伤身体。" => # Chinese
      "Wo Neng Tun Xia Bo Li Er Bu Shang Shen Ti . ",
    "私はガラスを食べられます。それは私を傷つけません。" => # Japanese
      "Si hagarasuwoShi beraremasu. sorehaSi woShang tukemasen. ",
    "⠋⠗⠁⠝⠉⠑" => # Braille
      "france"
  }

  def test_unidecoder_decode
    DONT_CONVERT.each do |ascii|
      assert_equal ascii, Stringex::Unidecoder.decode(ascii)
    end
    CONVERT_PAIRS.each do |unicode, ascii|
      assert_equal ascii, Stringex::Unidecoder.decode(unicode)
    end
  end

  def test_to_ascii
    require "stringex/core_ext"
    DONT_CONVERT.each do |ascii|
      assert_equal ascii, ascii.to_ascii
    end
    CONVERT_PAIRS.each do |unicode, ascii|
      assert_equal ascii, unicode.to_ascii
    end
  end

  def test_unidecoder_encode
    {
      # Strings
      "0041" => "A",
      "00e6" => "æ",
      "042f" => "Я"
    }.each do |codepoint, unicode|
      assert_equal unicode, Stringex::Unidecoder.encode(codepoint)
    end
  end

  def test_unidecoder_get_codepoint
    {
      # Strings
      "A" => "0041",
      "æ" => "00e6",
      "Я" => "042f"
    }.each do |unicode, codepoint|
      assert_equal codepoint, Stringex::Unidecoder.get_codepoint(unicode)
    end
  end

  def test_unidecoder_in_yaml_file
    {
      "A" => "x00.yml (line 67)",
      "π" => "x03.yml (line 194)",
      "Я" => "x04.yml (line 49)"
    }.each do |character, output|
      assert_equal output, Stringex::Unidecoder.in_yaml_file(character)
    end
  end
end
