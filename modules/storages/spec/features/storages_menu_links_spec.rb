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

describe 'Project menu', js: true do
  let(:storage1) { create(:storage, name: "Storage 1") }
  let(:storage2) { create(:storage, name: "Storage 2") }
  let(:storage3) { create(:storage, name: "Storage 3") }
  let(:project) { create(:project, enabled_module_names: %i[storages]) }
  let(:project_storage1) { create(:project_storage, project:, storage: storage1) }
  let(:project_storage2) { create(:project_storage, project:, storage: storage2) }
  let(:project_storage3) { create(:project_storage, project:, storage: storage3) }
  let(:user) { create(:user, member_in_project: project, member_with_permissions: permissions) }

  it 'has no links to storages when user is not logged in' do
    project_storage1
    visit(project_path(id: project.id))
    expect(page).not_to have_link(storage1.name, href: storage1.host)
  end

  context 'when user is logged in without permissions to see storage links' do
    let(:permissions) { %i[] }

    before do
      login_as(user)
    end

    it 'has no links to enabled storages' do
      project_storage1
      visit(project_path(id: project.id))
      expect(page).not_to have_link(storage1.name, href: storage1.host)
    end
  end

  context 'when user is logged in with permissions to see storage links' do
    let(:permissions) { %i[view_file_links] }

    before { login_as(user) }

    it 'has links to enabled storages' do
      project_storage1
      project_storage2
      storage3
      visit(project_path(id: project.id))
      expect(page).to have_link(storage1.name, href: storage1.host)
      expect(page).to have_link(storage2.name, href: storage2.host)
      expect(page).not_to have_link(storage3.name, href: storage3.host)
    end
  end
end
