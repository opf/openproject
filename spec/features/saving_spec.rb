require 'spec_helper'
require_relative 'support/pages/cost_report_page'

describe 'Cost report saving', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }

  let(:report_page) { ::Pages::CostReportPage.new project }

  before do
    login_as(user)
    visit cost_reports_path(project)
  end

  it 'can save reports privately' do
    report_page.clear

    report_page.add_to_columns 'Work package'
    report_page.add_to_rows 'Project'

    report_page.save as: 'Testreport'

    expect(page).to have_selector('#ur_caption', text: 'Testreport')
    expect(page).to have_selector('#private_sidebar_report_list', text: 'Testreport')

    report_page.expect_column_element 'Work package'
    report_page.expect_row_element 'Project'
  end

  it 'can save reports publicly' do
    report_page.clear

    report_page.add_to_columns 'Work package'
    report_page.add_to_rows 'Project'

    report_page.save as: 'Public report', public: true

    expect(page).to have_selector('#ur_caption', text: 'Public report')
    expect(page).to have_selector('#public_sidebar_report_list', text: 'Public report')

    report_page.expect_column_element 'Work package'
    report_page.expect_row_element 'Project'
  end

  context 'as user without permissions' do
    let(:role) { FactoryBot.create :role, permissions: %i(view_time_entries) }
    let!(:user) do
      FactoryBot.create :user,
                         member_in_project: project,
                         member_through_role: role
    end

    it 'cannot save reports' do
      expect(page).to have_no_selector('.buttons', text: 'Save')
    end
  end
end
