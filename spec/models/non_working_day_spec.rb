# frozen_string_literal: true

require "rails_helper"

RSpec.describe NonWorkingDay do
  subject { build(:non_working_day) }

  describe "validations" do
    it "is valid when all attributes are present" do
      expect(subject).to be_valid
    end

    it "is invalid without name" do
      subject.name = nil
      expect(subject).to be_invalid
      expect(subject.errors[:name]).to be_present
    end

    it "is invalid without date" do
      subject.date = nil
      expect(subject).to be_invalid
      expect(subject.errors[:date]).to be_present
    end

    it "is invalid with an already existing date" do
      existing = create(:non_working_day)
      subject.date = existing.date
      expect(subject).to be_invalid
      expect(subject.errors[:date]).to be_present
    end
  end

  describe ".for_dates" do
    let!(:inside) { create(:non_working_day, date: Date.new(2026, 3, 10)) }
    let!(:on_boundary) { create(:non_working_day, date: Date.new(2026, 3, 20)) }
    let!(:outside) { create(:non_working_day, date: Date.new(2026, 3, 21)) }

    it "returns the days within the inclusive range" do
      expect(described_class.for_dates(Date.new(2026, 3, 1)..Date.new(2026, 3, 20)))
        .to contain_exactly(inside, on_boundary)
    end
  end
end
