require 'rails_helper'
require_relative '../users/notifications/shared_examples'

describe "My notifications settings", type: :feature, js: true do
  current_user { FactoryBot.create :user }

  before do
    visit my_notifications_path
  end

  it_behaves_like 'notification settings workflow' do
    let(:user) { current_user }
  end
end
