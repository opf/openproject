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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Meeting::AddToSection, type: :forms do
  include_context "with rendered form"

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) { create(:user) }

  let(:params) { {} }

  def section_options
    expect(page).to have_css("opce-autocompleter")
    JSON.parse(page.find("opce-autocompleter")["data-items"])
  end

  def section_option_names
    section_options.map { |o| o["name"] }
  end

  def preselected_section_name
    section_options.find { |o| o["selected"] }&.fetch("name")
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
      expect(preselected_section_name).to eq("Agenda backlog")
    end
  end

  context "when the meeting has no named sections" do
    let(:model) do
      meeting = create(:meeting, project:, author: user)
      create(:meeting_agenda_item, meeting:)
    end

    it "inserts an untitled placeholder before the backlog" do
      expect(section_option_names).to eq(["Untitled section", "Agenda backlog"])
      expect(preselected_section_name).to eq("Agenda backlog")
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
      expect(preselected_section_name).to eq("Untitled section")
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
      expect(preselected_section_name).to eq("Untitled section")
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
      expect(preselected_section_name).to eq("Section B")
    end
  end

  context "when no meeting is selected" do
    let(:model) { build(:meeting_agenda_item, meeting: nil) }

    it "disables the section autocompleter and explains the prerequisite" do
      autocompleter = page.find("opce-autocompleter")

      expect(autocompleter["data-disabled"]).to be_json_eql(true)
      expect(autocompleter["data-placeholder"])
        .to be_json_eql(I18n.t("placeholder_section_select_meeting_first").to_json)
    end
  end

  context "when an agenda item is moved to the next occurrence" do
    let(:series) { create(:recurring_meeting, project:, author: user) }

    let(:current_meeting) do
      create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: series.start_time)
    end

    let(:next_meeting) do
      create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: series.start_time + 1.week).tap do |meeting|
        ["", "Intro", "Outro"].each { |title| create(:meeting_section, meeting:, title:) }
      end
    end

    let(:current_section) { create(:meeting_section, meeting: current_meeting, title: "Intro") }
    let(:model) { create(:meeting_agenda_item, meeting: current_meeting, meeting_section: current_section) }
    let(:item) { model }
    let(:params) { { occurrence: next_meeting, item:, move_to_section: false } }

    it "preselects the section with the same title" do
      expect(preselected_section_name).to eq("Intro")
    end

    context "when no section has the same title" do
      let(:current_section) { create(:meeting_section, meeting: current_meeting, title: "Other") }

      it "preselects the last section" do
        expect(preselected_section_name).to eq("Outro")
      end
    end

    context "when a section title only differs in case" do
      let(:current_section) { create(:meeting_section, meeting: current_meeting, title: "intro") }

      it "preselects the last section" do
        expect(preselected_section_name).to eq("Outro")
      end
    end

    context "when the current section is untitled" do
      let(:current_section) { create(:meeting_section, meeting: current_meeting, title: "") }

      it "preselects the last section" do
        expect(preselected_section_name).to eq("Outro")
      end
    end

    context "when the agenda item is in the backlog" do
      let(:current_section) { series.template.backlog }

      it "preselects the last section" do
        expect(preselected_section_name).to eq("Outro")
      end
    end
  end

  context "when an item is moved to another section of the same meeting" do
    let(:model) do
      meeting = create(:meeting, project:, author: user)
      current_section = create(:meeting_section, meeting:, title: "Intro")

      create(:meeting_section, meeting:, title: "Outro")
      create(:meeting_agenda_item, meeting:, meeting_section: current_section)
    end

    let(:params) { { occurrence: model.meeting, item: model, move_to_section: true } }

    it "hides the current section from the available options" do
      expect(section_option_names).not_to include("Intro")
      expect(section_option_names).to include("Outro")
    end
  end
end
