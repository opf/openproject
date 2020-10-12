require 'spec_helper'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'

describe 'new work package', js: true, with_mail: false do
  let(:type_task) { FactoryBot.create(:type_task, description: "# New Task template\n\nHello there") }
  let(:type_feature) { FactoryBot.create(:type_feature, description: "", is_default: true) }
  let(:type_bug) { FactoryBot.create(:type_bug, description: "# New Bug template\n\nGeneral Kenobi") }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let!(:project) do
    FactoryBot.create(:project, types: [type_feature, type_task, type_bug], no_types: true)
  end

  let(:user) { FactoryBot.create :admin }

  let(:subject_field) { wp_page.edit_field :subject }
  let(:description_field) { wp_page.edit_field :description }
  let(:project_field) { wp_page.edit_field :project }
  let(:type_field) { wp_page.edit_field :type }
  let(:notification) { PageObjects::Notifications.new(page) }
  let(:wp_page) { Pages::FullWorkPackageCreate.new }

  # Changing the type changes the description if it was empty or still the default.
  # Changes in the description shall not be overridden.
  def change_type_and_expect_description(set_project: false)
    if !set_project
      expect(page).to have_selector('.inline-edit--container.type', text: type_feature.name)
    end
    expect(page).to have_selector('.inline-edit--container.description', text: '')

    type_field.openSelectField
    type_field.set_value type_task
    expect(page).to have_selector('.inline-edit--container.description h1', text: 'New Task template')

    type_field.openSelectField
    type_field.set_value type_bug
    expect(page).to have_selector('.inline-edit--container.description h1', text: 'New Bug template')

    description_field.set_value 'Something different than the default.'

    type_field.openSelectField
    type_field.set_value type_task
    expect(page).to have_no_selector('.inline-edit--container.description h1', text: 'New Task template', wait: 5)

    description_field.set_value ''

    type_field.openSelectField
    type_field.set_value type_bug
    expect(page).to have_selector('.inline-edit--container.description h1', text: 'New Bug template')

    if set_project
      project_field.openSelectField
      project_field.set_value project
      sleep 1
    end

    scroll_to_and_click find('#work-packages--edit-actions-save')
    wp_page.expect_notification message: 'Successful creation.'

    expect(page).to have_selector('.inline-edit--display-field.description h1', text: 'New Bug template')
  end

  before do
    login_as(user)
  end

  describe 'global work package create' do
    it 'shows the template after selection of project and type' do
      visit '/work_packages/new'
      wp_page.expect_fully_loaded

      subject_field.set_value 'Foobar!'

      change_type_and_expect_description set_project: true
    end
  end

  describe 'project work package create' do
    let(:wp_table) { Pages::WorkPackagesTable.new project }
    let(:wp_page) { Pages::SplitWorkPackageCreate.new project: project }

    it 'shows the template after selection of project and type' do
      wp_table.visit!
      wp_table.create_wp_by_button type_feature

      wp_page.expect_fully_loaded

      subject_field.set_value 'Foobar!'

      type_field.activate!

      change_type_and_expect_description
    end
  end
end
