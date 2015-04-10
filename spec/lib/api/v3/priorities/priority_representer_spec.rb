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

describe ::API::V3::Priorities::PriorityRepresenter do
  let(:priority) { FactoryGirl.build(:priority) }
  let(:representer) { described_class.new(priority) }

  include API::V3::Utilities::PathHelper

  context 'generation' do
    subject { representer.to_json }

    it 'should indicate its type' do
      is_expected.to include_json('Priority'.to_json).at_path('_type')
    end

    describe 'links' do
      it { is_expected.to have_json_type(Object).at_path('_links') }
      it 'should link to self' do
        path = api_v3_paths.priority(priority.id)

        is_expected.to be_json_eql(path.to_json).at_path('_links/self/href')
      end
      it 'should display its name as title in self' do
        is_expected.to be_json_eql(priority.name.to_json).at_path('_links/self/title')
      end
    end

    describe 'priority' do
      it 'should have an id' do
        is_expected.to be_json_eql(priority.id.to_json).at_path('id')
      end
      it 'should have a name' do
        is_expected.to be_json_eql(priority.name.to_json).at_path('name')
      end
      it 'should have a position' do
        is_expected.to be_json_eql(priority.position.to_json).at_path('position')
      end
      it 'should have a default flag' do
        is_expected.to be_json_eql(priority.is_default.to_json).at_path('isDefault')
      end
      it 'should have an active flag' do
        is_expected.to be_json_eql(priority.active.to_json).at_path('isActive')
      end
    end
  end
end
