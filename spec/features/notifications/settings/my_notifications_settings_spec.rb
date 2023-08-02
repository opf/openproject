require 'rails_helper'
require_relative '../../users/notifications/shared_examples'
require 'support/pages/my/notifications'

describe "My notifications settings", js: true do
  shared_let(:user) { create(:user) }

  let(:settings_page) { Pages::My::Notifications.new(user) }

  before do
    login_as user
    settings_page.visit!
  end

  it_behaves_like 'notification settings workflow'
end
