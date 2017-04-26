require 'spec_helper'

describe 'inline create work package', js: true do
  let(:type) { FactoryGirl.create(:type) }
  let(:types) { [type] }

  let(:permissions) { %i(view_work_packages add_work_packages)}
  let(:role) { FactoryGirl.create :role, permissions: permissions }
  let(:user) do
    FactoryGirl.create :user,
                       member_in_project: project,
                       member_through_role: role
  end
  let(:status) { FactoryGirl.create(:default_status) }
  let(:workflow) do
    FactoryGirl.create :workflow,
                       type_id: type.id,
                       old_status: status,
                       new_status: FactoryGirl.create(:status),
                       role: role
  end

  let!(:project) { FactoryGirl.create(:project, is_public: true, types: types) }
  let!(:existing_wp) { FactoryGirl.create(:work_package, project: project) }
  let!(:priority) { FactoryGirl.create :priority, is_default: true }

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
        expect(page).to have_selector('.wp--row', count: 3)
        expect(page).to have_selector('.wp-inline-create-row')

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

        # Cancel creation
        expect(page).to have_selector('.wp-inline-create-row')
        page.find('.wp-table--cancel-create-link').click
        expect(page).to have_no_selector('.wp-inline-create-row')
        expect(page).to have_selector('.wp-inline-create--add-link')
      end
    end

    context 'when user may not create work packages' do
      let(:permissions) { [:view_work_packages] }

      it 'renders the work package, but no create row' do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_selector('.wp-inline-create--add-link')
      end
    end
  end

  describe 'global create' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new }

    before do
      wp_table.visit!
    end

    it_behaves_like 'inline create work package' do
      let(:callback) {
        ->() {
          # Set project
          project_field = wp_table.edit_field(nil, :project)
          project_field.expect_active!

          project_field.set_value project.name

          # Set type
          type_field = wp_table.edit_field(nil, :type)
          type_field.expect_active!

          type_field.set_value type.name
        }
      }
    end
  end

  describe 'project context create' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like 'inline create work package' do
      let(:callback) {
        ->() { }
      }
    end

    context 'user has permissions in other project' do
      let(:permissions) { [:view_work_packages] }

      let(:project2) { FactoryGirl.create :project }
      let(:role2) {
        FactoryGirl.create :role,
                           permissions: [:view_work_packages,
                                         :add_work_packages]
      }
      let!(:membership) {
        FactoryGirl.create :member,
                           user: user,
                           project: project2,
                           roles: [role2]
      }

      it 'renders the work packages, but no create' do
        wp_table.expect_work_package_listed(existing_wp)
        expect(page).to have_no_selector('.wp-inline-create--add-link')
        expect(page).to have_selector('.add-work-package[disabled]')
      end
    end
  end
end
