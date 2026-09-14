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

RSpec.describe "Meeting drag and drop", :js, :selenium do
  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_meetings manage_agendas] })
  end
  shared_let(:meeting) do
    create(:meeting,
           project:,
           author: user,
           state: :in_progress)
  end
  let!(:section1) { create(:meeting_section, meeting:, title: "Section 1") }
  let!(:section2) { create(:meeting_section, meeting:, title: "Section 2") }
  let!(:agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section: section1, title: "Item to drag") }

  let(:show_page) { Pages::Meetings::Show.new(meeting) }

  before do
    login_as user
  end

  it "allows dragging an agenda item from one section to another" do
    show_page.visit!
    show_page.expect_agenda_item_in_section(title: "Item to drag", section: section1)

    item_element = page.find("#meeting-agenda-items-item-component-show-component-#{agenda_item.id}")
    drag_handle = item_element.find(".handle svg")

    target_section = page.find("#meeting-sections-show-component-#{section2.id}")

    drag_n_drop_element(from: drag_handle, to: target_section)

    wait_for { agenda_item.reload.meeting_section_id }.to eq(section2.id)

    show_page.expect_no_agenda_item_in_section(title: "Item to drag", section: section1)
    show_page.expect_agenda_item_in_section(title: "Item to drag", section: section2)

    expect(agenda_item.meeting_section).to eq(section2)
  end

  it "allows dragging an agenda item from the backlog to a section" do
    show_page.visit!
    show_page.expect_agenda_item_in_section(title: "Item to drag", section: section1)

    item_element = page.find("#meeting-agenda-items-item-component-show-component-#{agenda_item.id}")
    drag_handle = item_element.find(".handle svg")

    backlog = meeting.backlog
    target_section = page.find("#meeting-sections-show-component-#{backlog.id}")

    show_page.click_on_backlog
    show_page.expect_backlog(collapsed: false)

    drag_n_drop_element(from: drag_handle, to: target_section, offset_y: 30)

    wait_for { agenda_item.reload.meeting_section_id }.to eq(backlog.id)

    show_page.expect_no_agenda_item_in_section(title: "Item to drag", section: section1)
    show_page.expect_agenda_item_in_section(title: "Item to drag", section: backlog)

    expect(agenda_item.meeting_section).to eq(backlog)
  end

  it "allows dragging sections to reorder them" do
    section3 = create(:meeting_section, meeting:, title: "Section 3")

    show_page.visit!
    show_page.expect_section(title: "Section 1")
    show_page.expect_section(title: "Section 2")
    show_page.expect_section(title: "Section 3")

    initial_positions = [section1, section2, section3].map(&:position)
    expect(initial_positions).to eq([1, 2, 3])

    section3_element = page.find("#meeting-sections-show-component-#{section3.id}")
    section1_element = page.find("#meeting-sections-show-component-#{section1.id}")

    section3_drag_handle = section3_element.find(".handle svg")

    drag_n_drop_element(from: section3_drag_handle, to: section1_element)

    wait_for { section3.reload.position }.to eq(1)

    final_positions = [section1, section2, section3].map { |s| s.reload.position }
    expect(final_positions).to eq([2, 3, 1])
  end
end
