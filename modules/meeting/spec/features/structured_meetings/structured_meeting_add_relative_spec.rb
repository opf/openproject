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

require_relative "../../support/pages/meetings/show"

RSpec.describe "Add agenda item above/below", :js do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings edit_meetings manage_agendas] })
  end
  shared_let(:meeting) { create(:meeting, project:, author: user) }
  shared_let(:section) { create(:meeting_section, meeting:) }
  shared_let(:first_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, title: "First") }
  shared_let(:second_item) { create(:meeting_agenda_item, meeting:, meeting_section: section, title: "Second") }

  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  current_user { user }

  before do
    show_page.visit!
  end

  it "inserts a new item above the selected item" do
    show_page.assert_agenda_order! "First", "Second"

    show_page.add_agenda_item_relative(second_item, position: :above) do
      fill_in "Title", with: "In between"
    end

    show_page.assert_agenda_order! "First", "In between", "Second"
  end

  it "inserts a new item below the selected item" do
    show_page.assert_agenda_order! "First", "Second"

    show_page.add_agenda_item_relative(first_item, position: :below) do
      fill_in "Title", with: "In between"
    end

    show_page.assert_agenda_order! "First", "In between", "Second"
  end

  it "keeps a second open form when saving the first one" do
    show_page.open_add_item_relative(first_item, position: :below)
    below_form = "#meeting-agenda-items-new-component-relative-#{first_item.id}-below"
    expect(page).to have_css(below_form, count: 1)

    show_page.add_agenda_item_relative(second_item, position: :above) do
      fill_in "Title", with: "Above second"
    end

    show_page.assert_agenda_order! "First", "Above second", "Second"
    expect(page).to have_css(below_form, count: 1)
  end

  it "does not stack a duplicate form when the same option is re-opened" do
    form_selector = "#meeting-agenda-items-new-component-relative-#{second_item.id}-above"

    show_page.open_add_item_relative(second_item, position: :above)
    expect(page).to have_css(form_selector, count: 1)

    show_page.open_add_item_relative(second_item, position: :above)
    expect(page).to have_css(form_selector, count: 1)
  end

  it "cancels the relative form without creating an item" do
    show_page.add_agenda_item_relative(first_item, position: :below, save: false) do
      click_on I18n.t("button_cancel")
    end

    expect(page).to have_no_css("#meeting-agenda-items-new-component-relative-#{first_item.id}-below")
    show_page.assert_agenda_order! "First", "Second"
  end
end
