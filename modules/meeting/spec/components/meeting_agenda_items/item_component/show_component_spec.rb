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

RSpec.describe MeetingAgendaItems::ItemComponent::ShowComponent, type: :component do
  include Rails.application.routes.url_helpers

  shared_let(:project) { create(:project, enabled_module_names: %w[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_meetings manage_agendas] })
  end

  current_user { user }

  describe "#move_to_next_meeting_action_item" do
    let(:series) do
      create(:recurring_meeting,
             project:,
             start_time: meeting_start_time,
             frequency: "weekly",
             end_after: "never",
             author: user)
    end
    let(:meeting) do
      create(:recurring_meeting_occurrence,
             project:,
             recurring_meeting: series,
             start_time: meeting_start_time,
             author: user)
    end
    let(:meeting_section) { create(:meeting_section, meeting:) }
    let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section:, title: "Test item") }

    subject(:rendered_component) do
      render_inline(described_class.new(meeting_agenda_item:))
    end

    context "when the meeting is in the past" do
      let(:meeting_start_time) { 1.week.ago }

      it "calculates next occurrence from current time" do
        travel_to Time.zone.local(2025, 6, 10, 12, 0, 0) do
          next_occurrence = series.next_occurrence(from_time: Time.current)

          expect(rendered_component).to have_css(
            "[data-href*='datetime=#{CGI.escape(next_occurrence.iso8601)}']"
          )
        end
      end
    end

    context "when the meeting is in the future" do
      let(:meeting_start_time) { 1.week.from_now }

      it "calculates next occurrence from meeting start time" do
        next_occurrence = series.next_occurrence(from_time: meeting.start_time)

        expect(rendered_component).to have_css(
          "[data-href*='datetime=#{CGI.escape(next_occurrence.iso8601)}']"
        )
      end
    end
  end

  describe "duplicate action visibility (Bugs #70242, #70287)" do
    let(:series) do
      create(:recurring_meeting,
             project:,
             start_time: 1.week.from_now,
             frequency: "weekly",
             end_after: "specific_date",
             end_date: 2.weeks.from_now.to_date,
             author: user)
    end
    let(:meeting_section) { create(:meeting_section, meeting:) }
    let(:meeting_agenda_item) { create(:meeting_agenda_item, meeting:, meeting_section:, title: "Test item") }

    subject(:rendered_component) do
      render_inline(described_class.new(meeting_agenda_item:))
    end

    context "when viewing a template" do
      let(:meeting) { series.template }

      it "does not show the duplicate submenu" do
        expect(rendered_component).to have_no_text(I18n.t("label_agenda_item_duplicate"))
      end
    end

    context "when viewing the last occurrence of a series" do
      let(:meeting) do
        create(:recurring_meeting_occurrence,
               project:,
               recurring_meeting: series,
               start_time: 2.weeks.from_now,
               author: user)
      end

      it "does not show the duplicate submenu" do
        expect(series.next_occurrence(from_time: meeting.start_time)).to be_nil
        expect(rendered_component).to have_no_text(I18n.t("label_agenda_item_duplicate"))
      end
    end

    context "when viewing an occurrence with future occurrences" do
      let(:meeting) do
        create(:recurring_meeting_occurrence,
               project:,
               recurring_meeting: series,
               start_time: 1.week.from_now,
               author: user)
      end

      it "shows the duplicate submenu" do
        expect(series.next_occurrence(from_time: meeting.start_time)).to be_present
        expect(rendered_component).to have_text(I18n.t("label_agenda_item_duplicate"))
      end
    end
  end
end
