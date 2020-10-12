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

require File.dirname(__FILE__) + '/../../spec_helper'

describe Costs::NumberHelper, type: :helper do
  describe '#parse_number_string' do
    context 'for a german local' do
      it 'parses a string with delimiter and separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123.456,78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string with space delimiter and separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123 456,78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string without delimiter and separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12345678"))
            .to eql "12345678"
        end
      end

      it 'parses a string without delimiter and with separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456,78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string with delimiter and without separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12.345.678"))
            .to eql "12345678"
        end
      end

      it 'parses a string with space delimiter and without separator correctly' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("12 345 678"))
            .to eql "12345678"
        end
      end

      it 'returns alphabetical values instead of a delimiter unchanged' do
        I18n.with_locale(:de) do
          expect(helper.parse_number_string("123456a78"))
            .to eql "123456a78"
        end
      end
    end

    context 'for an english local' do
      it 'parses a string with delimiter and separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123,456.78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string with space delimiter and separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123 456.78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string without delimiter and separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12345678"))
            .to eql "12345678"
        end
      end

      it 'parses a string without delimiter and with separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123456.78"))
            .to eql "123456.78"
        end
      end

      it 'parses a string with delimiter and without separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12,345,678"))
            .to eql "12345678"
        end
      end

      it 'parses a string with space delimiter and without separator correctly' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("12 345 678"))
            .to eql "12345678"
        end
      end

      it 'returns alphabetical values instead of a delimiter unchanged' do
        I18n.with_locale(:en) do
          expect(helper.parse_number_string("123456a78"))
            .to eql "123456a78"
        end
      end
    end

    context 'for nil' do
      it 'is nil' do
        expect(helper.parse_number_string(nil))
          .to be_nil
      end
    end
  end
end
