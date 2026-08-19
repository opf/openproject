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

RSpec.describe RecurringMeetings::UpdateService, "integration", type: :model do
  shared_let(:project) { create(:project, enabled_module_names: %i[meetings]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i(view_meetings edit_meetings) })
  end
  shared_let(:series, refind: true) do
    create(:recurring_meeting,
           project:,
           start_time: Time.zone.tomorrow + 10.hours,
           frequency: "daily",
           interval: 1,
           end_after: "specific_date",
           end_date: 1.month.from_now)
  end

  let(:instance) { described_class.new(model: series, user:) }
  let(:params) { {} }

  let(:service_result) { instance.call(**params) }
  let(:updated_meeting) { service_result.result }

  context "with a cancelled meeting for tomorrow" do
    let!(:cancelled_occurrence) do
      create(:meeting,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 1.day + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 1.day + 10.hours,
             state: :cancelled)
    end

    context "when updating the start_date to the time of the first cancellation" do
      let(:params) do
        { start_date: Time.zone.tomorrow + 1.day }
      end

      it "removes the cancelled occurrence" do
        expect(service_result).to be_success
        expect(updated_meeting.start_time).to eq(Time.zone.tomorrow + 1.day + 10.hours)

        expect { cancelled_occurrence.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when updating only the start time hour" do
      let(:params) do
        { start_time_hour: "09:00" }
      end

      it "updates the cancelled occurrence" do
        expect(service_result).to be_success

        cancelled_occurrence.reload
        expect(cancelled_occurrence.recurrence_start_time).to eq(Time.zone.tomorrow + 1.day + 9.hours)
        expect(cancelled_occurrence.start_time).to eq(Time.zone.tomorrow + 1.day + 9.hours)
      end
    end

    context "when updating the start_date to further in the future" do
      let(:params) do
        { start_date: Time.zone.today + 2.days }
      end

      it "deletes that cancelled occurrence" do
        expect(service_result).to be_success
        expect(updated_meeting.start_time).to eq(Time.zone.today + 2.days + 10.hours)

        expect { cancelled_occurrence.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  context "when ending a series with a stale cancelled occurrence" do
    let(:series) do
      create(:recurring_meeting,
             project:,
             start_time: 1.month.ago + 10.hours,
             frequency: "daily",
             interval: 1,
             end_after: "specific_date",
             end_date: 1.month.from_now)
    end
    let(:instance) do
      described_class.new(model: series, user:, contract_class: RecurringMeetings::EndSeriesContract)
    end
    let(:params) do
      {
        end_after: "specific_date",
        end_date: Time.zone.yesterday
      }
    end
    let!(:cancelled_occurrence) do
      create(:recurring_meeting_occurrence,
             recurring_meeting: series,
             start_time: Time.zone.tomorrow + 10.hours,
             recurrence_start_time: Time.zone.tomorrow + 10.hours,
             state: :cancelled)
    end
    let!(:section) { create(:meeting_section, meeting: cancelled_occurrence) }
    let!(:agenda_item) do
      create(:meeting_agenda_item, meeting: cancelled_occurrence, meeting_section: section)
    end

    it "destroys the cancelled occurrence with its structured meeting content" do
      expect(service_result).to be_success

      expect { cancelled_occurrence.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { section.reload }.to raise_error(ActiveRecord::RecordNotFound)
      expect { agenda_item.reload }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "rescheduling job" do
    context "when updating the title" do
      let(:params) do
        { title: "New title" }
      end

      it "does not reschedule" do
        expect { service_result }.not_to have_enqueued_job(RecurringMeetings::InitNextOccurrenceJob)
        expect(service_result).to be_success
      end
    end

    context "when updating the frequency and start_time",
            with_good_job: RecurringMeetings::InitNextOccurrenceJob do
      let(:params) do
        { start_time: Time.zone.today + 2.days + 11.hours }
      end

      before do
        RecurringMeetings::InitNextOccurrenceJob
          .set(wait_until: Time.zone.today + 1.day + 10.hours)
          .perform_later(series)
      end

      it "reschedules and enqueues the next job" do
        job = GoodJob::Job.find_by(job_class: "RecurringMeetings::InitNextOccurrenceJob")
        expect(job.scheduled_at).to eq Time.zone.today + 1.day + 10.hours
        expect(service_result).to be_success
        expect { job.reload }.to raise_error(ActiveRecord::RecordNotFound)

        new_job = GoodJob::Job.find_by(job_class: "RecurringMeetings::InitNextOccurrenceJob")
        expect(new_job.scheduled_at).to eq Time.zone.today + 2.days + 11.hours

        expect(series.upcoming_instantiated_meetings.count).to eq 1
      end
    end

    context "when the template is in draft mode",
            with_good_job: RecurringMeetings::InitNextOccurrenceJob do
      let(:params) do
        { start_time: Time.zone.today + 2.days + 11.hours }
      end

      before do
        series.template.update_column(:state, :draft)
      end

      it "reschedules, but does not init an occurrence (Bug #69175)" do
        expect(service_result).to be_success

        expect(series.upcoming_instantiated_meetings).to be_empty

        series.reload
        expect(series.start_time).to eq Time.zone.today + 2.days + 11.hours
      end
    end
  end

  describe "rescheduling mails" do
    context "when updating the title" do
      let(:params) do
        { title: "New title" }
      end

      it "does not create them" do
        expect(service_result).to be_success
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries).to be_empty
      end
    end

    context "when updating the frequency and start_time" do
      let(:params) do
        { start_time: Time.zone.today + 2.days + 11.hours }
      end

      let(:recipient) do
        create(:user, member_with_permissions: { project => %i(view_meetings) })
      end

      before do
        series.template.participants.delete_all
        series.template.participants << MeetingParticipant.new(user: recipient, invited: true)
      end

      it "sends out updated mails" do
        expect(service_result).to be_success
        perform_enqueued_jobs
        expect(ActionMailer::Base.deliveries.count).to eq(1)
        expect(ActionMailer::Base.deliveries.first.subject)
          .to eq "[#{project.name}] Meeting series '#{series.title}' has been updated"
      end
    end

    context "when updating only the location with recipients with different locales" do
      let(:german_author) do
        create(:user,
               language: "de",
               member_with_permissions: { project => %i(view_meetings edit_meetings) })
      end

      let(:english_recipient) do
        create(:user,
               language: "en",
               member_with_permissions: { project => %i(view_meetings) })
      end

      let(:german_recipient) do
        create(:user,
               language: "de",
               member_with_permissions: { project => %i(view_meetings) })
      end

      let(:instance) { described_class.new(model: series, user: german_author) }

      let(:params) { { location: "New location" } }

      before do
        series.update!(author: german_author)
        series.template.participants.delete_all
        series.template.participants << MeetingParticipant.new(user: english_recipient, invited: true)
        series.template.participants << MeetingParticipant.new(user: german_recipient, invited: true)
        series.template.update!(location: "Old location")
      end

      it "does not send a schedule update when not necessary (Bug #67287)" do
        expect(service_result).to be_success
        perform_enqueued_jobs

        expect(ActionMailer::Base.deliveries.count).to eq(2)

        english_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?(english_recipient.mail) }
        german_mail = ActionMailer::Base.deliveries.find { |m| m.to.include?(german_recipient.mail) }

        expect(english_mail.html_part.body).to include("Every day")
        expect(english_mail.html_part.body).not_to include("Jeden Tag")

        expect(german_mail.html_part.body).to include("Jeden Tag")
        expect(german_mail.html_part.body).not_to include("Every day")
      end
    end
  end

  describe "rescheduling occurrences" do
    let!(:scheduled_meetings) do
      Array.new(3) do |i|
        t = Time.zone.today + (i + 1).days + 10.hours
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
      end
    end

    context "when only changing the time of day" do
      let(:params) do
        { start_time_hour: "14:30" }
      end

      it "updates the time while keeping the same dates" do
        expect(service_result).to be_success

        # Verify each occurrence keeps its date but changes time
        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expect(meeting.recurrence_start_time).to eq(Time.zone.today + (index + 1).days + 14.hours + 30.minutes)
          expect(meeting.start_time).to eq(Time.zone.today + (index + 1).days + 14.hours + 30.minutes)
        end
      end
    end

    context "when changing the frequency from daily to weekly" do
      let(:params) do
        { frequency: "weekly" }
      end

      it "reschedules all future occurrences to weekly intervals" do
        expect(service_result).to be_success

        # Verify each occurrence is moved to weekly intervals
        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expect(meeting.recurrence_start_time).to eq(Time.zone.tomorrow + (index * 7).days + 10.hours)
          expect(meeting.start_time).to eq(Time.zone.tomorrow + (index * 7).days + 10.hours)
        end
      end

      context "when one of the occurrences is cancelled" do
        let!(:cancelled_meeting) do
          t = Time.zone.today + 5.days + 10.hours
          create(:meeting,
                 recurring_meeting: series,
                 start_time: t,
                 recurrence_start_time: t,
                 state: :cancelled)
        end

        it "removes cancelled occurrences" do
          expect(service_result).to be_success
          expect { cancelled_meeting.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe "updating end conditions" do
    let!(:scheduled_meetings) do
      Array.new(3) do |i|
        t = Time.zone.tomorrow + i.days + 10.hours
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
      end
    end

    context "when changing end_after to iterations with fewer iterations than scheduled meetings" do
      let(:params) do
        {
          end_after: "iterations",
          iterations: 1
        }
      end

      it "fails validation" do
        expect(service_result).not_to be_success
        expect(service_result.errors.messages[:base]).to include(
          I18n.t("activerecord.errors.models.recurring_meeting.must_cover_existing_meetings", count: 2)
        )
      end
    end

    context "when changing interval to 2, so that previous occurrences overlap" do
      let(:params) do
        {
          interval: 2
        }
      end

      it "succeeds" do
        expect(service_result).to be_success

        # Verify each occurrence is moved to 2-day intervals
        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expect(meeting.recurrence_start_time).to eq(Time.zone.tomorrow + (index * 2).days + 10.hours)
          expect(meeting.start_time).to eq(Time.zone.tomorrow + (index * 2).days + 10.hours)
        end
      end
    end

    context "when changing end_date to before the last scheduled meeting" do
      let(:params) do
        {
          end_after: "specific_date",
          end_date: Time.zone.today + 2.days
        }
      end

      it "fails validation" do
        expect(service_result).not_to be_success
        expect(service_result.errors.messages[:base]).to include(
          I18n.t("activerecord.errors.models.recurring_meeting.must_cover_existing_meetings", count: 1)
        )
      end
    end

    context "when changing end_after to iterations without providing iterations count" do
      let(:params) do
        {
          end_after: "iterations",
          iterations: nil
        }
      end

      it "fails validation without raising an exception" do
        expect(service_result).not_to be_success
        expect(service_result.errors.messages[:iterations]).to include("is not a number.")
      end
    end
  end

  describe "updating series title" do
    shared_let(:past_occurrence) do
      t = Time.zone.yesterday + 10.hours
      create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
    end
    shared_let(:future_occurrences) do
      Array.new(3) do |i|
        t = Time.zone.today + (i + 1).days + 10.hours
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
      end
    end

    let(:params) { { title: "Updated series title" } }

    it "updates open future meeting occurrence titles" do
      expect(service_result).to be_success

      future_occurrences.each do |occ|
        expect(occ.reload.title).to eq("Updated series title")
      end
    end

    it "does not update past meeting occurrence titles" do
      expect(service_result).to be_success

      expect(past_occurrence.reload.title).not_to eq("Updated series title")
    end
  end

  describe "rescheduling slot conflicts" do
    # Helper: base time for meeting slots relative to tomorrow
    let(:base_time) { Time.zone.tomorrow + 10.hours }

    context "when expanding interval from 1 to 2 (core overlap case)" do
      # 3 daily meetings at day+0, day+1, day+2
      # After interval=2: day+0, day+2, day+4
      # Meeting at day+2 would collide with meeting #3's old slot without reverse ordering
      let!(:scheduled_meetings) do
        Array.new(3) do |i|
          t = base_time + i.days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:params) { { interval: 2 } }

      it "does not violate unique constraint and reschedules correctly" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + (index * 2).days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when expanding interval from 1 to 3 (multiple overlaps)" do
      # 4 daily meetings at day+0, day+1, day+2, day+3
      # After interval=3: day+0, day+3, day+6, day+9
      # Meeting #2 (day+3) collides with meeting #4's old slot (day+3)
      let!(:scheduled_meetings) do
        Array.new(4) do |i|
          t = base_time + i.days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:params) { { interval: 3 } }

      it "does not violate unique constraint and reschedules correctly" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + (index * 3).days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when contracting interval from 2 to 1" do
      # 3 meetings at day+0, day+2, day+4 (series starts as interval=2)
      # After interval=1: day+0, day+1, day+2
      # last_new < last_old so forward order is used
      before do
        series.update_columns(interval: 2)
      end

      let!(:scheduled_meetings) do
        Array.new(3) do |i|
          t = base_time + (i * 2).days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:params) { { interval: 1 } }

      it "does not violate unique constraint and reschedules correctly" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + index.days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when changing frequency from daily to weekly (large expansion)" do
      # 3 daily meetings at day+0, day+1, day+2
      # After weekly: day+0, day+7, day+14
      let!(:scheduled_meetings) do
        Array.new(3) do |i|
          t = base_time + i.days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:params) { { frequency: "weekly" } }

      it "reschedules to weekly intervals using reverse order" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + (index * 7).days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when changing frequency from weekly to daily (contraction)" do
      # 3 weekly meetings at day+0, day+7, day+14
      before do
        series.update_columns(frequency: "weekly")
      end

      let!(:scheduled_meetings) do
        Array.new(3) do |i|
          t = base_time + (i * 7).days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:params) { { frequency: "daily" } }

      it "reschedules to daily intervals using forward order" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + index.days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when shifting start_date forward by 3 days" do
      # 3 daily meetings at day+0, day+1, day+2
      # After start_date shift +3: day+3, day+4, day+5
      # last_new > last_old so reverse order is used
      let!(:scheduled_meetings) do
        Array.new(3) do |i|
          t = base_time + i.days
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)
        end
      end

      let(:new_start_date) { Time.zone.tomorrow + 3.days }
      let(:params) { { start_date: new_start_date.to_date.iso8601 } }

      it "shifts all meetings forward correctly" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = new_start_date + 10.hours + index.days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when only a single meeting exists" do
      let!(:scheduled_meetings) do
        t = base_time
        [create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t)]
      end

      let(:params) { { interval: 3 } }

      it "updates the single meeting correctly" do
        expect(service_result).to be_success

        scheduled_meetings.first.reload
        expect(scheduled_meetings.first.recurrence_start_time).to eq(base_time)
        expect(scheduled_meetings.first.start_time).to eq(base_time)
      end
    end

    context "when last_new equals last_old in pair ordering" do
      # Existing slots are sparse and out of pattern.
      # Updating interval to 2 yields new slots at day+0, day+2, day+4,
      # so the tail remains unchanged while interior meetings move.
      let!(:scheduled_meetings) do
        [
          create(:recurring_meeting_occurrence,
                 recurring_meeting: series,
                 start_time: base_time,
                 recurrence_start_time: base_time),
          create(:meeting,
                 recurring_meeting: series,
                 start_time: base_time + 1.day + 2.hours,
                 recurrence_start_time: base_time + 1.day),
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: base_time + 4.days, recurrence_start_time: base_time + 4.days)
        ]
      end

      let(:params) { { interval: 2 } }

      it "updates all meetings without unique-index violations and resets moved start times" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + (index * 2).days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when future instantiated meetings have holes" do
      let!(:scheduled_meetings) do
        [
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: base_time, recurrence_start_time: base_time),
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: base_time + 2.days, recurrence_start_time: base_time + 2.days),
          create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: base_time + 4.days, recurrence_start_time: base_time + 4.days)
        ]
      end

      let(:params) { { frequency: "weekly" } }

      it "zips existing meetings to the next generated slots in recurrence_start_time order" do
        expect(service_result).to be_success

        scheduled_meetings.each_with_index do |meeting, index|
          meeting.reload
          expected_time = base_time + (index * 7).days
          expect(meeting.recurrence_start_time).to eq(expected_time)
          expect(meeting.start_time).to eq(expected_time)
        end
      end
    end

    context "when cancelled occurrences exist in the past and future" do
      let!(:past_cancelled) do
        t = Time.zone.yesterday + 10.hours
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t, state: :cancelled)
      end

      let!(:future_cancelled) do
        t = base_time + 2.days
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: t, recurrence_start_time: t, state: :cancelled)
      end

      let!(:active_future) do
        create(:recurring_meeting_occurrence, recurring_meeting: series, start_time: base_time, recurrence_start_time: base_time)
      end

      let(:params) { { interval: 2 } }

      it "removes cancelled stubs before rescheduling active meetings" do
        expect(service_result).to be_success

        expect { past_cancelled.reload }.to raise_error(ActiveRecord::RecordNotFound)
        expect { future_cancelled.reload }.to raise_error(ActiveRecord::RecordNotFound)

        active_future.reload
        expect(active_future.recurrence_start_time).to eq(base_time)
        expect(active_future.start_time).to eq(base_time)
      end
    end

    context "when rescheduling across a DST boundary" do
      let(:series_time_zone) { "America/New_York" }
      let(:new_york_zone) { ActiveSupport::TimeZone[series_time_zone] }
      let(:dst_series_start) { new_york_zone.parse("2026-03-07 10:00:00").utc }
      let(:travel_time) { Time.zone.parse("2026-03-01 09:00:00 UTC") }

      let(:series) do
        create(:recurring_meeting,
               project:,
               author: user,
               start_time: dst_series_start,
               frequency: "daily",
               interval: 1,
               end_after: "specific_date",
               end_date: Date.new(2026, 3, 20),
               time_zone: series_time_zone)
      end

      let!(:scheduled_meetings) do
        travel_to(travel_time) do
          series.scheduled_occurrences(limit: 4).map do |occurrence|
            create(:meeting,
                   recurring_meeting: series,
                   start_time: occurrence,
                   recurrence_start_time: occurrence)
          end
        end
      end

      let(:params) { { interval: 2 } }

      it "keeps canonical recurrence ids unique and aligned to local 10:00 occurrences" do
        travel_to(travel_time) do
          expect(service_result).to be_success

          expected_slots = updated_meeting.scheduled_occurrences(limit: scheduled_meetings.count)
          expect(expected_slots.length).to eq(scheduled_meetings.length)

          scheduled_meetings.each_with_index do |meeting, index|
            meeting.reload

            expect(meeting.recurrence_start_time).to eq(expected_slots[index])
            expect(meeting.start_time).to eq(expected_slots[index])
            expect(meeting.recurrence_start_time.in_time_zone(new_york_zone).hour).to eq(10)
          end

          canonical_slots = scheduled_meetings.map { |meeting| meeting.reload.recurrence_start_time }
          expect(canonical_slots.uniq.length).to eq(canonical_slots.length)
        end
      end
    end
  end
end
