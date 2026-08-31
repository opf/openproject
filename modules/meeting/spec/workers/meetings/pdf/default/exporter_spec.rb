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
require "pdf/inspector"

RSpec.describe Meetings::PDF::Default::Exporter do
  include Redmine::I18n

  shared_let(:role) { create(:project_role, permissions: [:view_work_packages]) }
  shared_let(:user) { create(:user, firstname: "Export", lastname: "User") }
  shared_let(:other_user) { create(:user, firstname: "Other", lastname: "Account") }
  shared_let(:project) do
    project = create(:project, enabled_module_names: Setting.default_projects_modules + %w[meetings])
    create(:member, principal: user, project:, roles: [role])
    project
  end
  shared_let(:export_time) { DateTime.new(2025, 6, 3, 13, 37) }
  shared_let(:export_time_formatted) { format_date(export_time) }
  shared_let(:recurring_meeting) do
    create :recurring_meeting,
           project:,
           author: user,
           start_time: DateTime.parse("2024-12-05T10:00:00Z"),
           frequency: "daily"
  end
  shared_let(:work_package) { create(:work_package, project:) }
  let(:options) do
    {
      participants: "0",
      outcomes: "0",
      backlog: "0"
    }
  end
  let(:exporter) { described_class.new(meeting, options) }
  let(:meeting) { create(:meeting, author: user, project:, title: "Awesome meeting!", location: "Moon Base") }

  subject(:pdf) do
    result = Timecop.freeze(export_time) do
      exporter.export!
    end
    # If you want to actually see the PDF for debugging, uncomment the following line
    # File.binwrite("Meetings-test-preview.pdf", result.content)
    # `open Meetings-test-preview.pdf`
    PDF::Inspector::Text.analyze(result.content).strings.join(" ")
  end

  def expected_cover_page
    [project.name,
     meeting.title,
     exporter.cover_page_dates,
     meeting.location,
     export_time_formatted]
  end

  def meeting_head
    [meeting.title, exporter.meeting_subtitle]
  end

  context "with an empty single meeting" do
    it "renders the expected document" do
      expected_document = [
        *expected_cover_page,
        *meeting_head,
        "1", # Page number
        export_time_formatted,
        project.name
      ].join(" ")

      expect(subject).to eq expected_document
    end
  end

  context "with an empty recurring meeting" do
    let!(:meeting) do
      create(:recurring_meeting_occurrence,
             :author_participates,
             recurring_meeting:,
             project:,
             title: "Awesome meeting!",
             location: "Moon Base")
    end

    it "renders the expected document" do
      expected_document = [
        *expected_cover_page,
        *meeting_head,
        "1", # Page number
        export_time_formatted,
        project.name
      ].join(" ")

      expect(subject).to eq expected_document
    end
  end

  context "with a meeting with agenda items" do
    let(:meeting) do
      create(:meeting, author: user, project:, title: "Awesome closed meeting!", location: "Mars Base", state: :closed)
    end
    let(:type_task) { create(:type_task) }
    let(:status) { create(:status, is_default: true, name: "Workin' on it") }
    let(:work_package) { create(:work_package, project:, status:, subject: "Important task", type: type_task) }
    let(:meeting_section) { create(:meeting_section, meeting:, title: nil) }
    let(:meeting_section_second) { create(:meeting_section, meeting:, title: "Second section") }
    let(:meeting_agenda_item) do
      create(:meeting_agenda_item, meeting_section:, duration_in_minutes: 15, title: "Agenda Item TOP 1", presenter: user,
                                   notes: "**foo**")
    end
    let(:wp_agenda_item) do
      create(:wp_meeting_agenda_item,
             meeting:,
             meeting_section: meeting_section_second,
             work_package:,
             duration_in_minutes: 10,
             notes: "*bar*")
    end
    let(:outcome1) { create(:meeting_outcome, meeting_agenda_item:, notes: "An outcome") }
    let(:outcome2) { create(:meeting_outcome, meeting_agenda_item:, notes: "A second outcome") }
    let(:outcome3) { create(:meeting_outcome, meeting_agenda_item: wp_agenda_item, notes: "A single outcome") }
    let(:attachment) { create(:attachment, container: meeting) }
    let(:meeting_backlog_item) do
      create(:meeting_agenda_item, meeting_section: meeting.backlog,
                                   duration_in_minutes: 1,
                                   title: "Agenda Item in Backlog", presenter: user, notes: "# yeah")
    end
    let(:invited) { create(:meeting_participant, user: other_user, meeting:, invited: true) }
    let(:attended) { create(:meeting_participant, user: user, meeting:, invited: true, attended: true) }

    before do
      User.current = user
      meeting_agenda_item # create the agenda item
      wp_agenda_item # create the wp agenda item
      outcome1 # create the outcome for first agenda item
      outcome2 # create the outcome for first agenda item
      outcome3 # create the outcome for wp agenda item
      attachment # create the attachment
      meeting_backlog_item # create the backlog item
      attended # create the attended participant
      invited # create the invited participant
      meeting.reload # ensure participants are accessible
    end

    context "with bells and whistles options" do
      let(:options) do
        {
          participants: "1",
          outcomes: "1",
          backlog: "1",
          attachments: "1",
          footer_text: "Custom Footer Text"
        }
      end
      let(:expected_document) do
        [
          *expected_cover_page,
          *meeting_head,
          "Participants (2)",
          "Export User", "  ", "Attended",
          "Other Account",

          "Untitled section", "  ", "15 mins",
          "Agenda Item TOP 1", "  ", "15 mins", "  ", "Export User",
          "foo",
          "✓   Outcome 1",
          "An outcome",
          "✓   Outcome 2",
          "A second outcome",

          "Second section", "  ", "10 mins",

          "Task", "##{work_package.id}", "Important task", " (Workin' on it)", "  ", "10 mins",
          "bar",
          "✓   Outcome",
          "A single outcome",

          "Attachments",
          attachment.filename,

          "Agenda backlog",
          "Agenda Item in Backlog", "  ", "1 min", "  ", "Export User",
          "yeah",

          "1", # Page number
          export_time_formatted,
          "Custom Footer Text"
        ].join(" ")
      end

      it "renders the expected document" do
        expect(subject).to eq expected_document
      end
    end

    context "with minimal options" do
      let(:options) do
        {
          participants: "0",
          outcomes: "0",
          backlog: "0",
          attachments: "0"
        }
      end

      it "renders the expected document" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Untitled section", "  ", "15 mins",
          "Agenda Item TOP 1", "  ", "15 mins", "  ", "Export User",
          "foo",

          "Second section", "  ", "10 mins",
          "Task", "##{work_package.id}", "Important task", " (Workin' on it)", "  ", "10 mins",
          "bar",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end

    context "with semantic work package identifiers",
            with_settings: { work_packages_identifier: "semantic" } do
      let(:options) do
        {
          participants: "0",
          outcomes: "0",
          backlog: "0",
          attachments: "0"
        }
      end
      let(:wp_agenda_item) do
        create(:wp_meeting_agenda_item,
               meeting:,
               meeting_section: meeting_section_second,
               work_package:,
               duration_in_minutes: 10,
               notes: "<mention class=\"mention\" data-id=\"#{work_package.id}\" data-type=\"work_package\" " \
                      "data-text=\"##{work_package.id}\">##{work_package.id}</mention>")
      end

      before do
        work_package.update_columns(identifier: "MEET-1", sequence_number: 1)
      end

      it "renders the semantic identifier for the agenda item and the mention in its notes" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Untitled section", "  ", "15 mins",
          "Agenda Item TOP 1", "  ", "15 mins", "  ", "Export User",
          "foo",

          "Second section", "  ", "10 mins",
          "Task", "MEET-1", "Important task", " (Workin' on it)", "  ", "10 mins",
          "MEET-1",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end
  end

  context "with a meeting with special work package agenda item" do
    let!(:secret_project) { create(:project, members: [other_user]) }
    let(:secret_work_package) { create(:work_package, project: secret_project) }
    let(:wp_agenda_item) do
      create(:wp_meeting_agenda_item, meeting:, work_package: secret_work_package, duration_in_minutes: 10,
                                      notes: "title of the work package should not be visible")
    end

    before do
      secret_work_package # create the work_package
      wp_agenda_item # create the wp agenda item
    end

    context "and with a non visible work package" do
      let(:options) do
        { participants: "0" }
      end

      it "renders the expected document" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Work package ##{secret_work_package.id} not visible", "  ", "10 mins",
          "title of the work package should not be visible",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end

    context "and with a deleted work package" do
      let(:options) do
        { participants: "0" }
      end

      before do
        secret_work_package.destroy
      end

      it "renders the expected document" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Deleted work package reference", "  ", "10 mins",
          "title of the work package should not be visible",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end
  end

  context "with a meeting with work package outcomes" do
    let(:meeting) do
      create(:meeting, author: user, project:, title: "Meeting with WP outcomes", location: "Somewhere", state: :closed)
    end
    let(:type_task) { create(:type_task) }
    let(:status) { create(:status, is_default: true, name: "In Progress") }
    let(:outcome_work_package) { create(:work_package, project:, status:, subject: "Outcome WP", type: type_task) }
    let(:meeting_section) { create(:meeting_section, meeting:, title: "Section with outcomes") }
    let(:meeting_agenda_item) do
      create(:meeting_agenda_item, meeting_section:, duration_in_minutes: 15, title: "Agenda Item", presenter: user,
                                   notes: "Agenda item notes")
    end

    before do
      User.current = user
      meeting_agenda_item
    end

    context "with a visible work package outcome" do
      let(:wp_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, kind: :work_package, work_package: outcome_work_package, notes: nil)
      end
      let(:options) do
        { participants: "0", outcomes: "1" }
      end

      before do
        wp_outcome
      end

      it "renders the work package outcome with type, id, subject and status" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Section with outcomes", "  ", "15 mins",
          "Agenda Item", "  ", "15 mins", "  ", "Export User",
          "Agenda item notes",
          "✓   Outcome",
          "Task", "##{outcome_work_package.id}", "Outcome WP", " (In Progress)",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end

      context "with semantic work package identifiers",
              with_settings: { work_packages_identifier: "semantic" } do
        before do
          outcome_work_package.update_columns(identifier: "MEET-1", sequence_number: 1)
        end

        it "renders the work package outcome with the semantic identifier" do
          expected_document = [
            *expected_cover_page,
            *meeting_head,

            "Section with outcomes", "  ", "15 mins",
            "Agenda Item", "  ", "15 mins", "  ", "Export User",
            "Agenda item notes",
            "✓   Outcome",
            "Task", "MEET-1", "Outcome WP", " (In Progress)",

            "1", # Page number
            export_time_formatted,
            project.name
          ].join(" ")

          expect(subject).to eq expected_document
        end
      end
    end

    context "with a hidden work package outcome" do
      let!(:secret_project) { create(:project, members: [other_user]) }
      let(:secret_work_package) { create(:work_package, project: secret_project) }
      let(:wp_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, kind: :work_package, work_package: secret_work_package, notes: nil)
      end
      let(:options) do
        { participants: "0", outcomes: "1" }
      end

      before do
        secret_work_package
        wp_outcome
      end

      it "renders the undisclosed work package message" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Section with outcomes", "  ", "15 mins",
          "Agenda Item", "  ", "15 mins", "  ", "Export User",
          "Agenda item notes",
          "✓   Outcome",
          "Work package ##{secret_work_package.id} not visible",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end

    context "with a deleted work package outcome" do
      let!(:deleted_wp) { create(:work_package, project:) }
      let(:wp_outcome) do
        create(:meeting_outcome, meeting_agenda_item:, kind: :work_package, work_package: deleted_wp, notes: nil)
      end
      let(:options) do
        { participants: "0", outcomes: "1" }
      end

      before do
        wp_outcome
        deleted_wp.destroy!
      end

      it "renders the deleted work package message" do
        expected_document = [
          *expected_cover_page,
          *meeting_head,

          "Section with outcomes", "  ", "15 mins",
          "Agenda Item", "  ", "15 mins", "  ", "Export User",
          "Agenda item notes",
          "✓   Outcome",
          "Deleted work package reference",

          "1", # Page number
          export_time_formatted,
          project.name
        ].join(" ")

        expect(subject).to eq expected_document
      end
    end
  end
end
