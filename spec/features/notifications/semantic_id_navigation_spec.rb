# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Notification center uses displayId when navigating to the work package",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  # Classic mode is a behavioural no-op: the URL helpers and the
  # resolveRoutingId bridge both collapse to the numeric id when semantic
  # mode is off. Covering semantic-only where the bug actually manifests.

  let(:project)      { create(:project, identifier: "NOTIFNAV") }
  let(:work_package) { create(:work_package, project:, subject: "Semantic notif WP") }
  let(:recipient) do
    create(:user, member_with_permissions: { project => %i[view_work_packages] })
  end
  let(:notification) do
    create(:notification,
           recipient:,
           resource: work_package,
           journal: work_package.journals.last)
  end

  let(:center) { Pages::Notifications::Center.new }
  let(:split_screen) { Pages::PrimerizedSplitWorkPackage.new(work_package) }

  current_user { recipient }

  before do
    work_package.allocate_and_register_semantic_id
    notification # realise
  end

  it "opens the split view at the semantic identifier URL" do
    semantic_id = work_package.reload.identifier
    visit notifications_path

    center.click_item(notification)
    split_screen.expect_open

    expect(page).to have_current_path(
      "/notifications/details/#{semantic_id}/activity"
    )
    center.expect_item_selected(notification)
  end

  it "renders the notification's WP link with the semantic identifier in its href" do
    semantic_id = work_package.reload.identifier
    visit notifications_path

    # Wait for the entry to finish loading the WP
    expect(page).to have_css(".op-ian-item--work-package-id-link", text: semantic_id)
    link = page.find(".op-ian-item--work-package-id-link")

    expect(link[:href]).to include("/work_packages/#{semantic_id}")
    expect(link[:href]).not_to include("/work_packages/#{work_package.id}")
  end
end
