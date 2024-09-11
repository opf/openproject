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
require_relative "../../support/pages/backlogs"

RSpec.describe "Backlogs context menu", :js, :with_cuprite do
  shared_let(:story_type) { create(:type_feature) }
  shared_let(:task_type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [story_type, task_type]) }
  shared_let(:role) do
    create(:project_role,
           permissions: %i[edit_work_packages
                           change_work_package_status
                           view_master_backlog
                           view_work_packages])
  end

  shared_let(:user) do
    create(:user,
           member_with_roles: { project => role })
  end
  shared_let(:sprint) do
    create(:version,
           project:,
           name: "Sprint")
  end
  shared_let(:new_status) { create(:default_status, name: "New") }
  shared_let(:in_progress_status) { create(:status, name: "In progress") }
  shared_let(:default_priority) { create(:default_priority) }
  shared_let(:story) do
    create(:work_package,
           type: story_type,
           project:,
           status: new_status,
           priority: default_priority,
           story_points: 3,
           version: sprint)
  end
  shared_let(:workflow) do
    create(:workflow,
           old_status: new_status,
           new_status: in_progress_status,
           role:,
           type: story_type)
  end

  let(:backlogs_page) { Pages::Backlogs.new(project) }

  before do
    allow(Setting)
      .to receive(:plugin_openproject_backlogs)
            .and_return("story_types" => [story_type.id.to_s],
                        "task_type" => task_type.id.to_s)
    login_as(user)
  end

  def expect_fields(enabled: [], disabled: [], none: [])
    enabled.each do |field|
      expect(page).to have_field(WorkPackage.human_attribute_name(field))
    end

    disabled.each do |field|
      expect(page).to have_field(WorkPackage.human_attribute_name(field), disabled: true)
    end

    none.each do |field|
      expect(page).to have_no_field(WorkPackage.human_attribute_name(field), visible: :all)
    end
  end

  # this test acts as a control for the other tests in this file as it's easy to
  # expect a field to not be present, and have the test still pass when the
  # field is renamed.
  context "when the user has edit_work_packages permission" do
    it "is possible to edit any story field" do
      backlogs_page.visit!
      backlogs_page.enter_edit_story_mode(story)

      expect_fields(enabled: %i[type subject status story_points])

      backlogs_page.alter_attributes_in_edit_story_mode(story, subject: "Hello subject")
      backlogs_page.save_story_from_edit_mode(story)

      expect(story.reload.subject).to eq("Hello subject")
    end
  end

  context "when the user has only change_work_package_status permission" do
    before do
      RolePermission.where(permission: "edit_work_packages").delete_all
    end

    it "is only possible to edit status field of stories" do
      backlogs_page.visit!
      backlogs_page.enter_edit_story_mode(story, text: story.status.name)

      expect_fields(enabled: %i[status], disabled: %i[type subject story_points])

      backlogs_page.alter_attributes_in_edit_story_mode(story, status: in_progress_status.name)
      backlogs_page.save_story_from_edit_mode(story)

      expect(story.reload.status).to eq(in_progress_status)
    end
  end

  context "when the user has neither change_work_package_status nor edit_work_packages permission" do
    before do
      RolePermission.where(permission: ["change_work_package_status", "edit_work_packages"]).delete_all
    end

    it "is not possible to edit any story field" do
      backlogs_page.visit!
      backlogs_page.enter_edit_story_mode(story)

      expect_fields(none: %i[type subject status story_points])
    end
  end
end
