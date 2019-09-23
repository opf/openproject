require 'spec_helper'
require_relative 'support/pages/cost_report_page'

describe 'Cost report project context', type: :feature, js: true do
  let(:project1) { FactoryBot.create :project }
  let(:project2) { FactoryBot.create :project }
  let(:admin) { FactoryBot.create :admin }

  let(:report_page) { ::Pages::CostReportPage.new project }

  before do
    project1
    project2
    login_as admin
  end

  it "switches the project context when visiting another project's cost report" do
    visit cost_reports_path(project1)
    expect(page).to have_selector('#project_id_arg_1_val option', text: project1.name)

    visit cost_reports_path(project2)
    expect(page).to have_selector('#project_id_arg_1_val option', text: project2.name)
  end
end