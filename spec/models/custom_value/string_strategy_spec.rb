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

describe CustomValue::StringStrategy do
  let(:instance) { described_class.new(custom_value) }
  let(:custom_value) do
    double('CustomValue',
           value: value)
  end

  describe '#typed_value' do
    subject { instance.typed_value }

    context 'value is some string' do
      let(:value) { 'foo bar!' }
      it { is_expected.to eql(value) }
    end

    context 'value is blank' do
      let(:value) { '' }
      it { is_expected.to eql(value) }
    end

    context 'value is nil' do
      let(:value) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '#formatted_value' do
    subject { instance.formatted_value }

    context 'value is some string' do
      let(:value) { 'foo bar!' }

      it 'is the string' do
        is_expected.to eql value
      end
    end

    context 'value is blank' do
      let(:value) { '' }

      it 'is a blank string' do
        is_expected.to eql value
      end
    end

    context 'value is nil' do
      let(:value) { nil }

      it 'is a blank string' do
        is_expected.to eql ''
      end
    end
  end

  describe '#validate_type_of_value' do
    subject { instance.validate_type_of_value }

    context 'value is some string' do
      let(:value) { 'foo bar!' }
      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value is empty string' do
      let(:value) { '' }
      it 'accepts' do
        is_expected.to be_nil
      end
    end
  end
end
