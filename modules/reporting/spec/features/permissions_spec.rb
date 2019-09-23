require 'spec_helper'
require_relative 'support/pages/cost_report_page'

describe 'Cost report calculations', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:admin) { FactoryBot.create :admin }

  let!(:permissions) { %i(view_cost_entries view_own_cost_entries) }
  let!(:role) { FactoryBot.create :role, permissions: permissions }
  let!(:user) do
    FactoryBot.create :user,
                       member_in_project: project,
                       member_through_role: role
  end

  let(:work_package) { FactoryBot.create :work_package, project: project }
  let!(:hourly_rate_admin) { FactoryBot.create :default_hourly_rate, user: admin, rate: 1.00, valid_from: 1.year.ago }
  let!(:hourly_rate_user) { FactoryBot.create :default_hourly_rate, user: user, rate: 1.00, valid_from: 1.year.ago }

  let(:report_page) { ::Pages::CostReportPage.new project }

  let!(:time_entry_user) {
    FactoryBot.create :time_entry,
                       user: admin,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }
  let!(:time_entry_admin) {
    FactoryBot.create :time_entry,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 5
  }
  let!(:cost_type) {
    type = FactoryBot.create :cost_type, name: 'Translations'
    FactoryBot.create :cost_rate, cost_type: type, rate: 7.00
    type
  }
  let!(:cost_entry_user) {
    FactoryBot.create :cost_entry,
                       work_package: work_package,
                       project: project,
                       units: 3.00,
                       cost_type: cost_type,
                       user: user
  }

  before do
    login_as current_user
    visit '/cost_reports?set_filter=1'
  end

  context 'as anonymous' do
    let(:current_user) { User.anonymous }
    it 'is redirect to login' do
      expect(page).to have_content 'Username'
      expect(page).to have_content 'Password'
    end
  end

  context 'as admin' do
    let(:current_user) { admin }

    it 'shows everything' do
      expect(page).to have_content '5.00 hours'
      expect(page).to have_content '10.00 hours'

      report_page.switch_to_type 'Translations'

      expect(page).to have_content '3.0 plural_unit'
      expect(page).to have_content '21.00 EUR'
    end
  end

  context 'as user with all permissions' do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_hourly_rate  view_hourly_rates view_cost_rates
         view_own_time_entries view_own_cost_entries view_cost_entries
         view_time_entries)
    end

    it 'shows everything' do
      expect(page).to have_content '5.00 hours'
      expect(page).to have_content '10.00 hours'
      report_page.switch_to_type 'Translations'
      expect(page).to have_selector('td.units', text: '3.0 plural_unit', wait: 10)
    end
  end

  context 'as user with no permissions' do
    let(:current_user) { user }
    let!(:permissions) { %i() }

    it 'shows nothing' do
      expect(page).to have_text '[Error 403]'
    end
  end

  context 'as user with own permissions' do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_hourly_rate  view_own_time_entries view_own_cost_entries)
    end

    it 'shows his own costs' do
      expect(page).to have_content '5.00 hours'
      expect(page).not_to have_content '10.00 hours'
      report_page.switch_to_type 'Translations'
      expect(page).to have_selector('td.units', text: '3.0 plural_unit', wait: 10)
    end
  end

  context 'as user with own time permissions' do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_time_entries)
    end

    it 'shows his own time only' do
      expect(page).to have_content '5.00 hours'
      expect(page).not_to have_content '10.00 hours'

      report_page.switch_to_type 'Translations'
      expect(page).to have_selector('.generic-table--no-results-title')
      expect(page).to have_no_selector('td.unit', text: '3.0 plural_unit')
    end
  end
  context 'as user with own costs permissions' do
    let(:current_user) { user }
    let!(:permissions) do
      %i(view_own_cost_entries)
    end

    it 'shows his own costs' do
      expect(page).to have_selector('.generic-table--no-results-title')
      expect(page).not_to have_content '5.00 hours'
      expect(page).not_to have_content '10.00 hours'
      report_page.switch_to_type 'Translations'
      expect(page).to have_no_selector('td.unit', text: '3.0 plural_unit')
    end
  end
end
