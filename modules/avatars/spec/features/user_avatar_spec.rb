require 'spec_helper'
require_relative './shared_avatar_examples'

describe 'User avatar management', type: :feature, js: true do
  include Rails.application.routes.url_helpers

  let(:user) { FactoryBot.create :admin }
  let(:avatar_management_path) { edit_user_path(target_user, tab: 'avatar') }

  before do
    login_as user
  end

  context 'when user is admin' do
    let(:target_user) { FactoryBot.create :user }
    it_behaves_like 'avatar management'
  end

  context 'when user is self' do
    let(:user) { FactoryBot.create :user }
    let(:target_user) { user }
    it 'forbids the user to access' do
      visit avatar_management_path
      expect(page).to have_text('[Error 403]')
    end
  end

  context 'when user is another user' do
    let(:target_user) { FactoryBot.create :user }
    let(:user) { FactoryBot.create :user }

    it 'forbids the user to access' do
      visit avatar_management_path
      expect(page).to have_text('[Error 403]')
    end
  end

  describe 'none enabled' do
    let(:target_user) { FactoryBot.create :user }

    before do
      allow(Setting)
        .to receive(:plugin_openproject_avatars)
        .and_return({})
    end

    it 'does not render the user edit tab' do
      visit edit_user_path(user)
      expect(page).to have_no_selector '#tab-avatar'
    end
  end
end
