require "spec_helper"
require_relative "../../../../../spec/features/work_packages/table/context_menu/context_menu_shared_examples"
require_relative "../../support/pages/ifc_models/show_default"

RSpec.describe "Work Package table hierarchy and sorting", :js, :with_cuprite, with_config: { edition: "bim" } do
  shared_let(:project) { create(:project, enabled_module_names: %i[bim work_package_tracking costs]) }

  let(:wp_table) { Pages::IfcModels::ShowDefault.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }

  shared_let(:work_package) do
    create(:work_package,
           project:,
           subject: "Parent")
  end

  shared_let(:wp_child1) do
    create(:work_package,
           project:,
           parent: work_package,
           subject: "WP child 1")
  end

  shared_let(:wp_child2) do
    create(:work_package,
           project:,
           parent: work_package,
           subject: "WP child 2")
  end
  shared_let(:menu) { Components::WorkPackages::ContextMenu.new }

  shared_current_user { create(:admin) }

  it "does not show indentation context in card view" do
    wp_table.visit!
    loading_indicator_saveguard
    wp_table.expect_work_package_listed(work_package, wp_child1, wp_child2)

    wp_table.switch_view "Cards"
    expect(page).to have_test_selector("op-wp-single-card", count: 3)

    # Expect indent-able for none
    hierarchy.expect_indent(work_package, indent: false, outdent: false, card_view: true)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: false, card_view: true)
    hierarchy.expect_indent(wp_child2, indent: false, outdent: false, card_view: true)
  end

  it_behaves_like "provides a single WP context menu" do
    let(:open_context_menu) do
      -> {
        # Go to table
        wp_table.visit!
        loading_indicator_saveguard

        wp_table.expect_work_package_listed(work_package)

        wp_table.switch_view "Cards"
        loading_indicator_saveguard

        # Open context menu
        menu.expect_closed
        menu.open_for(work_package, card_view: true)
      }
    end
  end
end
