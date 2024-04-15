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
end
