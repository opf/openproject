require 'spec_helper'

describe 'Work Package table group headers', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let(:category) { FactoryBot.create :category, project: project, name: 'Foo' }
  let(:category2) { FactoryBot.create :category, project: project, name: 'Bar' }

  let!(:wp_cat1) { FactoryBot.create(:work_package, project: project, category: category) }
  let!(:wp_cat2) { FactoryBot.create(:work_package, project: project, category: category2) }
  let!(:wp_none) { FactoryBot.create(:work_package, project: project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }

  let!(:query) do
    query              = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject', 'category']
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)

    wp_table.visit_query(query)
    wp_table.expect_work_package_listed(wp_cat1)
    wp_table.expect_work_package_listed(wp_cat2)
    wp_table.expect_work_package_listed(wp_none)
  end

  it 'shows group headers for group by category' do
    # Group by category
    group_by.enable_via_menu 'Category'

    # Expect table to be grouped as WP created above
    expect(page).to have_selector('.group--value .count', count: 3)
    expect(page).to have_selector('.group--value', text: 'Foo (1)')
    expect(page).to have_selector('.group--value', text: 'Bar (1)')
    expect(page).to have_selector('.group--value', text: '- (1)')

    # Update category of wp_none
    cat = wp_table.edit_field(wp_none, :category)
    cat.activate!
    cat.set_value 'Foo'

    loading_indicator_saveguard

    # Expect changed groups
    expect(page).to have_selector('.group--value .count', count: 2)
    expect(page).to have_selector('.group--value', text: 'Foo (2)')
    expect(page).to have_selector('.group--value', text: 'Bar (1)')
  end
end
