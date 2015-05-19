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

require 'spec_helper'

describe CustomValue::BoolStrategy do
  let(:custom_value) {
    double('CustomValue',
           value: value)
  }

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
    subject { described_class.new(custom_value).typed_value }

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

  describe '#validate_type_of_value' do
    subject { described_class.new(custom_value).validate_type_of_value }

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
end
