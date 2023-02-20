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

require_relative '../spec_helper'

describe 'Storages module', js: true do
  current_user { create(:admin) }

  let(:role) { create(:role, permissions: %i[manage_storages_in_project select_project_modules edit_project]) }
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:project) { create(:project, enabled_module_names: %i[storages work_package_tracking]) }

  shared_examples_for 'content section has storages module' do |is_upcase = false|
    it 'must show "storages" in content section' do
      within '#content' do
        text = I18n.t(:project_module_storages)
        expect(page).to have_text(is_upcase ? text.upcase : text)
      end
    end
  end

  shared_examples_for 'sidebar has storages module' do
    it 'must show "storages" in sidebar' do
      within '#menu-sidebar' do
        expect(page).to have_text(I18n.t(:project_module_storages))
      end
    end
  end

  shared_examples_for 'has storages module' do |sections: %i[content sidebar], is_upcase: false|
    before do
      visit(path)
    end

    include_examples 'content section has storages module', is_upcase if sections.include?(:content)
    include_examples 'sidebar has storages module' if sections.include?(:sidebar)
  end

  context 'when in administration' do
    context 'when showing index page' do
      it_behaves_like 'has storages module' do
        let(:path) { admin_index_path }
      end
    end

    context 'when showing system project settings page' do
      it_behaves_like 'has storages module', sections: [:content] do
        let(:path) { admin_settings_projects_path }
      end
    end

    context 'when showing system storage settings page' do
      before do
        visit admin_settings_storages_path
      end

      it 'must show the page' do
        expect(page).to have_text(I18n.t(:project_module_storages))
      end
    end

    context 'when creating a new role' do
      it_behaves_like 'has storages module', sections: [:content], is_upcase: true do
        let(:path) { new_role_path }
      end
    end

    context 'when editing a role' do
      it_behaves_like 'has storages module', sections: [:content], is_upcase: true do
        let(:path) { edit_role_path(role) }
      end
    end

    context 'when showing the role permissions report' do
      it_behaves_like 'has storages module', sections: [:content], is_upcase: true do
        let(:path) { report_roles_path(role) }
      end
    end
  end

  context 'when in project administration' do
    before do
      storage
      project
    end

    context 'when showing the project module settings' do
      it_behaves_like 'has storages module' do
        let(:path) { project_settings_modules_path(project) }
      end
    end

    context 'when showing project storages settings page' do
      context 'with storages module is enabled' do
        before do
          visit project_settings_projects_storages_path(project)
        end

        it 'must show the page' do
          expect(page).to have_text(I18n.t('storages.page_titles.project_settings.index'))
        end
      end

      context 'with storages module is disabled' do
        let(:project) { create(:project, enabled_module_names: %i[work_package_tracking]) }

        before do
          visit project_settings_projects_storages_path(project)
        end

        it 'mustn\'t show the page' do
          expect(page).not_to have_text(I18n.t('storages.page_titles.project_settings.index'))
        end
      end
    end
  end
end
