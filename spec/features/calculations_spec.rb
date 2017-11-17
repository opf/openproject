require 'spec_helper'

describe 'Cost report calculations', type: :feature, js: true do
  let(:project) { FactoryGirl.create :project }
  let(:user) { FactoryGirl.create :admin }

  let(:work_package) { FactoryGirl.create :work_package, project: project }
  let!(:hourly_rate1) { FactoryGirl.create :default_hourly_rate, user: user, rate: 1.00, valid_from: 1.year.ago }
  let!(:hourly_rate2) { FactoryGirl.create :default_hourly_rate, user: user, rate: 5.00, valid_from: 2.years.ago }
  let!(:hourly_rate3) { FactoryGirl.create :default_hourly_rate, user: user, rate: 10.00, valid_from: 3.years.ago }

  let!(:time_entry1) {
    FactoryGirl.create :time_entry,
                       spent_on: 6.months.ago,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }
  let!(:time_entry2) {
    FactoryGirl.create :time_entry,
                       spent_on: 18.months.ago,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }
  let!(:time_entry3) {
    FactoryGirl.create :time_entry,
                       spent_on: 30.months.ago,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }

  before do
    login_as(user)
    visit '/cost_reports?set_filter=1'
  end


  it 'shows the correct calculations' do
    expect(page).to have_text '10.00' # 1 EUR x 10
    expect(page).to have_text '50.00' # 5 EUR x 10
    expect(page).to have_text '100.00' # 10 EUR x 10
    expect(page).to have_text '160.00'
  end
end