require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe ::Avatars::UpdateService do
  let(:user_without_avatar) { FactoryBot.build_stubbed :user }
  let(:user_with_avatar) do
    u = FactoryBot.create :user
    u.attachments = [FactoryBot.build(:avatar_attachment, author: u)]
    u
  end

  let(:instance) { described_class.new user }

  describe 'replace' do
  end

  describe 'delete' do
    subject { instance.destroy }

    context 'user has avatar' do
      let(:user) { user_with_avatar }

      it 'destroys the attachment' do
        expect_any_instance_of(Attachment).to receive(:destroy).and_return true
        expect(subject).to be_success
      end
    end

    context 'user has no avatar' do
      let(:user) { user_without_avatar }

      it 'returns an error' do
        expect(subject).not_to be_success
        expect(subject.errors[:base]).to include I18n.t(:unable_to_delete_avatar)
      end
    end
  end
end
