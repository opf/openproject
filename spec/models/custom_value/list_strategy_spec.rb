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

describe CustomValue::ListStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_field) { FactoryBot.create :list_wp_custom_field }
  let(:custom_value) do
    double("CustomField", value: value, custom_field: custom_field, customized: customized)
  end

  let(:customized) { double('customized') }

  describe '#parse_value/#typed_value' do
    subject { instance }

    context 'with a CustomOption' do
      let(:value) { custom_field.custom_options.first }

      it 'returns the CustomOption and sets it for later retrieval' do
        expect(CustomOption)
          .to_not receive(:where)

        expect(subject.parse_value(value)).to eql value.id.to_s

        expect(subject.typed_value).to eql value.value
      end
    end

    context 'with an id string' do
      let(:value) { custom_field.custom_options.first.id.to_s }

      it 'returns the string and has to later find the CustoOption' do
        expect(subject.parse_value(value)).to eql value

        expect(subject.typed_value).to eql custom_field.custom_options.first.value
      end
    end

    context 'value is blank' do
      let(:value) { '' }

      it 'is nil and does not look for the CustomOption' do
        expect(CustomOption)
          .to_not receive(:where)

        expect(subject.parse_value(value)).to be_nil

        expect(subject.typed_value).to be_nil
      end
    end

    context 'value is nil' do
      let(:value) { nil }

      it 'is nil and does not look for the CustomOption' do
        expect(CustomOption)
          .to_not receive(:where)

        expect(subject.parse_value(value)).to be_nil

        expect(subject.typed_value).to be_nil
      end
    end
  end

  describe '#formatted_value' do
    subject { instance.formatted_value }

    context 'with a CustomOption' do
      let(:value) { custom_field.custom_options.first }

      it 'is the custom option to_s (without db access)' do
        instance.parse_value(value)

        expect(CustomOption)
          .to_not receive(:where)

        expect(subject).to eql value.to_s
      end
    end

    context 'with an id string' do
      let(:value) { custom_field.custom_options.first.id.to_s }

      it 'is the custom option to_s (with db access)' do
        expect(subject).to eql custom_field.custom_options.first.to_s
      end
    end

    context 'value is blank' do
      let(:value) { '' }

      it 'is blank' do
        expect(subject).to eql value
      end
    end

    context 'value is nil' do
      let(:value) { nil }

      it 'is blank' do
        expect(subject).to eql ''
      end
    end
  end

  describe '#validate_type_of_value' do
    subject { instance.validate_type_of_value }

    context 'value is included' do
      let(:value) { custom_field.custom_options.first.id.to_s }

      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value is not included' do
      let(:value) { 'cat' }
      it 'rejects' do
        is_expected.to eql(:inclusion)
      end
    end
  end
end
