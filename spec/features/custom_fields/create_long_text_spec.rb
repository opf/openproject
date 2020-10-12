require 'spec_helper'
require 'support/pages/custom_fields'

describe 'custom fields', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:cf_page) { Pages::CustomFields.new }
  let(:editor) { ::Components::WysiwygEditor.new '#default_value_long_text' }
  let(:type) { FactoryBot.create :type_task }
  let(:project) { FactoryBot.create :project, enabled_module_names: %i[work_package_tracking], types: [type] }

  let(:wp_page) { Pages::FullWorkPackageCreate.new project: project }

  let(:default_text) do
    <<~MARKDOWN
      # This is an exemplary test

      **Foo bar**

    MARKDOWN
  end

  before do
    login_as(user)
  end

  describe "creating a new long text custom field" do
    before do
      cf_page.visit!
      click_on "Create a new custom field"
    end

    it "creates a new bool custom field" do
      cf_page.set_name "New Field"
      cf_page.select_format "Long text"

      sleep 1

      editor.set_markdown default_text

      cf_page.set_all_projects true
      click_on "Save"

      expect(page).to have_text("Successful creation")
      expect(page).to have_text("New Field")

      cf = CustomField.last
      expect(cf.field_format).to eq 'text'

      # textareas get carriage returns entered
      expect(cf.default_value.gsub("\r\n", "\n").strip).to eq default_text.strip

      type.custom_fields << cf
      type.save!


      wp_page.visit!
      wp_editor = TextEditorField.new(page, 'description', selector: ".inline-edit--container.customField#{cf.id}")
      wp_editor.expect_active!

      wp_editor.ckeditor.in_editor do |container, _|
        expect(container).to have_selector('h1', text: 'This is an exemplary test')
        expect(container).to have_selector('strong', text: 'Foo bar')
      end
    end
  end
end
