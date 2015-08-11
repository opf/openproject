require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'features/work_packages/details/inplace_editor/work_package_field'
require 'features/work_packages/work_packages_page'

describe 'subject inplace editor', js: true do
  include_context 'maximized window'

  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let(:property_name) { :subject }
  let(:property_title) { 'Subject' }
  let!(:work_package) { FactoryGirl.create :work_package, project: project }
  let(:user) { FactoryGirl.create :admin }
  let(:work_packages_page) { WorkPackagesPage.new(project) }
  let(:field) { WorkPackageField.new page, property_name }

  before do
    allow(User).to receive(:current).and_return(user)

    work_packages_page.visit_index(work_package)
  end

  context 'in read state' do
    it 'has correct content' do
      expect(field.read_state_text).to eq work_package.send(property_name)
    end
  end

  it_behaves_like 'an auth aware field'
  it_behaves_like 'a cancellable field'
  it_behaves_like 'having a single validation point'
  it_behaves_like 'a required field'

  context 'in edit state' do
    before do
      field.activate_edition
    end

    it 'renders a text input' do
      expect(field.input_element).to be_visible
      expect(field.input_element['type']).to eq 'text'
    end

    it 'has a correct value for the input' do
      expect(field.input_element[:value]).to eq work_package.subject
    end

    context 'on save' do
      before do
        field.input_element.set 'Aloha'
      end

      # safeguard
      include_context 'ensure wp details pane update done' do
        let(:update_user) { user }
      end

      it 'displays the new value after save' do
        field.submit_by_click
        expect(field.read_state_text).to eq 'Aloha'
      end

      it 'saves the value on ENTER' do
        field.submit_by_enter
        expect(field.read_state_text).to eq 'Aloha'
      end
    end
  end
end
