require 'spec_helper'

describe Icalendar::Values::Duration do

  subject { described_class.new value }

  describe '#past?' do
    context 'positive explicit' do
      let(:value) { '+P15M' }
      specify { expect(subject.past?).to be false }
    end

    context 'positive implicit' do
      let(:value) { 'P15M' }
      specify { expect(subject.past?).to be false }
    end

    context 'negative' do
      let(:value) { '-P15M' }
      specify { expect(subject.past?).to be true }
    end
  end

  describe '#days' do
    context 'days given' do
      let(:value) { 'P5DT3H' }
      specify { expect(subject.days).to eq 5 }
    end
    context 'no days given' do
      let(:value) { 'P5W' }
      specify { expect(subject.days).to eq 0 }
    end
  end

  describe '#weeks' do
    let(:value) { 'P3W' }
    specify { expect(subject.weeks).to eq 3 }
  end

  describe '#hours' do
    let(:value) { 'PT6H' }
    specify { expect(subject.hours).to eq 6 }
  end

  describe '#minutes' do
    let(:value) { 'P2DT5H45M12S' }
    specify { expect(subject.minutes).to eq 45 }
  end

  describe '#seconds' do
    let(:value) { '-PT5M30S' }
    specify { expect(subject.seconds).to eq 30 }
  end

  describe '#value_ical' do
    let(:value) { 'P2DT4H' }
    specify { expect(subject.value_ical).to eq value }
  end

  describe '#days=' do
    let(:value) { 'P3D' }
    it 'can set the number of days' do
      subject.days = 4
      expect(subject.value_ical).to eq 'P4D'
    end
  end
end
