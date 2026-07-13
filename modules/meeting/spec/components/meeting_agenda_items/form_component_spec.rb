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
#
require "rails_helper"

RSpec.describe MeetingAgendaItems::FormComponent, type: :component do
  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:meeting) { build_stubbed(:meeting) }
  let(:meeting_section) { build_stubbed(:meeting_section, meeting:) }
  let(:meeting_agenda_item) { build_stubbed(:meeting_agenda_item, meeting:, meeting_section:) }
  let(:method) { :post }
  let(:submit_path) { "/submit" }
  let(:cancel_path) { "/cancel" }

  current_user { build_stubbed(:admin) }

  subject(:rendered_component) do
    render_component(
      meeting:, meeting_section:, meeting_agenda_item:, method:, submit_path:, cancel_path:
    )
  end

  context "with a new agenda item" do
    let(:meeting_agenda_item) { MeetingAgendaItem.new(meeting:, meeting_section:) }

    it "renders component wrapper" do
      expect(rendered_component).to have_element id: "meeting-agenda-items-form-component-new"
    end
  end

  context "with an existing agenda item" do
    it "renders component wrapper" do
      expect(rendered_component).to have_element id: "meeting-agenda-items-form-component-#{meeting_agenda_item.id}"
    end
  end

  it "renders form" do
    expect(rendered_component).to have_element :form, method:, action: submit_path
  end

  it "renders title field" do
    expect(rendered_component).to have_field "Title", required: true
  end

  it "renders duration field" do
    expect(rendered_component).to have_field "Duration", type: :number, placeholder: "mins"
  end

  it "renders presenter field" do
    expect(rendered_component).to have_element :label, text: "Presenter" do |label|
      expect(rendered_component).to have_element "opce-user-autocompleter",
                                                 "data-input-name": "\"meeting_agenda_item[presenter_id]\"",
                                                 "data-label-for-id": label["for"].to_json
    end
  end

  it "renders notes field" do
    expect(rendered_component).to have_field "Notes", type: :textarea, visible: :hidden do |textarea|
      expect(rendered_component).to have_element "opce-ckeditor-augmented-textarea",
                                                 "data-test-selector": "augmented-text-area-notes",
                                                 "data-text-area-id": textarea["id"].to_json
    end
  end

  it "renders Save button" do
    expect(rendered_component).to have_button "Save"
  end

  it "renders Cancel button" do
    expect(rendered_component).to have_link "Cancel", href: cancel_path
  end

  context "when meeting is a onetime template" do
    let(:meeting) { build_stubbed(:onetime_template) }

    it "does not render the presenter field" do
      expect(rendered_component).to have_no_element :label, text: "Presenter"
    end
  end
end
