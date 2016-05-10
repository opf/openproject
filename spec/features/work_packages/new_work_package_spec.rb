require 'spec_helper'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'
require 'features/page_objects/notification'


describe 'new work package', js: true do
  let(:type_task) { FactoryGirl.create(:type_task) }
  let(:type_bug) { FactoryGirl.create(:type_bug) }
  let(:types) { [type_task, type_bug] }
  let(:status) { FactoryGirl.build(:status, is_default: true) }
  let(:priority) { FactoryGirl.build(:priority, is_default: true) }
  let(:project) {
    FactoryGirl.create(:project, types: types)
  }

  let(:user) { FactoryGirl.create :admin }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  let(:subject) { 'My subject' }
  let(:description) { 'A description of the newly-created work package.' }

  let(:subject_field) { WorkPackageField.new(page, :subject) }
  let(:description_field) { WorkPackageField.new(page, :description) }

  let(:notification) { PageObjects::Notifications.new(page) }

  def disable_leaving_unsaved_warning
    FactoryGirl.create(:user_preference, user: user, others: { warn_on_leaving_unsaved: false })
  end

  before do
    status.save!
    priority.save!
    disable_leaving_unsaved_warning

    login_as(user)

    work_packages_page.visit_index
    create_work_package('Task')
  end

  def save_work_package!(expect_success=true)
    within '.work-packages--edit-actions' do
      click_button 'Save'
    end

    if expect_success
      notification.expect_success('Successful creation.')
    end
  end

  def create_work_package(type)
    loading_indicator_saveguard
    work_packages_page.click_toolbar_button 'Work package'

    within '#tasksDropdown' do
      click_link type
    end
  end

  shared_examples 'work package creation workflow' do
    it 'creates a subsequent work package' do
      work_packages_page.find_subject_field.set(subject)
      save_work_package!

      subject_field.expect_state_text(subject)

      create_work_package('Bug')
      expect(page).to have_selector(safeguard_selector, wait: 10)
      expect(page).to have_selector('#inplace-edit--write-value--type option[selected]',
                                    text: 'Bug')
    end

    context 'with missing values' do
      it 'shows an error when subject is missing' do
        find('#work-package-description textarea').set(description)
        save_work_package!(false)
        notification.expect_error("Subject can't be blank.")
      end
    end

    context 'with subject set' do
      before do
        find('#work-package-subject input').set(subject)
      end

      it 'creates a basic work package' do
        find('#work-package-description textarea').set(description)

        save_work_package!
        expect(page).to have_selector('#tabs')

        subject_field.expect_state_text(subject)
        description_field.expect_state_text(description)
      end

      it 'can switch types and keep attributes' do
        find('#work-package-subject input').set(subject)
        select 'Bug', from: 'inplace-edit--write-value--type'

        save_work_package!

        wp_page.expect_attributes subject: subject
        wp_page.expect_attributes type: 'Bug'
      end

      context 'custom fields' do
        let(:custom_fields) {
          [custom_field1, custom_field2]
        }
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
        let(:type_task) { FactoryGirl.create(:type_task, custom_fields: custom_fields) }
        let(:project) {
          FactoryGirl.create(:project,
                             types: types,
                             work_package_custom_fields: custom_fields)
        }

        it do
          within '.panel-toggler' do
            find('a', text: 'Show all attributes').click
          end

          ids = custom_fields.map(&:id)
          cf1 = find("input#inplace-edit--write-value--customField#{ids.first}")
          expect(cf1).not_to be_nil
          expect(page).to have_select("inplace-edit--write-value--customField#{ids.last}",
                                      options: %w(- foo bar xyz))

          select 'foo', from: "inplace-edit--write-value--customField#{ids.last}"
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

  context 'split screen' do
    let(:safeguard_selector) { '.work-packages--details-content.-create-mode' }
    let(:wp_page) { Pages::SplitWorkPackage.new(WorkPackage.new) }

    before do
      # Safeguard to ensure the create form to be loaded
      expect(page).to have_selector(safeguard_selector, wait: 10)
    end

    it_behaves_like 'work package creation workflow'
  end

  context 'full screen' do
    let(:safeguard_selector) { '.work-package--new-state' }
    let(:wp_page) { Pages::FullWorkPackage.new(WorkPackage.new) }

    before do
      find('#work-packages-show-view-button').click
      # Safeguard to ensure the create form to be loaded
      expect(page).to have_selector(safeguard_selector, wait: 10)
    end

    it_behaves_like 'work package creation workflow'
  end
end
