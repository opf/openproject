#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Projects', type: :feature, js: true do
  let(:current_user) { FactoryBot.create(:admin) }
  let(:name_field) { ::FormFields::InputFormField.new :name }
  let(:parent_field) { ::FormFields::SelectFormField.new :parent }

  before do
    allow(User).to receive(:current).and_return current_user
  end

  describe 'creation' do
    shared_let(:project) { FactoryBot.create(:project, name: 'Foo project', identifier: 'foo-project') }

    before do
      visit projects_path
    end

    it 'can create a project' do
      click_on 'New project'

      name_field.set_value 'Foo bar'
      click_button 'Save'

      expect(page).to have_content 'Foo bar'
      expect(page).to have_current_path /\/projects\/foo-bar\/?/
    end

    it 'can create a subproject' do
      click_on project.name
      SeleniumHubWaiter.wait
      click_on 'Project settings'
      SeleniumHubWaiter.wait
      click_on 'New subproject'

      name_field.set_value 'Foo child'
      parent_field.expect_selected project.name

      click_button 'Save'

      expect(page).to have_current_path /\/projects\/foo-child\/?/

      child = Project.last
      expect(child.identifier).to eq 'foo-child'
      expect(child.parent).to eq project
    end

    it 'does not create a project with an already existing identifier' do
      skip "TODO identifier is not yet rendered on error in dynamic form"

      click_on 'New project'

      name_field.set_value 'Foo project'
      click_on 'Save'

      expect(page).to have_content 'Identifier has already been taken'
      expect(page).to have_current_path /\/projects\/new\/?/
    end

    context 'with a multi-select custom field' do
      let!(:list_custom_field) { FactoryBot.create(:list_project_custom_field, name: 'List CF', multi_value: true) }
      let(:list_field) { ::FormFields::SelectFormField.new list_custom_field }

      it 'can create a project' do
        click_on 'New project'

        name_field.set_value 'Foo bar'

        find('.form--fieldset-legend a', text: 'ADVANCED SETTINGS').click

        list_field.select_option 'A', 'B'

        click_button 'Save'

        expect(page).to have_current_path /\/projects\/foo-bar\/?/
        expect(page).to have_content 'Foo bar'

        project = Project.last
        expect(project.name).to eq 'Foo bar'
        cvs = project.custom_value_for(list_custom_field)
        expect(cvs.count).to eq 2
        expect(cvs.map(&:typed_value)).to contain_exactly 'A', 'B'
      end
    end
  end

  describe 'project types' do
    let(:phase_type)     { FactoryBot.create(:type, name: 'Phase', is_default: true) }
    let(:milestone_type) { FactoryBot.create(:type, name: 'Milestone', is_default: false) }
    let!(:project) { FactoryBot.create(:project, name: 'Foo project', types: [phase_type, milestone_type]) }

    it "have the correct types checked for the project's types" do
      visit projects_path
      click_on 'Foo project'
      click_on 'Project settings'
      click_on 'Work package types'

      field_checked = find_field('Phase', visible: false)['checked']
      expect(field_checked).to be_truthy
      field_checked = find_field('Milestone', visible: false)['checked']
      expect(field_checked).to be_truthy
    end
  end

  describe 'deletion' do
    let(:project) { FactoryBot.create(:project) }
    let(:projects_page) { Pages::Projects::Destroy.new(project) }

    before do
      projects_page.visit!
    end

    describe 'disable delete w/o confirm' do
      it { expect(page).to have_css('.danger-zone .button[disabled]') }
    end

    describe 'disable delete with wrong input' do
      let(:input) { find('.danger-zone input') }
      it do
        input.set 'Not the project name'
        expect(page).to have_css('.danger-zone .button[disabled]')
      end
    end

    describe 'enable delete with correct input' do
      let(:input) { find('.danger-zone input') }
      it do
        input.set project.name
        expect(page).to have_css('.danger-zone .button:not([disabled])')
      end
    end
  end

  describe 'identifier edit' do
    let!(:project) { FactoryBot.create(:project, identifier: 'foo') }

    it 'updates the project identifier' do
      visit projects_path
      click_on project.name
      SeleniumHubWaiter.wait
      click_on 'Project settings'
      SeleniumHubWaiter.wait
      click_on 'Change identifier'

      expect(page).to have_content "CHANGE THE PROJECT'S IDENTIFIER"
      expect(current_path).to eq '/projects/foo/identifier'

      fill_in 'project[identifier]', with: 'foo-bar'
      click_on 'Update'

      expect(page).to have_content 'Successful update.'
      expect(current_path).to match '/projects/foo-bar/settings/generic'
      expect(Project.first.identifier).to eq 'foo-bar'
    end

    it 'displays error messages on invalid input' do
      visit identifier_project_path(project)

      fill_in 'project[identifier]', with: 'FOOO'
      click_on 'Update'

      expect(page).to have_content 'Identifier is invalid.'
      expect(current_path).to eq '/projects/foo/identifier'
    end
  end

  describe 'form' do
    let(:project) { FactoryBot.build(:project, name: 'Foo project', identifier: 'foo-project') }

    context 'when creating' do
      it 'hides the active field and the identifier' do
        visit new_project_path

        find('.form--fieldset-legend a', text: 'ADVANCED SETTINGS').click

        expect(page).to have_no_content 'Active'
        expect(page).to have_no_content 'Identifier'
      end
    end

    context 'when editing' do
      it 'hides the active field' do
        project.save!

        visit settings_generic_project_path(project.id)

        expect(page).to have_no_text :all, 'Active'
        expect(page).to have_no_text :all, 'Identifier'
      end
    end

    context 'with optional and required custom fields' do
      let!(:optional_custom_field) do
        FactoryBot.create(:custom_field, name: 'Optional Foo',
                          type: ProjectCustomField,
                          is_for_all: true)
      end
      let!(:required_custom_field) do
        FactoryBot.create(:custom_field, name: 'Required Foo',
                          type: ProjectCustomField,
                          is_for_all: true,
                          is_required: true)
      end

      it 'seperates optional and required custom fields for new' do
        visit new_project_path

        expect(page).to have_content 'Required Foo'

        click_on 'Advanced settings'

        within('.form--fieldset') do
          expect(page).to have_text 'Optional Foo'
          expect(page).to have_no_text 'Required Foo'
        end
      end

      it 'shows optional and required custom fields for edit without a separation' do
        project.custom_field_values.last.value = 'FOO'
        project.save!

        visit settings_generic_project_path(project.id)

        expect(page).to have_text 'Optional Foo'
        expect(page).to have_text 'Required Foo'
      end
    end

    context 'with a length restricted custom field' do
      let(:project) { FactoryBot.create(:project, name: 'Foo project', identifier: 'foo-project') }
      let!(:required_custom_field) do
        FactoryBot.create(:string_project_custom_field,
                          name: 'Foo',
                          type: ProjectCustomField,
                          min_length: 1,
                          max_length: 2,
                          is_for_all: true)
      end
      let(:foo_field) { ::FormFields::InputFormField.new required_custom_field }

      it 'shows the errors of that field when saving (Regression #33766)' do
        visit settings_generic_project_path(project.id)

        expect(page).to have_content 'Foo'

        # Enter something too long
        foo_field.set_value '1234'

        # It should cut of that remaining value
        foo_field.expect_value '12'

        click_button 'Save'

        expect(page).to have_text 'Successful update.'
      end
    end
  end

  context 'with a multi-select custom field' do
    include_context 'ng-select-autocomplete helpers'

    let(:project) { FactoryBot.create(:project, name: 'Foo project', identifier: 'foo-project') }
    let!(:list_custom_field) { FactoryBot.create(:list_project_custom_field, name: 'List CF', multi_value: true) }
    let(:form_field) { ::FormFields::SelectFormField.new list_custom_field }

    it 'can create a project' do
      visit settings_generic_project_path(project.id)

      form_field.select_option 'A', 'B'

      click_on 'Save'

      expect(page).to have_content 'Successful update.'

      form_field.expect_selected 'A', 'B'

      cvs = project.reload.custom_value_for(list_custom_field)
      expect(cvs.count).to eq 2
      expect(cvs.map(&:typed_value)).to contain_exactly 'A', 'B'
    end
  end
end
