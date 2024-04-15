require "spec_helper"
require "features/page_objects/notification"
require "features/work_packages/details/inplace_editor/shared_examples"
require "features/work_packages/shared_contexts"
require "support/edit_fields/edit_field"
require "features/work_packages/work_packages_page"

RSpec.describe "subject inplace editor", :js, :selenium do
  let(:project) { create(:project_with_types, public: true) }
  let(:property_name) { :subject }
  let(:property_title) { "Subject" }
  let(:work_package) { create(:work_package, project:) }
  let(:user) { create(:admin) }
  let(:work_packages_page) { Pages::SplitWorkPackage.new(work_package, project) }
  let(:field) { work_packages_page.edit_field(property_name) }
  let(:notification) { PageObjects::Notifications.new(page) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  context "as a read state" do
    it "has correct content" do
      field.expect_state_text(work_package.send(property_name))
    end
  end

  it_behaves_like "as an auth aware field"
  it_behaves_like "a cancellable field"
  it_behaves_like "as a single validation point"
  it_behaves_like "as a required field"

  context "as an edit state" do
    before do
      field.activate_edition
    end

    it "renders a text input" do
      expect(field.input_element).to be_visible
      expect(field.input_element["type"]).to eq "text"
    end

    it "has a correct value for the input" do
      expect(field.input_element[:value]).to eq work_package.subject
    end

    it "displays an error when too long" do
      too_long = "*" * 256
      field.set_value too_long
      field.submit_by_enter

      field.expect_error
      field.expect_active!
      expect(field.input_element.value).to eq(too_long)

      notification.expect_error("Subject is too long (maximum is 255 characters)")
    end

    context "when save" do
      before do
        field.input_element.set "Aloha"
      end

      # safeguard
      include_context "ensure wp details pane update done" do
        let(:update_user) { user }
      end

      it "saves the value on ENTER" do
        field.submit_by_enter
        field.expect_state_text("Aloha")
      end
    end
  end

  context "with conflicting modification" do
    it "shows a conflict when modified elsewhere" do
      work_package.subject = "Some other subject!"
      work_package.save!

      field.display_element.click

      notification.expect_error(I18n.t("api_v3.errors.code_409"))
    end
  end
end
