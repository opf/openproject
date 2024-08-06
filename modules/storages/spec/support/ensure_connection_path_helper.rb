# frozen_string_literal: true

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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

module EnsureConnectionPathHelper
  def ensure_connection_path(project_storage)
    url_helpers = OpenProject::StaticRouting::StaticRouter.new.url_helpers
    url_helpers.oauth_clients_ensure_connection_path(
      oauth_client_id: project_storage.storage.oauth_client.client_id,
      storage_id: project_storage.storage.id,
      destination_url: url_helpers.open_project_storage_url(
        protocol: "https",
        project_id: project_storage.project.identifier,
        id: project_storage.id
      )
    )
  end
end
