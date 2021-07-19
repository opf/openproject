require 'rails_helper'
require_relative './shared_examples'

describe "user notifications settings", type: :feature, js: true do
  shared_let(:user) { FactoryBot.create :user }

  let(:settings_page) { ::Pages::Notifications::Settings.new(user) }

  before do
    login_as current_user
    settings_page.visit!
  end

  context 'as admin' do
    let(:current_user) { FactoryBot.create :admin }

    it_behaves_like 'notification settings workflow'
  end

  context 'as regular user' do
    let(:current_user) { FactoryBot.create :user }

    it 'does not allow to visit the page' do
      expect(page).to have_text 'You are not authorized to access this page.'
    end
  end
end
