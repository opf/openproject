# frozen_string_literal: true

require "spec_helper"

RSpec.describe "custom fields", :js do
  let(:user) { create(:admin) }
  let(:cf_page) { Pages::CustomFields::Index.new }
  let(:editor) { Components::WysiwygEditor.new "#custom_field_form" }
  let(:type) { create(:type_task) }
  let!(:project) { create(:project, enabled_module_names: %i[work_package_tracking], types: [type]) }

  let(:wp_page) { Pages::FullWorkPackageCreate.new project: }

  let(:default_text) do
    <<~MARKDOWN
      # This is an exemplary test

      **Foo bar**

    MARKDOWN
  end

  current_user { user }

  before do
    cf_page.visit!
  end

  describe "creating a new long text custom field" do
    it "creates a new bool custom field" do
      cf_page.click_to_create_new_custom_field("Long text")

      cf_page.set_name "New Field"

      editor.set_markdown default_text

      cf_page.set_all_projects true
      click_on "Save"

      cf_page.expect_and_dismiss_flash(message: "Successful creation.")
      expect(page).to have_text("New Field")

      cf = CustomField.last
      expect(cf.field_format).to eq "text"

      # textareas get carriage returns entered
      expect(cf.default_value.gsub("\r\n", "\n").strip).to eq default_text.strip

      type.default_variant.custom_fields << cf
      type.save!

      wp_page.visit!
      wp_editor = TextEditorField.new(page, "description", selector: ".inline-edit--container.customField#{cf.id}")
      wp_editor.expect_active!

      wp_editor.ckeditor.in_editor do |container, _|
        expect(container).to have_css("h1", text: "This is an exemplary test")
        expect(container).to have_css("strong", text: "Foo bar")
      end
    end
  end
end
