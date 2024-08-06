#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require File.expand_path(File.dirname(__FILE__) + "/../spec_helper")

RSpec.describe WorkPackage do
  let(:user) { create(:admin) }
  let(:role) { create(:project_role) }
  let(:project) do
    create(:project_with_types, members: { user => role })
  end

  let(:project2) { create(:project_with_types, types: project.types) }
  let(:work_package) do
    create(:work_package, project:,
                          type: project.types.first,
                          author: user)
  end
  let!(:cost_entry) do
    create(:cost_entry, work_package:, project:, units: 3, spent_on: Date.today, user:,
                        comments: "test entry")
  end
  let!(:budget) { create(:budget, project:) }

  def move_to_project(work_package, project)
    WorkPackages::UpdateService
      .new(model: work_package, user:)
      .call(project:)
  end

  it "updates cost entries on move" do
    expect(work_package.project_id).to eql project.id
    expect(move_to_project(work_package, project2)).not_to be_falsey
    expect(cost_entry.reload.project_id).to eql project2.id
  end

  it "allows to set budget to nil" do
    work_package.budget = budget
    work_package.save!
    expect(work_package.budget).to eql budget

    work_package.reload
    work_package.budget = nil
    expect { work_package.save! }.not_to raise_error
  end
end
