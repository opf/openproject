# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

require "spec_helper"
require_module_spec_helper

RSpec.describe "Storages module", :js, :with_cuprite do
  let(:permissions) do
    %i[manage_storages_in_project
       select_project_modules
       edit_project]
  end
  let(:user) { create(:admin) }
  let(:role) { create(:project_role, permissions:) }
  let(:storage) { create(:nextcloud_storage, name: "Storage 1") }
  let(:project) { create(:project, enabled_module_names: %i[storages work_package_tracking]) }

  current_user { user }

  shared_examples_for "content section has storages module" do |is_upcase = false|
    it 'must show "storages" in content section' do
      within "#content" do
        text = I18n.t(:project_module_storages)
        expect(page).to have_text(is_upcase ? text.upcase : text)
      end
    end
  end

  shared_examples_for "sidebar has storages module" do
    it 'must show "storages" in sidebar' do
      within "#menu-sidebar" do
        expect(page).to have_text(I18n.t(:project_module_storages))
      end
    end
  end

  shared_examples_for "has storages module" do |sections: %i[content sidebar], is_upcase: false|
    before { visit(path) }

    include_examples "content section has storages module", is_upcase if sections.include?(:content)
    include_examples "sidebar has storages module" if sections.include?(:sidebar)
  end

  context "when in administration" do
    context "when showing index page" do
      it_behaves_like "has storages module" do
        let(:path) { admin_index_path }
      end
    end

    context "when showing system project settings page" do
      it_behaves_like "has storages module", sections: [:content] do
        let(:path) { admin_settings_new_project_path }
      end
    end

    context "when showing system storage settings page" do
      before { visit admin_settings_storages_path }

      it "must show the page" do
        expect(page).to have_text(I18n.t(:project_module_storages))
      end
    end

    context "when creating a new role" do
      it 'must have appropriate storage permissions header in content section' do
        visit new_role_path

        within "#content" do
          expect(page).to have_text(I18n.t(:permission_header_for_project_module_storages).upcase)
        end
      end
    end

    context "when editing a role" do
      it 'must have appropriate storage permissions header in content section' do
        visit edit_role_path(role)

        within "#content" do
          expect(page).to have_text(I18n.t(:permission_header_for_project_module_storages).upcase)
        end
      end
    end

    context "when showing the role permissions report" do
      it_behaves_like "has storages module", sections: [:content], is_upcase: true do
        let(:path) { report_roles_path(role) }
      end
    end
  end

  context "when in project administration" do
    let(:user) { create(:user, member_with_permissions: { project => permissions }) }

    before do
      storage
      project
    end

    context "when showing the project module settings" do
      it_behaves_like "has storages module" do
        let(:path) { project_settings_modules_path(project) }
      end
    end

    context "when showing project storages settings page" do
      context "when storages module is enabled" do
        before do
          visit external_file_storages_project_settings_project_storages_path(project)
        end

        it "must show the page" do
          expect(page).to have_text(I18n.t("project_module_storages"))
        end
      end

      context "when storages module is disabled" do
        let(:project) { create(:project, enabled_module_names: %i[work_package_tracking]) }

        context "when user has manage_storages_in_project permission" do
          it "must show the page and storage menu entry" do
            visit project_path(project)
            page.find_test_selector("main-menu-toggler--settings").click # opens project setting menu

            within "#menu-sidebar" do
              expect(page).to have_text(I18n.t(:project_module_storages))
            end

            visit external_file_storages_project_settings_project_storages_path(project)

            expect(page).to have_text(I18n.t("project_module_storages"))
          end
        end

        context "when user has no manage_storages_in_project permission" do
          let(:permissions) { %i[select_project_modules edit_project] }

          it "must not show the page and storage menu entry" do
            visit project_path(project)
            page.find_test_selector("main-menu-toggler--settings").click # opens project setting menu

            within "#menu-sidebar" do
              expect(page).to have_no_text(I18n.t(:project_module_storages))
            end

            visit external_file_storages_project_settings_project_storages_path(project)

            expect(page).to have_no_text(I18n.t("project_module_storages"))
            expect(page).to have_text("[Error 403] You are not authorized to access this page.")
          end
        end
      end
    end
  end
end
