require 'spec_helper'

describe JournalManager do
  describe '#self.changed?' do
    let(:journable) do
      FactoryGirl.create(:work_package, description: old).tap do |journable|
        # replace newline character and apply another change
        journable.assign_attributes description: changed
      end
    end

    context 'when only the newline character representation has changed' do
      let(:old) { "Description\nContains newline character" }
      let(:changed) { old.gsub("\n", "\r\n") }

      subject { JournalManager.changed? journable }

      it { should be_false }
    end

    context 'when old value is nil and changed value is an empty string' do
      let(:old) { nil }
      let(:changed) { '' }

      subject { JournalManager.changed? journable }

      it { should be_false }
    end

    context 'when changed value is nil and old value is an empty string' do
      let(:old) { '' }
      let(:changed) { nil }

      subject { JournalManager.changed? journable }

      it { should be_false }
    end

    context 'when changed value has a value and old value is an empty string' do
      let(:old) { '' }
      let(:changed) { 'Changed text' }

      subject { JournalManager.changed? journable }

      it { should be_true }
    end

    context 'when changed value has a value and old value is nil' do
      let(:old) { nil }
      let(:changed) { 'Changed text' }

      subject { JournalManager.changed? journable }

      it { should be_true }
    end

    context 'when changed value is nil and old value was some text' do
      let(:old) { 'Old text' }
      let(:changed) { nil }

      subject { JournalManager.changed? journable }

      it { should be_true }
    end

    context 'when changed value is an empty string and old value was some text' do
      let(:old) { 'Old text' }
      let(:changed) { '' }

      subject { JournalManager.changed? journable }

      it { should be_true }
    end
  end
end
