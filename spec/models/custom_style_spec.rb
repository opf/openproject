require 'spec_helper'

RSpec.describe CustomStyle, type: :model do
  describe "#current" do
    # let(:custom_style) { CustomStyle.create }
    subject { CustomStyle.current }

    # before do
    #   custom_style = CustomStyle.create
    # end


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
      it 'returns nil' do
        expect(subject).to be nil
      end
    end
  end
end
