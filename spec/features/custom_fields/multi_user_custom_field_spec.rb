require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

describe "multi select custom values", js: true do
  shared_let(:admin) { FactoryBot.create :admin }
  let(:current_user) { admin }

  shared_let(:type) { FactoryBot.create :type }
  shared_let(:project) { FactoryBot.create :project, types: [type] }
  shared_let(:role) { FactoryBot.create :role }

  shared_let(:custom_field) do
    FactoryBot.create(
      :user_wp_custom_field,
      name: "Reviewer",
      multi_value: true,
      types: [type],
      projects: [project]
    )
  end

  let(:wp_page) { Pages::FullWorkPackage.new work_package }

  let(:cf_edit_field) do
    field = wp_page.edit_field "customField#{custom_field.id}"
    field.field_type = 'create-autocompleter'
    field
  end

  before do
    login_as current_user
    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  describe 'with mixed users, group, and placeholdders' do
    let(:work_package) { FactoryBot.create :work_package, project: project, type: type }

    let!(:user) do
      FactoryBot.create :user,
                        firstname: 'Da Real',
                        lastname: 'User',
                        member_in_project: project,
                        member_through_role: role
    end

    let!(:group) do
      FactoryBot.create :group,
                        name: 'groupfoo',
                        member_in_project: project,
                        member_through_role: role
    end

    let!(:placeholder) do
      FactoryBot.create :placeholder_user,
                        name: 'PLACEHOLDER',
                        member_in_project: project,
                        member_through_role: role
    end

    it "should be shown and allowed to be updated" do
      expect(page).to have_text custom_field.name

      cf_edit_field.activate!
      cf_edit_field.set_value "Da Real"
      cf_edit_field.set_value "groupfoo"
      cf_edit_field.set_value "PLACEHOLDER"

      cf_edit_field.submit_by_dashboard

      expect(page).to have_text custom_field.name
      expect(page).to have_text "Da Real"
      expect(page).to have_text "groupfoo"
      expect(page).to have_text "PLACEHOLDER"

      wp_page.expect_and_dismiss_notification(message: "Successful update.")

      work_package.reload
      cvs = work_package
          .custom_value_for(custom_field)
          .map(&:typed_value)

      expect(cvs).to contain_exactly(group, user, placeholder)

      cf_edit_field.activate!
      cf_edit_field.unset_value "Da Real", true
      cf_edit_field.submit_by_dashboard

      wp_page.expect_and_dismiss_notification(message: "Successful update.")

      expect(page).to have_text "groupfoo"
      expect(page).to have_text "PLACEHOLDER"
      expect(page).to have_no_text "Da Real"

      work_package.reload
      cvs = work_package
          .custom_value_for(custom_field)
          .map(&:typed_value)

      expect(cvs).to contain_exactly(group, placeholder)
    end
  end

  describe 'with all users' do
    let!(:user1) do
      FactoryBot.create :user,
                        firstname: 'Billy',
                        lastname: 'Nobbler',
                        member_in_project: project,
                        member_through_role: role
    end

    let!(:user2) do
      FactoryBot.create :user,
                        firstname: 'Cooper',
                        lastname: 'Quatermaine',
                        member_in_project: project,
                        member_through_role: role
    end

    let!(:user3) do
      FactoryBot.create :user,
                        firstname: 'Anton',
                        lastname: 'Lupin',
                        status: User.statuses[:invited],
                        member_in_project: project,
                        member_through_role: role
    end

    context "with existing custom values" do
      let(:work_package) do
        wp = FactoryBot.build :work_package, project: project, type: type

        wp.custom_field_values = {
          custom_field.id => [user1.id.to_s, user3.id.to_s]
        }

        wp.save
        wp
      end

      it "should be shown and allowed to be updated" do
        expect(page).to have_text custom_field.name
        expect(page).to have_text "Billy Nobbler"
        expect(page).to have_text "Anton Lupin"

        page.find(".inline-edit--display-field", text: "Billy Nobbler").click

        cf_edit_field.unset_value "Anton Lupin", true
        cf_edit_field.set_value "Cooper Quatermaine"

        click_on "Reviewer: Save"
        wp_page.expect_and_dismiss_notification(message: "Successful update.")
        expect(page).to have_selector('.custom-option', count: 2)

        expect(page).to have_text custom_field.name
        expect(page).to have_text "Billy Nobbler"
        expect(page).not_to have_text "Anton Lupin"
        expect(page).to have_text "Cooper Quatermaine"
      end
    end
  end
end
