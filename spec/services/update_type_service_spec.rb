#-- encoding: UTF-8
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
require 'services/shared_type_service'

describe UpdateTypeService do
  let(:type) { FactoryBot.build_stubbed(:type) }
  let(:user) { FactoryBot.build_stubbed(:admin) }

  let(:instance) { described_class.new(type, user) }
  let(:service_call) { instance.call(params) }

  let(:valid_group) { { 'type' => 'attribute', 'name' => 'foo', 'attributes' => ['date'] } }

  it_behaves_like 'type service'

  describe "#validate_attribute_groups" do
    let(:params) { { name: 'blubs blubs' } }

    it 'raises an exception for invalid structure' do
      # Example for invalid structure:
      result = instance.call(attribute_groups: ['foo'])
      expect(result.success?).to be_falsey
      # Example for invalid structure:
      result = instance.call(attribute_groups: [[]])
      expect(result.success?).to be_falsey
      # Example for invalid group name:
      result = instance.call(attribute_groups: [['', ['date']]])
      expect(result.success?).to be_falsey
    end

    it 'fails for duplicate group names' do
      result = instance.call(attribute_groups: [valid_group, valid_group])
      expect(result.success?).to be_falsey
      expect(result.errors[:attribute_groups].first).to include 'used more than once.'
    end

    it 'passes validations for known attributes' do
      expect(type).to receive(:save).and_return(true)
      result = instance.call(attribute_groups: [valid_group])
      expect(result.success?).to be_truthy
    end

    it 'passes validation for defaults' do
      expect(type).to be_valid
    end

    it 'passes validation for reset' do
      # A reset is to save an empty Array
      expect(type).to receive(:save).and_return(true)
      result = instance.call(attribute_groups: [])
      expect(result.success?).to be_truthy
      expect(type).to be_valid
    end

    context 'with an invalid query' do
      let(:params) { { attribute_groups: [{ 'type' => 'query', name: 'some name', query: 'wat' }] } }

      it 'is invalid' do
        expect(service_call.success?).to be_falsey
      end
    end
  end
end
