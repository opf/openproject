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

require_relative "../support/pages/meetings/show"

RSpec.describe "Convert agenda item to work package", :js do
  shared_let(:status) { create(:status, is_default: true) }
  shared_let(:priority) { create(:priority, is_default: true) }
  shared_let(:project) { create(:project_with_types, enabled_module_names: %w[meetings work_package_tracking]) }
  shared_let(:user) do
    create :user,
           preferences: { time_zone: "Etc/UTC" },
           member_with_permissions: { project => %i[view_meetings manage_agendas view_work_packages add_work_packages] }
  end
  shared_let(:meeting) do
    create :meeting,
           project:,
           start_time: "2024-12-31T13:30:00Z",
           duration: 1.5,
           author: user
  end
  shared_let(:meeting_agenda_item) do
    create(:meeting_agenda_item,
           meeting:,
           author: user,
           title: "Discuss the roadmap",
           notes: "Some discussion notes")
  end

  let(:show_page) { Pages::Meetings::Show.new(meeting) }
  let(:dialog_title) { I18n.t(:label_agenda_item_convert_to_work_package) }

  before do
    login_as user
  end

  it "creates a work package and converts the agenda item to link it" do
    show_page.visit!
    wait_for_network_idle

    show_page.open_menu(meeting_agenda_item) do
      expect(page).to have_text(dialog_title)
      click_on dialog_title
    end

    expect(page).to have_dialog(dialog_title)

    page.within_dialog(dialog_title) do
      expect(page).to have_field("Subject", with: "Discuss the roadmap")
      fill_in "Subject", with: "Roadmap planning"
      click_on "Create"
    end

    wait_for_network_idle

    expect(page).to have_no_selector(:dialog, dialog_title, wait: 10)

    created_wp = WorkPackage.find_by(subject: "Roadmap planning")
    expect(created_wp).to be_present
    expect(created_wp.project).to eq(project)

    meeting_agenda_item.reload
    expect(meeting_agenda_item).to be_work_package
    expect(meeting_agenda_item.work_package_id).to eq(created_wp.id)
    expect(meeting_agenda_item.title).to be_nil
    expect(meeting_agenda_item.notes).to eq("workPackageValue:#{created_wp.id}:description")

    within("#meeting-agenda-item-#{meeting_agenda_item.id}") do
      expect(page).to have_link(created_wp.subject)
    end
  end

  context "when user lacks add_work_packages permission" do
    let(:restricted_user) do
      create(:user,
             member_with_permissions: { project => %i[view_meetings manage_agendas view_work_packages] })
    end

    before { login_as restricted_user }

    it "does not show the convert option in the menu" do
      show_page.visit!
      wait_for_network_idle

      show_page.open_menu(meeting_agenda_item) do
        expect(page).to have_no_text(dialog_title)
      end
    end
  end
end
