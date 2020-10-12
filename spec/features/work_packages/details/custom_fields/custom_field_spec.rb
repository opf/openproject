require 'spec_helper'
require 'features/work_packages/work_packages_page'
require 'features/work_packages/details/inplace_editor/shared_examples'

describe 'custom field inplace editor', js: true do
  let(:user) { FactoryBot.create :admin }
  let(:type) { FactoryBot.create(:type_standard, custom_fields: custom_fields) }
  let(:project) do
    FactoryBot.create :project,
                      types: [type],
                      work_package_custom_fields: custom_fields
  end
  let(:custom_fields) { [custom_field] }
  let(:work_package) do
    FactoryBot.create :work_package,
                      type: type,
                      project: project,
                      custom_values: initial_custom_values
  end
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }

  let(:property_name) { "customField#{custom_field.id}" }
  let(:field) { wp_page.edit_field(property_name) }

  before do
    login_as(user)

    wp_page.visit!
    wp_page.ensure_page_loaded
  end

  def expect_update(value, update_args)
    wp_field = update_args.delete(:field) { field }

    wp_field.set_value value
    wp_field.submit_by_enter if wp_field.field_type == 'input'
    wp_page.expect_notification(update_args)
    wp_page.dismiss_notification!
  end

  describe 'long text' do
    let(:custom_field) do
      FactoryBot.create(:text_issue_custom_field, name: 'LongText')
    end
    let(:field) { TextEditorField.new wp_page, property_name }
    let(:initial_custom_values) { { custom_field.id => 'foo' } }

    it 'can cancel through the button only' do
      # Activate the field
      field.activate!

      # Pressing escape does nothing here
      field.cancel_by_escape
      field.expect_active!

      # Cancelling through the action panel
      field.cancel_by_click
      field.expect_inactive!
    end

    it_behaves_like 'a workpackage autocomplete field'
  end

  describe 'custom field lists' do
    let(:custom_field1) do
      FactoryBot.create(:list_wp_custom_field,
                        is_required: false,
                        possible_values: %w(foo bar baz))
    end
    let(:custom_field2) do
      FactoryBot.create(:list_wp_custom_field,
                        is_required: false,
                        possible_values: %w(X Y Z))
    end

    let(:custom_fields) { [custom_field1, custom_field2] }
    let(:field1) do
      f = wp_page.custom_edit_field(custom_field1)
      f.field_type = 'create-autocompleter'
      f
    end
    let(:field2) do
      f = wp_page.custom_edit_field(custom_field2)
      f.field_type = 'create-autocompleter'
      f
    end
    let(:initial_custom_values) { {} }

    def custom_value(value)
      CustomOption.find_by(value: value).try(:id)
    end

    it 'properly updates both values' do
      field1.activate!
      expect_update 'bar',
                    message: I18n.t('js.notice_successful_update'),
                    field: field1

      field2.activate!
      expect_update 'Y',
                    message: I18n.t('js.notice_successful_update'),
                    field: field2

      wp_page.expect_attributes :"customField#{custom_field1.id}" => 'bar',
                                :"customField#{custom_field2.id}" => 'Y'

      field1.activate!
      expect(field1.input_element).to have_text 'bar'

      field1.cancel_by_escape

      field2.activate!
      expect(field2.input_element).to have_text 'Y'

      expect_update 'X',
                    message: I18n.t('js.notice_successful_update'),
                    field: field2

      wp_page.expect_attributes :"customField#{custom_field1.id}" => 'bar',
                                :"customField#{custom_field2.id}" => 'X'
    end
  end

  describe 'integer type' do
    let(:custom_field) do
      FactoryBot.create(:integer_issue_custom_field, args.merge(name: 'MyNumber'))
    end
    let(:initial_custom_values) { { custom_field.id => 123 } }

    context 'with length restrictions' do
      let(:args) do
        { min_length: 2, max_length: 5 }
      end

      it 'renders errors for invalid entries' do
        field.activate!
        # exceeding max length
        expect_update '123456',
                      type: :error,
                      message: 'MyNumber is too long (maximum is 5 characters).'

        # below min length
        expect_update '1',
                      type: :error,
                      message: 'MyNumber is too short (minimum is 2 characters).'

        # Correct value
        expect_update '9999',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes property_name => '9999'
      end
    end

    context 'no restrictions' do
      let(:args) { {} }
      it 'renders errors for invalid entries' do
        # Valid input
        field.activate!
        expect_update '9999999999',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes property_name => '9999999999'

        # Remove value
        field.activate!
        expect_update '',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes property_name => '-'

        # Zero value
        field.activate_edition
        expect_update '0',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes property_name => '0'
      end
    end

    context 'required' do
      let(:args) { { is_required: true } }

      it 'renders errors for invalid entries' do
        # Invalid input (non-digit)
        field.activate!
        field.set_value ''
        field.expect_invalid

        field.save!

        work_package.reload
        expect(work_package.send("custom_field_#{custom_field.id}")).to eq 123
      end
    end
  end

  describe 'float type' do
    let(:custom_field) do
      FactoryBot.create(:float_wp_custom_field, args.merge(name: 'MyFloat'))
    end
    let(:args) { {} }
    let(:initial_custom_values) { { custom_field.id => 123.50 } }

    context 'with english locale' do
      let(:user) { FactoryBot.create :admin, language: 'en' }

      it 'displays the float with english locale and allows editing' do
        field.expect_state_text '123.5'
        field.update '10000.55'
        field.expect_state_text '10,000.55'

        work_package.reload
        expect(work_package.custom_value_for(custom_field.id).typed_value).to eq 10000.55
      end
    end

    context 'with german locale',
            driver: :firefox_headless_de do
      let(:user) { FactoryBot.create :admin, language: 'de' }

      it 'displays the float with german locale and allows editing' do
        field.expect_state_text '123,5'
        field.update '10000,55'
        field.expect_state_text '10.000,55'

        work_package.reload
        expect(work_package.custom_value_for(custom_field.id).typed_value).to eq 10000.55
      end
    end
  end
end
