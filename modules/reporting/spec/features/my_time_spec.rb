require 'spec_helper'

describe 'Cost report showing my own times', type: :feature, js: true do
  let(:project) { create :project }
  let(:user) { create :admin }
  let(:user2) { create :admin }

  let(:work_package) { create :work_package, project: project }
  let!(:hourly_rate1) { create :default_hourly_rate, user: user, rate: 1.00, valid_from: 1.year.ago }

  let!(:time_entry1) do
    create :time_entry,
                      user: user,
                      work_package: work_package,
                      project: project,
                      hours: 10
  end

  before do
    login_as(current_user)
    visit cost_reports_path(project)
  end

  context 'as user with logged time' do
    let(:current_user) { user }
    it 'shows my time' do
      expect(page).to have_selector('.report', text: '10.0')
    end
  end

  context 'as user without logged time' do
    let(:current_user) { user2 }
    it 'shows my time' do
      expect(page).to have_no_selector('.report')
      expect(page).to have_selector('.generic-table--no-results-title')
      expect(page).not_to have_text '10.0' # 1 EUR x 10
    end
  end
end
