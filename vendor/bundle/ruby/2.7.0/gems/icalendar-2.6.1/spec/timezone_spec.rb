require 'spec_helper'

describe Icalendar::Timezone do

  describe "valid?" do
    subject { described_class.new.tap { |t| t.tzid = 'Eastern' } }

    context 'with both standard and daylight components' do
      before(:each) do
        subject.daylight { |d| allow(d).to receive(:valid?).and_return true }
        subject.standard { |s| allow(s).to receive(:valid?).and_return true }
      end

      it { should be_valid }
    end

    context 'with only standard' do
      before(:each) { subject.standard { |s| allow(s).to receive(:valid?).and_return true } }
      it { expect(subject).to be_valid }
    end

    context 'with only daylight' do
      before(:each) { subject.daylight { |d| allow(d).to receive(:valid?).and_return true } }
      it { expect(subject).to be_valid }
    end

    context 'with neither standard or daylight' do
      it { should_not be_valid }
    end
  end

  context 'marshalling' do
    context 'with standard/daylight components' do
      before do
        subject.standard do |standard|
          standard.rrule = Icalendar::Values::Recur.new("FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=10")
          standard.dtstart = Icalendar::Values::DateTime.new("16010101T030000")
          standard.tzoffsetfrom = Icalendar::Values::UtcOffset.new("+0200")
          standard.tzoffsetto = Icalendar::Values::UtcOffset.new("+0100")
        end

        subject.daylight do |daylight|
          daylight.rrule = Icalendar::Values::Recur.new("FREQ=YEARLY;INTERVAL=1;BYDAY=-1SU;BYMONTH=3")
          daylight.dtstart = Icalendar::Values::DateTime.new("16010101T020000")
          daylight.tzoffsetfrom = Icalendar::Values::UtcOffset.new("+0100")
          daylight.tzoffsetto = Icalendar::Values::UtcOffset.new("+0200")
        end
      end

      it 'can be de/serialized' do
        first_standard = subject.standards.first
        first_daylight = subject.daylights.first

        expect(first_standard.valid?).to be_truthy
        expect(first_daylight.valid?).to be_truthy

        # calling previous_occurrence intializes @cached_occurrences with a time that's not handled by ruby marshaller
        first_occurence_for = Time.new(1601, 10, 31)

        standard_previous_occurrence = first_standard.previous_occurrence(first_occurence_for)
        expect(standard_previous_occurrence).not_to be_nil

        daylight_previous_occurrence = first_daylight.previous_occurrence(first_occurence_for)
        expect(daylight_previous_occurrence).not_to be_nil

        deserialized = nil

        expect { deserialized = Marshal.load(Marshal.dump(subject)) }.not_to raise_exception

        expect(deserialized.standards.first.previous_occurrence(first_occurence_for)).to eq(standard_previous_occurrence)
        expect(deserialized.daylights.first.previous_occurrence(first_occurence_for)).to eq(daylight_previous_occurrence)
      end
    end

    it 'can be de/serialized' do
      expect { Marshal.load(Marshal.dump(subject)) }.not_to raise_exception
    end
  end
end
