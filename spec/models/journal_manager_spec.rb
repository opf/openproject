require 'spec_helper'

describe JournalManager do
  describe '#self.changed?' do
    context 'when only the newline character representation has changed' do
      let(:description_with_newline) { "Description\nContains newline character" }
      let(:description_with_other_newline) { description_with_newline.gsub("\n", "\r\n") }
      let(:journable) do
        FactoryGirl.create(:work_package, description: description_with_newline).tap do |journable|
          # replace newline character and apply another change
          journable.assign_attributes description: description_with_other_newline
        end
      end

      subject { JournalManager.changed? journable }

      it { should be_false }
    end
  end
end