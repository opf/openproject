#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe CustomValue do
  shared_let(:version) { create(:version) }

  let(:format) { 'bool' }
  let(:custom_field) { create(:custom_field, field_format: format) }
  let(:custom_value) { create(:custom_value, custom_field:, value:, customized: version) }

  describe '#typed_value' do
    subject { custom_value }

    before do
      # we are testing roundtrips through the database here
      # the databases might choose to store values in weird and unexpected formats (e.g. booleans)
      subject.reload
    end

    describe 'boolean custom value' do
      let(:format) { 'bool' }
      let(:value) { true }

      context 'when it is true' do
        it { expect(subject.typed_value).to eql(value) }
      end

      context 'when it is false' do
        let(:value) { false }

        it { expect(subject.typed_value).to eql(value) }
      end

      context 'when it is nil' do
        let(:value) { nil }

        it { expect(subject.typed_value).to eql(value) }
      end
    end

    describe 'string custom value' do
      let(:format) { 'string' }
      let(:value) { 'This is a string!' }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'integer custom value' do
      let(:format) { 'int' }
      let(:value) { 123 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'float custom value' do
      let(:format) { 'float' }
      let(:value) { 3.147 }

      it { expect(subject.typed_value).to eql(value) }
    end

    describe 'date custom value' do
      let(:format) { 'date' }
      let(:value) { Date.new(2016, 12, 1) }

      it { expect(subject.typed_value).to eql(value) }

      context 'for a date format', with_settings: { date_format: '%Y/%m/%d' } do
        it { expect(subject.formatted_value).to eq('2016/12/01') }
      end
    end
  end

  describe 'trying to use a custom field that does not exist' do
    subject { build(:custom_value, custom_field_id: 123412341, value: 'my value') }

    it 'returns an empty placeholder' do
      expect(subject.custom_field).to be_nil
      expect(subject.send(:strategy)).to be_kind_of CustomValue::EmptyStrategy
      expect(subject.typed_value).to eq 'my value not found'
      expect(subject.formatted_value).to eq 'my value not found'
    end
  end

  describe '#valid?' do
    let(:custom_field) { build_stubbed(:custom_field, field_format:, is_required:, min_length:, max_length:, regexp:) }
    let(:custom_value) { described_class.new(custom_field:, value:) }
    let(:is_required) { false }
    let(:min_length) { 0 }
    let(:max_length) { 0 }
    let(:regexp) { nil }

    context 'for a data custom field' do
      let(:field_format) { 'date' }

      context 'with a valid date' do
        let(:value) { '1975-07-14' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with some non date string' do
        let(:value) { 'abc' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end
    end

    context 'for a string custom field' do
      let(:field_format) { 'string' }

      context 'with some string' do
        let(:value) { 'abc' }

        it 'is invalid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a nil value' do
        let(:value) { nil }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with an empty value' do
        let(:value) { '' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a nil value when required' do
        let(:value) { nil }
        let(:is_required) { true }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with an empty value when required' do
        let(:value) { '' }
        let(:is_required) { true }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with an empty value when having a min_length' do
        let(:value) { '' }
        let(:min_length) { 1 }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with too short a value when having a min_length' do
        let(:value) { 'a' }
        let(:min_length) { 2 }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with too long a value when having a max_length' do
        let(:value) { 'a' * 6 }
        let(:max_length) { 5 }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with a value of the correct length when having a max_length and a min_value' do
        let(:value) { 'a' * 4 }
        let(:min_length) { 4 }
        let(:max_length) { 4 }

        it 'is invalid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with an empty value when having a regexp' do
        let(:value) { '' }
        let(:regexp) { '^[A-Z0-9]*$' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a not matching value when having a regexp' do
        let(:value) { 'a' }
        let(:regexp) { '^[A-Z0-9]*$' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with a matching value when having a regexp' do
        let(:value) { 'A' }
        let(:regexp) { '^[A-Z0-9]*$' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context 'for a list custom field' do
      let(:custom_option1) { build_stubbed(:custom_option, value: 'value1') }
      let(:custom_option2) { build_stubbed(:custom_option, value: 'value1') }
      let(:custom_field) { build_stubbed(:custom_field, field_format: 'list', custom_options: [custom_option1, custom_option2]) }

      context 'with a value from the list' do
        let(:value) { custom_option1.id }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with some string' do
        let(:value) { 'abc' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with nil string' do
        let(:value) { nil }

        it 'is invalid' do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context 'for an int custom field' do
      let(:field_format) { 'int' }

      context 'with a valid int string' do
        let(:value) { '123' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a valid negative int string' do
        let(:value) { '-123' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a valid positive int string' do
        let(:value) { '+123' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with some non int string' do
        let(:value) { 'abc' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with a float string' do
        let(:value) { '5.5' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with an empty string' do
        let(:value) { '' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end
    end

    context 'for a float custom field' do
      let(:field_format) { 'float' }

      context 'with a valid float string' do
        let(:value) { '123.5' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a valid negative float string' do
        let(:value) { '-123.5' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a valid positive float string' do
        let(:value) { '+123.5' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with some non float string' do
        let(:value) { 'abc' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end

      context 'with an int string' do
        let(:value) { '5' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with an empty string' do
        let(:value) { '' }

        it 'is valid' do
          expect(custom_value)
            .to be_valid
        end
      end

      context 'with a mixed string' do
        let(:value) { '6.5a' }

        it 'is invalid' do
          expect(custom_value)
            .not_to be_valid
        end
      end
    end
  end

  describe 'value/value=' do
    let(:custom_value) { build_stubbed(:custom_value) }
    let(:strategy_double) { instance_double(CustomValue::FormatStrategy) }

    it 'calls the strategy for parsing and uses that value' do
      original_value = 'original value'
      parsed_value = 'parsed value'

      allow(custom_value)
        .to receive(:strategy)
        .and_return(strategy_double)

      allow(strategy_double)
        .to receive(:parse_value)
        .with(original_value)
        .and_return(parsed_value)

      custom_value.value = original_value

      expect(custom_value.value).to eql parsed_value
    end
  end
end
