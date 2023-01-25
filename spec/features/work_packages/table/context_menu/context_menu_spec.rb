require 'spec_helper'
require_relative 'context_menu_shared_examples'

describe 'Work package table context menu', js: true do
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package) }

  let(:wp_table) { Pages::WorkPackagesTable.new(work_package.project) }
  let(:wp_timeline) { Pages::WorkPackagesTimeline.new(work_package.project) }
  let(:menu) { Components::WorkPackages::ContextMenu.new }
  let(:display_representation) { Components::WorkPackages::DisplayRepresentation.new }

  before do
    login_as(user)
    work_package
  end

  context 'when in the table' do
    it_behaves_like 'provides a single WP context menu' do
      let(:open_context_menu) do
        -> {
          # Go to table
          wp_table.visit!
          wp_table.expect_work_package_listed(work_package)
          loading_indicator_saveguard

          # Open context menu
          menu.expect_closed
          menu.open_for(work_package)
        }
      end

      it 'provides a context menu with timeline options' do
        open_context_menu.call
        # Open timeline
        wp_timeline.toggle_timeline
        wp_timeline.expect_timeline!(open: true)

        # Open context menu
        menu.expect_closed
        menu.open_for(work_package)
        menu.expect_options ['Add predecessor', 'Add follower']
      end

      context 'for multiple selected WPs' do
        let!(:work_package2) { create(:work_package, project: work_package.project) }

        it 'provides a context menu with a subset of the available menu items' do
          # Go to table
          wp_table.visit!
          wp_table.expect_work_package_listed(work_package)
          wp_table.expect_work_package_listed(work_package2)

          loading_indicator_saveguard

          # Select all WPs
          find('body').send_keys [:control, 'a']

          menu.open_for(work_package)
          menu.expect_options ['Open details view', 'Open fullscreen view',
                               'Bulk edit', 'Bulk copy', 'Bulk change of project', 'Bulk delete']
        end
      end
    end
  end

  context 'when in the card view' do
    it_behaves_like 'provides a single WP context menu' do
      let(:open_context_menu) do
        -> {
          # Go to table
          wp_table.visit!
          wp_table.expect_work_package_listed(work_package)

          display_representation.switch_to_card_layout
          loading_indicator_saveguard

          # Open context menu
          menu.expect_closed
          menu.open_for(work_package)
        }
      end
    end
  end
end
