require 'spec_helper'

describe Icalendar::Values::DateTime do

  subject { described_class.new value, params }
  let(:value) { '20140209T194355Z' }
  let(:params) { {} }

  # not sure how to automatically test both sides of this.
  # For now - relying on commenting out dev dependency in gemspec
  # AND uninstalling gem manually
  if defined? ActiveSupport

    context 'with ActiveSupport' do
      it 'parses a string to a ActiveSupport::TimeWithZone instance' do
        expect(subject.value).to be_a_kind_of ActiveSupport::TimeWithZone
        expect(subject.value_ical).to eq value
      end

      context 'local time' do
        let(:value) { '20140209T160652' }
        let(:params) { {'tzid' => 'America/Denver'} }

        it 'parses the value as local time' do
          expect(subject.value.hour).to eq 16
          expect(subject.value.utc_offset).to eq -25200
          expect(subject.value.utc.hour).to eq 23
        end
      end
    end

  else

    context 'without ActiveSupport' do
      it 'parses a string to a DateTime instance' do
        expect(subject.value).to be_a_kind_of ::DateTime
      end

      context 'local time' do
        let(:value) { '20140209T160652' }
        let(:params) { {'tzid' => 'America/Denver'} }

        it 'parses the value as local time' do
          expect(subject.value.hour).to eq 16
          # TODO better offset support without ActiveSupport
          #expect(subject.offset).to eq Rational(-7, 24)
        end
      end
    end

  end


  context 'common tests' do
    it 'does not add any tzid parameter to output' do
      expect(subject.to_ical described_class).to eq ":#{value}"
    end

    context 'manually set UTC' do
      let(:value) { '20140209T194355' }
      let(:params) { {'TZID' => 'UTC'} }

      it 'does not add a tzid parameter, but does add a Z' do
        expect(subject.to_ical described_class).to eq ":#{value}Z"
      end
    end

    context 'local time' do
      let(:value) { '20140209T160652' }
      let(:params) { {'tzid' => 'America/Denver'} }

      it 'keeps value and tzid as localtime on output' do
        expect(subject.to_ical described_class).to eq ";TZID=America/Denver:#{value}"
      end
    end

    context 'floating local time' do
      let(:value) { '20140209T162845' }

      it 'keeps the value as a DateTime' do
        expect(subject.value).to be_a_kind_of ::DateTime
      end

      it 'does not append a Z on output' do
        expect(subject.to_ical described_class).to eq ":#{value}"
      end
    end

    context 'unparseable time' do
      let(:value) { 'unparseable_time' }

      it 'raises an error including the unparseable time' do
        expect { subject }.to raise_error(ArgumentError, %r{Failed to parse \"#{value}\"})
      end
    end
  end
end
