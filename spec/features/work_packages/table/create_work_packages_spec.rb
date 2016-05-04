require 'spec_helper'

describe 'inline create work package', js: true do
  let(:type) { FactoryGirl.create(:type_with_workflow) }
  let(:types) { [type] }

  let(:user) { FactoryGirl.create :admin }

  let!(:project) { FactoryGirl.create(:project, is_public: true, types: types) }
  let!(:existing_wp) { FactoryGirl.create(:work_package, project: project) }
  let!(:priority) { FactoryGirl.create :priority, is_default: true }

  before do
    login_as user
  end

  shared_examples 'inline create work package' do
    context 'when user may create work packages' do
      it 'allows to create work packages' do
        wp_table.expect_work_package_listed(existing_wp)

        wp_table.click_inline_create
        expect(page).to have_selector('.wp--row', count: 2)
        expect(page).to have_selector('.wp--row.-new')

        # Expect subject to be activated
        subject_field = InlineEditField.new(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value 'Some subject'
        subject_field.save!

        wp_table.expect_notification(
          message: 'Successful creation. Click here to open this work package in fullscreen view.'
        )

        # Expect new create row to exist
        expect(page).to have_selector('.wp--row', count: 3)
        expect(page).to have_selector('.wp--row.-new')

        subject_field = InlineEditField.new(nil, :subject)
        subject_field.expect_active!
        subject_field.set_value 'Another subject'
        subject_field.save!

        expect(page).to have_selector('.wp--row .subject', text: 'Some subject')
        expect(page).to have_selector('.wp--row .subject', text: 'Another subject')

        # Cancel creation
        expect(page).to have_selector('.wp--row.-new')
        page.find('.wp-table--cancel-create-link').click
        expect(page).to have_no_selector('.wp--row.-new')
        expect(page).to have_selector('.wp-inline-create--add-link')
      end
    end

    context 'when user may not create work packages' do
      let(:user) {
        FactoryGirl.create(:user, member_in_project: project, member_through_role: role)
      }
      let(:role) { FactoryGirl.create(:role, permissions: permissions) }
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

    it_behaves_like 'inline create work package'
  end

  describe 'project context create' do
    let(:wp_table) { ::Pages::WorkPackagesTable.new(project) }

    before do
      wp_table.visit!
    end

    it_behaves_like 'inline create work package'
  end
end
