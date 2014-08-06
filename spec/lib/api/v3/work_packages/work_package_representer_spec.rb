#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe ::API::V3::WorkPackages::WorkPackageRepresenter do
  let(:project) { FactoryGirl.create(:project) }
  let(:role) { FactoryGirl.create(:role, permissions: [:view_time_entries,
                                                       :view_cost_entries,
                                                       :view_cost_rates]) }
  let(:user) { FactoryGirl.create(:user,
                                  member_in_project: project,
                                  member_through_role: role) }

  let(:cost_object) { FactoryGirl.create(:cost_object, project: project) }
  let(:cost_entry_1) { FactoryGirl.create(:cost_entry,
                                          work_package: work_package,
                                          project: project,
                                          units: 3,
                                          spent_on: Date.today,
                                          user: user,
                                          comments: "Entry 1") }
  let(:cost_entry_2) { FactoryGirl.create(:cost_entry,
                                          work_package: work_package,
                                          project: project,
                                          units: 3,
                                          spent_on: Date.today,
                                          user: user,
                                          comments: "Entry 2") }

  let(:work_package) { FactoryGirl.create(:work_package,
                                          project_id: project.id,
                                          cost_object: cost_object) }
  let(:model) { ::API::V3::WorkPackages::WorkPackageModel.new(work_package: work_package) }
  let(:representer) { described_class.new(model, current_user: user) }


  before(:each) do
    allow(User).to receive(:current).and_return user
  end

  describe 'generation' do
    before do
      cost_entry_1
      cost_entry_2
    end

    subject(:generated) { representer.to_json }

    describe 'work_package' do
      it { should have_json_path('spentHours') }
      it { should have_json_path('overallCosts') }

      describe 'embedded' do
        it { should have_json_path('_embedded/costObject') }
      end
    end
  end
end
