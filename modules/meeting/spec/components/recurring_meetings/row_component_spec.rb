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

require "rails_helper"

RSpec.describe RecurringMeetings::RowComponent, type: :component do
  include Rails.application.routes.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:table) do
    instance_double(RecurringMeetings::TableComponent,
                    columns: [], grid_class: "test", has_actions?: true, current_project:)
  end
  let(:recurring_meeting) { build_stubbed(:recurring_meeting, project:) }
  let(:current_project) { nil }
  let(:user) { build_stubbed(:user) }

  subject do
    render_inline(described_class.new(row: row_model, table:))
    page
  end

  before do
    login_as(user)
  end

  describe "download ics file" do
    let(:meeting) do
      build_stubbed(:meeting,
                    id: 1234,
                    project:,
                    recurring_meeting:,
                    recurrence_start_time: 1.week.from_now,
                    start_time: 1.week.from_now)
    end
    let(:row_model) { meeting }

    it "links to the correct meeting (Regression #61462)" do
      expect(subject).to have_link "Download iCalendar event",
                                   href: download_ics_project_recurring_meeting_path(
                                     project,
                                     recurring_meeting,
                                     occurrence_id: meeting.id
                                   )
    end
  end

  describe "cancel occurrence" do
    context "with project delete meetings permissions" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:delete_meetings, project:)
        end
      end

      context "with a planned (not-yet-instantiated) occurrence" do
        let(:occurrence_time) { 1.day.from_now }
        let(:row_model) do
          RecurringMeetings::PlannedOccurrence.new(recurrence_start_time: occurrence_time, recurring_meeting:)
        end

        context "without a current project" do
          it "shows cancel menu item" do
            expect(subject).to have_link "Cancel this occurrence",
                                         href: delete_scheduled_dialog_project_recurring_meeting_path(
                                           project,
                                           recurring_meeting,
                                           start_time: occurrence_time.iso8601
                                         )
          end
        end

        context "with a current project" do
          let(:current_project) { project }

          it "shows cancel menu item" do
            expect(subject).to have_link "Cancel this occurrence",
                                         href: delete_scheduled_dialog_project_recurring_meeting_path(
                                           project, recurring_meeting, start_time: occurrence_time.iso8601
                                         )
          end
        end
      end

      context "with an instantiated meeting" do
        let(:meeting) do
          build_stubbed(:meeting,
                        project:,
                        recurring_meeting:,
                        recurrence_start_time: 1.day.from_now,
                        start_time: 1.day.from_now)
        end
        let(:row_model) { meeting }

        context "without a current project" do
          it "shows cancel menu item" do
            expect(subject).to have_link "Cancel this occurrence",
                                         href: delete_dialog_project_meeting_path(project, meeting)
          end
        end

        context "with a current project" do
          let(:current_project) { project }

          it "shows cancel menu item" do
            expect(subject).to have_link "Cancel this occurrence",
                                         href: delete_dialog_project_meeting_path(project, meeting)
          end
        end
      end

      context "with an ongoing instantiated meeting" do
        let(:meeting) do
          build_stubbed(:meeting,
                        project:,
                        recurring_meeting:,
                        recurrence_start_time: 30.minutes.ago,
                        start_time: 30.minutes.ago,
                        duration: 2)
        end
        let(:row_model) { meeting }

        it "shows cancel menu item" do
          expect(subject).to have_link "Cancel this occurrence",
                                       href: delete_dialog_project_meeting_path(project, meeting)
        end
      end

      context "with a past instantiated meeting" do
        let(:meeting) do
          build_stubbed(:meeting,
                        project:,
                        recurring_meeting:,
                        recurrence_start_time: 2.days.ago,
                        start_time: 2.days.ago,
                        duration: 1)
        end
        let(:row_model) { meeting }

        it "shows delete menu item" do
          expect(subject).to have_link "Delete occurrence",
                                       href: delete_dialog_project_meeting_path(project, meeting)
        end
      end
    end
  end
end
