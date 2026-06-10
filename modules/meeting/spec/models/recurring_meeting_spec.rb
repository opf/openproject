# frozen_string_literal: true

require "spec_helper"
require_module_spec_helper

RSpec.describe RecurringMeeting,
               with_settings: {
                 date_format: "%Y-%m-%d"
               } do
  describe "end_date" do
    subject { build(:recurring_meeting, start_date: (Date.current + 2.days).iso8601, end_date:) }

    context "with end_date before start_date" do
      let(:end_date) { Date.current + 1.day }

      it "is invalid" do
        expect(subject).not_to be_valid
        expect(subject.errors[:end_date]).to include("must be after #{subject.start_date}.")
      end
    end
  end

  describe "intervals" do
    subject { build(:recurring_meeting) }

    it "validates integer values >= 1" do
      subject.interval = 1
      expect(subject).to be_valid
      expect(subject.errors[:interval]).to be_empty
    end

    it "validates max value" do
      subject.interval = 101
      expect(subject).not_to be_valid
      expect(subject.errors[:interval]).to include("must be less than or equal to 100.")

      subject.interval = 100
      expect(subject).to be_valid
    end

    it "adds errors for invalid values", :aggregate_failures do
      subject.interval = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:interval]).to include("must be greater than or equal to 1.")

      subject.interval = -1
      expect(subject).not_to be_valid
      expect(subject.errors[:interval]).to include("must be greater than or equal to 1.")

      subject.interval = 0.1
      expect(subject).not_to be_valid
      expect(subject.errors[:interval]).to include("is not an integer.")

      subject.interval = "asdf"
      expect(subject).not_to be_valid
      expect(subject.errors[:interval]).to include("is not a number.")
    end
  end

  describe "iterations" do
    subject { build(:recurring_meeting, end_after: "iterations") }

    it "does not validate if end_after is not iterations" do
      subject.end_after = "specific_date"
      subject.iterations = nil
      expect(subject).to be_valid
    end

    it "validates integer values >= 1" do
      subject.iterations = 1
      expect(subject).to be_valid
      expect(subject.errors[:iterations]).to be_empty
    end

    it "validates max value" do
      subject.iterations = 1001
      expect(subject).not_to be_valid
      expect(subject.errors[:iterations]).to include("must be less than or equal to 1000.")

      subject.iterations = 1000
      expect(subject).to be_valid
    end

    it "adds errors for invalid values", :aggregate_failures do
      subject.iterations = 0
      expect(subject).not_to be_valid
      expect(subject.errors[:iterations]).to include("must be greater than or equal to 1.")

      subject.iterations = -1
      expect(subject).not_to be_valid
      expect(subject.errors[:iterations]).to include("must be greater than or equal to 1.")

      subject.iterations = 0.1
      expect(subject).not_to be_valid
      expect(subject.errors[:iterations]).to include("is not an integer.")

      subject.iterations = "asdf"
      expect(subject).not_to be_valid
      expect(subject.errors[:iterations]).to include("is not a number.")
    end
  end

  describe "daily schedule" do
    subject do
      build(:recurring_meeting,
            start_time: Time.zone.tomorrow + 10.hours,
            frequency: "daily",
            end_after: "specific_date",
            end_date: Time.zone.tomorrow + 1.week)
    end

    it "schedules daily", :aggregate_failures do
      expect(subject.first_occurrence).to eq Time.zone.tomorrow + 10.hours
      expect(subject.last_occurrence).to eq Time.zone.tomorrow + 7.days + 10.hours

      occurrence_in_two_days = Time.zone.today + 2.days + 10.hours
      Timecop.freeze(Time.zone.tomorrow + 11.hours) do
        expect(subject.next_occurrence).to eq occurrence_in_two_days
      end

      next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
      expect(next_occurrences).to eq [
        Time.zone.tomorrow + 10.hours,
        Time.zone.today + 2.days + 10.hours,
        Time.zone.today + 3.days + 10.hours,
        Time.zone.today + 4.days + 10.hours,
        Time.zone.today + 5.days + 10.hours
      ]

      Timecop.freeze(Time.zone.tomorrow + 2.weeks) do
        expect(subject.next_occurrence).to be_nil
      end
    end
  end

  describe "working_days schedule" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-02T10:00Z"),
            frequency: "working_days",
            end_after: "specific_date",
            end_date: DateTime.parse("2024-12-29T10:00Z"))
    end

    context "with working days set to four-week", with_settings: { working_days: [1, 2, 3, 4] } do
      it "schedules working days", :aggregate_failures do
        # Monday, 9AM
        Timecop.freeze(DateTime.parse("2024-12-02T09:00Z")) do
          expect(subject.first_occurrence).to eq Time.zone.today + 10.hours
          # Last thursday of the year
          expect(subject.last_occurrence).to eq DateTime.parse("2024-12-26T10:00Z")

          next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
          expect(next_occurrences).to eq [
            DateTime.parse("2024-12-02T10:00Z"),
            DateTime.parse("2024-12-03T10:00Z"),
            DateTime.parse("2024-12-04T10:00Z"),
            DateTime.parse("2024-12-05T10:00Z"),
            DateTime.parse("2024-12-09T10:00Z")
          ]
        end

        # Go to Saturday, expect next on Monday
        Timecop.freeze(DateTime.parse("2024-12-07T09:00Z")) do
          expect(subject.next_occurrence).to eq DateTime.parse("2024-12-09T10:00Z")
        end
      end
    end
  end

  describe "weekly schedule" do
    subject do
      build(:recurring_meeting,
            start_time: Time.zone.tomorrow + 10.hours,
            frequency: "weekly",
            end_after: "specific_date",
            end_date: Time.zone.tomorrow + 4.weeks)
    end

    it "schedules weekly", :aggregate_failures do
      expect(subject.first_occurrence).to eq Time.zone.tomorrow + 10.hours
      expect(subject.last_occurrence).to eq Time.zone.tomorrow + 4.weeks + 10.hours

      following_occurrence = Time.zone.tomorrow + 7.days + 10.hours
      Timecop.freeze(Time.zone.tomorrow + 11.hours) do
        expect(subject.next_occurrence).to eq following_occurrence
      end

      next_occurrences = subject.scheduled_occurrences(limit: 5).map(&:to_time)
      expect(next_occurrences).to eq [
        Time.zone.tomorrow + 10.hours,
        Time.zone.tomorrow + 7.days + 10.hours,
        Time.zone.tomorrow + 14.days + 10.hours,
        Time.zone.tomorrow + 21.days + 10.hours,
        Time.zone.tomorrow + 28.days + 10.hours
      ]

      Timecop.freeze(Time.zone.tomorrow + 5.weeks) do
        expect(subject.next_occurrence).to be_nil
      end
    end
  end

  describe "monthly schedule by day of month" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-01T10:00Z"),
            frequency: "monthly_day_of_month",
            monthly_day: 16,
            end_after: "specific_date",
            end_date: Date.parse("2025-03-20"))
    end

    it "schedules on the configured day of month", :aggregate_failures do
      expect(subject.first_occurrence).to eq DateTime.parse("2024-12-16T10:00Z")
      expect(subject.last_occurrence).to eq DateTime.parse("2025-03-16T10:00Z")

      next_occurrences = subject.scheduled_occurrences(limit: 4, from_time: subject.start_time).map(&:to_time)
      expect(next_occurrences).to eq [
        DateTime.parse("2024-12-16T10:00Z"),
        DateTime.parse("2025-01-16T10:00Z"),
        DateTime.parse("2025-02-16T10:00Z"),
        DateTime.parse("2025-03-16T10:00Z")
      ]
    end
  end

  describe "monthly schedule by nth weekday" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-01T10:00Z"),
            frequency: "monthly_nth_weekday",
            monthly_ordinal: 1,
            monthly_weekday: "tuesday",
            end_after: "specific_date",
            end_date: Date.parse("2025-03-31"))
    end

    it "schedules first weekday of month", :aggregate_failures do
      expect(subject.first_occurrence).to eq DateTime.parse("2024-12-03T10:00Z")
      expect(subject.last_occurrence).to eq DateTime.parse("2025-03-04T10:00Z")

      next_occurrences = subject.scheduled_occurrences(limit: 4, from_time: subject.start_time).map(&:to_time)
      expect(next_occurrences).to eq [
        DateTime.parse("2024-12-03T10:00Z"),
        DateTime.parse("2025-01-07T10:00Z"),
        DateTime.parse("2025-02-04T10:00Z"),
        DateTime.parse("2025-03-04T10:00Z")
      ]
    end
  end

  describe "monthly schedule by last weekday with interval" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-01T10:00Z"),
            frequency: "monthly_nth_weekday",
            monthly_ordinal: -1,
            monthly_weekday: "friday",
            interval: 2,
            end_after: "specific_date",
            end_date: Date.parse("2025-08-31"))
    end

    it "schedules every n months", :aggregate_failures do
      next_occurrences = subject.scheduled_occurrences(limit: 5, from_time: subject.start_time).map(&:to_time)
      expect(next_occurrences).to eq [
        DateTime.parse("2024-12-27T10:00Z"),
        DateTime.parse("2025-02-28T10:00Z"),
        DateTime.parse("2025-04-25T10:00Z"),
        DateTime.parse("2025-06-27T10:00Z"),
        DateTime.parse("2025-08-29T10:00Z")
      ]
    end
  end

  describe "localized monthly nth weekday wording" do
    subject do
      build(:recurring_meeting,
            start_time: DateTime.parse("2024-12-01T10:00Z"),
            frequency: "monthly_nth_weekday",
            monthly_ordinal: 1,
            monthly_weekday: "tuesday")
    end

    it "uses the inflected ordinal translation" do
      I18n.with_locale(:en) do
        expect(subject.monthly_ordinal_label).to eq("first")
      end
    end
  end

  describe "#actual_start_differs?" do
    context "when start time matches first occurrence" do
      subject do
        build(:recurring_meeting,
              start_time: DateTime.parse("2024-12-03T10:00Z"),
              frequency: "monthly_nth_weekday",
              monthly_ordinal: 1,
              monthly_weekday: "tuesday")
      end

      it "returns false" do
        expect(subject.actual_start_differs?).to be(false)
      end
    end

    context "when start time does not match first occurrence" do
      subject do
        build(:recurring_meeting,
              start_time: DateTime.parse("2024-12-01T10:00Z"),
              frequency: "monthly_nth_weekday",
              monthly_ordinal: 1,
              monthly_weekday: "tuesday")
      end

      it "returns true" do
        expect(subject.actual_start_differs?).to be(true)
      end
    end
  end

  describe "never ending meeting" do
    subject do
      build(:recurring_meeting,
            start_time: Time.zone.tomorrow + 10.hours,
            frequency: "daily",
            end_after: "never")
    end

    it "schedules daily", :aggregate_failures do
      expect(subject.first_occurrence).to eq Time.zone.tomorrow + 10.hours
      expect(subject.remaining_occurrences).to be_nil
      expect(subject.last_occurrence).to be_nil
    end
  end

  describe "#upcoming_instantiated_meetings" do
    let!(:recurring_meeting) { create(:recurring_meeting) }
    let!(:ongoing_meeting) do
      create(:recurring_meeting_occurrence,
             recurring_meeting:,
             start_time: 5.minutes.ago,
             recurrence_start_time: 5.minutes.ago)
    end
    let!(:cancelled_meeting) do
      create(:recurring_meeting_occurrence,
             recurring_meeting:,
             start_time: 1.day.from_now,
             recurrence_start_time: 1.day.from_now,
             state: :cancelled)
    end

    it "returns only upcoming and not cancelled meetings" do
      expect(recurring_meeting.upcoming_instantiated_meetings).to eq [ongoing_meeting]
    end
  end

  describe "#ical_schedule / #schedule" do
    context "with a schedule with number of iterations" do
      let(:recurring_meeting) do
        build(:recurring_meeting,
              start_time: DateTime.parse("2024-10-01T12:00Z"),
              frequency: "weekly",
              end_after: "iterations",
              iterations: 5,
              current_schedule_start: DateTime.parse("2024-10-15T12:00Z"))

        # Occurrences on 2024-10-01, 2024-10-08, 2024-10-15, 2024-10-22, 2024-10-29
      end

      it "builds an IceCube schedule for iCal based on current_schedule_start" do
        schedule = recurring_meeting.ical_schedule

        expect(schedule.start_time).to eq(recurring_meeting.current_schedule_start)
        expect(schedule.rrules.count).to eq 1

        rrule = schedule.rrules.first

        expect(rrule).to be_a(IceCube::WeeklyRule)
        expect(rrule.occurrence_count).to eq(3) # 15th is the 3rd occurrence, so with it 3 remaining
      end

      it "builds an IceCube schedule for based on start_time" do
        schedule = recurring_meeting.schedule

        expect(schedule.start_time).to eq(recurring_meeting.start_time)
        expect(schedule.rrules.count).to eq 1

        rrule = schedule.rrules.first

        expect(rrule).to be_a(IceCube::WeeklyRule)
        expect(rrule.occurrence_count).to eq(5)
      end
    end

    context "with a schedule until a specific date" do
      let(:recurring_meeting) do
        build(:recurring_meeting,
              start_time: DateTime.parse("2024-10-01T12:00Z"),
              frequency: "weekly",
              end_after: "specific_date",
              end_date: Date.parse("2024-11-05"),
              current_schedule_start: DateTime.parse("2024-10-15T12:00Z"))
      end

      it "builds an IceCube schedule for iCal based on current_schedule_start" do
        schedule = recurring_meeting.ical_schedule

        expect(schedule.start_time).to eq(recurring_meeting.current_schedule_start)
        expect(schedule.rrules.count).to eq 1

        rrule = schedule.rrules.first

        expect(rrule).to be_a(IceCube::WeeklyRule)
        expect(rrule.until_time).to eq(recurring_meeting.end_date + 1.day)
      end

      it "builds an IceCube schedule for based on start_time" do
        schedule = recurring_meeting.schedule

        expect(schedule.start_time).to eq(recurring_meeting.start_time)
        expect(schedule.rrules.count).to eq 1

        rrule = schedule.rrules.first

        expect(rrule).to be_a(IceCube::WeeklyRule)
        expect(rrule.until_time).to eq(recurring_meeting.end_date + 1.day)
      end
    end
  end

  describe "#current_schedule_end" do
    let(:recurring_meeting) do
      create(
        :recurring_meeting,
        start_time: DateTime.parse("2026-02-24T13:45:00+01:00"),
        current_schedule_start: DateTime.parse("2026-05-05T13:45:00+02:00"),
        duration: 0.25,
        time_zone: "Europe/Berlin"
      )
    end

    it "uses current_schedule_start plus duration" do
      expect(recurring_meeting.current_schedule_end).to eq(DateTime.parse("2026-05-05T14:00:00+02:00"))
    end
  end

  describe "#uid" do
    it "assigns a uid on create" do
      series = build(:recurring_meeting)
      expect(series.uid).to be_present
      expect(series.uid).to include "@#{Setting.host_name}"
    end
  end
end
