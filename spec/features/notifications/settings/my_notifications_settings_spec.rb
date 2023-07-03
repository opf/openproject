require 'rails_helper'
require_relative '../../users/notifications/shared_examples'
require 'support/pages/my/notifications'

RSpec.describe "My notifications settings", js: true, with_cuprite: true do
  current_user { create(:user) }

  let(:settings_page) { Pages::My::Notifications.new(current_user) }

  before do
    settings_page.visit!
  end

  it_behaves_like 'notification settings workflow' do
    let(:user) { current_user }
  end
end
