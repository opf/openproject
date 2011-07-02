#-- copyright
# ChiliProject is a project management system.
#
# Copyright (C) 2010-2011 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# See doc/COPYRIGHT.rdoc for more details.
#++
require File.expand_path('../../../test_helper', __FILE__)

class RepositoryHelperTest < HelperTestCase
  include RepositoriesHelper

  def test_from_latin1_to_utf8_for_repositories
    with_settings :repositories_encodings => 'UTF-8,ISO-8859-1' do
      s1 = "Texte encod\xc3\xa9"
      s2 = "Texte encod\xe9"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding("UTF-8")
        s2.force_encoding("ASCII-8BIT")
        s3.force_encoding("UTF-8")
      end
      assert_equal s1, to_utf8_for_repositories(s2)
      assert_equal s1, to_utf8_for_repositories(s3)
    end
  end

  def test_from_euc_jp_to_utf8_for_repositories
    with_settings :repositories_encodings => 'UTF-8,EUC-JP' do
      s1 = "\xe3\x83\xac\xe3\x83\x83\xe3\x83\x89\xe3\x83\x9e\xe3\x82\xa4\xe3\x83\xb3"
      s2 = "\xa5\xec\xa5\xc3\xa5\xc9\xa5\xde\xa5\xa4\xa5\xf3"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding("UTF-8")
        s2.force_encoding("ASCII-8BIT")
        s3.force_encoding("UTF-8")
      end
      assert_equal s1, to_utf8_for_repositories(s2)
      assert_equal s1, to_utf8_for_repositories(s3)
    end
  end

  def test_to_utf8_for_repositories_should_be_converted_all_latin1_to_utf8
    with_settings :repositories_encodings => 'ISO-8859-1' do
      s1 = "\xc3\x82\xc2\x80"
      s2 = "\xC2\x80"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding("UTF-8")
        s2.force_encoding("ASCII-8BIT")
        s3.force_encoding("UTF-8")
      end
      assert_equal s1, to_utf8_for_repositories(s2)
      assert_equal s1, to_utf8_for_repositories(s3)
    end
  end

  def test_to_utf8_for_repositories_blank_string
    assert_equal "",  to_utf8_for_repositories("")
    assert_equal nil, to_utf8_for_repositories(nil)
  end

  def test_to_utf8_for_repositories_returns_ascii_as_utf8
    s1 = "ASCII"
    s2 = s1.dup
    if s1.respond_to?(:force_encoding)
      s1.force_encoding("UTF-8")
      s2.force_encoding("ISO-8859-1")
    end
    str1 = to_utf8_for_repositories(s1)
    str2 = to_utf8_for_repositories(s2)
    assert_equal s1, str1
    assert_equal s1, str2
    if s1.respond_to?(:force_encoding)
      assert_equal "UTF-8", str1.encoding.to_s
      assert_equal "UTF-8", str2.encoding.to_s
    end
  end

  def test_to_utf8_for_repositories_invalid_utf8_sequences_should_be_stripped
    with_settings :repositories_encodings => '' do
      s1 = File.read("#{RAILS_ROOT}/test/fixtures/encoding/iso-8859-1.txt")
      str = to_utf8_for_repositories(s1)
      if str.respond_to?(:force_encoding)
        assert_equal "Texte encod? en ISO-8859-1.", str
        assert str.valid_encoding?
        assert_equal "UTF-8", str.encoding.to_s
      else
        assert_equal "Texte encod en ISO-8859-1.", str
      end
    end
  end
end
