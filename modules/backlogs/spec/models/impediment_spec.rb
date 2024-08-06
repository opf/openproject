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

RSpec.describe Impediment do
  let(:user) { @user ||= create(:user) }
  let(:role) { @role ||= create(:project_role) }
  let(:type_feature) { @type_feature ||= create(:type_feature) }
  let(:type_task) { @type_task ||= create(:type_task) }
  let(:issue_priority) { @issue_priority ||= create(:priority, is_default: true) }
  let(:status) { create(:status) }
  let(:task) do
    build(:task, type: type_task,
                 project:,
                 author: user,
                 priority: issue_priority,
                 status:)
  end
  let(:feature) do
    build(:work_package, type: type_feature,
                         project:,
                         author: user,
                         priority: issue_priority,
                         status:)
  end
  let(:version) { create(:version, project:) }

  let(:project) do
    unless @project
      @project = build(:project, types: [type_feature, type_task])
      @project.members = [build(:member, principal: user,
                                         project: @project,
                                         roles: [role])]
    end
    @project
  end

  let(:impediment) do
    build(:impediment, author: user,
                       version:,
                       assigned_to: user,
                       priority: issue_priority,
                       project:,
                       type: type_task,
                       status:)
  end

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
      .and_return({ "points_burn_direction" => "down",
                    "wiki_template" => "",
                    "story_types" => [type_feature.id.to_s],
                    "task_type" => type_task.id.to_s })

    login_as user
  end

  describe "instance methods" do
    describe "blocks_ids=/blocks_ids" do
      describe "WITH an integer" do
        it do
          impediment.blocks_ids = 2
          expect(impediment.blocks_ids).to eql [2]
        end
      end

      describe "WITH a string" do
        it do
          impediment.blocks_ids = "1, 2, 3"
          expect(impediment.blocks_ids).to eql [1, 2, 3]
        end
      end

      describe "WITH an array" do
        it do
          impediment.blocks_ids = [1, 2, 3]
          expect(impediment.blocks_ids).to eql [1, 2, 3]
        end
      end

      describe "WITH loading from the backend" do
        before do
          feature.version = version
          feature.save
          task.version = version
          task.save

          impediment.blocks_ids = [feature.id, task.id]
          impediment.save
        end

        it { expect(described_class.find(impediment.id).blocks_ids).to eql [feature.id, task.id] }
      end
    end
  end
end
