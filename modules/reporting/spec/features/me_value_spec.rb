require 'spec_helper'

describe 'Cost report showing my own times', type: :feature, js: true do
  let(:project) { FactoryBot.create :project }
  let(:user) { FactoryBot.create :admin }
  let(:user2) { FactoryBot.create :admin }

  let(:work_package) { FactoryBot.create :work_package, project: project }
  let!(:hourly_rate1) { FactoryBot.create :default_hourly_rate, user: user, rate: 1.00, valid_from: 1.year.ago }

  let!(:time_entry1) {
    FactoryBot.create :time_entry,
                       user: user,
                       work_package: work_package,
                       project: project,
                       hours: 10
  }
  let!(:time_entry2) {
    FactoryBot.create :time_entry,
                      user: user2,
                      work_package: work_package,
                      project: project,
                      hours: 15
  }

  before do
    # Login as first user
    login_as user

    # Create and save cost report
    visit cost_reports_path(project)

  end

  shared_examples 'me filter value' do |filter_name, filter_selector|
    it 'keeps the special "me" value for the current user' do
      select 'me', from: filter_selector
      click_on 'Save'
      fill_in 'query_name', with: 'Query ME value'
      check 'query_is_public'
      find('#query-icon-save-button').click

      expect(page).to have_selector('.report', text: '10.00')

      report = CostQuery.last
      user_filter = report.serialized[:filters].detect { |name,_| name == filter_name }
      expect(user_filter[1][:values]).to eq %w(me)

      # Login as the next user
      login_as user2

      # Create and save cost report
      visit cost_report_path(report.id, project_id: project.identifier)
      expect(page).to have_no_selector('.report', text: '10.00')
      expect(page).to have_selector('.report', text: '15.00')

      expect(find("##{filter_selector}").value).to eq 'me'
    end
  end

  describe 'assignee filter' do
    let(:work_package) { FactoryBot.create :work_package, project: project, assigned_to: user }
    let(:work_package2) { FactoryBot.create :work_package, project: project, assigned_to: user2 }

    let!(:time_entry1) {
      FactoryBot.create :time_entry,
                        user: user,
                        work_package: work_package,
                        project: project,
                        hours: 10
    }
    let!(:time_entry2) {
      FactoryBot.create :time_entry,
                        user: user2,
                        work_package: work_package2,
                        project: project,
                        hours: 15
    }


    before do
      # Remove default user filter, add assignee filter
      find('#rm_box_user_id .filter_rem').click
      select 'Assignee', from: 'add_filter_select'
    end

    it_behaves_like 'me filter value', 'AssignedToId', 'assigned_to_id_arg_1_val'
  end

  describe 'user filter' do
    it_behaves_like 'me filter value', 'UserId', 'user_id_arg_1_val'
  end
end
