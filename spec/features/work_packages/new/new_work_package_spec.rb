require 'spec_helper'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'

describe 'new work package', js: true do
  let(:type_task) { FactoryBot.create(:type_task) }
  let(:type_bug) { FactoryBot.create(:type_bug) }
  let(:types) { [type_task, type_bug] }
  let!(:status) { FactoryBot.create(:status, is_default: true) }
  let!(:priority) { FactoryBot.create(:priority, is_default: true) }
  let!(:project) do
    FactoryBot.create(:project, types: types)
  end

  let(:permissions) { [:view_work_packages, :add_work_packages, :edit_work_packages] }
  let(:user) do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end

  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:subject) { 'My subject' }
  let(:description) { 'A description of the newly-created work package.' }

  let(:subject_field) { wp_page.edit_field :subject }
  let(:description_field) { wp_page.edit_field :description }
  let(:project_field) { wp_page.edit_field :project }
  let(:assignee_field) { wp_page.edit_field :assignee }
  let(:type_field) { wp_page.edit_field :type }
  let(:notification) { PageObjects::Notifications.new(page) }

  def disable_leaving_unsaved_warning
    FactoryBot.create(:user_preference, user: user, others: { warn_on_leaving_unsaved: false })
  end

  def save_work_package!(expect_success = true)
    scroll_to_and_click find('#work-packages--edit-actions-save')

    if expect_success
      notification.expect_success('Successful creation.')
    end
  end

  def create_work_package(type, project)
    loading_indicator_saveguard

    wp_page.click_create_wp_button(type)

    loading_indicator_saveguard
    expect(page).to have_focus_on('#wp-new-inline-edit--field-subject')
    wp_page.subject_field.set(subject)

    sleep 1
  end

  def create_work_package_globally(type, project)
    loading_indicator_saveguard

    wp_page.click_create_wp_button(type)

    loading_indicator_saveguard
    wp_page.subject_field.set(subject)

    project_field.openSelectField
    project_field.set_value project

    sleep 1

    # Select self as assignee
    assignee_field.openSelectField
    assignee_field.set_value user.name

    sleep 1
  end

  before do
    disable_leaving_unsaved_warning
    login_as(user)
  end

  shared_examples 'work package creation workflow' do
    before do
      create_method.call(type_task, project.name)

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

      create_method.call(type_bug, project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      # Use regex to not be case sensitive
      type_field.expect_state_text /#{type_bug.name}/i
    end

    it 'saves the work package with enter' do
      subject_field = wp_page.subject_field
      subject_field.set(subject)
      subject_field.send_keys(:enter)

      # safegurards
      wp_page.dismiss_notification!
      wp_page.expect_no_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      wp_page.edit_field(:subject).expect_text(subject)
    end

    context 'with missing values' do
      it 'shows an error when subject is missing' do
        description_field.set_value(description)

        # Need to send keys to emulate change
        subject_field = wp_page.subject_field
        subject_field.set('')
        subject_field.send_keys('a')
        subject_field.send_keys(:backspace)

        save_work_package!(false)
        notification.expect_error("Subject can't be blank.")
      end
    end

    context 'with subject set' do
      it 'creates a basic work package' do
        description_field = wp_page.edit_field :description
        description_field.set_value description

        save_work_package!
        expect(page).to have_selector('#tabs')

        subject_field.expect_state_text(subject)
        description_field = wp_page.edit_field :description
        description_field.expect_state_text(description)
      end

      it 'can switch types and keep attributes' do
        wp_page.subject_field.set(subject)
        type_field.activate!
        type_field.openSelectField
        type_field.set_value type_bug.name

        save_work_package!

        wp_page.expect_attributes subject: subject
        wp_page.expect_attributes type: type_bug.name.upcase
      end

      context 'custom fields' do
        let(:custom_field1) do
          FactoryBot.create(
            :work_package_custom_field,
            field_format: 'string',
            is_required: true,
            is_for_all: true
          )
        end
        let(:custom_field2) do
          FactoryBot.create(
            :work_package_custom_field,
            field_format: 'list',
            possible_values: %w(foo bar xyz),
            is_required: false,
            is_for_all: true
          )
        end
        let(:custom_fields) do
          [custom_field1, custom_field2]
        end
        let(:type_task) { FactoryBot.create(:type_task, custom_fields: custom_fields) }
        let(:project) do
          FactoryBot.create(:project,
                            types: types,
                            work_package_custom_fields: custom_fields)
        end

        it do
          ids = custom_fields.map(&:id)
          cf1 = find(".customField#{ids.first} input")
          expect(cf1).not_to be_nil

          expect(page).to have_selector(".customField#{ids.last} ng-select")

          cf = wp_page.edit_field "customField#{ids.last}"
          cf.field_type = 'create-autocompleter'
          cf.openSelectField
          cf.set_value 'foo'
          save_work_package!(false)

          notification.expect_error("#{custom_field1.name} can't be blank.")

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

      create_work_package(type_task, project.name)
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
    let(:existing_wp) { FactoryBot.create :work_package, type: type_bug, project: project }
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

    it 'can stop and re-create with correct selection (Regression #30216)' do
      create_work_package_globally(type_bug, project.name)

      click_on 'Cancel'

      wp_page.click_create_wp_button type_bug
      expect(page).to have_no_selector('.ng-value', text: project.name)

      project_field.openSelectField
      project_field.set_value project.name

      click_on 'Cancel'
    end

    it 'can save the work package with an assignee (Regression #32887)' do
      create_work_package_globally(type_task, project.name)
      expect(page).to have_selector(safeguard_selector, wait: 10)

      wp_page.subject_field.set('new work package')
      save_work_package!
      wp_page.dismiss_notification!

      assignee_field.expect_state_text user.name
      wp = WorkPackage.last
      expect(wp.assigned_to).to eq user
    end

    context 'with a project without type_bug' do
      let!(:project_without_bug) do
        FactoryBot.create(:project, name: 'Unrelated project', types: [type_task])
      end

      it 'will not show that value in the project drop down' do
        create_work_package_globally(type_bug, project.name)

        sleep 2

        project_field.openSelectField

        expect(page).to have_selector('.ng-dropdown-panel .ng-option', text: project.name)
        expect(page).to have_no_selector('.ng-dropdown-panel .ng-option', text: project_without_bug.name)
      end
    end
  end

  context 'as a user with no permissions' do
    let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryBot.create :role, permissions: %i(view_work_packages) }
    let(:wp_page) { ::Pages::Page.new }

    let(:paths) do
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    end

    it 'shows a 403 error on creation paths' do
      paths.each do |path|
        visit path
        wp_page.expect_notification(type: :error, message: I18n.t('api_v3.errors.code_403'))
      end
    end
  end

  context 'as a user with add_work_packages permission, but not edit_work_packages permission (Regression 28580)' do
    let(:user) { FactoryBot.create(:user, member_in_project: project, member_through_role: role) }
    let(:role) { FactoryBot.create :role, permissions: %i(view_work_packages add_work_packages) }
    let(:wp_page) { Pages::FullWorkPackageCreate.new }

    before do
      visit new_project_work_packages_path(project)
    end

    it 'can create the work package, but not update it after saving' do
      type_field.activate!
      type_field.set_value type_bug.name
      # wait after the type change
      sleep(0.2)
      subject_field.update('new work package')

      wp_page.expect_and_dismiss_notification(
        message: 'Successful creation.'
      )

      subject_field.expect_read_only
      subject_field.display_element.click
      subject_field.expect_inactive!
    end
  end

  context 'an anonymous user is prompted to login' do
    let(:user) { FactoryBot.create(:anonymous) }
    let(:wp_page) { ::Pages::Page.new }

    let(:paths) do
      [
        new_work_packages_path,
        new_split_work_packages_path,
        new_project_work_packages_path(project),
        new_split_project_work_packages_path(project)
      ]
    end

    it 'shows a 403 error on creation paths' do
      paths.each do |path|
        visit path
        expect(wp_page.current_url).to match /#{signin_path}\?back_url=/
      end
    end
  end
end
