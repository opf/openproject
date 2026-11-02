# frozen_string_literal: true

require "spec_helper"

# Regression: the placeholder pages used @page, which the core wiki menu partial
# (wiki/_menu_pages_tree, current_page_id: @page&.id) also reads – every placeholder page
# 500'd in projects with the wiki module. Render each page with a wiki that has pages,
# so the wiki menu tree is part of the response.
RSpec.describe "Test management placeholder pages with the wiki module", :skip_csrf, type: :rails_request do
  shared_let(:project) { create(:project, enabled_module_names: %i[wiki test_management]) }
  shared_let(:admin) { create(:admin) }

  before do
    if defined?(Wikis::InternalProvider) && Wikis::InternalProvider.respond_to?(:enabled?)
      allow(Wikis::InternalProvider).to receive(:enabled?).and_return(true)
    end
    wiki = project.wiki || create(:wiki, project:)
    create(:wiki_page, wiki:, title: "Release checklist") unless wiki.pages.exists?
    login_as(admin)
  end

  TestManagement::PlaceholdersController::PAGES.each do |page|
    it "renders the #{page} placeholder" do
      get project_test_management_placeholder_path(project, page:)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(%(data-test-selector="tm-placeholder-#{page}"))
    end
  end

  it "only keeps the CI placeholder" do
    expect(TestManagement::PlaceholdersController::PAGES).to eq(%w[ci])
  end

  it "still 404s for unknown pages" do
    get project_test_management_placeholder_path(project, page: "nope")

    expect(response).to have_http_status(:not_found)
  end
end
