require 'spec_helper'
require 'features/page_objects/notification'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'date inplace editor',
         with_settings: { date_format: '%Y-%m-%d' },
         js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, is_public: true }
  let(:work_package) { FactoryBot.create :work_package, project: project, start_date: '2016-01-01' }
  let(:user) { FactoryBot.create :admin }
  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package,project) }

  let(:due_date) { work_packages_page.edit_field(:dueDate) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'uses the start date as a placeholder for the end date' do
    due_date.activate!

    within('.ui-datepicker') do
      expect(page).to have_selector('.ui-datepicker-month option', text: 'Jan')
      expect(page).to have_selector('.ui-datepicker-year option', text: '2016')
      day = find('td a', text: '25')
      scroll_to_and_click(day)
    end

    due_date.expect_inactive!
    due_date.expect_state_text '2016-01-25'
  end
end
