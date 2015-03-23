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

describe ::API::V3::Types::TypeRepresenter do
  let(:type) { FactoryGirl.build_stubbed(:type, color: FactoryGirl.build(:color)) }
  let(:representer) { described_class.new(type) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject { representer.to_json }

    describe 'links' do
      it_behaves_like 'has a titled link' do
        let(:link) { 'self' }
        let(:href) { api_v3_paths.type(type.id) }
        let(:title) { type.name }
      end
    end

    it 'indicates its id' do
      is_expected.to be_json_eql(type.id.to_json).at_path('id')
    end

    it 'indicates its name' do
      is_expected.to be_json_eql(type.name.to_json).at_path('name')
    end

    it 'indicates its color' do
      is_expected.to be_json_eql(type.color.hexcode.to_json).at_path('color')
    end

    context 'no color set' do
      let(:type) { FactoryGirl.build(:type, color: nil) }

      it 'indicates a missing color' do
        is_expected.to be_json_eql(nil.to_json).at_path('color')
      end
    end

    it 'indicates its position' do
      is_expected.to be_json_eql(type.position.to_json).at_path('position')
    end

    it 'indicates that it is not the default type' do
      is_expected.to be_json_eql(false.to_json).at_path('isDefault')
    end

    context 'as default type' do
      let(:type) { FactoryGirl.build(:type, is_default: true) }

      it 'indicates that it is the default type' do
        is_expected.to be_json_eql(true.to_json).at_path('isDefault')
      end
    end

    it 'indicates that it is not a milestone' do
      is_expected.to be_json_eql(false.to_json).at_path('isMilestone')
    end

    context 'as milestone' do
      let(:type) { FactoryGirl.build(:type, is_milestone: true) }

      it 'indicates that it is a milestone' do
        is_expected.to be_json_eql(true.to_json).at_path('isMilestone')
      end
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { type.created_at }
      let(:json_path) { 'createdAt' }
    end

    it_behaves_like 'has UTC ISO 8601 date and time' do
      let(:date) { type.updated_at }
      let(:json_path) { 'updatedAt' }
    end
  end
end
