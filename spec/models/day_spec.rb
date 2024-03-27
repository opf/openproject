require "spec_helper"

RSpec.describe Day do
  shared_let(:week_days) { week_with_saturday_and_sunday_as_weekend }
  let(:today) { Date.current }
  let(:date_range) { Date.new(2022, 1, 1)..Date.new(2022, 2, 1) }
  let(:first_of_year) { date_range.begin }
  let(:days) { described_class.from_range(from: date_range.begin, to: date_range.end) }

  subject { days.find(first_of_year.strftime("%Y%m%d").to_i) }

  it { is_expected.to be_readonly }
  it { is_expected.to respond_to :id }
  it { is_expected.to respond_to :date }
  it { is_expected.to respond_to :day_of_week }
  it { is_expected.to respond_to :name }

  context "with default_scope" do
    let(:days) { described_class.default_scope }

    it "returns a default date range" do
      expect(days.minmax.pluck(:date)).to eq(
        [today.at_beginning_of_month, today.next_month.at_end_of_month]
      )
    end

    it "loads week_day method" do
      expect(days).to(be_all { |d| d.week_day.present? })
    end

    it "eager loads non_working_days relation" do
      expect(days).to(be_all { |d| d.association(:non_working_days).loaded? })
    end

    it "loads the id attribute" do
      expect(days.first.id).to eq(today.at_beginning_of_month.strftime("%Y%m%d").to_i)
    end

    it "loads the date attribute" do
      expect(days.first.date).to eq(today.at_beginning_of_month)
    end

    it "loads the day_of_week attribute" do
      expect(days.first.day_of_week % 7).to eq(today.at_beginning_of_month.wday) # wday is from 0-6
    end

    it "loads the name attribute" do
      expect(days.first.name).to eq(today.at_beginning_of_month.strftime("%A"))
    end
  end

  context "for collection with multiple non-working days" do
    let(:non_working_dates) { [date_range.begin, date_range.begin + 1.day] }

    before do
      non_working_dates.each { |date| create(:non_working_day, date:) }
    end

    it "returns the correct number of days" do
      expect(days.count).to eq(date_range.count)
    end

    it "returns the dates included in the date_range" do
      expect(days.collect(&:date)).to eq(date_range.to_a)
    end

    it "returns working false for weekends and non_working_days" do
      expected_working_states = date_range.map do |day|
        !(day.saturday? || day.sunday? || day.in?(non_working_dates))
      end
      expect(days.pluck(:working)).to eq(expected_working_states)
    end

    it "returns the correct day_of_week" do
      expected_days_of_week = date_range.map { |day| Array(1..7)[day.wday - 1] }
      expect(days.pluck(:day_of_week)).to eq(expected_days_of_week)
    end
  end

  context "with the weekday present" do
    it "loads the name attribute" do
      expect(subject.name).to eq("Saturday")
    end
  end

  describe ".last_working" do
    subject { described_class.last_working }

    around do |ex|
      Timecop.travel(current_time, &ex)
    end

    context "when today is Monday" do
      let(:current_time) { Time.current.monday }

      context "when yesterday is a weekend day" do
        it "returns last Friday" do
          expect(subject.date).to eq(current_time.prev_occurring(:friday))
        end
      end
    end

    context "when today is Tuesday" do
      let(:current_time) { Time.current.monday + 1.day }

      context "when yesterday is working" do
        it "returns Monday" do
          expect(subject.date).to eq(current_time.yesterday)
        end
      end

      context "when yesterday is non-working" do
        before do
          create(:non_working_day, date: current_time.yesterday)
        end

        it "returns last Friday" do
          expect(subject.date).to eq(current_time.prev_occurring(:friday))
        end
      end
    end
  end

  describe "#working" do
    context "when the week day is non-working" do
      shared_let(:working_days) { week_with_no_working_days }

      it "is false" do
        expect(subject.working).to be_falsy
      end

      context "with a non-working day" do
        before do
          create(:non_working_day, date: first_of_year)
        end

        it "is false" do
          expect(subject.working).to be_falsy
        end
      end
    end

    context "when the week day is working" do
      shared_let(:working_days) { set_work_week("saturday") }

      it "is true" do
        expect(subject.working).to be_truthy
      end

      context "with a non working day" do
        before do
          create(:non_working_day, date: first_of_year)
        end

        it "is false" do
          expect(subject.working).to be_falsy
        end
      end
    end
  end
end
