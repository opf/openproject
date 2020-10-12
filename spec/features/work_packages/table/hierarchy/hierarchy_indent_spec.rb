require 'spec_helper'

describe 'Work Package table hierarchy and sorting', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:project) { FactoryBot.create(:project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:hierarchy) { ::Components::WorkPackages::Hierarchies.new }
  let(:representation) { ::Components::WorkPackages::DisplayRepresentation.new }
  let(:sort_by) { ::Components::WorkPackages::SortBy.new }

  let!(:wp_root) do
    FactoryBot.create :work_package,
                      project: project,
                      subject: 'Parent'
  end

  let!(:wp_child1) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'WP child 1'
  end

  let!(:wp_child2) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'WP child 2'
  end

  let!(:wp_child3) do
    FactoryBot.create :work_package,
                      project: project,
                      parent: wp_root,
                      subject: 'WP child 3'
  end

  before do
    login_as(user)
  end

  it 'can indent hierarchies' do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    # Expect indent-able for all except wp_root wp_child
    hierarchy.expect_indent(wp_root, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: true)
    hierarchy.expect_indent(wp_child2, indent: true, outdent: true)
    hierarchy.expect_indent(wp_child3, indent: true, outdent: true)

    # Indent last child
    hierarchy.indent! wp_child3

    wp_table.expect_and_dismiss_notification message: 'Successful update.'

    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    # Remove first child
    hierarchy.outdent! wp_child1
    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    sleep 1

    wp_child1.reload
    expect(wp_child1.parent).to be_nil

    wp_child3.reload
    expect(wp_child3.parent).to eq(wp_child2)
  end

  it 'does not show indentation context in card view' do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)

    representation.switch_to_card_layout
    expect(page).to have_selector('.wp-card', count: 4)

    # Expect indent-able for none
    hierarchy.expect_indent(wp_root, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child1, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child2, indent: false, outdent: false)
    hierarchy.expect_indent(wp_child3, indent: false, outdent: false)
  end

  it 'can edit a work package, then indent, and then edit again (Regression #30994)' do
    wp_table.visit!
    wp_table.expect_work_package_listed(wp_root, wp_child1, wp_child2, wp_child3)
    hierarchy.expect_hierarchy_at(wp_root)
    hierarchy.expect_leaf_at(wp_child1, wp_child2, wp_child3)

    subject = wp_table.edit_field(wp_child3, :subject)
    subject.update 'First edit'
    wp_table.expect_and_dismiss_notification message: 'Successful update.'

    # Wait a bit before moving
    sleep 2

    # Indent last child
    hierarchy.indent! wp_child3
    wp_table.expect_and_dismiss_notification message: 'Successful update.'

    # Expect changed
    hierarchy.expect_hierarchy_at(wp_root, wp_child2)
    hierarchy.expect_leaf_at(wp_child1, wp_child3)

    # Wait a bit again
    sleep 2

    subject = wp_table.edit_field(wp_child3, :subject)
    subject.update 'Second edit'
    wp_table.expect_and_dismiss_notification message: 'Successful update.'

    sleep 2
    wp_child3.reload
    expect(wp_child3.subject).to eq 'Second edit'
    expect(wp_child3.parent).to eq wp_child2
  end
end
