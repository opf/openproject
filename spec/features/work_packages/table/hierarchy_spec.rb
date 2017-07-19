require 'spec_helper'

describe 'Work Package table hierarchy', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }

  before do
    login_as(user)
  end

  describe 'hierarchies in same project' do
    let(:category) { FactoryGirl.create :category, project: project, name: 'Foo' }

    let!(:wp_root) { FactoryGirl.create(:work_package, project: project) }
    let!(:wp_inter) { FactoryGirl.create(:work_package, project: project, parent: wp_root) }
    let!(:wp_leaf) { FactoryGirl.create(:work_package, project: project, category: category, parent: wp_inter) }
    let!(:wp_other) { FactoryGirl.create(:work_package, project: project) }

    let!(:query) do
      query              = FactoryGirl.build(:query, user: user, project: project)
      query.column_names = ['subject', 'category']
      query.filters.clear
      query.add_filter('category_id', '=', [category.id])
      query.show_hierarchies = true

      query.save!
      query
    end

    it 'shows hierarchy correctly' do
      wp_table.visit!
      wp_table.expect_work_package_listed(wp_root, wp_inter, wp_leaf, wp_other)

      # Hierarchy mode is enabled by default
      hierarchy.expect_hierarchy_at(wp_root, wp_inter)
      hierarchy.expect_leaf_at(wp_leaf, wp_other)

      # Toggling hierarchies hides the inner children
      hierarchy.toggle_row(wp_root)

      # Root, other showing
      wp_table.expect_work_package_listed(wp_root, wp_other)
      # Inter, Leaf hidden
      hierarchy.expect_hidden(wp_inter, wp_leaf)

      # Show all again
      hierarchy.toggle_row(wp_root)
      wp_table.expect_work_package_listed(wp_root, wp_other, wp_inter, wp_leaf)

      # Disable hierarchies
      hierarchy.disable_hierarchy
      hierarchy.expect_no_hierarchies

      # Editing is possible while retaining hierarchy
      hierarchy.enable_hierarchy
      subject = wp_table.edit_field wp_inter, :subject
      subject.update 'New subject'

      wp_table.expect_notification message: 'Successful update.'
      wp_table.dismiss_notification!

      hierarchy.expect_hierarchy_at(wp_root, wp_inter)
      hierarchy.expect_leaf_at(wp_leaf, wp_other)

      # Disable hierarchy again
      hierarchy.disable_hierarchy
      hierarchy.expect_no_hierarchies

      # Now visiting the query for category
      wp_table.visit_query(query)

      # Should only list the matching leaf
      wp_table.expect_work_package_listed(wp_leaf)

      hierarchy.expect_hierarchy_at(wp_root, wp_inter)

      # need to reload wp_inter as we changed the subject
      wp_inter.reload
      wp_table.expect_work_package_listed(wp_root, wp_inter, wp_leaf)

      # Disabling hierarchy hides them again
      hierarchy.disable_hierarchy

      wp_table.expect_work_package_not_listed(wp_root, wp_inter)
    end
  end

  describe 'with a cross project hierarchy' do
    let(:project2) { FactoryGirl.create(:project) }
    let!(:wp_root) { FactoryGirl.create(:work_package, project: project) }
    let!(:wp_inter) { FactoryGirl.create(:work_package, project: project2, parent: wp_root) }
    let(:global_table) { Pages::WorkPackagesTable.new }
    it 'shows the hierarchy indicator only when the rows are both shown' do
      wp_table.visit!
      wp_table.expect_work_package_listed(wp_root)
      wp_table.expect_work_package_not_listed(wp_inter)
      hierarchy.expect_leaf_at(wp_root)

      # Visit global table
      global_table.visit!
      wp_table.expect_work_package_listed(wp_root, wp_inter)
      hierarchy.expect_hierarchy_at(wp_root)
      hierarchy.expect_leaf_at(wp_inter)
    end
  end

  describe 'flat table such that the parent appears below the child' do
    let!(:wp_root) { FactoryGirl.create(:work_package, project: project) }
    let!(:wp_inter) { FactoryGirl.create(:work_package, project: project, parent: wp_root) }
    let!(:wp_leaf) { FactoryGirl.create(:work_package, project: project, parent: wp_inter) }

    let!(:query) do
      query              = FactoryGirl.build(:query, user: user, project: project)
      query.column_names = ['subject', 'category']
      query.filters.clear
      query.show_hierarchies = false

      query.save!
      query
    end

    it 'removes the parent from the flow in hierarchy mode, moving it above' do
      # Hierarchy disabled, expect wp_inter before wp_root
      wp_table.visit_query query
      wp_table.expect_work_package_listed(wp_inter, wp_root, wp_leaf)
      wp_table.expect_work_package_order(wp_inter.id, wp_root.id, wp_leaf.id)

      hierarchy.expect_no_hierarchies

      # Enable hierarchy mode, should move it above now
      hierarchy.enable_hierarchy

      # Should not be marked as additional row (grey)
      expect(page).to have_no_selector('.wp-table--hierarchy-aditional-row')

      hierarchy.expect_hierarchy_at(wp_root, wp_inter)
      hierarchy.expect_leaf_at(wp_leaf)

      wp_table.expect_work_package_listed(wp_inter, wp_root, wp_leaf)
      wp_table.expect_work_package_order(wp_root.id, wp_inter.id, wp_leaf.id)

      # Toggling hierarchies hides the inner children
      hierarchy.toggle_row(wp_root)

      # Root showing
      wp_table.expect_work_package_listed(wp_root)
      # Inter hidden
      hierarchy.expect_hidden(wp_inter, wp_leaf)
    end
  end

  describe 'sorting by assignee' do
    include_context 'work package table helpers'
    let!(:root_assigned) do
      FactoryGirl.create(:work_package, subject: 'root_assigned', project: project, assigned_to: user)
    end
    let!(:inter_assigned) do
      FactoryGirl.create(:work_package, subject: 'inter_assigned', project: project, assigned_to: user, parent: root_assigned)
    end
    let!(:inter) do
      FactoryGirl.create(:work_package, subject: 'inter', project: project, parent: root_assigned)
    end
    let!(:leaf_assigned) do
      FactoryGirl.create(:work_package, subject: 'leaf_assigned', project: project, assigned_to: user, parent: inter)
    end
    let!(:leaf) do
      FactoryGirl.create(:work_package, subject: 'leaf', project: project, parent: inter)
    end
    let!(:root) do
      FactoryGirl.create(:work_package, project: project)
    end

    let(:user) do
      FactoryGirl.create :user,
                         member_in_project: project,
                         member_through_role: role
    end
    let(:permissions) { %i(view_work_packages add_work_packages) }
    let(:role) { FactoryGirl.create :role, permissions: permissions }

    let!(:query) do
      query              = FactoryGirl.build(:query, user: user, project: project)
      query.column_names = ['subject', 'assigned_to']
      query.filters.clear
      query.sort_criteria = [['assigned_to', 'asc']]
      query.show_hierarchies = false

      query.save!
      query
    end

    it 'shows the respective order' do
      wp_table.visit_query query
      wp_table.expect_work_package_listed(leaf, inter, root)
      wp_table.expect_work_package_listed(leaf_assigned, inter_assigned, root_assigned)

      wp_table.expect_work_package_order(
        leaf_assigned.id, inter_assigned.id, root_assigned.id,
        leaf.id, inter.id, root.id
      )

      # Hierarchy should be disabled
      hierarchy.expect_no_hierarchies

      # Enable hierarchy mode, should sort according to spec above
      hierarchy.enable_hierarchy
      hierarchy.expect_hierarchy_at(root_assigned, inter)
      hierarchy.expect_leaf_at(root, leaf, leaf_assigned, inter_assigned)

      # When ascending, order should be:
      # ├──root_assigned
      # |  ├─ inter_assigned
      # |  ├─ inter
      # |  |  ├─ leaf_assigned
      # |  |  ├─ leaf
      # ├──root
      wp_table.expect_work_package_order(
        root_assigned.id,
        inter_assigned.id,
        inter.id,
        leaf_assigned.id,
        leaf.id,
        root.id
      )

      # Test collapsing of rows
      hierarchy.toggle_row(root_assigned)
      wp_table.expect_work_package_listed(root, root_assigned)
      hierarchy.expect_hidden(inter, inter_assigned, leaf, leaf_assigned)
      hierarchy.toggle_row(root_assigned)

      # Sort descending
      sort_wp_table_by 'Assignee', order: :desc
      loading_indicator_saveguard
      wp_table.expect_work_package_listed(root, root_assigned)

      # When descending, order should be:
      # ├──root
      # ├──root
      # |  ├─ inter
      # |  |  ├─ leaf
      # |  |  ├─ leaf_assigned
      # |  ├─ inter_assigned
      wp_table.expect_work_package_order(
        root.id,
        root_assigned.id,
        inter.id,
        inter_assigned.id,
        leaf.id,
        leaf_assigned.id
      )

      # Disable hierarchy mode
      hierarchy.disable_hierarchy

      wp_table.expect_work_package_order(
        leaf.id, inter.id, root.id,
        leaf_assigned.id, inter_assigned.id, root_assigned.id
      )
    end
  end
end
