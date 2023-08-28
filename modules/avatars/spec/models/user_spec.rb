require File.expand_path("#{File.dirname(__FILE__)}/../spec_helper")
require File.expand_path("#{File.dirname(__FILE__)}/../shared_examples")

RSpec.describe User do
  let(:user) { build(:user) }

  include_examples "there are users with and without avatars"

  specify { expect(user.attachments).to all be_a Attachment }

  describe "#local_avatar_attachment" do
    subject { user.local_avatar_attachment }

    context "when user has an avatar" do
      let(:user) { user_with_avatar }

      it { is_expected.to be_a Attachment }
    end

    context "when user has no avatar" do
      let(:user) { user_without_avatar }

      it { is_expected.to be_blank }
    end
  end

  describe "#local_avatar_attachment=" do
    context "when the uploaded file is a good image" do
      subject { lambda { user.local_avatar_attachment = avatar_file } }

      specify { expect { subject.call }.not_to raise_error }
      specify { expect { subject.call }.to change(user, :local_avatar_attachment) }
    end
  end
end
