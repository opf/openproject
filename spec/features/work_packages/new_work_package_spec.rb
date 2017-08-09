require 'spec_helper'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'

describe 'new work package', js: true do
  let(:type_task) { FactoryGirl.create(:type_task) }
  let(:type_bug) { FactoryGirl.create(:type_bug) }
  let(:types) { [type_task, type_bug] }
  let!(:status) { FactoryGirl.create(:status, is_default: true) }
  let!(:priority) { FactoryGirl.create(:priority, is_default: true) }
  let!(:project) {
    FactoryGirl.create(:project, types: types)
  }

  let(:user) { FactoryGirl.create :admin }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:subject) { 'My subject' }
  let(:description) { 'A description of the newly-created work package.' }

  let(:subject_field) { wp_page.edit_field :subject }
  let(:description_field) { wp_page.edit_field :description }
  let(:project_field) { wp_page.edit_field :project }
  let(:type_field) { wp_page.edit_field :type }
  let(:notification) { PageObjects::Notifications.new(page) }

  def disable_leaving_unsaved_warning
    FactoryGirl.create(:user_preference, user: user, others: { warn_on_leaving_unsaved: false })
  end

  def save_work_package!(expect_success = true)
    within '.work-packages--edit-actions' do
      click_button 'Save'
    end

    if expect_success
      notification.expect_success('Successful creation.')
    end
  end

  def create_work_package(type, project)
    loading_indicator_saveguard

    wp_page.click_create_wp_button(type)

    loading_indicator_saveguard
    wp_page.subject_field.set(subject)

    project_field.set_value project
    sleep 1
  end

  def create_work_package_globally(type, project)
    loading_indicator_saveguard

    wp_page.click_add_wp_button

    loading_indicator_saveguard
    wp_page.subject_field.set(subject)

    project_field.set_value project

    expect(page).to have_selector("#wp-new-inline-edit--field-type option[label=#{type}", wait: 10)
    type_field.set_value type
    sleep 1
  end

  before do
    disable_leaving_unsaved_warning
    login_as(user)
  end

  shared_examples 'work package creation workflow' do
    before do
      create_method.call('Task', project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)
    end

    it 'creates a subsequent work package' do
      wp_page.subject_field.set(subject)
      save_work_package!

      # safegurards
      wp_page.dismiss_notification!
      wp_page.expect_no_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      subject_field.expect_state_text(subject)

      create_method.call('Bug', project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)
      expect(page).to have_select(WorkPackage.human_attribute_name(:type),
                                  selected: 'Bug')
    end

    it 'saves the work package with enter' do
      subject_field = wp_page.subject_field
      subject_field.set(subject)
      subject_field.send_keys(:return)

      # safegurards
      wp_page.dismiss_notification!
      wp_page.expect_no_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      wp_page.edit_field(:subject).expect_text(subject)
    end

    context 'with missing values' do
      it 'shows an error when subject is missing' do
        wp_page.description_field.set(description)
        wp_page.subject_field.set('')
        save_work_package!(false)
        notification.expect_error("Subject can't be blank.")
      end
    end

    context 'with subject set' do
      it 'creates a basic work package' do
        wp_page.description_field.set(description)

        save_work_package!
        expect(page).to have_selector('#tabs')

        subject_field.expect_state_text(subject)
        description_field.expect_state_text(description)
      end

      it 'can switch types and keep attributes' do
        wp_page.subject_field.set(subject)
        wp_page.select_type('Bug')

        save_work_package!

        wp_page.expect_attributes subject: subject
        wp_page.expect_attributes type: 'Bug'
      end

      context 'custom fields' do
        let(:custom_field1) {
          FactoryGirl.create(
            :work_package_custom_field,
            field_format: 'string',
            is_required: true,
            is_for_all: true
          )
        }
        let(:custom_field2) {
          FactoryGirl.create(
            :work_package_custom_field,
            field_format: 'list',
            possible_values: %w(foo bar xyz),
            is_required: false,
            is_for_all: true)
        }
        let(:custom_fields) {
          [custom_field1, custom_field2]
        }
        let(:type_task) { FactoryGirl.create(:type_task, custom_fields: custom_fields) }
        let(:project) {
          FactoryGirl.create(:project,
                             types: types,
                             work_package_custom_fields: custom_fields)
        }

        it do
          ids = custom_fields.map(&:id)
          cf1 = find(".customField#{ids.first} input")
          expect(cf1).not_to be_nil

          expect(page).to have_selector(".customField#{ids.last} select")

          find(".customField#{ids.last} option", text: 'foo').select_option
          save_work_package!(false)
          # Its a known bug that custom fields validation errors do not contain their names
          notification.expect_error("can't be blank.")

          cf1.set 'Custom field content'
          save_work_package!(true)

          wp_page.expect_attributes "customField#{custom_field1.id}" => 'Custom field content',
                                    "customField#{custom_field2.id}" => 'foo'
        end
      end
    end
  end

  context 'project split screen' do
    let(:safeguard_selector) { '.work-packages--details-content.-create-mode' }
    let(:wp_page) { Pages::SplitWorkPackage.new(WorkPackage.new) }
    let(:wp_table) { Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like 'work package creation workflow' do
      let(:create_method) { method(:create_work_package) }
    end

    it 'reloads the table and selects the new work package' do
      expect(page).to have_no_selector('.wp--row')

      create_work_package('Task', project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      wp_page.subject_field.set('new work package')
      save_work_package!
      wp_page.dismiss_notification!

      expect(page).to have_selector('.wp--row.-checked')

      # Editing the subject after creation
      # Fix for WP #23879
      new_wp = WorkPackage.last
      new_subject = 'new subject'
      table_subject = wp_table.edit_field(new_wp, :subject)
      table_subject.activate!
      table_subject.set_value new_subject
      table_subject.submit_by_enter
      table_subject.expect_state_text new_subject

      wp_page.expect_notification(
        message: 'Successful update. Click here to open this work package in fullscreen view.'
      )

      new_wp.reload
      expect(new_wp.subject).to eq(new_subject)

      # Expect this to be synced
      details_subject = wp_table.edit_field(new_wp, :subject)
      details_subject.expect_state_text new_subject
    end
  end

  context 'full screen' do
    let(:safeguard_selector) { '.work-package--new-state' }
    let(:existing_wp) { FactoryGirl.create :work_package, type: type_bug, project: project }
    let(:wp_page) { Pages::FullWorkPackage.new(existing_wp) }

    before do
      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it_behaves_like 'work package creation workflow' do
      let(:create_method) { method(:create_work_package) }
    end
  end

  context 'global split screen' do
    let(:safeguard_selector) { '.work-packages--details-content.-create-mode' }
    let(:wp_page) { Pages::SplitWorkPackage.new(WorkPackage.new) }
    let(:wp_table) { Pages::WorkPackagesTable.new(nil) }

    before do
      wp_table.visit!
    end

    it_behaves_like 'work package creation workflow' do
      let(:create_method) { method(:create_work_package_globally) }
    end
  end

  context 'as a user with no permissions' do
    let(:user) { FactoryGirl.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryGirl.create :role, permissions: %i(view_work_packages) }
    let(:wp_page) { ::Pages::Page.new }

    let(:paths) {
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    }

    it 'shows a 403 error on creation paths' do
      paths.each do |path|
        visit path
        wp_page.expect_notification(type: :error, message: I18n.t('api_v3.errors.code_403'))
      end
    end
  end

  context 'a anonymous user is prompted to login' do
    let(:user) { FactoryGirl.create(:anonymous) }
    let(:wp_page) { ::Pages::Page.new }

    let(:paths) {
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    }

    it 'shows a 403 error on creation paths' do
      paths.each do |path|
        visit path
        expect(wp_page.current_url).to match /#{signin_path}\?back_url=/
      end
    end
  end
end
