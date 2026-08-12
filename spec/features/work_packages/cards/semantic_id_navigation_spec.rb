# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package card ID link uses displayId",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  # Classic mode is a behavioural no-op here: the card href is built via
  # `workPackage.displayId`, which returns the numeric id in classic mode — i.e.
  # the same value the pre-fix code (`workPackage.id`) used. Covering only
  # semantic mode where the bug actually manifests.

  let(:admin)        { create(:admin) }
  let(:project)      { create(:project, identifier: "NAVTEST") }
  let(:work_package) { create(:work_package, project:, subject: "Card semantic nav") }
  let(:wp_cards)     { Pages::WorkPackageCards.new(project) }

  current_user { admin }

  include_context "with mobile screen size"

  before do
    work_package
    Pages::WorkPackagesTable.new(project).visit!
    wp_cards.expect_work_package_listed(work_package)
  end

  it "renders an href that contains the semantic identifier" do
    semantic_id = work_package.reload.identifier

    card_link = page.find(".op-wp-single-card-#{work_package.id} .__ui-state-link")

    expect(card_link[:href]).to include("/work_packages/#{semantic_id}/")
    expect(card_link[:href]).not_to include("/work_packages/#{work_package.id}/")
  end
end
