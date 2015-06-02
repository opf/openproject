#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

#-- encoding: UTF-8
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
require 'legacy_spec_helper'

describe Redmine::CodesetUtil do
  it 'should to utf8 by setting from latin1' do
    with_settings repositories_encodings: 'UTF-8,ISO-8859-1' do
      s1 = "Texte encod\xc3\xa9"
      s2 = "Texte encod\xe9"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding('UTF-8')
        s2.force_encoding('ASCII-8BIT')
        s3.force_encoding('UTF-8')
      end
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s2)
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s3)
    end
  end

  it 'should to utf8 by setting from euc jp' do
    with_settings repositories_encodings: 'UTF-8,EUC-JP' do
      s1 = "\xe3\x83\xac\xe3\x83\x83\xe3\x83\x89\xe3\x83\x9e\xe3\x82\xa4\xe3\x83\xb3"
      s2 = "\xa5\xec\xa5\xc3\xa5\xc9\xa5\xde\xa5\xa4\xa5\xf3"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding('UTF-8')
        s2.force_encoding('ASCII-8BIT')
        s3.force_encoding('UTF-8')
      end
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s2)
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s3)
    end
  end

  it 'should to utf8 by setting should be converted all latin1' do
    with_settings repositories_encodings: 'ISO-8859-1' do
      s1 = "\xc3\x82\xc2\x80"
      s2 = "\xC2\x80"
      s3 = s2.dup
      if s1.respond_to?(:force_encoding)
        s1.force_encoding('UTF-8')
        s2.force_encoding('ASCII-8BIT')
        s3.force_encoding('UTF-8')
      end
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s2)
      assert_equal s1, Redmine::CodesetUtil.to_utf8_by_setting(s3)
    end
  end

  it 'should to utf8 by setting blank string' do
    assert_equal '',  Redmine::CodesetUtil.to_utf8_by_setting('')
    assert_equal nil, Redmine::CodesetUtil.to_utf8_by_setting(nil)
  end

  it 'should to utf8 by setting returns ascii as utf8' do
    s1 = 'ASCII'
    s2 = s1.dup
    if s1.respond_to?(:force_encoding)
      s1.force_encoding('UTF-8')
      s2.force_encoding('ISO-8859-1')
    end
    str1 = Redmine::CodesetUtil.to_utf8_by_setting(s1)
    str2 = Redmine::CodesetUtil.to_utf8_by_setting(s2)
    assert_equal s1, str1
    assert_equal s1, str2
    if s1.respond_to?(:force_encoding)
      assert_equal 'UTF-8', str1.encoding.to_s
      assert_equal 'UTF-8', str2.encoding.to_s
    end
  end

  it 'should to utf8 by setting invalid utf8 sequences should be stripped' do
    with_settings repositories_encodings: '' do
      s1 = "Texte encod\xe9 en ISO-8859-1."
      s1.force_encoding('ASCII-8BIT') if s1.respond_to?(:force_encoding)
      str = Redmine::CodesetUtil.to_utf8_by_setting(s1)
      if str.respond_to?(:force_encoding)
        assert str.valid_encoding?
        assert_equal 'UTF-8', str.encoding.to_s
      end
      assert_equal 'Texte encod? en ISO-8859-1.', str
    end
  end

  it 'should to utf8 by setting invalid utf8 sequences should be stripped ja jis' do
    with_settings repositories_encodings: 'ISO-2022-JP' do
      s1 = "test\xb5\xfetest\xb5\xfe"
      s1.force_encoding('ASCII-8BIT') if s1.respond_to?(:force_encoding)
      str = Redmine::CodesetUtil.to_utf8_by_setting(s1)
      if str.respond_to?(:force_encoding)
        assert str.valid_encoding?
        assert_equal 'UTF-8', str.encoding.to_s
      end
      assert_equal 'test??test??', str
    end
  end
end
