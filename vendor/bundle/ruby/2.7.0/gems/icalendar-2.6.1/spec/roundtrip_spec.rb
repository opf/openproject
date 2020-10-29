require 'spec_helper'

describe Icalendar do

  describe 'single event round trip' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event.ics') }

    it 'will generate the same file as is parsed' do
      ical = Icalendar::Calendar.parse(source).first.to_ical
      expect(ical).to eq source
    end

    it 'array properties can be assigned to a new event' do
      event = Icalendar::Event.new
      parsed = Icalendar::Calendar.parse(source).first
      event.rdate = parsed.events.first.rdate
      expect(event.rdate.first).to be_kind_of Icalendar::Values::Array
      expect(event.rdate.first.params_ical).to eq ";TZID=US-Mountain"
    end
  end

  describe 'cleanly handle facebook organizers' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event_bad_organizer.ics') }
    let(:source_lowered_uri) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'single_event_organizer_parsed.ics') }
    it 'will generate the same file as it parsed' do
      ical = Icalendar::Calendar.parse(source).first.to_ical
      source_equal = ical == source
      # rbx-3 parses the organizer as a URI, which strips the space and lowercases everything after the first :
      # this is correct behavior, according to the icalendar spec, so we're not fudging the parser to accomodate
      # facebook not properly wrapping the CN param in dquotes
      source_lowered_equal = ical == source_lowered_uri
      expect(source_equal || source_lowered_equal).to be true
    end
  end

  describe 'timezone round trip' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'timezone.ics') }
    it 'will generate the same file as it parsed' do
      ical = Icalendar::Calendar.parse(source).first.to_ical
      expect(ical).to eq source
    end
  end

  describe 'non-default values' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'nondefault_values.ics') }
    subject { Icalendar::Calendar.parse(source).first.events.first }

    it 'will set dtstart to Date' do
      expect(subject.dtstart.value).to eq ::Date.new(2006, 12, 15)
    end

    it 'will set dtend to Date' do
      expect(subject.dtend.value).to eq ::Date.new(2006, 12, 15)
    end

    it 'will output value param on dtstart' do
      expect(subject.dtstart.to_ical(subject.class.default_property_types['dtstart'])).to match /^;VALUE=DATE:20061215$/
    end

    it 'will output value param on dtend' do
      expect(subject.dtend.to_ical(subject.class.default_property_types['dtend'])).to match /^;VALUE=DATE:20061215$/
    end
  end

  describe 'sorting daily events' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'two_day_events.ics') }
    subject { Icalendar::Calendar.parse(source).first.events }

    it 'sorts day events' do
      events = subject.sort_by(&:dtstart)

      expect(events.first.dtstart).to eq ::Date.new(2014, 7, 13)
      expect(events.last.dtstart).to eq ::Date.new(2014, 7, 14)
    end
  end

  describe 'sorting time events' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'two_time_events.ics') }
    subject { Icalendar::Calendar.parse(source).first.events }

    it 'sorts time events by start time' do
      events = subject.sort_by(&:dtstart)

      expect(events.first.dtstart.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 0, 0, '-4')

      expect(events.last.dtstart.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 1, 0, '-4')
      expect(events.last.dtend.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 59, 0, '-4')
    end

    it 'sorts time events by end time' do
      events = subject.sort_by(&:dtend)

      expect(events.first.dtstart.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 1, 0, '-4')
      expect(events.first.dtend.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 59, 0, '-4')
      expect(events.last.dtstart.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 0, 0, '-4')
    end
  end

  describe 'sorting date / time events' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'two_date_time_events.ics') }
    subject { Icalendar::Calendar.parse(source).first.events }

    it 'sorts time events' do
      events = subject.sort_by(&:dtstart)

      expect(events.first.dtstart.to_date).to eq ::Date.new(2014, 7, 14)
      expect(events.last.dtstart.to_datetime).to eq ::DateTime.new(2014, 7, 14, 9, 0, 0, '-4')
    end
  end

  describe 'non-standard values' do
    if defined? File::NULL
      before(:all) { Icalendar.logger = Icalendar::Logger.new File::NULL }
      after(:all) { Icalendar.logger = nil }
    end
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', 'nonstandard.ics') }
    subject { Icalendar::Parser.new(source, strict) }

    context 'strict parser' do
      let(:strict) { true }
      specify { expect { subject.parse }.to raise_error(NoMethodError) }
    end

    context 'lenient parser' do
      let(:strict) { false }
      specify { expect { subject.parse }.to_not raise_error }

      context 'saves non-standard fields' do
        let(:parsed) { subject.parse.first.events.first }
        specify { expect(parsed.custom_property('customfield').first).to eq 'Not properly noted as custom with X- prefix.' }
        specify { expect(parsed.custom_property('CUSTOMFIELD').first).to eq 'Not properly noted as custom with X- prefix.' }
      end

      it 'can output custom fields' do
        ical = subject.parse.first.to_ical
        expect(ical).to include 'CUSTOMFIELD:Not properly noted as custom with X- prefix.'
      end
    end
  end
end
