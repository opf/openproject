require 'spec_helper'

describe Icalendar::Calendar do

  context 'marshalling' do
    it 'can be de/serialized' do
      Marshal.load(Marshal.dump(subject))
    end
  end

  context 'values' do
    let(:property) { 'my-value' }

    %w(prodid version calscale ip_method).each do |prop|
      it "##{prop} sets and gets" do
        subject.send("#{prop}=", property)
        expect(subject.send prop).to eq property
      end
    end

    it "sets and gets custom properties" do
      subject.x_custom_prop = property
      expect(subject.x_custom_prop).to eq [property]
    end

    it 'can set params on a property' do
      subject.prodid.ical_params = {'hello' => 'world'}
      expect(subject.prodid.value).to eq 'icalendar-ruby'
      expect(subject.prodid.ical_params).to eq('hello' => 'world')
    end

    context "required values" do
      it 'is not valid when prodid is not set' do
        subject.prodid = nil
        expect(subject).to_not be_valid
      end

      it 'is not valid when version is not set' do
        subject.version = nil
        expect(subject).to_not be_valid
      end

      it 'is valid when both prodid and version are set' do
        subject.version = '2.0'
        subject.prodid = 'my-product'
        expect(subject).to be_valid
      end

      it 'is valid by default' do
        expect(subject).to be_valid
      end
    end
  end

  context 'components' do
    let(:ical_component) { double 'Component', name: 'event', :'parent=' => nil }

    %w(event todo journal freebusy timezone).each do |component|
      it "##{component} adds a new component" do
        expect(subject.send "#{component}").to be_a_kind_of Icalendar::Component
      end

      it "##{component} passes a component to a block to build parts" do
        expect { |b| subject.send("#{component}", &b) }.to yield_with_args Icalendar::Component
      end

      it "##{component} can be passed in" do
        expect { |b| subject.send("#{component}", ical_component, &b) }.to yield_with_args ical_component
        expect(subject.send "#{component}", ical_component).to eq ical_component
      end
    end

    it "adds event to events list" do
      subject.event ical_component
      expect(subject.events).to eq [ical_component]
    end

    describe '#add_event' do
      it 'delegates to non add_ version' do
        expect(subject).to receive(:event).with(ical_component)
        subject.add_event ical_component
      end
    end

    describe '#find_event' do
      let(:ical_component) { double 'Component', uid: 'uid' }
      let(:other_component) { double 'Component', uid: 'other' }
      before(:each) do
        subject.events << other_component
        subject.events << ical_component
      end

      it 'finds by uid' do
        expect(subject.find_event 'uid').to eq ical_component
      end
    end

    describe '#find_timezone' do
      let(:ical_timezone) { double 'Timezone', tzid: 'Eastern' }
      let(:other_timezone) { double 'Timezone', tzid: 'Pacific' }
      before(:each) do
        subject.timezones << other_timezone
        subject.timezones << ical_timezone
      end

      it 'finds by tzid' do
        expect(subject.find_timezone 'Eastern').to eq ical_timezone
      end
    end

    it "adds reference to parent" do
      e = subject.event
      expect(e.parent).to eq subject
    end

    it 'can be added with add_x_ for custom components' do
      expect(subject.add_x_custom_component).to be_a_kind_of Icalendar::Component
      expect { |b| subject.add_x_custom_component(&b) }.to yield_with_args Icalendar::Component
      expect(subject.add_x_custom_component ical_component).to eq ical_component
    end
  end

  describe '#to_ical' do
    before(:each) do
      Timecop.freeze DateTime.new(2013, 12, 26, 5, 0, 0, '+0000')
      subject.event do |e|
        e.summary = 'An event'
        e.dtstart = "20140101T000000Z"
        e.dtend = "20140101T050000Z"
        e.geo = [-1.2, -2.1]
      end
      subject.freebusy do |f|
        f.dtstart = "20140102T080000Z"
        f.dtend = "20140102T100000Z"
        f.comment = 'Busy'
      end
    end
    after(:each) do
      Timecop.return
    end

    it 'outputs properties and components' do
      expected_no_uid = <<-EOICAL.gsub("\n", "\r\n")
BEGIN:VCALENDAR
VERSION:2.0
PRODID:icalendar-ruby
CALSCALE:GREGORIAN
BEGIN:VEVENT
DTSTAMP:20131226T050000Z
DTSTART:20140101T000000Z
DTEND:20140101T050000Z
GEO:-1.2;-2.1
SUMMARY:An event
END:VEVENT
BEGIN:VFREEBUSY
DTSTAMP:20131226T050000Z
DTSTART:20140102T080000Z
DTEND:20140102T100000Z
COMMENT:Busy
END:VFREEBUSY
END:VCALENDAR
      EOICAL
      expect(subject.to_ical.gsub(/^UID:.*\r\n(?: .*\r\n)*/, '')).to eq expected_no_uid
    end
  end

  describe '#publish' do
    it 'sets ip_method to "PUBLISH"' do
      subject.publish
      expect(subject.ip_method).to eq 'PUBLISH'
    end
  end
end
