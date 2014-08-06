#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

require 'spec_helper'

describe ::API::V3::CostObjects::CostObjectRepresenter do
  let(:project) { FactoryGirl.build(:project, id: 999) }
  let(:user) { FactoryGirl.build(:user,
                                 member_in_project: project,
                                 created_on: 1.day.ago,
                                 updated_on: Date.today) }
  let(:cost_object) { FactoryGirl.build(:cost_object,
                                        author: user,
                                        project: project,
                                        created_on: 1.day.ago,
                                        updated_on: Date.today) }

  let(:representer)  { described_class.new(model) }

  let(:model) { ::API::V3::CostObjects::CostObjectModel.new(cost_object) }

  context 'generation' do
    subject(:generated) { representer.to_json }

    it { should include_json('CostObject'.to_json).at_path('_type') }

    describe 'cost_object' do
      it { should have_json_path('id') }

      it { should have_json_path('description') }

      it { should have_json_path('projectId') }
      it { should have_json_path('projectName') }

      it { should have_json_path('subject') }
      it { should have_json_path('type') }

      it { should have_json_path('createdAt') }
      it { should have_json_path('updatedAt') }
    end
  end
end
