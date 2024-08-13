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

RSpec.describe WorkPackage do
  describe "#backlogs_types" do
    it "returns all the ids of types that are configures to be considered backlogs types" do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [1], "task_type" => 2 })

      expect(described_class.backlogs_types).to contain_exactly(1, 2)
    end

    it "returns an empty array if nothing is defined" do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({})

      expect(described_class.backlogs_types).to eq([])
    end

    it "reflects changes to the configuration" do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [1], "task_type" => 2 })
      expect(described_class.backlogs_types).to contain_exactly(1, 2)

      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [3], "task_type" => 4 })
      expect(described_class.backlogs_types).to contain_exactly(3, 4)
    end
  end

  describe "#story" do
    shared_let(:project) { create(:project) }
    shared_let(:status) { create(:status) }
    shared_let(:story_type) { create(:type, name: "Story") }
    shared_let(:task_type) { create(:type, name: "Task") }

    before do
      allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [story_type.id],
                                                                           "task_type" => task_type.id })
    end

    context "for a WorkPackage" do
      let(:work_package) { build_stubbed(:work_package) }

      it "returns nil" do
        expect(work_package.story).to be_nil
      end
    end

    context "for a Story" do
      let(:story) { create(:story, project:, status:, type: story_type) }

      it "returns self" do
        expect(story.story).to eq(story)
      end
    end

    context "for a Task" do
      let(:parent_parent_story) { create(:story, project:, status:, type: story_type) }
      let(:parent_story) { create(:story, parent: parent_parent_story, project:, status:, type: story_type) }
      let(:task) { create(:task, parent: parent_story, project:, status:, type: task_type) }

      it "returns the closest WorkPackage ancestor being a Story" do
        expect(task.story).to eq(described_class.find(parent_story.id))

        # transform the parent_story into a task
        parent_story.update(type: task_type)

        # the returned story is now the grand parent
        expect(task.story).to eq(described_class.find(parent_parent_story.id))
      end
    end
  end
end
