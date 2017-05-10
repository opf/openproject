#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe CustomValue::BoolStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) do
    double('CustomValue',
           value: value)
  end

  describe '#value_present?' do
    subject { described_class.new(custom_value).value_present? }

    context 'value is nil' do
      let(:value) { nil }
      it { is_expected.to be false }
    end

    context 'value is empty string' do
      let(:value) { '' }
      it { is_expected.to be false }
    end

    context 'value is present string' do
      let(:value) { '1' }
      it { is_expected.to be true }
    end

    context 'value is true' do
      let(:value) { true }
      it { is_expected.to be true }
    end

    context 'value is false' do
      let(:value) { false }
      it { is_expected.to be true }
    end
  end

  describe '#typed_value' do
    subject { instance.typed_value }

    context 'value corresponds to true' do
      let(:value) { '1' }
      it { is_expected.to be true }
    end

    context 'value corresponds to false' do
      let(:value) { '0' }
      it { is_expected.to be false }
    end

    context 'value is blank' do
      let(:value) { '' }
      it { is_expected.to be_nil }
    end

    context 'value is nil' do
      let(:value) { nil }
      it { is_expected.to be_nil }
    end

    context 'value is true' do
      let(:value) { true }
      it { is_expected.to be true }
    end

    context 'value is false' do
      let(:value) { false }
      it { is_expected.to be false }
    end
  end

  describe '#formatted_value' do
    subject { instance.formatted_value }

    context 'value is present string' do
      let(:value) { '1' }

      it 'is the true string' do
        is_expected.to eql I18n.t(:general_text_Yes)
      end
    end

    context 'value is zero string' do
      let(:value) { '0' }

      it 'is the false string' do
        is_expected.to eql I18n.t(:general_text_No)
      end
    end

    context 'value is true' do
      let(:value) { true }

      it 'is the true string' do
        is_expected.to eql I18n.t(:general_text_Yes)
      end
    end

    context 'value is false' do
      let(:value) { false }

      it 'is the false string' do
        is_expected.to eql I18n.t(:general_text_No)
      end
    end

    context 'value is nil' do
      let(:value) { nil }

      it 'is the false string' do
        is_expected.to eql I18n.t(:general_text_No)
      end
    end

    context 'value is blank' do
      let(:value) { '' }

      it 'is the false string' do
        is_expected.to eql I18n.t(:general_text_No)
      end
    end
  end

  describe '#validate_type_of_value' do
    subject { instance.validate_type_of_value }

    context 'value corresponds to true' do
      let(:value) { '1' }
      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value corresponds to false' do
      let(:value) { '0' }
      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value is true' do
      let(:value) { true }
      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value is false' do
      let(:value) { false }
      it 'accepts' do
        is_expected.to be_nil
      end
    end
  end

  describe '#parse_value' do
    subject { instance.parse_value(value) }

    ActiveRecord::Type::Boolean::FALSE_VALUES.each do |falsey_value|
      context "for #{falsey_value}" do
        let(:value) { falsey_value }

        it "is 'f'" do
          is_expected.to eql 'f'
        end
      end
    end

    context 'for nil' do
      let(:value) { nil }

      it "is nil" do
        is_expected.to be_nil
      end
    end

    context "for ''" do
      let(:value) { '' }

      it "is nil" do
        is_expected.to be_nil
      end
    end

    [true, '1', 1, 't', 42, 'true'].each do |truthy_value|
      context "for #{truthy_value}" do
        let(:value) { truthy_value }

        it "is 't'" do
          is_expected.to eql 't'
        end
      end
    end
  end
end
