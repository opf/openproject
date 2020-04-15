require 'spec_helper'

describe 'Work Package table configuration modal filters spec', js: true do
  let(:user) { FactoryBot.create :admin }

  let(:project) { FactoryBot.create(:project) }
  let!(:wp_1) { FactoryBot.create(:work_package, project: project) }

  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:modal) { ::Components::WorkPackages::TableConfigurationModal.new }
  let(:filters) { ::Components::WorkPackages::TableConfiguration::Filters.new }

  let!(:query) do
    query = FactoryBot.build(:query, user: user, project: project)
    query.column_names = ['subject', 'done_ratio']

    query.save!
    query
  end

  before do
    login_as(user)
  end

  context 'by version in project' do
    let(:version) { FactoryBot.create :version, project: project }
    let(:work_package_with_version) { FactoryBot.create :work_package, project: project, version: version }
    let(:work_package_without_version) { FactoryBot.create :work_package, project: project }

    before do
      work_package_with_version
      work_package_without_version

      wp_table.visit!
    end

    it 'allows filtering, saving, retrieving and altering the saved filter' do
      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version
      filters.open

      filters.expect_filter_count 2
      filters.add_filter_by('Version', 'is', version.name)
      filters.save

      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version

      wp_table.save_as('Some query name')

      filters.open
      filters.expect_filter_count 3
      filters.remove_filter 'version'
      filters.save

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version, work_package_without_version

      last_query = Query.last

      wp_table.visit_query(last_query)

      loading_indicator_saveguard
      wp_table.expect_work_package_listed work_package_with_version
      wp_table.ensure_work_package_not_listed! work_package_without_version
    end
  end
end
