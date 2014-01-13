#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
require 'features/work_packages/work_packages_page'

describe 'Custom field accessibility' do
  describe 'language tag' do
    let(:type) { FactoryGirl.create(:type_standard) }
    let(:custom_field) { FactoryGirl.create(:work_package_custom_field,
                                            name_locales: { en: 'Field1', de: 'Feld1' },
                                            field_format: 'text',
                                            is_required: true) }
    let(:project) { FactoryGirl.create :project,
                                       types: [type],
                                       work_package_custom_fields: [custom_field] }
    let(:role) { FactoryGirl.create :role,
                                    permissions: [:view_work_packages] }
    let(:current_user) { FactoryGirl.create :user, member_in_project: project,
                                                   member_through_role: role }

    shared_examples_for "Element has lang tag" do
      let(:lang_tag_locale) { defined?(element_locale) ? element_locale : locale }

      it { expect(element['lang']).to eq(lang_tag_locale) }
    end

    before do
      User.stub(:current).and_return current_user
    end

    describe 'Work Package' do
      let(:work_packages_page) { WorkPackagesPage.new(project) }
      let!(:work_package) { FactoryGirl.create(:work_package,
                                               project: project,
                                               type: type,
                                               custom_fields: [{ "cf_#{custom_field.id}" => '' }]) }

      describe 'index' do
        shared_context "index page with query" do
          let!(:query) do
            query = FactoryGirl.build(:query, project: project)
            query.column_names = ["cf_#{custom_field.id}"]

            query.save! and return query
          end

          before do
            I18n.stub(:locale).and_return locale

            work_packages_page.visit_index
            work_packages_page.select_query query
          end
        end

        shared_examples_for "localized table header" do
          it_behaves_like 'Element has lang tag' do
            let(:element) { find('th a', text: custom_field.name) }
          end

          it_behaves_like 'Element has lang tag' do
            let(:element) { find("td[class='cf_#{custom_field.id}']") }
          end
        end

        context "en" do
          let(:locale) { 'en' }

          include_context "index page with query"

          it_behaves_like "localized table header"
        end

        context "de" do
          let(:locale) { 'de' }

          include_context "index page with query"

          it_behaves_like "localized table header"
        end
      end
    end
  end
end
