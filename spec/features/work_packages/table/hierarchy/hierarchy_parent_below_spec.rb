require "spec_helper"

RSpec.describe "Work Package table hierarchy parent below", :js do
  let(:user) { create(:admin) }
  let(:type_bug) { create(:type_bug) }
  let(:type_task) { create(:type_task) }
  let(:project) { create(:project, types: [type_task, type_bug]) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { Components::WorkPackages::Hierarchies.new }

  before do
    login_as(user)
  end

  ##
  # Regression test for WP#26772
  # Assume the following work package
  # ID      | Subject     | Type
  # ---------------------------
  # N       | Child       | Task
  # N+1     | Parent      | Bug
  # N+2     | Grandparent | Task
  #
  # And the following query:
  # Filter Type = Task
  # Sort by ID asc
  # Hierarchy mode ON
  #
  #
  # You would see the ID N+2 Grantparent twice in the table
  # V Grandparent
  # .. V Parent
  # .... Child
  # V Grandparent
  describe "grand-parent sorted below child, parent invisible" do
    let(:child) { create(:work_package, project:, type: type_task) }
    let(:parent) { create(:work_package, project:, type: type_bug) }
    let(:grandparent) { create(:work_package, project:, type: type_task) }

    let(:query) do
      query              = build(:query, user:, project:)
      query.column_names = ["id", "subject", "type"]
      query.sort_criteria = [%w(id asc)]
      query.filters.clear
      query.add_filter("type_id", "=", [type_task.id])
      query.show_hierarchies = true

      query.save!
      query
    end

    before do
      child
      parent
      grandparent

      child.update(parent_id: parent.id)
      parent.update(parent_id: grandparent.id)

      query
    end

    it "shows hierarchy correctly" do
      wp_table.visit_query query
      wp_table.expect_work_package_listed(child, parent, grandparent)

      # Double order result from regression
      # wp_table.expect_work_package_order(child.id, parent.id, grandparent.id, grandparent.id)
      wp_table.expect_work_package_order(grandparent.id, parent.id, child.id)

      # Enable hierarchy mode, should sort according to spec above
      hierarchy.expect_hierarchy_at(grandparent, parent)
      hierarchy.expect_leaf_at(child)

      # Test collapsing of rows
      hierarchy.toggle_row(parent)
      wp_table.expect_work_package_listed(grandparent, parent)
      hierarchy.expect_hidden(child)
      hierarchy.toggle_row(grandparent)
      hierarchy.expect_hidden(parent)
      hierarchy.toggle_row(grandparent)
      hierarchy.toggle_row(parent)
      wp_table.expect_work_package_listed(grandparent, parent, child)
      wp_table.expect_work_package_order(grandparent.id, parent.id, child.id)

      # Disable hierarchy
      hierarchy.disable_hierarchy
      hierarchy.expect_no_hierarchies

      wp_table.expect_work_package_listed(child, grandparent)
      wp_table.expect_work_package_order(child.id, grandparent.id)
    end
  end

  describe "grand-parent of 2+ children visible anywhere on the page, but parent is not (Regression #29652)" do
    let(:child) { create(:work_package, subject: "AA Child WP", project:, type: type_task) }
    let(:child2) { create(:work_package, subject: "BB Child WP", project:, type: type_task) }
    let(:parent) { create(:work_package, subject: "ZZ Parent WP", project:, type: type_task) }
    let(:grandparent) { create(:work_package, subject: "Grandparent", project:, type: type_task) }

    let(:query) do
      query              = build(:query, user:, project:)
      query.column_names = %w(id subject)
      query.sort_criteria = [%w(subject asc), %w(id asc)]
      query.show_hierarchies = true

      query.save!
      query
    end

    before do
      child
      parent
      grandparent

      child.update(parent_id: parent.id)
      child2.update(parent_id: parent.id)
      parent.update(parent_id: grandparent.id)

      allow(Setting).to receive(:per_page_options).and_return "3"
      query
    end

    it "shows hierarchy correctly" do
      wp_table.visit_query query

      wp_table.expect_work_package_listed(child, child2, parent, grandparent)

      # Expect pagination to be correct
      expect(page).to have_css(".op-pagination--item_current", text: "3")

      # Expect count to be correct (one additional parent shown)
      expect(page).to have_css(".wp--row", count: 4)

      # Double order result from regression
      wp_table.expect_work_package_order(grandparent.id, parent.id, child.id, child2.id)

      # Enable hierarchy mode, should sort according to spec above
      hierarchy.expect_hierarchy_at(grandparent, parent)
      hierarchy.expect_leaf_at(child, child2)
    end
  end

  describe "An arrow is beside parent name" do
    let(:child) { create(:work_package, subject: "AA Child WP", project:, parent:) }
    let(:parent) { create(:work_package, subject: "ZZ Parent WP", project:) }
    let(:relations) { Components::WorkPackages::Relations.new(parent) }

    before do
      child
    end

    it 'and it should not be shown when children are removed "#33109"' do
      wp_table.visit!
      wp_table.expect_work_package_listed(child, parent)

      expect(page).to have_css(".wp-table--hierarchy-indicator-icon")

      split_page = wp_table.open_split_view(parent)
      split_page.visit_tab!("relations")
      relations.remove_child(child)
      loading_indicator_saveguard

      expect(page).to have_no_css(".wp-table--hierarchy-indicator-icon")
    end
  end
end
