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

RSpec.describe Meeting::AddToSection, type: :forms do
  include_context "with rendered form"

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) { create(:user) }

  let(:params) { {} }

  def section_option_names
    autocompleter_items.map { |item| item["name"] }
  end

  def selected_section_name
    JSON.parse(autocompleter["data-model"])&.fetch("name")
  end

  def autocompleter_items
    JSON.parse(autocompleter["data-items"])
  end

  def autocompleter
    page.find("opce-autocompleter")
  end

  # Sections must be created inside `let(:model)` so they exist when the form is evaluated.
  # The shared context renders the form in an outer `before` hook, which runs before any
  # `let!` inner hooks — so data must be set up as part of the model itself.

  context "when the meeting has named sections" do
    let(:model) do
      meeting = create(:meeting, project:, author: user)
      create(:meeting_section, meeting:, title: "Section A")
      create(:meeting_section, meeting:, title: "Section B")
      meeting.sections.reload
      create(:meeting_agenda_item, meeting:)
    end

    it "lists named sections and the backlog, without a placeholder" do
      expect(section_option_names).to include("Section A", "Section B", "Agenda backlog")
      expect(section_option_names).not_to include("Untitled section")
      expect(selected_section_name).to eq("Agenda backlog")
    end
  end

  context "when the meeting has no named sections" do
    let(:model) do
      meeting = create(:meeting, project:, author: user)
      create(:meeting_agenda_item, meeting:)
    end

    it "inserts an untitled placeholder before the backlog" do
      expect(section_option_names).to eq(["Untitled section", "Agenda backlog"])
      expect(selected_section_name).to eq("Agenda backlog")
    end
  end

  context "when an occurrence with no named sections is given" do
    let(:model) do
      recurring_meeting = create(:recurring_meeting, project:, author: user)
      create(:recurring_meeting_occurrence, project:, recurring_meeting:)
      create(:meeting_agenda_item, meeting: recurring_meeting.template)
    end
    let(:params) do
      { occurrence: model.meeting.recurring_meeting.meetings.find_by!(template: false) }
    end

    it "inserts an untitled placeholder for the occurrence" do
      expect(section_option_names).to contain_exactly("Untitled section")
      expect(selected_section_name).to eq("Untitled section")
    end
  end

  context "when a recurring occurrence with no named sections is selected" do
    let(:model) do
      recurring_meeting = create(:recurring_meeting, project:, author: user)
      occurrence = create(:recurring_meeting_occurrence, project:, recurring_meeting:)
      create(:meeting_agenda_item, meeting: occurrence)
    end

    it "inserts an untitled placeholder before the series backlog" do
      expect(section_option_names).to contain_exactly("Untitled section", "Series backlog")
      expect(selected_section_name).to eq("Untitled section")
    end
  end

  context "when an occurrence with named sections is given" do
    let(:model) do
      recurring_meeting = create(:recurring_meeting, project:, author: user)
      occurrence = create(:recurring_meeting_occurrence, project:, recurring_meeting:)
      create(:meeting_section, meeting: occurrence, title: "Section A")
      create(:meeting_section, meeting: occurrence, title: "Section B")
      create(:meeting_agenda_item, meeting: occurrence)
    end

    it "lists the occurrence sections and series backlog and selects the last section" do
      expect(section_option_names).to contain_exactly("Section A", "Section B", "Series backlog")
      expect(selected_section_name).to eq("Section B")
    end
  end

  context "when no meeting is selected" do
    let(:model) { build(:meeting_agenda_item, meeting: nil) }

    it "disables the section autocompleter and explains the prerequisite" do
      expect(autocompleter["data-disabled"]).to be_json_eql(true)
      expect(autocompleter["data-placeholder"])
        .to be_json_eql(I18n.t("placeholder_section_select_meeting_first").to_json)
    end
  end
end
