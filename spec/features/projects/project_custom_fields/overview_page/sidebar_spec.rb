#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'
require_relative 'shared_context'
require_relative 'overview_page'

RSpec.describe 'Show project custom fields on project overview page', :js, :with_cuprite do
  include_context 'with seeded projects, members and project custom fields'

  let(:overview_page) { OverviewPage.new(project) }

  before do
    login_as admin
  end

  describe 'with disabled project attributes feature', with_flag: { project_attributes: false } do
    it 'does not show the project attributes sidebar' do
      overview_page.visit_page

      within '.op-grid-page' do
        expect(page).to have_no_css('#project-attributes-sidebar')
      end
    end
  end

  describe 'with enabled project attributes feature', with_flag: { project_attributes: true } do
    it 'does show the project attributes sidebar' do
      overview_page.visit_page

      within '.op-grid-page' do
        expect(page).to have_css('#project-attributes-sidebar')
      end
    end

    describe 'with correct scoping' do
      it 'shows enabled project custom fields in a sidebar grouped by section' do
        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          expect(page).to have_css('.op-project-custom-field-section-container', count: 3)

          overview_page.within_custom_field_section_container(section_for_input_fields) do
            expect(page).to have_text 'Input fields'

            expect(page).to have_text 'Boolean field'
            expect(page).to have_text 'String field'
            expect(page).to have_text 'Integer field'
            expect(page).to have_text 'Float field'
            expect(page).to have_text 'Date field'
            expect(page).to have_text 'Text field'
          end

          overview_page.within_custom_field_section_container(section_for_select_fields) do
            expect(page).to have_text 'Select fields'

            expect(page).to have_text 'List field'
            expect(page).to have_text 'Version field'
            expect(page).to have_text 'User field'
          end

          overview_page.within_custom_field_section_container(section_for_multi_select_fields) do
            expect(page).to have_text 'Multi select fields'

            expect(page).to have_text 'Multi list field'
            expect(page).to have_text 'Multi version field'
            expect(page).to have_text 'Multi user field'
          end
        end
      end

      it 'does not show project custom fields not enabled for this project in a sidebar' do
        create(:string_project_custom_field, projects: [other_project], name: 'String field enabled for other project')

        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          expect(page).to have_no_text 'String field enabled for other project'
        end
      end
    end

    describe 'with correct order' do
      it 'shows the project custom field sections in the correct order' do
        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          sections = page.all('.op-project-custom-field-section-container')

          expect(sections.size).to eq(3)

          expect(sections[0].text).to include('Input fields')
          expect(sections[1].text).to include('Select fields')
          expect(sections[2].text).to include('Multi select fields')
        end

        section_for_input_fields.move_to_bottom

        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          sections = page.all('.op-project-custom-field-section-container')

          expect(sections.size).to eq(3)

          expect(sections[0].text).to include('Select fields')
          expect(sections[1].text).to include('Multi select fields')
          expect(sections[2].text).to include('Input fields')
        end
      end

      it 'shows the project custom fields in the correct order within the sections' do
        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          overview_page.within_custom_field_section_container(section_for_input_fields) do
            fields = page.all('.op-project-custom-field-container')

            expect(fields.size).to eq(6)

            expect(fields[0].text).to include('Boolean field')
            expect(fields[1].text).to include('String field')
            expect(fields[2].text).to include('Integer field')
            expect(fields[3].text).to include('Float field')
            expect(fields[4].text).to include('Date field')
            expect(fields[5].text).to include('Text field')
          end
        end

        string_project_custom_field.move_to_bottom

        overview_page.visit_page

        overview_page.within_async_loaded_sidebar do
          overview_page.within_custom_field_section_container(section_for_input_fields) do
            fields = page.all('.op-project-custom-field-container')

            expect(fields.size).to eq(6)

            expect(fields[0].text).to include('Boolean field')
            expect(fields[1].text).to include('Integer field')
            expect(fields[2].text).to include('Float field')
            expect(fields[3].text).to include('Date field')
            expect(fields[4].text).to include('Text field')
            expect(fields[5].text).to include('String field')
          end
        end
      end
    end

    describe 'with correct values' do
      describe 'with boolean CF' do
        # it_behaves_like 'a project custom field' do
        #   let(subject) { boolean_project_custom_field }
        # end

        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(boolean_project_custom_field) do
                expect(page).to have_text 'Boolean field'
                expect(page).to have_text 'Yes'
              end
            end
          end
        end

        describe 'with value unset by user' do
          # A boolean cannot be completely unset via UI, only toggle between true and false, no blank value possible
          before do
            boolean_project_custom_field.custom_values.where(customized: project).first.update!(value: false)
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(boolean_project_custom_field) do
                expect(page).to have_text 'Boolean field'
                expect(page).to have_text 'No'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            boolean_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(boolean_project_custom_field) do
                expect(page).to have_text 'Boolean field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            boolean_project_custom_field.update!(default_value: true)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(boolean_project_custom_field) do
                expect(page).to have_text 'Boolean field'
                expect(page).to have_text 'Yes'
              end
            end

            boolean_project_custom_field.update!(default_value: false)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(boolean_project_custom_field) do
                expect(page).to have_text 'Boolean field'
                expect(page).to have_text 'No'
              end
            end
          end
        end
      end

      describe 'with string CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(string_project_custom_field) do
                expect(page).to have_text 'String field'
                expect(page).to have_text 'Foo'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            string_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(string_project_custom_field) do
                expect(page).to have_text 'String field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            string_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(string_project_custom_field) do
                expect(page).to have_text 'String field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            string_project_custom_field.update!(default_value: 'Bar')

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(string_project_custom_field) do
                expect(page).to have_text 'String field'
                expect(page).to have_text 'Bar'
              end
            end
          end
        end
      end

      describe 'with integer CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(integer_project_custom_field) do
                expect(page).to have_text 'Integer field'
                expect(page).to have_text '123'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            integer_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(integer_project_custom_field) do
                expect(page).to have_text 'Integer field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            integer_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(integer_project_custom_field) do
                expect(page).to have_text 'Integer field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            integer_project_custom_field.update!(default_value: 456)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(integer_project_custom_field) do
                expect(page).to have_text 'Integer field'
                expect(page).to have_text '456'
              end
            end
          end
        end
      end

      describe 'with date CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(date_project_custom_field) do
                expect(page).to have_text 'Date field'
                expect(page).to have_text '01/01/2024'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            date_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(date_project_custom_field) do
                expect(page).to have_text 'Date field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            date_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(date_project_custom_field) do
                expect(page).to have_text 'Date field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            date_project_custom_field.update!(default_value: Date.new(2024, 2, 2))

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(date_project_custom_field) do
                expect(page).to have_text 'Date field'
                expect(page).to have_text '02/02/2024'
              end
            end
          end
        end
      end

      describe 'with float CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(float_project_custom_field) do
                expect(page).to have_text 'Float field'
                expect(page).to have_text '123.456'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            float_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(float_project_custom_field) do
                expect(page).to have_text 'Float field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            float_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(float_project_custom_field) do
                expect(page).to have_text 'Float field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            float_project_custom_field.update!(default_value: 456.789)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(float_project_custom_field) do
                expect(page).to have_text 'Float field'
                expect(page).to have_text '456.789'
              end
            end
          end
        end
      end

      describe 'with text CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(text_project_custom_field) do
                expect(page).to have_text 'Text field'
                expect(page).to have_text "Lorem\nipsum"
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            text_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(text_project_custom_field) do
                expect(page).to have_text 'Text field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            text_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(text_project_custom_field) do
                expect(page).to have_text 'Text field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            text_project_custom_field.update!(default_value: 'Dolor sit amet')

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(text_project_custom_field) do
                expect(page).to have_text 'Text field'
                expect(page).to have_text 'Dolor sit amet'
              end
            end
          end
        end
      end

      describe 'with list CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(list_project_custom_field) do
                expect(page).to have_text 'List field'
                expect(page).to have_text 'Option 1'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            list_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(list_project_custom_field) do
                expect(page).to have_text 'List field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            list_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(list_project_custom_field) do
                expect(page).to have_text 'List field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value for the project custom field if no value given' do
            list_project_custom_field.custom_options.first.update!(default_value: true)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(list_project_custom_field) do
                expect(page).to have_text 'List field'
                expect(page).to have_text 'Option 1'
              end
            end
          end
        end
      end

      describe 'with version CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(version_project_custom_field) do
                expect(page).to have_text 'Version field'
                expect(page).to have_text 'Version 1'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            version_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(version_project_custom_field) do
                expect(page).to have_text 'Version field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            version_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(version_project_custom_field) do
                expect(page).to have_text 'Version field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end
      end

      describe 'with user CF' do
        describe 'with value set by user' do
          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(user_project_custom_field) do
                expect(page).to have_text 'User field'
                expect(page).to have_text 'Member 1 In Project'
              end
            end
          end
        end

        describe 'with value unset by user' do
          before do
            user_project_custom_field.custom_values.where(customized: project).first.update!(value: '')
          end

          it 'shows the correct value for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(user_project_custom_field) do
                expect(page).to have_text 'User field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            user_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(user_project_custom_field) do
                expect(page).to have_text 'User field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end

        describe 'with support for user groups' do
          # TODO
        end

        describe 'with support for user placeholders' do
          # TODO
        end
      end

      describe 'with multi list CF' do
        describe 'with value set by user' do
          it 'shows the correct values for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_list_project_custom_field) do
                expect(page).to have_text 'Multi list field'
                expect(page).to have_text 'Option 1, Option 2'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            multi_list_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_list_project_custom_field) do
                expect(page).to have_text 'Multi list field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end

          it 'shows the default value(s) for the project custom field if no value given' do
            multi_list_project_custom_field.custom_options.first.update!(default_value: true)
            multi_list_project_custom_field.custom_options.second.update!(default_value: true)

            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_list_project_custom_field) do
                expect(page).to have_text 'Multi list field'
                expect(page).to have_text 'Option 1, Option 2'
              end
            end
          end
        end
      end

      describe 'with multi version CF' do
        describe 'with value set by user' do
          it 'shows the correct values for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_version_project_custom_field) do
                expect(page).to have_text 'Multi version field'
                expect(page).to have_text 'Version 1, Version 2'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            multi_version_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_version_project_custom_field) do
                expect(page).to have_text 'Multi version field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end
      end

      describe 'with multi user CF' do
        describe 'with value set by user' do
          it 'shows the correct values for the project custom field if given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_user_project_custom_field) do
                expect(page).to have_text 'Multi user field'
                expect(page).to have_text 'Member 1 In Project, Member 2 In Project'
              end
            end
          end
        end

        describe 'with no value set by user' do
          before do
            multi_user_project_custom_field.custom_values.where(customized: project).destroy_all
          end

          it 'shows an N/A text for the project custom field if no value given' do
            overview_page.visit_page

            overview_page.within_async_loaded_sidebar do
              overview_page.within_custom_field_container(multi_user_project_custom_field) do
                expect(page).to have_text 'Multi user field'
                expect(page).to have_text 'Not set yet'
              end
            end
          end
        end
      end
    end
  end
end
