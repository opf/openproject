require 'spec_helper'

describe 'Work Package table hierarchy and sorting', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }
  let(:sort_by) { ::Components::WorkPackages::SortBy.new }

  let!(:wp_root) do
    FactoryBot.create :work_package,
                      project: project,
                      subject: 'Parent',
                      start_date: Date.today - 10.days,
                      due_date: Date.today
  end

  let!(:wp_child1) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'Child at end',
                      start_date: Date.today - 2.days,
                      due_date: Date.today
  end

  let!(:wp_child2) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'Middle child',
                      start_date: Date.today - 5.days,
                      due_date: Date.today - 3.days
  end

  let!(:wp_child3) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'Child at beginning',
                      start_date: Date.today - 10.days,
                      due_date: Date.today - 9.days
  end

  before do
    login_as(user)
  end

  it 'can show hierarchies and sort by start_date' do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect order to be by IDs
    wp_table.expect_work_package_order wp_root, wp_child1, wp_child2, wp_child3

    # Enable sort by start date
    sort_by.update_criteria ['Start date', 'asc']
    loading_indicator_saveguard

    # Hierarchy still exists
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect order to be by dates
    wp_table.expect_work_package_order wp_root, wp_child3, wp_child2, wp_child1
  end
end
