require 'test/unit'
require 'coderay'

class WordListTest < Test::Unit::TestCase
  
  include CodeRay
  
  # define word arrays
  RESERVED_WORDS = %w[
    asm break case continue default do else
    ...
  ]
  
  PREDEFINED_TYPES = %w[
    int long short char void
    ...
  ]
  
  PREDEFINED_CONSTANTS = %w[
    EOF NULL ...
  ]
  
  # make a WordList
  IDENT_KIND = WordList.new(:ident).
    add(RESERVED_WORDS, :reserved).
    add(PREDEFINED_TYPES, :pre_type).
    add(PREDEFINED_CONSTANTS, :pre_constant)

  def test_word_list_example
    assert_equal :pre_type, IDENT_KIND['void']
    # assert_equal :pre_constant, IDENT_KIND['...']  # not specified
  end
  
  def test_word_list
    list = WordList.new(:ident).add(['foobar'], :reserved)
    assert_equal :reserved, list['foobar']
    assert_equal :ident, list['FooBar']
  end

  def test_word_list_cached
    list = WordList.new(:ident, true).add(['foobar'], :reserved)
    assert_equal :reserved, list['foobar']
    assert_equal :ident, list['FooBar']
  end

  def test_case_ignoring_word_list
    list = CaseIgnoringWordList.new(:ident).add(['foobar'], :reserved)
    assert_equal :ident, list['foo']
    assert_equal :reserved, list['foobar']
    assert_equal :reserved, list['FooBar']

    list = CaseIgnoringWordList.new(:ident).add(['FooBar'], :reserved)
    assert_equal :ident, list['foo']
    assert_equal :reserved, list['foobar']
    assert_equal :reserved, list['FooBar']
  end

  def test_case_ignoring_word_list_cached
    list = CaseIgnoringWordList.new(:ident, true).add(['foobar'], :reserved)
    assert_equal :ident, list['foo']
    assert_equal :reserved, list['foobar']
    assert_equal :reserved, list['FooBar']

    list = CaseIgnoringWordList.new(:ident, true).add(['FooBar'], :reserved)
    assert_equal :ident, list['foo']
    assert_equal :reserved, list['foobar']
    assert_equal :reserved, list['FooBar']
  end

  def test_dup
    list = WordList.new(:ident).add(['foobar'], :reserved)
    assert_equal :reserved, list['foobar']
    list2 = list.dup
    list2.add(%w[foobar], :keyword)
    assert_equal :keyword, list2['foobar']
    assert_equal :reserved, list['foobar']
  end

end