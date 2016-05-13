require 'spec_helper'
require 'features/page_objects/notification'

describe 'edit work package', js: true do
  let(:dev_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :add_work_packages]
  end
  let(:dev) do
    FactoryGirl.create :user,
                       firstname: 'Dev',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: dev_role
  end
  let(:manager_role) do
    FactoryGirl.create :role,
                       permissions: [:view_work_packages,
                                     :edit_work_packages]
  end
  let(:manager) do
    FactoryGirl.create :user,
                       firstname: 'Manager',
                       lastname: 'Guy',
                       member_in_project: project,
                       member_through_role: manager_role
  end
  let(:type) { FactoryGirl.create :type }
  let(:type2) { FactoryGirl.create :type }
  let(:project) { FactoryGirl.create(:project, types: [type, type2]) }
  let(:work_package) { FactoryGirl.create(:work_package, author: dev, project: project, type: type) }

  let(:new_subject) { 'Some other subject' }
  let(:wp_page) { Pages::FullWorkPackage.new(work_package) }
  let(:priority2) { FactoryGirl.create :priority }
  let(:status2) { FactoryGirl.create :status }
  let(:workflow) do
    FactoryGirl.create :workflow,
                       type_id: type2.id,
                       old_status: work_package.status,
                       new_status: status2,
                       role: manager_role
  end
  let(:version) { FactoryGirl.create :version, project: project }
  let(:category) { FactoryGirl.create :category, project: project }

  before do
    login_as(manager)

    manager
    dev
    priority2
    workflow

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  it 'allows updating and seeing the results' do
    wp_page.view_all_attributes
    wp_page.update_attributes type: type2.name,
                              :'start-date' => '2013-03-04',
                              :'end-date' => '2013-03-20',
                              responsible: manager.name,
                              assignee: manager.name,
                              estimatedTime: '5.00',
                              percentageDone: '30',
                              subject: 'a new subject',
                              description: 'a new description',
                              priority: priority2.name,
                              status: status2.name,
                              version: version.name,
                              category: category.name

    wp_page.expect_notification message: I18n.t('js.notice_successful_update')

    wp_page.expect_attributes Type: type2.name,
                              Responsible: manager.name,
                              Assignee: manager.name,
                              Date: '03/04/2013 - 03/20/2013',
                              'Estimated time' => '5.00',
                              Progress: '30',
                              Subject: 'a new subject',
                              Description: 'a new description',
                              Priority: priority2.name,
                              Status: status2.name,
                              Version: version.name,
                              Category: category.name
  end

  context 'switching to custom field with required CF' do
    let(:custom_field) {
      FactoryGirl.create(
        :work_package_custom_field,
        field_format: 'string',
        is_required:  true,
        is_for_all:   false
      )
    }
    let(:type2) { FactoryGirl.create(:type, custom_fields: [custom_field]) }
    let(:project) { FactoryGirl.create(:project, types: [type, type2]) }
    let(:work_package) {
      FactoryGirl.create(:work_package,
                         type:    type,
                         project: project)
    }

    before do
      work_package

      # Require custom fields for this project
      project.work_package_custom_fields = [custom_field]
      project.save!

      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it 'shows the required field when switching' do
      page.click_button(I18n.t('js.button_edit'))
      type_field = wp_page.edit_field(:type)

      type_field.set_value type2.name
      expect(type_field.input_element).to have_selector('option:checked', text: type2.name)

      cf_field = wp_page.edit_field("customField#{custom_field.id}")
      cf_field.expect_active!
      cf_field.expect_value('')
    end
  end
end
