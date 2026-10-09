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

RSpec.describe "Creating a work package from a forum message", :js do
  shared_let(:type) { create(:type_task) }
  shared_let(:project) { create(:project, types: [type]) }
  shared_let(:status) { create(:default_status) }
  shared_let(:priority) { create(:default_priority) }
  shared_let(:forum) { create(:forum, project:) }
  shared_let(:topic) { create(:message, forum:, subject: "Release planning", content: "Opening post") }
  shared_let(:reply) { create(:message, forum:, parent: topic, content: "We should freeze on Friday") }
  shared_let(:member) do
    create(:user, member_with_permissions: { project => %i[view_messages view_work_packages add_work_packages] })
  end

  current_user { member }

  it "opens the prefilled dialog and returns to the message once created", :aggregate_failures do
    visit project_forum_topic_path(project, forum, topic)

    within_test_selector("message-actions-#{reply.id}") do
      click_on accessible_name: "Message actions"
      click_on "Add new work package"
    end

    within("#create-work-package-dialog") do
      expect(page).to have_field("Subject", with: "Release planning")
      expect(page).to have_text("We should freeze on Friday")
      fill_in "Subject", with: "Freeze on Friday"
      click_on "Create"
    end

    expect(page).to have_text("Successful creation.")
    expect(page).to have_current_path(project_forum_topic_path(project, forum, topic), ignore_query: true)
    expect(WorkPackage.last).to have_attributes(subject: "Freeze on Friday", description: "We should freeze on Friday")
  end
end
