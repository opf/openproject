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

RSpec.describe 'Project menu', js: true, with_cuprite: true do
  let(:storage) { create(:storage, name: "Storage 1") }
  let(:another_storage) { create(:storage, name: "Storage 2") }
  let(:unlinked_storage) { create(:storage, name: "Storage 3") }
  let(:project) { create(:project, enabled_module_names: %i[storages]) }
  let(:project_storage_without_folder) { create(:project_storage, project:, storage:) }
  let(:project_storage_with_manual_folder) do
    create(:project_storage, project:, storage: another_storage, project_folder_mode: 'manual', project_folder_id: '42')
  end
  let(:permissions) { %i[view_file_links] }
  let(:user) { create(:user, member_in_project: project, member_with_permissions: permissions) }

  before do
    project_storage_without_folder
    project_storage_with_manual_folder
    unlinked_storage

    login_as(user)
    visit(project_path(project))
  end

  context 'if user has permission to see storage links' do
    it 'has links to enabled storages' do
      visit(project_path(id: project.id))

      expect(page).to have_link(storage.name, href: storage.host)
      project_folder_id = project_storage_with_manual_folder.project_folder_id
      folder_href = "#{another_storage.host}/index.php/f/#{project_folder_id}?openfile=1"
      expect(page).to have_link(another_storage.name, href: folder_href)
      expect(page).not_to have_link(unlinked_storage.name)
    end

    context 'if user is an admin but not a member of the project' do
      let(:user) { create(:admin) }

      it 'has no links to enabled storage' do
        visit(project_path(id: project.id))

        expect(page).not_to have_link(storage.name, href: storage.host)
        project_folder_id = project_storage_with_manual_folder.project_folder_id
        folder_href = "#{another_storage.host}/index.php/f/#{project_folder_id}?openfile=1"
        expect(page).not_to have_link(another_storage.name, href: folder_href)
        expect(page).not_to have_link(another_storage.name, href: another_storage.host)
        expect(page).not_to have_link(unlinked_storage.name)
      end
    end
  end

  context 'if user has no permission to see storage links' do
    let(:permissions) { %i[] }

    it 'has no links to enabled storages' do
      visit(project_path(id: project.id))

      expect(page).not_to have_link(storage.name)
      expect(page).not_to have_link(another_storage.name)
    end
  end
end
