require "spec_helper"
require "support/pages/work_packages/abstract_work_package"

describe "multi select custom values", js: true do
  let(:type) { FactoryBot.create :type }
  let(:project) { FactoryBot.create :project, types: [type] }

  let(:custom_field) do
    FactoryBot.create(
      :user_wp_custom_field,
      name: "Reviewer",
      multi_value: true,
      types: [type],
      projects: [project]
    )
  end

  let(:cf_edit_field) do
    field = wp_page.edit_field "customField#{custom_field.id}"
    field.field_type = 'create-autocompleter'
    field
  end

  let(:member_names) { ["Billy Nobbler", "Cooper Quatermaine", "Anton Lupin"] }

  # We include an invited member to check at the same time that invited users are properly
  # offered for user custom fields as they weren't before.
  let(:member_statuses) do
    [User::STATUSES[:active], User::STATUSES[:active], User::STATUSES[:invited]]
  end

  let(:members) do
    member_names.zip(member_statuses).map do |name, status|
      first, last = name.split(" ")

      FactoryBot.create :user, firstname: first, lastname: last, status: status
    end
  end

  let(:role) { FactoryBot.create :role }

  let(:wp_page) { Pages::FullWorkPackage.new work_package }
  let(:user) { FactoryBot.create :admin }

  before do
    members.each do |user|
      project.add_member user, role
    end

    project.save!
  end

  context "with existing custom values" do
    let(:work_package) do
      wp = FactoryBot.build :work_package, project: project, type: type

      wp.custom_field_values = {
        custom_field.id => [members[0].id.to_s, members[2].id.to_s]
      }

      wp.save
      wp
    end

    before do
      login_as(user)

      wp_page.visit!
      wp_page.ensure_page_loaded
    end

    it "should be shown and allowed to be updated" do
      expect(page).to have_text custom_field.name
      expect(page).to have_text "Billy Nobbler"
      expect(page).to have_text "Anton Lupin"

      page.find(".inline-edit--display-field", text: "Billy Nobbler").click

      cf_edit_field.unset_value "Anton Lupin", true
      cf_edit_field.set_value "Cooper Quatermaine"

      click_on "Reviewer: Save"

      expect(page).to have_selector('.custom-option', count: 2)
      expect(page).to have_text "Successful update"

      expect(page).to have_text custom_field.name
      expect(page).to have_text "Billy Nobbler"
      expect(page).not_to have_text "Anton Lupin"
      expect(page).to have_text "Cooper Quatermaine"
    end
  end
end
