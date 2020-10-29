require 'spec_helper'

describe Icalendar::Values::UtcOffset do

  subject { described_class.new value }

  describe '#value_ical' do
    let(:value) { '-050000' }

    it 'does not output seconds unless required' do
      expect(subject.value_ical).to eq '-0500'
    end

    context 'with seconds' do
      let(:value) { '+023030' }
      specify { expect(subject.value_ical).to eq '+023030' }
    end
  end

  describe '#behind?' do
    context 'negative offset' do
      let(:value) { '-0500' }
      specify { expect(subject.behind?).to be true }
    end

    context 'positive offset' do
      let(:value) { '+0200' }
      specify { expect(subject.behind?).to be false }
    end

    context 'no offset' do
      let(:value) { '-0000' }
      specify { expect(subject.behind?).to be false }

      it 'does not allow override' do
        subject.behind = true
        expect(subject.behind?).to be false
      end
    end
  end
end
