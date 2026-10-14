# frozen_string_literal: true

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

require "spec_helper"

RSpec.describe Planner::OrphanedProjectService do
  let!(:task) { create(:type_task) }
  let!(:role) do
    create(:project_role, permissions: ProjectRole::PERMISSIONS_FOR_PROJECT_CREATOR + %i[view_work_packages])
  end
  let(:user) { create(:user) }
  let!(:planner_project) { Planner::ProjectService.new(user).call.result }
  let(:member) { Member.find_by(project: planner_project, principal: user) }

  subject { Members::DeleteService.new(user: User.system, model: member, contract_class: EmptyContract).call }

  it "schedules the deletion of the user's My work project once they are gone" do
    expect { subject }.to have_enqueued_job(Projects::DeleteProjectJob).with(user: User.system, project: planner_project)
    expect(planner_project.reload).to be_archived
  end

  context "when someone else is still a member" do
    before { create(:member, project: planner_project, principal: create(:user), roles: [role]) }

    it "keeps the project" do
      expect { subject }.not_to have_enqueued_job(Projects::DeleteProjectJob)
    end
  end

  context "when the member leaves another project" do
    let(:other_project) { create(:project) }
    let(:member) { create(:member, project: other_project, principal: user, roles: [role]) }

    it "keeps both projects" do
      expect { subject }.not_to have_enqueued_job(Projects::DeleteProjectJob)
      expect(other_project.reload).not_to be_archived
    end
  end
end
