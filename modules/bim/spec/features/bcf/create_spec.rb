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

  shared_examples 'bcf details creation' do
    it 'can create a new bcf work package' do
      create_page = index_page.create_wp_by_button(type)
      create_page.view_route = view_route

      create_page.expect_current_path

      create_page.subject_field.set(subject)

      # switch the type
      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type_with_cf.name

      cf_field = create_page.edit_field(:"customField#{integer_cf.id}")
      cf_field.set_value(815)

      create_page.save!

      index_page.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      work_package = WorkPackage.last
      split_page = ::Pages::SplitWorkPackage.new(work_package, project)
      split_page.ensure_page_loaded
      split_page.expect_subject

      split_page.close
      split_page.expect_closed

      expect(page).to have_current_path /bcf\/#{Regexp.escape(view_route)}$/, ignore_query: true
    end
  end

  before do
    login_as(user)
  end

  context 'with all permissions' do
    context 'on the split page' do
      let(:view_route) { 'split' }
      before do
        index_page.visit!
      end

      it_behaves_like 'bcf details creation'
    end

    context 'on the split page switching to list' do
      let(:view_route) { 'list' }
      before do
        index_page.visit!
        index_page.switch_view 'List'
        expect(page).to have_current_path /\/bcf\/list$/, ignore_query: true
      end

      it_behaves_like 'bcf details creation'
    end

    context 'starting on the list page' do
      let(:view_route) { 'list' }
      before do
        visit bcf_project_frontend_path(project, "list")
        expect(page).to have_current_path /\/bcf\/list$/, ignore_query: true
      end

      it_behaves_like 'bcf details creation'
    end

    context 'starting on the details page of an existing work package' do
      let(:work_package) { FactoryBot.create :work_package, project: project }
      let(:view_route) { 'split' }
      before do
        visit bcf_project_frontend_path(project, "split/details/#{work_package.id}")
        expect(page).to have_current_path /\/bcf\/split\/details/, ignore_query: true
      end

      it_behaves_like 'bcf details creation'
    end
  end

  context 'without create work package permission' do
    let(:permissions) { %i[view_ifc_models manage_ifc_models view_work_packages] }

    it 'has the create button disabled' do
      index_page.visit!
      index_page.expect_wp_create_button_disabled
    end
  end
end
