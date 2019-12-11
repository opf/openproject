require 'spec_helper'

describe 'inline create work package', js: true do
  let(:type) { FactoryBot.create(:type) }
  let(:types) { [type] }

  let(:permissions) { %i(view_work_packages add_work_packages edit_work_packages) }
  let(:role) { FactoryBot.create :role, permissions: permissions }
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end
  let(:status) { FactoryBot.create(:default_status) }
  let(:workflow) do
    FactoryBot.create :workflow,
                      type_id: type.id,
                      old_status: status,
                      new_status: FactoryBot.create(:status),
                      role: role
  end

  let!(:project) { FactoryBot.create(:project, public: true, types: types) }
  let!(:existing_wp) { FactoryBot.create(:work_package, project: project) }
  let!(:priority) { FactoryBot.create :priority, is_default: true }
  let(:filters) { ::Components::WorkPackages::Filters.new }

  before do
    workflow
    login_as user
  end

  shared_examples 'inline create work package' do
    context 'when user may create work packages' do
      it 'allows to create work packages' do
        wp_table.expect_work_package_listed(existing_wp)

        wp_table.click_inline_create
        expect(page).to have_selector('.wp--row', count: 2)
        expect(page).to have_selector('.wp-inline-create-row')
        expect(page).to have_focus_on('#wp-new-inline-edit--field-subject')

        # Expect subject to be activated
        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value 'Some subject'
        subject_field.save!

        # Callback for adjustments
        callback.call

        wp_table.expect_notification(
          message: 'Successful creation. Click here to open this work package in fullscreen view.'
        )

        # Expect new create row to exist
        expect(page).to have_selector('.wp--row', count: 2)
        expect(page).to have_selector('.wp-inline-create--add-link')

        wp_table.click_inline_create

        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value 'Another subject'
        subject_field.save!

        # Callback for adjustments
        callback.call

        expect(page).to have_selector('.wp--row .subject', text: 'Some subject')
        expect(page).to have_selector('.wp--row .subject', text: 'Another subject')

        # safegurards
        wp_table.dismiss_notification!
        wp_table.expect_no_notification(
          message: 'Successful update. Click here to open this work package in fullscreen view.'
        )

        # Expect no inline create open
        expect(page).to have_no_selector('.wp-inline-create-row')
      end
    end

    context 'when user may not create work packages' do
      let(:permissions) { [:view_work_packages] }

      it 'renders the work package, but no create row' do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_selector('.wp-inline-create--add-link')
      end
    end

    context 'when having filtered by custom field and switching to that type' do
      let(:cf_list) do
        FactoryBot.create(:list_wp_custom_field, is_for_all: true, is_filter: true)
      end
      let(:cf_accessor_frontend) { "customField#{cf_list.id}" }
      let(:types) { [type, cf_type] }
      let(:type) { FactoryBot.create(:type_standard) }
      let(:cf_type) { FactoryBot.create(:type, custom_fields: [cf_list]) }
      let(:columns) { ::Components::WorkPackages::Columns.new }

      it 'applies the filter value for the custom field' do
        wp_table.visit!
        filters.open
        filters.add_filter_by cf_list.name, 'is', cf_list.custom_options.second.name, cf_accessor_frontend

        sleep(0.3)

        columns.open_modal
        columns.add(cf_list.name, save_changes: true)

        wp_table.click_inline_create

        callback.call

        type_field = wp_table.edit_field(nil, :type)
        type_field.activate!
        type_field.openSelectField
        type_field.set_value cf_type.name

        wp_table.expect_notification(
          type: :error,
          message: 'Subject can\'t be blank.'
        )

        subject_field = wp_table.edit_field(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value 'Some subject'
        subject_field.save!

        wp_table.expect_notification(
          message: 'Successful creation. Click here to open this work package in fullscreen view.'
        )

        created_wp = WorkPackage.last

        cf_field = wp_table.edit_field(created_wp, :"customField#{cf_list.id}")
        cf_field.expect_text(cf_list.custom_options.second.name)
      end
    end
  end

  describe 'global create' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new }

    before do
      wp_table.visit!
    end

    it_behaves_like 'inline create work package' do
      let(:callback) do
        ->() {
          # Set project
          project_field = wp_table.edit_field(nil, :project)
          project_field.expect_active!

          project_field.openSelectField
          project_field.set_value project.name

          # Set type
          type_field = wp_table.edit_field(nil, :type)
          type_field.expect_active!

          type_field.openSelectField
          type_field.set_value type.name
        }
      end
    end
  end

  describe 'project context create' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like 'inline create work package' do
      let(:callback) do
        ->() {}
      end
    end

    context 'user has permissions in other project' do
      let(:permissions) { [:view_work_packages] }

      let(:project2) { FactoryBot.create :project }
      let(:role2) do
        FactoryBot.create :role,
                          permissions: %i[view_work_packages
                                          add_work_packages]
      end
      let!(:membership) do
        FactoryBot.create :member,
                          user: user,
                          project: project2,
                          roles: [role2]
      end

      it 'renders the work packages, but no create' do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_selector('.wp-inline-create--add-link')
        expect(page).to have_selector('.add-work-package[disabled]')
      end
    end
  end
end
