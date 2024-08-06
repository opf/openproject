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

RSpec.describe "rb_taskboards/show" do
  let(:user1) { create(:user) }
  let(:user2) { create(:user) }
  let(:role_allowed) do
    create(:project_role,
           permissions: %i[add_work_packages edit_work_packages manage_subtasks])
  end
  let(:role_forbidden) { create(:project_role) }
  # We need to create these as some view helpers access the database
  let(:statuses) { create_list(:status, 3) }

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
  let(:sprint) { create(:sprint, project:) }
  let(:task) do
    task = create(:task, project:, status: statuses[0], version: sprint, type: type_task)
    # This is necessary as for some unknown reason passing the parent directly
    # leads to the task searching for the parent with 'root_id' is NULL, which
    # is not the case as the story has its own id as root_id
    task.parent_id = story_a.id
    task
  end
  let(:impediment) do
    create(:impediment, project:, status: statuses[0], version: sprint, blocks_ids: task.id.to_s,
                        type: type_task)
  end

  before do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ "story_types" => [type_feature.id],
                                                                         "task_type" => type_task.id })
    view.extend RbCommonHelper
    view.extend TaskboardsHelper

    assign(:project, project)
    assign(:sprint, sprint)
    assign(:statuses, statuses)

    # We directly force the creation of stories by calling the method
    stories
  end

  describe "story blocks" do
    it "contains the story id" do
      render

      stories.each do |story|
        expect(rendered).to have_css("#story_#{story.id} .id", text: story.id.to_s)
      end
    end

    it "has a title containing the story subject" do
      render

      stories.each do |story|
        expect(rendered).to have_css("#story_#{story.id} .subject", text: story.subject)
      end
    end

    it "contains the story status" do
      render

      stories.each do |story|
        expect(rendered).to have_css("#story_#{story.id} .status", text: story.status.name)
      end
    end

    it "contains the user it is assigned to" do
      story_a.update(assigned_to: user1)
      story_c.update(assigned_to: user2)

      render

      stories.each do |story|
        expected_text = story.assigned_to ? story.assigned_to.name : "Unassigned"
        expect(rendered).to have_css("#story_#{story.id} .assigned_to_id", text: expected_text)
      end
    end
  end

  describe "create buttons" do
    it "renders clickable + buttons for all stories with the right permissions" do
      allow(User).to receive(:current).and_return(user1)

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_content "+"
          expect(td.first[:class]).to include "clickable"
        end
      end
    end

    it "does not render a clickable + buttons for all stories without the right permissions" do
      allow(User).to receive(:current).and_return(user2)

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_no_content "+"
          expect(td.first[:class]).not_to include "clickable"
        end
      end
    end

    it "renders clickable + buttons for impediments with the right permissions" do
      allow(User).to receive(:current).and_return(user1)

      render

      stories.each do |_story|
        assert_select "#impediments td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_content "+"
          expect(td.first[:class]).to include "clickable"
        end
      end
    end

    it "does not render a clickable + buttons for impediments without the right permissions" do
      allow(User).to receive(:current).and_return(user2)

      render

      stories.each do |_story|
        assert_select "#impediments td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_no_content "+"
          expect(td.first[:class]).not_to include "clickable"
        end
      end
    end
  end

  describe "update tasks or impediments" do
    it "allows edit and drag for all tasks with the right permissions" do
      allow(User).to receive(:current).and_return(user1)
      task
      impediment
      render

      assert_select ".model.work_package.task" do |task|
        expect(task.count).to eq 1
        expect(task.first).to have_no_css ".task.prevent_edit"
      end
    end

    it "does not allow to edit and drag for all tasks without the right permissions" do
      allow(User).to receive(:current).and_return(user2)
      task
      impediment

      render

      assert_select ".model.work_package.task" do |task|
        expect(task.count).to eq 1
        expect(task.first).to have_css ".task.prevent_edit"
      end
    end

    it "allows edit and drag for all impediments with the right permissions" do
      allow(User).to receive(:current).and_return(user1)
      task
      impediment

      render

      assert_select ".model.work_package.impediment" do |impediment|
        expect(impediment.count).to eq 3 # 2 additional for the task and the invisible form
        expect(impediment.first).to have_no_css ".impediment.prevent_edit"
      end
    end

    it "does not allow to edit and drag for all impediments without the right permissions" do
      allow(User).to receive(:current).and_return(user2)
      task
      impediment

      render

      assert_select ".model.work_package.impediment" do |impediment|
        expect(impediment.count).to eq 3 # 2 additional for the task and the invisible form
        expect(impediment.first).to have_css ".impediment.prevent_edit"
      end
    end
  end
end
