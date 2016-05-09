require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/work_packages/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'description inplace editor', js: true, selenium: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let(:property_name) { :description }
  let(:property_title) { 'Description' }
  let(:description_text) { 'Ima description' }
  let!(:work_package) {
    FactoryGirl.create(
      :work_package,
      project: project,
      description: description_text
    )
  }
  let(:user) { FactoryGirl.create :admin }
  let(:field) { WorkPackageField.new page, property_name }
  let(:work_packages_page) { WorkPackagesPage.new(project) }

  before do
    login_as(user)

    work_packages_page.visit_index(work_package)
  end

  context 'in read state' do
    it 'renders the correct text' do
      field.expect_state_text work_package.send(property_name)
    end

    context 'when is empty' do
      let(:description_text) { '' }

      it 'renders a placeholder' do
        field.expect_state_text 'Click to enter description...'
      end
    end

    context 'when is editable' do
      context 'when clicking on an anchor' do
        it 'navigates to the given url'
        it 'does not trigger editing'
      end
    end
  end

  it_behaves_like 'an auth aware field'
  it_behaves_like 'a cancellable field'

  context 'in edit state' do
    before do
      field.activate_edition
    end

    after do
      field.cancel_by_click
    end

    it 'renders a textarea' do
      expect(field.input_element).to be_visible
      expect(field.input_element.tag_name).to eq 'textarea'
    end
    it 'renders formatting buttons'
    it 'renders a preview button'
    it 'prevents page navigation in edit mode'
    it 'has a correct value for the textarea'
    it 'displays the new HTML after save'
  end
end
