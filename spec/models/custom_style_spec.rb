require 'spec_helper'

RSpec.describe CustomStyle, type: :model do
  describe "#current" do
    subject { CustomStyle.current }

    context "there is one in DB" do
      it 'returns an instance' do
        CustomStyle.create
        expect(subject).to be_a CustomStyle
      end

      it 'returns the same instance for subsequent calls' do
        CustomStyle.create
        first_instance = CustomStyle.current
        expect(subject).to be first_instance
      end
    end

    context "there is none in DB" do
      before do
        RequestStore.delete(:current_custom_style)
      end
      it 'returns nil' do
        expect(subject).to be nil
      end
    end
  end
end
