require 'spec_helper'
require_relative '../../../../../spec/features/work_packages/table/context_menu/context_menu_shared_examples'
require_relative '../../support/pages/ifc_models/show_default'

RSpec.describe 'Work Package table hierarchy and sorting', :js, :with_cuprite, with_config: { edition: 'bim' } do
  shared_let(:project) { create(:project) }

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }

  shared_let(:wp_root) do
    create(:work_package,
           project:,
           subject: 'Parent')
  end

  shared_let(:wp_child1) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: 'WP child 1')
  end

  shared_let(:wp_child2) do
    create(:work_package,
           project:,
           parent: wp_root,
           subject: 'WP child 2')
  end

  shared_current_user { create(:admin) }

  it 'does not show indentation context in card view' do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2)

    wp_table.switch_view 'Cards'
    expect(page).to have_test_selector('op-wp-single-card', count: 3)

    # Expect indent-able for none
    hierarchy.expect_indent(wp_root, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child2, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child3, indent: false, outdent: false)
  end

  it_behaves_like 'provides a single WP context menu' do
    let(:open_context_menu) do
      -> {
        # Go to table
        wp_table.visit!
        wp_table.expect_work_package_listed(wp_root)

        wp_table.switch_view 'Cards'
        loading_indicator_saveguard

        # Open context menu
        menu.expect_closed
        menu.open_for(wp_root)
      }
    end
  end
end
