require "spec_helper"

RSpec.describe "Cost Report", "calculations", :js, :with_cuprite do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:work_package) { create(:work_package, project:) }

  def create_hourly_rates
    create(:default_hourly_rate, user:, rate: 1.00,  valid_from: 1.year.ago)
    create(:default_hourly_rate, user:, rate: 5.00,  valid_from: 2.years.ago)
    create(:default_hourly_rate, user:, rate: 10.00, valid_from: 3.years.ago)
  end

  def create_time_entries_on(*timestamps_of_recordings)
    timestamps_of_recordings.each do |spent_on|
      create(:time_entry,
             spent_on:,
             user:,
             work_package:,
             project:,
             hours: 10)
    end
  end

  before do
    create_hourly_rates
    create_time_entries_on(6.months.ago, 18.months.ago, 30.months.ago)
    login_as user
    visit "/cost_reports?set_filter=1"
  end

  it "shows the correct calculations" do
    expect(page).to have_text "10.00"  # 1  EUR x 10
    expect(page).to have_text "50.00"  # 5  EUR x 10
    expect(page).to have_text "100.00" # 10 EUR x 10
    expect(page).to have_text "160.00" # Total
  end
end
