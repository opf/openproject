require "spec_helper"

RSpec.describe "Cost report showing my own times", :js do
  let(:project) { create(:project) }
  let(:user) { create(:admin) }
  let(:user2) { create(:admin) }

  let(:work_package) { create(:work_package, project:) }
  let!(:hourly_rate1) { create(:default_hourly_rate, user:, rate: 1.00, valid_from: 1.year.ago) }

  let!(:time_entry1) do
    create(:time_entry,
           user:,
           work_package:,
           project:,
           hours: 10)
  end

  before do
    login_as(current_user)
    visit cost_reports_path(project)
  end

  context "as user with logged time" do
    let(:current_user) { user }

    it "shows my time" do
      expect(page).to have_css(".report", text: "10.0")
    end
  end

  context "as user without logged time" do
    let(:current_user) { user2 }

    it "shows my time" do
      expect(page).to have_no_css(".report")
      expect(page).to have_css(".generic-table--no-results-title")
      expect(page).to have_no_text "10.0" # 1 EUR x 10
    end
  end
end
