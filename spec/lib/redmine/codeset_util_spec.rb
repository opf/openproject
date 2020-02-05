#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe Redmine::CodesetUtil do
  context 'with utf8 and latin1 setting', with_settings: { repositories_encodings: 'UTF-8,ISO-8859-1' } do
    let(:s1) do
      "Texte encod\xc3\xa9".tap do |s|
        s.force_encoding('UTF-8')
      end
    end
    let(:s2) do
      "Texte encod\xe9".tap do |s|
        s.force_encoding('ASCII-8BIT')
      end
    end
    let(:s3) do
      "Texte encod\xe9".tap do |s|
        s.force_encoding('UTF-8')
      end
    end

    it 'transforms from 8bit' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2).encoding.to_s)
        .to eql 'UTF-8'
    end

    it 'transforms from utf8' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3).encoding.to_s)
        .to eql 'UTF-8'
    end
  end

  context 'with utf-8 and euc jp setting', with_settings: { repositories_encodings: 'UTF-8,EUC-JP' } do
    let(:s1) do
      "\xe3\x83\xac\xe3\x83\x83\xe3\x83\x89\xe3\x83\x9e\xe3\x82\xa4\xe3\x83\xb3".tap do |s|
        s.force_encoding('UTF-8')
      end
    end
    let(:s2) do
      "\xa5\xec\xa5\xc3\xa5\xc9\xa5\xde\xa5\xa4\xa5\xf3".tap do |s|
        s.force_encoding('ASCII-8BIT')
      end
    end
    let(:s3) do
      "\xa5\xec\xa5\xc3\xa5\xc9\xa5\xde\xa5\xa4\xa5\xf3".tap do |s|
        s.force_encoding('UTF-8')
      end
    end

    it 'transforms from 8bit' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2).encoding.to_s)
        .to eql 'UTF-8'
    end

    it 'transforms from utf8' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3).encoding.to_s)
        .to eql 'UTF-8'
    end
  end

  context 'with latin1 only setting', with_settings: { repositories_encodings: 'ISO-8859-1' } do
    let(:s1) do
      "\xc3\x82\xc2\x80".tap do |s|
        s.force_encoding('UTF-8')
      end
    end
    let(:s2) do
      "\xC2\x80".tap do |s|
        s.force_encoding('ASCII-8BIT')
      end
    end
    let(:s3) do
      "\xC2\x80".tap do |s|
        s.force_encoding('UTF-8')
      end
    end

    it 'transforms from 8bit' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s2).encoding.to_s)
        .to eql 'UTF-8'
    end

    it 'transforms from utf8' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3))
        .to eql s1

      expect(Redmine::CodesetUtil.to_utf8_by_setting(s3).encoding.to_s)
        .to eql 'UTF-8'
    end
  end

  context 'with blank setting', with_settings: { repositories_encodings: '' } do
    it 'transforms blank string' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(''))
        .to eql ''
    end

    it 'transforms nil' do
      expect(Redmine::CodesetUtil.to_utf8_by_setting(nil))
        .to eql nil
    end

    context 'with an invalid utf8 sequences' do
      let(:s1) do
        "Texte encod\xe9 en ISO-8859-1.".tap do |s|
          s.force_encoding('ASCII-8BIT')
        end
      end

      it 'returns a valid utf-8 encoding' do
        expect(Redmine::CodesetUtil.to_utf8_by_setting(s1).encoding.to_s)
          .to eql 'UTF-8'
      end

      it 'strips out the invalid char' do
        expect(Redmine::CodesetUtil.to_utf8_by_setting(s1))
          .to eql 'Texte encod? en ISO-8859-1.'
      end
    end
  end

  context 'with ja jis setting', with_settings: { repositories_encodings: 'ISO-2022-JP' } do
    context 'with an invalid utf8 sequences' do
      let(:s1) do
        "test\xb5\xfetest\xb5\xfe".tap do |s|
          s.force_encoding('ASCII-8BIT')
        end
      end

      it 'returns a valid utf-8 encoding' do
        expect(Redmine::CodesetUtil.to_utf8_by_setting(s1).encoding.to_s)
          .to eql 'UTF-8'
      end

      it 'strips out the invalid char' do
        expect(Redmine::CodesetUtil.to_utf8_by_setting(s1))
          .to eql 'test??test??'
      end
    end
  end
end
