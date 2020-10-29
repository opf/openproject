require 'spec_helper'

describe Icalendar::Event do

  describe '#dtstart' do
    context 'no parent' do
      it 'is invalid if not set' do
        expect(subject).to_not be_valid
      end

      it 'is valid if set' do
        subject.dtstart = DateTime.now
        expect(subject).to be_valid
      end
    end

    context 'with parent' do
      before(:each) { subject.parent = Icalendar::Calendar.new }

      it 'is invalid without method set' do
        expect(subject).to_not be_valid
      end

      it 'is valid with parent method set' do
        subject.parent.ip_method = 'UPDATE'
        expect(subject).to be_valid
      end
    end
  end

  context 'mutually exclusive values' do
    before(:each) { subject.dtstart = DateTime.now }

    it 'is invalid if both dtend and duration are set' do
      subject.dtend = Date.today + 1;
      subject.duration = 'PT15M'
      expect(subject).to_not be_valid
    end

    it 'is valid if dtend is set' do
      subject.dtend = Date.today + 1;
      expect(subject).to be_valid
    end

    it 'is valid if duration is set' do
      subject.duration = 'PT15M'
      expect(subject).to be_valid
    end
  end

  context 'suggested single values' do
    before(:each) do
      subject.dtstart = DateTime.now
      subject.append_rrule double('RRule').as_null_object
      subject.append_rrule double('RRule').as_null_object
    end

    it 'is valid by default' do
      expect(subject).to be_valid
    end

    it 'is invalid with strict checking' do
      expect(subject.valid?(true)).to be false
    end
  end

  context 'multi values' do
    describe '#comment' do
      it 'will return an array when set singly' do
        subject.comment = 'a comment'
        expect(subject.comment).to eq ['a comment']
      end

      it 'can be appended' do
        subject.comment << 'a comment'
        subject.comment << 'b comment'
        expect(subject.comment).to eq ['a comment', 'b comment']
      end

      it 'can be added' do
        subject.append_comment 'a comment'
        expect(subject.comment).to eq ['a comment']
      end
    end

    if defined? ActiveSupport
      describe '#rdate' do
        it 'does not convert a DateTime delegating for an ActiveSupport::TimeWithZone into an Array' do
          timestamp = '20140130T230000Z'
          expected = [Icalendar::Values::DateTime.new(timestamp)]

          subject.rdate = timestamp
          expect(subject.rdate).to eq(expected)
        end
      end
    end
  end

  describe "#append_custom_property" do
    context "with custom property" do
      it "appends to the custom properties hash" do
        subject.append_custom_property "x_my_property", "test value"
        expect(subject.custom_properties).to eq({"x_my_property" => ["test value"]})
      end
    end

    context "with a defined property" do
      it "sets the proper setter" do
        subject.append_custom_property "summary", "event"
        expect(subject.summary).to eq "event"
        expect(subject.custom_properties).to eq({})
      end
    end
  end

  describe "#custom_property" do
    it "returns a default for missing properties" do
      expect(subject.x_doesnt_exist).to eq([])
      expect(subject.custom_property "x_doesnt_exist").to eq([])
    end
  end

  describe '.parse' do
    let(:source) { File.read File.join(File.dirname(__FILE__), 'fixtures', fn) }
    let(:fn) { 'event.ics' }

    it 'should return an events array' do
      events = Icalendar::Event.parse(source)
      expect(events).to be_instance_of Array
      expect(events.count).to be 1
      expect(events.first).to be_instance_of Icalendar::Event
    end
  end

  describe '#find_alarm' do
    it 'should not respond_to find_alarm' do
      expect(subject.respond_to?(:find_alarm)).to be false
    end
  end

  describe '#has_alarm?' do
    context 'without a set valarm' do
      it { is_expected.not_to have_alarm }
    end

    context 'with a set valarm' do
      before { subject.alarm }

      it { is_expected.to have_alarm }
    end
  end

  describe '#to_ical' do
    before(:each) do
      subject.dtstart = "20131227T013000Z"
      subject.dtend = "20131227T033000Z"
      subject.summary = 'My event, my ical, my test'
      subject.geo = [41.230896,-74.411774]
      subject.x_custom_property = 'customize'
    end

    it { expect(subject.to_ical).to include 'DTSTART:20131227T013000Z' }
    it { expect(subject.to_ical).to include 'DTEND:20131227T033000Z' }
    it { expect(subject.to_ical).to include 'SUMMARY:My event\, my ical\, my test' }
    it { expect(subject.to_ical).to include 'X-CUSTOM-PROPERTY:customize' }
    it { expect(subject.to_ical).to include 'GEO:41.230896;-74.411774' }

    context 'simple organizer' do
      before :each do
        subject.organizer = 'mailto:jsmith@example.com'
      end

      it { expect(subject.to_ical).to include 'ORGANIZER:mailto:jsmith@example.com' }
    end

    context 'complex organizer' do
      before :each do
        subject.organizer = Icalendar::Values::CalAddress.new("mailto:jsmith@example.com", cn: 'John Smith')
      end

      it { expect(subject.to_ical).to include 'ORGANIZER;CN=John Smith:mailto:jsmith@example.com' }
    end

  end

end
