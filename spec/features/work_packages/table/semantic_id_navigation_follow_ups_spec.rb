# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Work package table navigation follow-ups use displayId",
               :js,
               :with_cuprite,
               with_settings: { work_packages_identifier: "semantic" } do
  # Classic mode is a behavioural no-op for each of these fixes:
  # `workPackage.displayId` and `resolveRoutingId(...)` both collapse to the
  # numeric id when semantic mode is off. Covering semantic-only where the
  # bugs manifest.

  let(:admin) { create(:admin) }
  let(:project) { create(:project, identifier: "NAVFOLLOW") }

  let(:work_package) { create(:work_package, project:, subject: "First WP") }
  let(:other_wp)     { create(:work_package, project:, subject: "Other WP") }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:context_menu) { Components::WorkPackages::ContextMenu.new }

  current_user { admin }

  before do
    work_package
    other_wp
    wp_table.visit!
    wp_table.expect_work_package_listed(work_package, other_wp)
  end

  describe "row 'Open details view' anchor" do
    it "renders an href that contains the semantic identifier (not the literal string 'null')" do
      semantic_id = work_package.reload.identifier

      details_anchor = within(wp_table.row(work_package)) do
        find_link(title: "Open details view", visible: :all)
      end

      expect(details_anchor[:href]).to include("/details/#{semantic_id}")
      expect(details_anchor[:href]).not_to end_with("/null")
      expect(details_anchor[:href]).not_to include("/details/#{work_package.id}")
    end
  end

  describe "right-click context menu 'Open fullscreen' item" do
    it "links to the semantic identifier URL" do
      semantic_id = work_package.reload.identifier
      context_menu.open_for(work_package)

      open_fullscreen = page.find(:menuitem, text: "Open fullscreen view", exact_text: true)

      expect(open_fullscreen[:href]).to include("/work_packages/#{semantic_id}/")
      expect(open_fullscreen[:href]).not_to include("/work_packages/#{work_package.id}/")
    end
  end

  describe "right-click context menu 'Copy link to clipboard' item" do
    it "copies a URL containing the semantic identifier" do
      semantic_id = work_package.reload.identifier

      # Spy directly on navigator.clipboard.writeText — the existing
      # have_message_copied_to_clipboard matcher only inspects the flash DOM,
      # which can't distinguish numeric vs semantic ids in the copied value.
      page.execute_script(<<~JS)
        window.__lastCopiedText = null;
        navigator.clipboard.writeText = function(text) {
          window.__lastCopiedText = text;
          return Promise.resolve();
        };
      JS

      context_menu.open_for(work_package)
      context_menu.choose("Copy link to clipboard")

      copied = nil
      retry_block do
        copied = page.evaluate_script("window.__lastCopiedText")
        raise "clipboard write not yet observed" if copied.nil?
      end

      expect(copied).to include("/wp/#{semantic_id}")
      expect(copied).not_to include("/wp/#{work_package.id}")
    end
  end

  describe "toolbar info icon" do
    it "opens the split view at the semantic identifier URL" do
      semantic_id = work_package.reload.identifier

      # Focus the row without opening split
      wp_table.row(work_package).click

      # Wait until the row is actually selected before clicking the toolbar
      # button. The toolbar reads wpTableFocus.focusedWorkPackage, which is
      # written by the same handler that toggles the `-checked` class — so
      # the class is a reliable sync point for both pieces of state.
      expect(page).to have_css(
        %(.wp-table--row.-checked[data-work-package-id="#{work_package.id}"])
      )

      page.find_by_id("work-packages-details-view-button").click

      expect(page).to have_current_path(
        %r{/details/#{Regexp.escape(semantic_id)}($|/|\?)}
      )
    end
  end

  describe "clicking a different row while split view is open" do
    it "switches the URL to the newly focused WP's semantic identifier" do
      wp_semantic_id = work_package.reload.identifier
      other_semantic_id = other_wp.reload.identifier

      # Open split view on the first WP
      wp_table.open_split_view(work_package)
      expect(page).to have_current_path(
        %r{/details/#{Regexp.escape(wp_semantic_id)}($|/|\?)}
      )

      # Click the other row
      wp_table.row(other_wp).click

      expect(page).to have_current_path(
        %r{/details/#{Regexp.escape(other_semantic_id)}($|/|\?)}
      )
      expect(page).to have_no_current_path(
        %r{/details/#{other_wp.id}($|/|\?)}
      )
    end
  end
end
