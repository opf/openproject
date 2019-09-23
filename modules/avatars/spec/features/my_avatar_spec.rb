require 'spec_helper'
require_relative './shared_avatar_examples'

describe 'My avatar management', type: :feature, js: true do
  include Rails.application.routes.url_helpers

  let(:user) { FactoryBot.create :user }
  let(:target_user) { user }
  let(:avatar_management_path) { edit_my_avatar_path }

  before do
    login_as user
  end

  it_behaves_like 'avatar management'

  describe 'none enabled' do
    before do
      allow(Setting)
        .to receive(:plugin_openproject_avatars)
        .and_return({})
    end

    it 'renders 404 when visiting and does not render the menu item' do
      visit edit_my_avatar_path
      expect(page).to have_text '[Error 404]'

      visit my_account_path
      expect(page).to have_no_selector '.avatar-menu-item'
    end
  end
end
