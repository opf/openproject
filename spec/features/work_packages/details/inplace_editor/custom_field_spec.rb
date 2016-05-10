require 'spec_helper'
require 'features/work_packages/work_packages_page'

describe 'custom field inplace editor', js: true, selenium: true do
  let(:user) { FactoryGirl.create :admin }
  let(:type) { FactoryGirl.create(:type_standard, custom_fields: [custom_field]) }
  let(:project) {
    FactoryGirl.create :project,
                       types: [type],
                       work_package_custom_fields: [custom_field]
  }

  let(:work_package) {
    FactoryGirl.create :work_package,
                       type: type,
                       project: project,
                       custom_values: { custom_field.id => 123 }
  }
  let(:wp_page) { Pages::SplitWorkPackage.new(work_package) }

  let(:property_name) { :customField1 }
  let(:field) { wp_page.edit_field(property_name) }

  before do
    login_as(user)

    wp_page.visit!
    wp_page.ensure_page_loaded

    wp_page.view_all_attributes

    field.activate_edition
    expect(page).to have_selector("#{field.field_selector} input")
  end

  def expect_update(value, update_args)
    field.input_element.set value
    field.submit_by_enter
    wp_page.expect_notification(update_args)
  end

  def expect_field_invalid(value)
    field.input_element.set value
    field.submit_by_enter
    expect(field).to have_selector("#{field.input_selector}:invalid")
  end

  describe 'integer type' do
    let(:custom_field) {
      FactoryGirl.create(:integer_issue_custom_field, args.merge(name: 'MyNumber'))
    }
    let(:fieldName) { "customField#{custom_field.id}" }

    context 'with length restrictions' do
      let(:args) {
        { min_length: 2, max_length: 5 }
      }

      it 'renders errors for invalid entries' do
        # Invalid input (non-digit)
        expect_field_invalid 'certainly no digit'

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
        wp_page.expect_attributes fieldName => '9999'
      end
    end

    context 'no restrictions' do
      let(:args) { {} }
      it 'renders errors for invalid entries' do
        # Invalid input (non-digit)
        expect_field_invalid 'certainly no digit'

        # Valid input
        expect_update '9999999999',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes fieldName => '9999999999'

        # Remove value
        field.activate_edition
        expect_update '',
                      message: I18n.t('js.notice_successful_update')
        wp_page.expect_attributes fieldName => '-'
      end
    end

    context 'required' do
      let(:args) { { is_required: true } }

      it 'renders errors for invalid entries' do
        # Invalid input (non-digit)
        expect_update '',
                      type: :error,
                      message: "MyNumber can't be blank"
      end
    end
  end
end
