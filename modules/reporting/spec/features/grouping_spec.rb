require 'spec_helper'
require_relative 'support/pages/cost_report_page'

describe 'Cost report calculations', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }

  let(:work_package) { FactoryBot.create :work_package, project: project }
  let!(:hourly_rate1) { FactoryBot.create :default_hourly_rate, user: user, rate: 1.00, valid_from: 1.year.ago }

  let(:report_page) { ::Pages::CostReportPage.new project}

  let!(:time_entry1) {
    FactoryBot.create :time_entry,
                       spent_on: 6.months.ago,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }
  before do
    login_as(user)
    visit cost_reports_path(project)
  end


  it 'provides grouping' do
      #   Then I should see "Week (Spent)" in columns
      #   And I should see "Work package" in rows
      report_page.expect_column_element('Week (Spent)')
      report_page.expect_row_element('Work package')

      #   When I click on "Clear"
      report_page.clear
      #   Then I should not see "Week (Spent)" in columns
      #   And I should not see "Work package" in rows
      report_page.expect_column_element('Week (Spent)', present: false)
      report_page.expect_row_element('Work package', present: false)

      #   And I group rows by "User"
      report_page.add_to_rows 'User'
      #   And I group rows by "Cost type"
      report_page.add_to_rows 'Cost type'

      #   When I click on "Clear"
      report_page.clear

      #   Then I should not see "Week (Spent)" in columns
      #   And I should not see "Work package" in rows
      report_page.expect_column_element('Week (Spent)', present: false)
      report_page.expect_row_element('Work package', present: false)
      #   And I should not see "User" in rows
      #   And I should not see "Cost type" in rows
      report_page.expect_row_element('User', present: false)
      report_page.expect_row_element('Cost type', present: false)

      #   When I click on "Clear"
      report_page.clear
      #   And I group columns by "Work package"
      report_page.add_to_columns 'Work package'

      #   Then I should see "Work package" in columns
      report_page.expect_column_element('Work package')
      #   When I group rows by "Project"
      report_page.add_to_columns 'Project'
      #   Then I should see "Project" in rows
      report_page.expect_column_element('Project')

      #   When I click on "Clear"
      report_page.clear
      #   And I group columns by "Work package"
      report_page.add_to_columns 'Work package'
      #   And I group rows by "Project"
      report_page.add_to_rows 'Project'

      #   Then I should see "Work package" in columns
      report_page.expect_column_element('Work package')
      #   And I should see "Project" in rows
      report_page.expect_row_element('Project')

      #   When I remove "Project" from rows
      report_page.remove_row_element('Project')

      #   And I remove "Work package" from columns
      report_page.remove_column_element('Work package')

      #   Then I should not see "Work package" in columns
      report_page.expect_column_element('Work package', present: false)
      #   And I should not see "Project" in rows
      report_page.expect_row_element('Project', present: false)

      #   When I click on "Clear"
      report_page.clear

      #   And I group columns by "Project"
      report_page.add_to_columns 'Project'
      #   And I group columns by "Work package"
      report_page.add_to_columns 'Work package'
      #   And I group rows by "User"
      report_page.add_to_rows 'User'
      #   And I group rows by "Cost type"
      report_page.add_to_rows 'Cost type'

      #   And I send the query
      report_page.apply

      #   Then I should see "Project" in columns
      report_page.expect_column_element('Work package')
      #   And I should see "Work package" in columns
      report_page.expect_column_element('Project')
      #   And I should see "User" in rows
      report_page.expect_row_element('User')
      #   And I should see "Cost type" in rows
      report_page.expect_row_element('Cost type')
  end
end