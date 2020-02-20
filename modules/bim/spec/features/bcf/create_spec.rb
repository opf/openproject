require 'spec_helper'

require_relative '../../support/pages/ifc_models/show_default'

describe 'Create BCF', type: :feature, js: true, with_mail: false do
  let(:project) { FactoryBot.create :project, types: [type] }
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

  before do
    login_as(user)
    index_page.visit!
  end

  context 'with all permissions' do
    it 'can create a new bcf work package' do
      create_page = index_page.create_wp_by_button(type)

      create_page.expect_current_path

      create_page.subject_field.set(subject)
      create_page.save!

      # TODO: adapt notification message
      index_page.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      work_package = WorkPackage.last

      index_page.expect_work_package_listed(work_package)


      #index_page.model_listed true, model.title
      #index_page.add_model_allowed true
      #index_page.edit_model_allowed model.title, true
      #index_page.delete_model_allowed model.title, true

      #index_page.edit_model model.title, 'My super cool new name'
      #index_page.delete_model 'My super cool new name'
    end
  end

  context 'without create permission' do
    let(:permissions) { %i[view_ifc_models manage_ifc_models] }

    #it 'I can see, but not edit models' do
    #  index_page.model_listed true, model.title
    #  index_page.add_model_allowed false
    #  index_page.edit_model_allowed model.title, false
    #  index_page.delete_model_allowed model.title, false
    #end

    #it 'I can see single models and the defaults' do
    #  index_page.model_listed true, model.title
    #  index_page.show_model model

    #  index_page.model_listed true, model.title
    #  index_page.show_defaults
    #end
  end
end
