#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/custom_fields/custom_fields_page'
require 'features/projects/project_settings_page'
require 'features/work_packages/work_packages_page'

describe 'Custom field accessibility', type: :feature do
  describe 'language tag' do
    let(:custom_field) {
      FactoryGirl.create(:work_package_custom_field,
                         name_locales: { en: 'Field1', de: 'Feld1' },
                         field_format: 'text',
                         is_required: true)
    }
    let(:type) {
      FactoryGirl.create(:type_standard,
                         custom_fields: [custom_field])
    }
    let(:project) {
      FactoryGirl.create :project,
                         types: [type],
                         work_package_custom_fields: [custom_field]
    }
    let(:role) {
      FactoryGirl.create :role,
                         permissions: [:view_work_packages, :edit_project]
    }
    let(:current_user) {
      FactoryGirl.create :admin, member_in_project: project,
                                 member_through_role: role
    }

    shared_examples_for 'Element has lang tag' do
      let(:lang_tag_locale) { defined?(element_locale) ? element_locale : locale }

      it { expect(element['lang']).to eq(lang_tag_locale) }
    end

    before { allow(User).to receive(:current).and_return current_user }

    describe 'Custom Field Admin Page', js: true do
      let(:custom_fields_page) { CustomFieldsPage.new }
      let(:element) { custom_fields_page.name_attributes }

      shared_context 'custom field new page' do
        let(:available_languages) { [locale] }

        before do
          allow(I18n).to receive(:locale).and_return locale

          allow(Setting).to receive(:available_languages).and_return(available_languages)

          custom_fields_page.visit_new
        end
      end

      context 'en' do
        let(:locale) { 'en' }

        include_context 'custom field new page'

        it_behaves_like 'Element has lang tag'
      end

      context 'de' do
        let(:locale) { 'de' }

        include_context 'custom field new page'

        it_behaves_like 'Element has lang tag'
      end

      describe 'Locale change' do
        shared_context 'custom field new page with changed name locale' do
          include_context 'custom field new page' do
            let(:available_languages) { ['en', 'de'] }
          end

          before { find(element_selector).click }
        end

        describe 'Name locale change' do
          let(:element_selector) { "#custom_field_name_attributes select.locale_selector option[value='#{element_locale}']" }

          context 'en' do
            let(:locale) { 'en' }
            let(:element_locale) { 'de' }

            include_context 'custom field new page with changed name locale'

            it_behaves_like 'Element has lang tag'
          end

          context 'de' do
            let(:locale) { 'de' }
            let(:element_locale) { 'en' }

            include_context 'custom field new page with changed name locale'

            it_behaves_like 'Element has lang tag'
          end
        end

        describe 'Default value locale change' do
          let(:element) { custom_fields_page.default_value_attributes }
          let(:element_selector) { "#custom_field_default_value_attributes select.locale_selector option[value='#{element_locale}']" }

          context 'en' do
            let(:locale) { 'en' }
            let(:element_locale) { 'de' }

            include_context 'custom field new page with changed name locale'

            it_behaves_like 'Element has lang tag'
          end

          context 'de' do
            let(:locale) { 'de' }
            let(:element_locale) { 'en' }

            include_context 'custom field new page with changed name locale'

            it_behaves_like 'Element has lang tag'
          end
        end
      end
    end

    describe 'Project Settings' do
      let(:project_settings_page) { ProjectSettingsPage.new(project) }
      let(:element) { project_settings_page.fieldset_label }

      shared_context 'project settings page' do
        before do
          allow(I18n).to receive(:locale).and_return locale

          project_settings_page.visit_settings
        end
      end

      context 'en' do
        let(:locale) { 'en' }

        include_context 'project settings page'

        it_behaves_like 'Element has lang tag'
      end

      context 'de' do
        let(:locale) { 'en' }

        include_context 'project settings page'

        it_behaves_like 'Element has lang tag'
      end
    end

    describe 'Work Package' do
      let(:work_packages_page) { WorkPackagesPage.new(project) }
      let!(:work_package) {
        FactoryGirl.create(:work_package,
                           project: project,
                           type: type,
                           custom_values: { custom_field.id => 'value' })
      }

      describe 'index', js: true do
        shared_context 'index page with query' do
          let!(:query) do
            query = FactoryGirl.build(:query, project: project)
            query.column_names = ["cf_#{custom_field.id}"]

            query.save!
            query
          end

          before do
            allow(I18n).to receive(:locale).and_return locale

            work_packages_page.visit_index
            work_packages_page.select_query query
          end
        end

        shared_examples_for 'localized table header' do
          it_behaves_like 'Element has lang tag' do
            let(:element) { find('th a', text: custom_field.name) }
          end

          it_behaves_like 'Element has lang tag' do
            let(:element) { find("td[class='cf_#{custom_field.id}']") }
          end
        end

        context 'en' do
          let(:locale) { 'en' }

          include_context 'index page with query'

          skip # it_behaves_like "localized table header"
        end

        context 'de' do
          let(:locale) { 'de' }

          include_context 'index page with query'

          skip # it_behaves_like "localized table header"
        end
      end

      let(:value) { 'Wert' }

      describe 'show' do
        shared_context 'work package show view' do
          before { work_packages_page.visit_show work_package.id }
        end

        shared_examples_for 'attribute header lang' do
          let(:element) { find("dt.attributes-key-value--key.-custom_field.-cf_#{custom_field.id}") }

          it_behaves_like 'Element has lang tag'
        end

        shared_examples_for 'attribute value lang' do
          let(:element) { find("dt.attributes-key-value--key.-custom_field.-cf_#{custom_field.id} + dd") }

          it_behaves_like 'Element has lang tag'
        end

        context 'de' do
          let(:locale) { 'de' }
          let(:element_locale) { 'en' }

          include_context 'work package show view'

          it_behaves_like 'attribute header lang'

          it_behaves_like 'attribute value lang'
        end

        context 'en' do
          let(:locale) { 'en' }
          let(:element_locale) { 'en' }

          include_context 'work package show view'

          it_behaves_like 'attribute header lang'

          it_behaves_like 'attribute value lang'
        end

        describe 'mixed language for custom field name and default value' do
          let(:cf_with_mixed_lang) {
            FactoryGirl.create(:work_package_custom_field,
                               name_locales: { en: 'Field2', de: nil },
                               default_locales: { en: nil, de: value  },
                               field_format: 'text',
                               is_required: false)
          }
          let(:custom_field) { cf_with_mixed_lang }

          before do
            Globalize.fallbacks = { en: [:en, :de] }

            work_package.custom_field_values.first.value = value
            work_package.save!
          end

          after { Globalize.fallbacks = [:en] }

          shared_context 'work package show view' do
            before do
              allow(I18n).to receive(:locale).and_return locale

              work_packages_page.visit_show work_package.id
            end
          end

          context 'attribute header' do
            context 'de' do
              let(:locale) { 'de' }
              let(:element_locale) { 'en' }

              include_context 'work package show view'

              it_behaves_like 'attribute header lang'
            end

            context 'en' do
              let(:locale) { 'en' }
              let(:element_locale) { 'en' }

              include_context 'work package show view'

              it_behaves_like 'attribute header lang'
            end
          end

          context 'attribute value' do
            context 'de' do
              let(:locale) { 'de' }
              let(:element_locale) { 'de' }

              include_context 'work package show view'

              it_behaves_like 'attribute value lang'
            end

            context 'en' do
              let(:locale) { 'en' }
              let(:element_locale) { 'de' }

              include_context 'work package show view'

              it_behaves_like 'attribute value lang'
            end
          end
        end
      end

      describe 'edit' do
        shared_context 'work package edit view' do
          before { work_packages_page.visit_edit work_package.id }
        end

        shared_examples_for 'attribute header lang' do
          let(:element) { find("#attributes label[for='work_package_custom_field_values_#{custom_field.id}']") }

          it_behaves_like 'Element has lang tag'
        end

        shared_examples_for 'attribute value lang' do
          let(:element) { find("#work_package_custom_field_values_#{custom_field.id}") }

          it_behaves_like 'Element has lang tag'
        end

        context 'de' do
          let(:locale) { 'de' }
          let(:element_locale) { 'en' }

          include_context 'work package edit view'

          it_behaves_like 'attribute header lang'

          it_behaves_like 'attribute value lang'
        end

        context 'en' do
          let(:locale) { 'en' }
          let(:element_locale) { 'en' }

          include_context 'work package edit view'

          it_behaves_like 'attribute header lang'

          it_behaves_like 'attribute value lang'
        end

        describe 'default value language is different' do
          let(:cf_with_mixed_lang) {
            FactoryGirl.create(:work_package_custom_field,
                               name_locales: { en: 'Field2', de: nil },
                               default_locales: { en: nil, de: value  },
                               field_format: 'text',
                               is_required: false)
          }
          let(:custom_field) { cf_with_mixed_lang }

          before do
            Globalize.fallbacks = { en: [:en, :de] }

            work_package.custom_field_values.first.value = value
            work_package.save!
          end

          after { Globalize.fallbacks = [:en] }

          context 'attribute value' do
            context 'en' do
              let(:locale) { 'en' }
              let(:element_locale) { 'en' }

              include_context 'work package edit view'

              it_behaves_like 'attribute value lang'
            end
          end
        end
      end
    end
  end
end
