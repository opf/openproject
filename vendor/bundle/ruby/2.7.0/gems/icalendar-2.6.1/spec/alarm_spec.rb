require 'spec_helper'

describe Icalendar::Alarm do

  # currently no behavior in Alarm not tested other places
  describe '#valid?' do
    subject do
      described_class.new.tap do |a|
        a.action = 'AUDIO'
        a.trigger = Icalendar::Values::DateTime.new(Time.now.utc)
      end
    end
    context 'neither duration or repeat is set' do
      it { should be_valid }
    end
    context 'both duration and repeat are set' do
      before(:each) do
        subject.duration = 'PT15M'
        subject.repeat = 4
      end
      it { should be_valid }
    end
    context 'only duration is set' do
      before(:each) { subject.duration = 'PT15M' }
      it { should_not be_valid }
    end
    context 'only repeat is set' do
      before(:each) { subject.repeat = 4 }
      it { should_not be_valid }
    end

    context 'display action' do
      before(:each) { subject.action = 'DISPLAY' }
      it 'requires description' do
        expect(subject).to_not be_valid
        subject.description = 'Display Text'
        expect(subject).to be_valid
      end
    end

    context 'email action' do
      before(:each) { subject.action = 'EMAIL' }
      context 'requires subject and body' do
        before(:each) { subject.attendee = ['mailto:test@email.com'] }
        it 'requires description' do
          subject.summary = 'Email subject'
          expect(subject).to_not be_valid
          subject.description = 'Email Body'
          expect(subject).to be_valid
        end
        it 'requires summary' do
          subject.description = 'Email body'
          expect(subject).to_not be_valid
          subject.summary = 'Email subject'
          expect(subject).to be_valid
        end
      end
      context 'attendees are required' do
        before(:each) do
          subject.summary = 'subject'
          subject.description = 'body'
        end

        it 'must be present' do
          subject.attendee = nil
          expect(subject).to_not be_valid
        end

        it 'can be single' do
          subject.attendee << 'mailto:test@email.com'
          expect(subject).to be_valid
        end

        it 'can be multi' do
          subject.attendee << 'mailto:test@email.com'
          subject.attendee << 'mailto:email@test.com'
          expect(subject).to be_valid
        end
      end
    end

    context 'strict validations check parent' do
      subject do
        described_class.new.tap do |a|
          a.action = 'AUDIO'
          a.trigger = Icalendar::Values::DateTime.new(Time.now.utc)
        end
      end
      specify { expect(subject.valid? true).to be true }
      context 'with parent' do
        before(:each) { subject.parent = parent }
        context 'event' do
          let(:parent) { Icalendar::Event.new }
          specify { expect(subject.valid? true).to be true }
        end
        context 'todo' do
          let(:parent) { Icalendar::Todo.new }
          specify { expect(subject.valid? true).to be true }
        end
        context 'journal' do
          let(:parent) { Icalendar::Journal.new }
          specify { expect(subject.valid? true).to be false }
        end
      end
    end
  end

end
