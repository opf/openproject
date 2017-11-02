require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

class UsersHelperTest
  include UsersHelper
end

describe UsersHelperTest do
  describe "#user_settings_tabs" do
    subject { UsersHelperTest.new.user_settings_tabs }

    context 'when enabled' do
      before do
        allow(::OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return true
      end
      it { is_expected.to include(name: 'avatar', partial: 'avatars/users/avatar_tab', label: :label_avatar) }
    end

    context 'when disabled' do
      before do
        allow(::OpenProject::Avatars::AvatarManager).to receive(:avatars_enabled?).and_return false
      end
      it { is_expected.not_to include(name: 'avatar', partial: 'avatars/users/avatar_tab', label: :label_avatar) }
    end
  end
end
