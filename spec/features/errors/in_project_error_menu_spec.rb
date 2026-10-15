# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Side menu on in-project error pages" do
  shared_let(:project) { create(:project, :with_internal_wiki) }

  context "when a page is missing inside a project" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_wiki_pages] }) }

    before do
      login_as(user)
      visit "/projects/#{project.identifier}/wiki/no-such-page"
    end

    it "renders the 404 page" do
      expect(page).to have_text "The page you were trying to access doesn't exist or has been removed."
    end

    # The page is gone, the project is not, so the navigation stays reachable.
    it "keeps the project side menu" do
      expect(page).to have_css "#main-menu"
    end
  end

  context "when the user may not see the page inside a project" do
    let(:user) { create(:user, member_with_permissions: { project => %i[view_project] }) }

    before do
      login_as(user)
      visit project_settings_general_path(project)
    end

    it "renders the 403 page" do
      expect(page).to have_text "You are not authorized to access this page."
    end

    # Unlike a 404, an authorization failure drops the project: its structure is
    # part of what the user may not see.
    it "renders no side menu" do
      expect(page).to have_no_css "#main-menu"
    end
  end
end
