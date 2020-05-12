require_relative '../../spec_helper'

describe 'Create BCF',
         type: :feature,
         js: true,
         with_config: { edition: 'bim' },
         with_mail: false do
  let(:project) do
    FactoryBot.create(:project,
                      types: [type, type_with_cf],
                      enabled_module_names: %i[bim work_package_tracking],
                      work_package_custom_fields: [integer_cf])
  end
  let(:index_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:permissions) { %i[view_ifc_models view_linked_issues manage_bcf add_work_packages edit_work_packages view_work_packages] }
  let!(:status) { FactoryBot.create(:default_status) }
  let!(:priority) { FactoryBot.create :priority, is_default: true }

  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: permissions
  end

  let!(:model) do
    FactoryBot.create(:ifc_model_minimal_converted,
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

  shared_examples 'bcf details creation' do |with_viewpoints|
    it "can create a new #{with_viewpoints ? 'bcf' : 'plain'} work package" do
      create_page = index_page.create_wp_by_button(type)
      create_page.view_route = view_route

      create_page.expect_current_path

      create_page.subject_field.set(subject)

      if with_viewpoints
        create_page.add_viewpoint
        create_page.expect_viewpoint_count 1

        sleep 1
        create_page.add_viewpoint
        create_page.expect_viewpoint_count 2

        # Create and delete one viewpoint
        sleep 1
        create_page.add_viewpoint
        create_page.expect_viewpoint_count 3

        # Expect no confirm dialog to be present
        create_page.delete_viewpoint_at_position 2
        create_page.expect_viewpoint_count 2
      else
        create_page.expect_no_viewpoint_addable
      end

      # switch the type
      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type_with_cf.name

      cf_field = create_page.edit_field(:"customField#{integer_cf.id}")
      cf_field.set_value(815)

      create_page.save!

      sleep 5

      index_page.expect_and_dismiss_notification(
        message: 'Successful creation. Click here to open this work package in fullscreen view.'
      )

      if with_viewpoints
        create_page.expect_viewpoint_count 2
      end

      work_package = WorkPackage.last
      split_page = ::Pages::SplitWorkPackage.new(work_package, project)
      split_page.ensure_page_loaded
      split_page.expect_subject

      split_page.close
      split_page.expect_closed

      if with_viewpoints
        expect(work_package.bcf_issue).to be_present
        expect(work_package.bcf_issue.viewpoints.count).to eq 2
      end

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

      it_behaves_like 'bcf details creation', true
    end

    context 'on the split page switching to list' do
      let(:view_route) { 'list' }
      before do
        index_page.visit!
        index_page.switch_view 'Cards'
        expect(page).to have_current_path /\/bcf\/list$/, ignore_query: true
      end

      it_behaves_like 'bcf details creation', false
    end

    context 'starting on the list page' do
      let(:view_route) { 'list' }
      before do
        visit bcf_project_frontend_path(project, "list")
        expect(page).to have_current_path /\/bcf\/list$/, ignore_query: true
      end

      it_behaves_like 'bcf details creation', false
    end

    context 'starting on the details page of an existing work package' do
      let(:work_package) { FactoryBot.create :work_package, project: project }
      let(:view_route) { 'split' }
      before do
        visit bcf_project_frontend_path(project, "split/details/#{work_package.id}")
        expect(page).to have_current_path /\/bcf\/split\/details/, ignore_query: true
      end

      it_behaves_like 'bcf details creation', true
    end
  end

  context 'without add_work_packages permission' do
    let(:permissions) { %i[view_ifc_models manage_bcf view_work_packages] }

    it 'has the create button disabled' do
      index_page.visit!
      index_page.expect_wp_create_button_disabled
    end
  end

  context 'with add_work_packages but without manage_bcf permission' do
    let(:permissions) { %i[view_ifc_models view_work_packages add_work_packages] }

    context 'on the split page' do
      let(:view_route) { 'split' }
      before do
        index_page.visit!
      end

      it_behaves_like 'bcf details creation', false
    end
  end
end
