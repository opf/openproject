require "rails_helper"
require_relative "shared_examples"

RSpec.describe "user notifications settings",
               :js,
               :with_cuprite do
  shared_let(:user) { create(:user) }

  let(:settings_page) { Pages::Notifications::Settings.new(user) }

  before do
    login_as current_user
    settings_page.visit!
  end

  context "as an admin" do
    let(:current_user) { create(:admin) }

    it_behaves_like "notification settings workflow"
  end

  context "as a regular user" do
    let(:current_user) { create(:user) }

    it "does not allow to visit the page" do
      expect(page).to have_text "You are not authorized to access this page."
    end
  end
end
