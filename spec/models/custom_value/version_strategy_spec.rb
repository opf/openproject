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

describe CustomValue::VersionStrategy do
  let(:custom_value) {
    double('CustomValue',
           value: value,
           custom_field: custom_field,
           customized: customized)
  }
  let(:customized) { double('customized') }
  let(:custom_field) { FactoryGirl.build(:custom_field) }

  describe '#typed_value' do
    subject { described_class.new(custom_value).typed_value }
    let(:version) { FactoryGirl.build(:version) }

    before do
      allow(Version).to receive(:find_by_id).with(value).and_return(version)
    end

    context 'value is some id string' do
      let(:value) { '10' }
      it { is_expected.to eql(version) }
    end

    context 'value is blank' do
      let(:value) { '' }
      it { is_expected.to be_nil }
    end

    context 'value is nil' do
      let(:value) { nil }
      it { is_expected.to be_nil }
    end
  end

  describe '#validate_type_of_value' do
    subject { described_class.new(custom_value).validate_type_of_value }
    let(:allowed_ids) { %w(12 13) }

    before do
      allow(custom_field).to receive(:possible_values).with(customized).and_return(allowed_ids)
    end

    context 'value is id of included element' do
      let(:value) { '12' }
      it 'accepts' do
        is_expected.to be_nil
      end
    end

    context 'value is id of non included element' do
      let(:value) { '10' }
      it 'rejects' do
        is_expected.to eql(:inclusion)
      end
    end
  end
end
