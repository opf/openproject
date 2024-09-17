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

RSpec.describe "rb_master_backlogs/index" do
  let(:user) { create(:user) }
  let(:role_allowed) do
    create(:project_role,
           permissions: %i[view_master_backlog view_taskboards])
  end
  let(:statuses) do
    [create(:status, is_default: true),
     create(:status),
     create(:status)]
  end
  let(:type_task) { create(:type_task) }
  let(:type_feature) { create(:type_feature) }
  let(:issue_priority) { create(:priority) }
  let(:project) do
    project = create(:project, types: [type_feature, type_task])
    project.members = [create(:member, principal: user, project:, roles: [role_allowed])]
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
  let(:sprint) { create(:sprint, project:) }

  before do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [type_feature.id],
                                                                         "task_type" => type_task.id })
    view.extend RbCommonHelper
    view.extend RbMasterBacklogsHelper
    allow(view).to receive(:current_user).and_return(user)

    assign(:project, project)
    assign(:sprint, sprint)
    assign(:owner_backlogs, Backlog.owner_backlogs(project))
    assign(:sprint_backlogs, Backlog.sprint_backlogs(project))

    allow(User).to receive(:current).and_return(user)

    # We directly force the creation of stories by calling the method
    stories
  end
end
