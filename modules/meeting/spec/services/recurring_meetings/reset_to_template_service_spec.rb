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

RSpec.describe RecurringMeetings::ResetToTemplateService, type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings edit_meetings create_meetings) })
  end
  shared_let(:series, refind: true) do
    create(:recurring_meeting,
           project:,
           author: user,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  let(:occurrence_time) { series.start_time + 2.days }

  # The recurring_meeting factory already creates a template with one non-backlog section
  # and one agenda item ("My template item") via the add_to_latest_meeting_section callback.
  let(:template_section_count) { series.template.sections.count }
  let(:template_agenda_item_count) { series.template.sections.flat_map(&:agenda_items).count }

  # A cancelled occurrence that has stale/empty content
  let!(:cancelled_occurrence) do
    create(:meeting,
           project:,
           author: user,
           recurring_meeting: series,
           start_time: occurrence_time,
           recurrence_start_time: occurrence_time,
           state: :cancelled)
  end

  let(:extra_params) { {} }
  let(:instance) { described_class.new(user:, meeting: cancelled_occurrence, params: extra_params) }
  let(:service_result) { instance.call }

  it "returns a successful service result" do
    expect(service_result).to be_success
    expect(service_result.result).to eq(cancelled_occurrence)
  end

  it "does not change state when no params are given" do
    service_result
    expect(cancelled_occurrence.reload).to be_cancelled
  end

  context "when params: { state: :open } is passed" do
    let(:extra_params) { { state: :open } }

    it "sets the meeting state to open" do
      service_result
      expect(cancelled_occurrence.reload).to be_open
    end
  end

  it "copies the template title, location, and duration" do
    service_result
    restored = cancelled_occurrence.reload
    expect(restored.title).to eq(series.template.title)
    expect(restored.location).to eq(series.template.location)
    expect(restored.duration).to eq(series.template.duration)
  end

  it "copies sections and agenda items from the template" do
    service_result
    sections = cancelled_occurrence.reload.sections
    expect(sections.count).to eq(template_section_count)
    expect(sections.flat_map(&:agenda_items).count).to eq(template_agenda_item_count)
  end

  it "copies participants from the template" do
    # The recurring_meeting factory creates the author as a participant via :author_participates
    template_participant_count = series.template.allowed_participants.count
    service_result
    expect(cancelled_occurrence.reload.participants.count).to eq(template_participant_count)
  end

  context "when the occurrence had stale sections and participants" do
    let(:another_user) do
      create(:user, member_with_permissions: { project => %i(view_meetings) })
    end

    before do
      # Add extra sections and participants to the occurrence that should be cleared
      stale_section = MeetingSection.create!(meeting: cancelled_occurrence, title: "Old section", position: 1)
      MeetingAgendaItem.create!(meeting: cancelled_occurrence, meeting_section: stale_section,
                                title: "Old item", duration_in_minutes: 5, position: 1, author: user)
      cancelled_occurrence.participants.create!(user: another_user, invited: true)
    end

    it "replaces stale sections with template sections" do
      service_result
      sections = cancelled_occurrence.reload.sections
      expect(sections.count).to eq(template_section_count)
      expect(sections.map(&:title)).not_to include("Old section")
    end

    it "replaces stale participants with template participants" do
      template_participant_count = series.template.allowed_participants.count
      service_result
      expect(cancelled_occurrence.reload.participants.count).to eq(template_participant_count)
    end
  end

  context "when the template has a work package agenda item whose work package was deleted" do
    before do
      template_section = series.template.sections.first
      wp_item = MeetingAgendaItem.create!(
        meeting: series.template,
        meeting_section: template_section,
        item_type: :work_package,
        work_package: create(:work_package, project:),
        author: user,
        position: 2
      )

      # Simulate the work package being destroyed (dependent: :nullify)
      wp_item.update_columns(work_package_id: nil)
    end

    it "returns a successful service result" do
      expect(service_result).to be_success
    end

    it "copies the deleted WP agenda item preserving its type and nil work_package_id" do
      service_result
      deleted_item = cancelled_occurrence.reload.agenda_items.last
      expect(deleted_item).to be_present
      expect(deleted_item).to be_work_package
      expect(deleted_item.work_package_id).to be_nil
    end
  end
end
