require 'spec_helper'

describe 'Invalid query spec', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }

  let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  let(:member) do
    FactoryGirl.create(:member,
                       user: user,
                       project: project,
                       roles: [FactoryGirl.create(:role)])
  end
  let(:status) do
    FactoryGirl.create(:status)
  end
  let(:status2) do
    FactoryGirl.create(:status)
  end

  let(:invalid_query) do
    query = FactoryGirl.create(:query,
                               project: project,
                               user: user)

    query.add_filter('assigned_to_id', '=', [99999])
    query.columns << 'cf_0815'
    query.group_by = 'cf_0815'
    query.sort_criteria = [['cf_0815', 'desc']]
    query.save(validate: false)

    query
  end

  let(:valid_query) do
    FactoryGirl.create(:query,
                       project: project,
                       user: user)
  end

  let(:work_package_assigned) do
    FactoryGirl.create(:work_package,
                       project: project,
                       status: status2,
                       assigned_to: user)
  end

  before do
    login_as(user)
    status
    status2
    member
    work_package_assigned
  end

  it 'should load a faulty query and also the drop down' do
    wp_table.visit_query(invalid_query)

    filters.open
    filters.expect_filter_count 1
    filters.expect_no_filter_by('Assignee')
    filters.expect_filter_by('Status', 'open', nil)

    wp_table.expect_no_notification(type: :error,
                                    message: I18n.t('js.work_packages.faulty_query.description'))

    wp_table.expect_work_package_listed work_package_assigned

    wp_table.expect_query_in_select_dropdown(invalid_query.name)
  end

  it 'should not load with faulty parameters but can be fixed' do
    filter_props = [{ 'n': 'assignee', 'o': '=', 'v': ['999999'] },
                    { 'n': 'status', 'o': '=', 'v': [status.id.to_s, status2.id.to_s] }]
    column_props = ['id', 'subject', 'customField0815']
    invalid_props = JSON.dump('f': filter_props,
                              'c': column_props,
                              'g': 'customField0815',
                              't': 'customField0815:desc')

    wp_table.visit_with_params("query_id=#{valid_query.id}&query_props=#{invalid_props}")

    filters.open
    filters.expect_filter_count 2
    filters.expect_filter_by('Assignee', 'is', I18n.t('js.placeholders.selection'))
    filters.expect_filter_by('Status', 'is', [status.name, status2.name])

    wp_table.expect_notification(type: :error,
                                 message: I18n.t('js.work_packages.faulty_query.description'))

    wp_table.expect_no_work_package_listed

    wp_table.group_by('Assignee')
    sleep(0.3)
    filters.set_filter('Assignee', 'is', user.name)
    sleep(0.3)

    wp_table.expect_work_package_listed work_package_assigned
    wp_table.save

    wp_table.expect_notification(message: I18n.t('js.notice_successful_update'))
  end
end
