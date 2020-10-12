#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require File.dirname(__FILE__) + '/../../spec_helper'

describe 'rb_taskboards/show', type: :view do
  let(:user1) { FactoryBot.create(:user) }
  let(:user2) { FactoryBot.create(:user) }
  let(:role_allowed) {
    FactoryBot.create(:role,
                       permissions: [:add_work_packages, :edit_work_packages, :manage_subtasks])
  }
  let(:role_forbidden) { FactoryBot.create(:role) }
  # We need to create these as some view helpers access the database
  let(:statuses) {
    [FactoryBot.create(:status),
     FactoryBot.create(:status),
     FactoryBot.create(:status)]
  }

  let(:type_task) { FactoryBot.create(:type_task) }
  let(:type_feature) { FactoryBot.create(:type_feature) }
  let(:issue_priority) { FactoryBot.create(:priority) }
  let(:project) do
    project = FactoryBot.create(:project, types: [type_feature, type_task])
    project.members = [FactoryBot.create(:member, principal: user1, project: project, roles: [role_allowed]),
                       FactoryBot.create(:member, principal: user2, project: project, roles: [role_forbidden])]
    project
  end

  let(:story_a) {
    FactoryBot.create(:story, status: statuses[0],
                               project: project,
                               type: type_feature,
                               version: sprint,
                               priority: issue_priority
                      )
  }
  let(:story_b) {
    FactoryBot.create(:story, status: statuses[1],
                               project: project,
                               type: type_feature,
                               version: sprint,
                               priority: issue_priority
                      )
  }
  let(:story_c) {
    FactoryBot.create(:story, status: statuses[2],
                               project: project,
                               type: type_feature,
                               version: sprint,
                               priority: issue_priority
                      )
  }
  let(:stories) { [story_a, story_b, story_c] }
  let(:sprint)   { FactoryBot.create(:sprint, project: project) }
  let(:task) do
    task = FactoryBot.create(:task, project: project, status: statuses[0], version: sprint, type: type_task)
    # This is necessary as for some unknown reason passing the parent directly
    # leads to the task searching for the parent with 'root_id' is NULL, which
    # is not the case as the story has its own id as root_id
    task.parent_id = story_a.id
    task
  end
  let(:impediment) { FactoryBot.create(:impediment, project: project, status: statuses[0], version: sprint, blocks_ids: task.id.to_s, type: type_task) }

  before :each do
    allow(Setting).to receive(:plugin_openproject_backlogs).and_return({ 'story_types' => [type_feature.id], 'task_type' => type_task.id })
    view.extend RbCommonHelper
    view.extend TaskboardsHelper

    assign(:project, project)
    assign(:sprint, sprint)
    assign(:statuses, statuses)

    # We directly force the creation of stories by calling the method
    stories
  end

  describe 'story blocks' do
    it 'contains the story id' do
      render

      stories.each do |story|
        expect(rendered).to have_selector "#story_#{story.id}" do
          with_selector '.id', Regexp.new(story.id.to_s)
        end
      end
    end

    it 'has a title containing the story subject' do
      render

      stories.each do |story|
        expect(rendered).to have_selector "#story_#{story.id}" do
          with_selector '.subject', story.subject
        end
      end
    end

    it 'contains the story status' do
      render

      stories.each do |story|
        expect(rendered).to have_selector "#story_#{story.id}" do
          with_selector '.status', story.status.name
        end
      end
    end

    it 'contains the user it is assigned to' do
      render

      stories.each do |story|
        expect(rendered).to have_selector "#story_#{story.id}" do
          with_selector '.assigned_to_id', assignee.name
        end
      end
    end
  end

  describe 'create buttons' do
    it 'renders clickable + buttons for all stories with the right permissions' do
      allow(User).to receive(:current).and_return(user1)

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_content '+'
          expect(td.first[:class]).to include 'clickable'
        end
      end
    end

    it 'does not render a clickable + buttons for all stories without the right permissions' do
      allow(User).to receive(:current).and_return(user2)

      render

      stories.each do |story|
        assert_select "tr.story_#{story.id} td.add_new" do |td|
          expect(td.count).to eq 1
          expect(td.first).not_to have_content '+'
          expect(td.first[:class]).not_to include 'clickable'
        end
      end
    end

    it 'renders clickable + buttons for impediments with the right permissions' do
      allow(User).to receive(:current).and_return(user1)

      render

      stories.each do |_story|
        assert_select '#impediments td.add_new' do |td|
          expect(td.count).to eq 1
          expect(td.first).to have_content '+'
          expect(td.first[:class]).to include 'clickable'
        end
      end
    end

    it 'does not render a clickable + buttons for impediments without the right permissions' do
      allow(User).to receive(:current).and_return(user2)

      render

      stories.each do |_story|
        assert_select '#impediments td.add_new' do |td|
          expect(td.count).to eq 1
          expect(td.first).not_to have_content '+'
          expect(td.first[:class]).not_to include 'clickable'
        end
      end
    end
  end

  describe 'update tasks or impediments' do
    it 'allows edit and drag for all tasks with the right permissions' do
      allow(User).to receive(:current).and_return(user1)
      task
      impediment
      render

      assert_select '.model.work_package.task' do |task|
        expect(task.count).to eq 1
        expect(task.first).not_to have_css '.task.prevent_edit'
      end
    end

    it 'does not allow to edit and drag for all tasks without the right permissions' do
      allow(User).to receive(:current).and_return(user2)
      task
      impediment

      render

      assert_select '.model.work_package.task' do |task|
        expect(task.count).to eq 1
        expect(task.first).to have_css '.task.prevent_edit'
      end
    end

    it 'allows edit and drag for all impediments with the right permissions' do
      allow(User).to receive(:current).and_return(user1)
      task
      impediment

      render

      assert_select '.model.work_package.impediment' do |impediment|
        expect(impediment.count).to eq 3 # 2 additional for the task and the invisible form
        expect(impediment.first).not_to have_css '.impediment.prevent_edit'
      end
    end

    it 'does not allow to edit and drag for all impediments without the right permissions' do
      allow(User).to receive(:current).and_return(user2)
      task
      impediment

      render

      assert_select '.model.work_package.impediment' do |impediment|
        expect(impediment.count).to eq 3 # 2 additional for the task and the invisible form
        expect(impediment.first).to have_css '.impediment.prevent_edit'
      end
    end
  end
end
