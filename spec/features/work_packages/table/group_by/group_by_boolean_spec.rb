require 'spec_helper'

describe 'Work Package group by boolean field', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project, types: [type], work_package_custom_fields: [bool_cf]) }
  let(:bool_cf) { FactoryBot.create :bool_wp_custom_field, name: 'booleanField', types: [type] }
  let(:type) { FactoryBot.create(:type) }

  let!(:wp1) { FactoryBot.create(:work_package, project: project, type: type) }
  let!(:wp2) { FactoryBot.create(:work_package, project: project, type: type, custom_field_values: { bool_cf.id => true }) }
  let!(:wp3) { FactoryBot.create(:work_package, project: project, type: type, custom_field_values: { bool_cf.id => false }) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:group_by) { ::Components::WorkPackages::GroupBy.new }

  before do
    login_as(user)
    wp_table.visit!
    wp_table.expect_work_package_listed wp1, wp2, wp3
  end

  it 'shows group headers for groups by bool cf (regression test #34904)' do
    # Group by category
    group_by.enable_via_menu 'booleanField'
    loading_indicator_saveguard

    # Expect table to be grouped
    group_by.expect_number_of_groups 3
    group_by.expect_grouped_by_value '-', 1
    group_by.expect_grouped_by_value 'true', 1
    group_by.expect_grouped_by_value 'false', 1
  end
end
