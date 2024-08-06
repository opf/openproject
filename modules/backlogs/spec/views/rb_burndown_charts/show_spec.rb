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

RSpec.describe "rb_burndown_charts/show" do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:role_allowed) do
    create(:project_role,
           permissions: %i[add_work_packages manage_subtasks])
  end
  let(:role_forbidden) { create(:project_role) }
  # We need to create these as some view helpers access the database
  let(:statuses) do
    [create(:status),
     create(:status),
     create(:status)]
  end

  let(:type_task) { create(:type_task) }
  let(:type_feature) { create(:type_feature) }
  let(:issue_priority) { create(:priority) }
  let(:project) do
    project = create(:project, types: [type_feature, type_task])
    project.members = [create(:member, principal: user1, project:, roles: [role_allowed]),
                       create(:member, principal: user2, project:, roles: [role_forbidden])]
    project
  end

  let(:story_a) do
    create(:story, status: statuses[0],
                   project:,
                   type: type_feature,
                   version: sprint,
                   priority: issue_priority)
  end
  let(:story_b) do
    create(:story, status: statuses[1],
                   project:,
                   type: type_feature,
                   version: sprint,
                   priority: issue_priority)
  end
  let(:story_c) do
    create(:story, status: statuses[2],
                   project:,
                   type: type_feature,
                   version: sprint,
                   priority: issue_priority)
  end
  let(:stories) { [story_a, story_b, story_c] }
  let(:sprint) do
    create(:sprint, project:, start_date: Date.today - 1.week, effective_date: Date.today + 1.week)
  end
  let(:task) do
    task = create(:task, project:, status: statuses[0], version: sprint, type: type_task)
    # This is necessary as for some unknown reason passing the parent directly
    # leads to the task searching for the parent with 'root_id' is NULL, which
    # is not the case as the story has its own id as root_id
    task.parent_id = story_a.id
    task
  end

  before do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [type_feature.id],
                                                                         "task_type" => type_task.id })
    view.extend BurndownChartsHelper

    # We directly force the creation of stories,statuses by calling the method
    stories
  end

  describe "burndown chart" do
    it "renders a version with dates" do
      assign(:sprint, sprint)
      assign(:project, project)
      assign(:burndown, sprint.burndown(project))
      render

      expect(view).to render_template(partial: "_burndown", count: 1)
    end

    it "renders a version without dates" do
      sprint.start_date = nil
      sprint.effective_date = nil
      sprint.save
      assign(:sprint, sprint)
      assign(:project, project)
      assign(:burndown, sprint.burndown(project))

      render

      expect(view).to render_template(partial: "_burndown", count: 0)
      expect(rendered).to include(I18n.t("backlogs.no_burndown_data"))
    end
  end
end
