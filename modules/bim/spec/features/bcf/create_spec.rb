require_relative "../../spec_helper"

RSpec.describe "Create BCF", :js,
               with_config: { edition: "bim" } do
  let(:project) do
    create(:project,
           types: [type, type_with_cf],
           enabled_module_names: %i[bim work_package_tracking],
           work_package_custom_fields: [integer_cf])
  end
  let(:index_page) { Pages::IfcModels::ShowDefault.new(project) }
  let(:permissions) { %i[view_ifc_models view_linked_issues manage_bcf add_work_packages edit_work_packages view_work_packages] }
  let!(:status) { create(:default_status) }
  let!(:priority) { create(:priority, is_default: true) }

  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end

  let!(:model) do
    create(:ifc_model_minimal_converted,
           project:,
           uploader: user)
  end
  let(:type) { create(:type) }
  let(:type_with_cf) do
    create(:type, custom_fields: [integer_cf])
  end
  let(:integer_cf) do
    create(:integer_wp_custom_field)
  end

  shared_examples "bcf details creation" do |with_viewpoints:|
    it "can create a new #{with_viewpoints ? 'bcf' : 'plain'} work package" do
      create_page = index_page.create_wp_by_button(type)

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

      cf_field = create_page.edit_field(integer_cf.attribute_name(:camel_case).to_sym)
      cf_field.set_value(815)

      create_page.save!

      index_page.expect_and_dismiss_toaster(
        message: "Successful creation."
      )

      if with_viewpoints
        create_page.expect_viewpoint_count 2
      end

      work_package = WorkPackage.last
      split_page = Pages::SplitWorkPackage.new(work_package, project)
      split_page.ensure_page_loaded
      split_page.expect_subject

      split_page.close
      split_page.expect_closed

      if with_viewpoints
        expect(work_package.bcf_issue).to be_present
        expect(work_package.bcf_issue.viewpoints.count).to eq 2
      end

      expect(page).to have_current_path /bcf$/, ignore_query: true
    end
  end

  before do
    login_as(user)
  end

  context "with all permissions" do
    context "when on default view" do
      before do
        index_page.visit_and_wait_until_finished_loading!
      end

      it_behaves_like "bcf details creation", with_viewpoints: true
    end

    context "when going to split table view first" do
      before do
        index_page.visit_and_wait_until_finished_loading!

        index_page.switch_view "Viewer and table"
      end

      it_behaves_like "bcf details creation", with_viewpoints: true
    end

    context "when going to cards view first" do
      before do
        index_page.visit_and_wait_until_finished_loading!

        index_page.switch_view "Cards"
      end

      it_behaves_like "bcf details creation", with_viewpoints: false
    end

    context "when going to table view first" do
      before do
        index_page.visit_and_wait_until_finished_loading!

        index_page.switch_view "Table"
      end

      it_behaves_like "bcf details creation", with_viewpoints: false
    end

    context "when starting on the details page of an existing work package" do
      let(:work_package) { create(:work_package, project:) }

      before do
        visit bcf_project_frontend_path(project, "details/#{work_package.id}")
        index_page.finished_loading
        index_page.expect_details_path
      end

      it_behaves_like "bcf details creation", with_viewpoints: true
    end
  end

  context "without add_work_packages permission" do
    let(:permissions) { %i[view_ifc_models manage_bcf view_work_packages] }

    it "has the create button disabled" do
      index_page.visit_and_wait_until_finished_loading!

      index_page.expect_wp_create_button_disabled
    end
  end

  context "with add_work_packages but without manage_bcf permission" do
    let(:permissions) { %i[view_ifc_models view_work_packages add_work_packages] }

    context "when on default view" do
      before do
        index_page.visit_and_wait_until_finished_loading!
      end

      it_behaves_like "bcf details creation", with_viewpoints: false
    end
  end
end
