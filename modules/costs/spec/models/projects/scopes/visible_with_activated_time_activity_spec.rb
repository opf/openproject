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

RSpec.describe Projects::Scopes::VisibleWithActivatedTimeActivity do
  let!(:activity) { create(:time_entry_activity) }
  let!(:project) { create(:project) }
  let!(:work_package) { create(:work_package, project:) }
  let!(:other_project) { create(:project) }
  let!(:other_work_package) { create(:work_package, project: other_project) }
  let(:project_permissions) { [:view_time_entries] }
  let(:other_project_permissions) { [:view_time_entries] }
  let(:current_user) do
    create(:user).tap do |u|
      create(:member,
             project:,
             principal: u,
             roles: [create(:project_role, permissions: project_permissions)])

      create(:member,
             project: other_project,
             principal: u,
             roles: [create(:project_role, permissions: other_project_permissions)])
    end
  end

  before do
    login_as(current_user)
  end

  describe ".fetch" do
    subject { Project.visible_with_activated_time_activity(activity) }

    context "without project specific overrides" do
      context "and being active" do
        it "returns all projects" do
          expect(subject)
            .to contain_exactly(project, other_project)
        end
      end

      context "and not being active" do
        before do
          activity.update_attribute(:active, false)
        end

        it "returns no projects" do
          expect(subject)
            .to be_empty
        end
      end

      context "and having only view_own_time_entries_permission" do
        let(:project_permissions) { [:view_own_time_entries] }
        let(:other_project_permissions) { [:view_own_time_entries] }

        it "returns all projects" do
          expect(subject)
            .to contain_exactly(project, other_project)
        end
      end

      context "and having no view permission" do
        let(:project_permissions) { [] }
        let(:other_project_permissions) { [] }

        it "returns all projects" do
          expect(subject)
            .to be_empty
        end
      end
    end

    context "with project specific overrides" do
      before do
        TimeEntryActivitiesProject.insert({ activity_id: activity.id, project_id: project.id, active: true })
        TimeEntryActivitiesProject.insert({ activity_id: activity.id, project_id: other_project.id, active: false })
      end

      context "and being active" do
        it "returns the project the activity is activated in" do
          expect(subject)
            .to contain_exactly(project)
        end
      end

      context "and not being active" do
        before do
          activity.update_attribute(:active, false)
        end

        it "returns only the projects the activity is activated in" do
          expect(subject)
            .to contain_exactly(project)
        end
      end
    end
  end
end
