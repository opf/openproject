require 'spec_helper'

require_relative '../../support/pages/ifc_models/show_default'

describe 'Create BCF', type: :feature, js: true, with_mail: false do
  let(:project) do
    FactoryBot.create(:project, types: [type, type_with_cf], work_package_custom_fields: [integer_cf])
  end
  let(:index_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:permissions) { %i[view_ifc_models manage_ifc_models add_work_packages view_work_packages] }
  let!(:status) { FactoryBot.create(:default_status) }
  let!(:priority) { FactoryBot.create :priority, is_default: true }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: permissions
  end

  let!(:model) do
    FactoryBot.create(:ifc_model_converted,
                      project: project,
                      uploader: user)
  end
  let(:type) { FactoryBot.create(:type) }
  let(:type_with_cf) do
    FactoryBot.create(:type, custom_fields: [integer_cf])
  end
  let(:integer_cf) do
    FactoryBot.create(:int_wp_custom_field)
  end

  before do
    login_as(user)
    index_page.visit!
  end

  context 'with all permissions' do
    it 'can create a new bcf work package' do
      create_page = index_page.create_wp_by_button(type)

      create_page.expect_current_path

      create_page.subject_field.set(subject)

      # switch the type
      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type_with_cf.name

      cf_field = create_page.edit_field(:"customField#{integer_cf.id}")
      cf_field.set_value(815)

      create_page.save!

      # TODO: adapt notification message
      index_page.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      work_package = WorkPackage.last

      index_page.expect_work_package_listed(work_package)
    end
  end

  context 'without create work package permission' do
    let(:permissions) { %i[view_ifc_models manage_ifc_models view_work_packages] }

    it 'has the create button disabled' do
      index_page.expect_wp_create_button_disabled
    end
  end
end
