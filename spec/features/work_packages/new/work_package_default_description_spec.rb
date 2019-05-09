require 'spec_helper'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'

describe 'new work package', js: true do
  let(:type_task) { FactoryBot.create(:type_task, description: "# New Task template\n\nHello there") }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let!(:project) do
    FactoryBot.create(:project, types: [type_task])
  end

  let(:user) { FactoryBot.create :admin }

  let(:subject_field) { wp_page.edit_field :subject }
  let(:description_field) { wp_page.edit_field :description }
  let(:project_field) { wp_page.edit_field :project }
  let(:type_field) { wp_page.edit_field :type }
  let(:notification) { PageObjects::Notifications.new(page) }
  let(:wp_page) { Pages::FullWorkPackageCreate.new }

  before do
    login_as(user)
  end

  describe 'global work package create' do
    it 'shows the template after selection of project and type' do
      visit '/work_packages/new'
      wp_page.expect_fully_loaded

      project_field.openSelectField
      project_field.set_value project

      subject_field.set_value 'Foobar!'

      # Wait until project is set
      expect(page).to have_no_selector('.wp-project-context--warning')

      type_field.openSelectField
      type_field.set_value type_task

      scroll_to_and_click find('#work-packages--edit-actions-save')
      wp_page.expect_notification message: 'Successful creation.'

      expect(page).to have_selector('.wp-edit-field--display-field.description h1', text: 'New Task template')
    end
  end

  describe 'project work package create' do
    let(:wp_table) { Pages::WorkPackagesTable.new project }
    let(:wp_page) { Pages::SplitWorkPackageCreate.new project: project }

    it 'shows the template after selection of project and type' do
      wp_table.visit!
      wp_table.create_wp_split_screen type_task

      wp_page.expect_fully_loaded

      subject_field.set_value 'Foobar!'

      scroll_to_and_click find('#work-packages--edit-actions-save')
      wp_page.expect_notification message: 'Successful creation.'

      expect(page).to have_selector('.wp-edit-field--display-field.description h1', text: 'New Task template')
    end
  end
end
