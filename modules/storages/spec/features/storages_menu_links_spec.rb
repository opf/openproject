# frozen_string_literal: true

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
require_module_spec_helper

RSpec.describe 'Storage links in project menu', :js do
  include API::V3::Utilities::PathHelper

  let!(:storage_configured_linked1) { create(:nextcloud_storage_configured, name: "Storage 1") }
  let!(:project_storage1) { create(:project_storage, project:, storage: storage_configured_linked1) }
  let!(:storage_configured_linked2) { create(:nextcloud_storage_configured, name: "Storage 2") }
  let!(:project_storage2) { create(:project_storage, project:, storage: storage_configured_linked2) }
  let!(:storage_configured_unlinked) { create(:nextcloud_storage_configured, name: "Storage 3") }
  let!(:storage_unconfigured_linked) { create(:nextcloud_storage, name: "Storage 4") }
  let!(:project_storage4) { create(:project_storage, project:, storage: storage_unconfigured_linked) }
  let!(:project) { create(:project, enabled_module_names: %i[storages]) }
  let(:permissions) { %i[view_file_links] }
  let(:user) { create(:user, member_with_permissions: { project => permissions }) }

  before do
    login_as(user)
    visit(project_path(project))
  end

  def href(project_storage)
    oauth_clients_ensure_connection_path(
      oauth_client_id: project_storage.storage.oauth_client.client_id,
      storage_id: project_storage.storage.id,
      destination_url: open_project_storage_url(
        protocol: 'https',
        project_id: project_storage.project.identifier,
        id: project_storage.id
      )
    )
  end

  context 'if user has permission to see storage links' do
    it 'has links to enabled storages' do
      visit(project_path(id: project.id))

      expect(page).to have_link(storage_configured_linked1.name, href: href(project_storage1))
      expect(page).to have_link(storage_configured_linked2.name, href: href(project_storage2))
      expect(page).not_to have_link(storage_configured_unlinked.name)
      expect(page).not_to have_link(storage_unconfigured_linked.name)
    end

    context 'if user is an admin but not a member of the project' do
      let(:user) { create(:admin) }

      it 'has no links to enabled storage' do
        visit(project_path(id: project.id))

        expect(page).not_to have_link(storage_configured_linked1.name)
        expect(page).not_to have_link(storage_configured_linked2.name)
        expect(page).not_to have_link(storage_configured_unlinked.name)
        expect(page).not_to have_link(storage_unconfigured_linked.name)
      end
    end
  end

  context 'if user has no permission to see storage links' do
    let(:permissions) { %i[] }

    it 'has no links to enabled storages' do
      visit(project_path(id: project.id))

      expect(page).not_to have_link(storage_configured_linked1.name)
      expect(page).not_to have_link(storage_configured_linked2.name)
      expect(page).not_to have_link(storage_configured_unlinked.name)
      expect(page).not_to have_link(storage_unconfigured_linked.name)
    end
  end
end
