require 'spec_helper'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/details/inplace_editor/work_package_field'

describe 'subject inplace editor', js: true do
  let(:project) { FactoryGirl.create :project_with_types, is_public: true }
  let(:property_name) { :subject }
  let(:property_title) { 'Subject' }
  let!(:work_package) { FactoryGirl.create :work_package, project: project }
  let(:user) { FactoryGirl.create :admin }

  let(:field_selector) { '.work-package-field.work-packages--details--subject' }
  let(:field) { WorkPackageField.new page.find(field_selector) }
  before do
    allow(User).to receive(:current).and_return(user)
    visit project_work_packages_path(project)
    page.driver.browser.manage.window.resize_to(1300, 1024)
    row = page.find("#work-package-#{work_package.id}")
    sleep 0.1 # wait for angular to run digest to hook the listeners
    # TODO: try capybara-angular
    row.double_click
  end

  context 'in read state' do
    it 'has correct content' do
      expect(field.read_state_text).to eq work_package.send(property_name)
    end

    context 'when is editable' do
      it_behaves_like 'an accessible inplace editor'
    end

    context 'when user is authorized' do
      it 'is editable' do
        expect(field.trigger_link).to be_visible
      end
    end

    context 'when user is not authorized' do
      let(:user) {
        FactoryGirl.create :user,
          member_in_project: project,
          member_through_role: FactoryGirl.build(
            :role,
            permissions: [:view_work_packages]
          )
      }

      it 'is not editable' do
        expect { field.trigger_link }.to raise_error Capybara::ElementNotFound
      end
    end
  end

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
