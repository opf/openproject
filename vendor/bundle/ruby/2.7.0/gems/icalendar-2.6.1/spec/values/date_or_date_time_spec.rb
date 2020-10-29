require 'spec_helper'

describe Icalendar::Values::DateOrDateTime do

  subject { described_class.new value, params }
  let(:params) { {} }

  describe '#call' do
    context 'DateTime value' do
      let(:value) { '20140209T194355Z' }

      it 'returns a DateTime object' do
        expect(subject.call).to be_a_kind_of(Icalendar::Values::DateTime)
      end

      it 'has the proper value' do
        expect(subject.call.value).to eq DateTime.new(2014, 2, 9, 19, 43, 55)
      end
    end

    context 'Date value' do
      let(:value) { '20140209' }

      it 'returns a Date object' do
        expect(subject.call).to be_a_kind_of(Icalendar::Values::Date)
      end

      it 'has the proper value' do
        expect(subject.call.value).to eq Date.new(2014, 2, 9)
      end
    end

    context 'unparseable date' do
      let(:value) { '99999999' }

      it 'raises an error including the unparseable time' do
        expect { subject.call }.to raise_error(ArgumentError, %r{Failed to parse \"#{value}\"})
      end
    end
  end

  describe "#to_ical" do
    let(:event) { Icalendar::Event.new }
    let(:time_stamp) { Time.now.strftime Icalendar::Values::DateTime::FORMAT }

    it "should call parse behind the scenes" do
      event.dtstart = described_class.new time_stamp, "tzid" => "UTC"
      expect(event.to_ical).to include "DTSTART:#{time_stamp}Z"
    end
  end
end
