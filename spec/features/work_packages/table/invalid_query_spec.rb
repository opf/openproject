require 'spec_helper'

describe 'Invalid query spec', js: true do
  let(:user) { FactoryGirl.create :admin }
  let(:project) { FactoryGirl.create :project }

  let(:wp_table) { ::Pages::WorkPackagesTable.new }
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

  let(:query) do
    query = FactoryGirl.create(:query,
                               project: project,
                               user: user)

    query.add_filter('assigned_to_id', '=', [99999])
    query.save!(validate: false)

    query
  end

  before do
    login_as(user)
    status
    member

    wp_table.visit_query(query)
  end

  # Regression test for bug #24114 (broken watcher filter)
  it 'should load the faulty query' do
    expect(page).to have_selector(".notification-box.-error", text: I18n.t('js.work_packages.faulty_query.description'), wait: 10)

    filters.open
    filters.expect_filter_count 2
    expect(page).to have_select('values-assignee', selected: I18n.t('js.placeholders.selection'))
  end
end
