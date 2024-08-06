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

module API::V3::ProjectStorages
  class ProjectStorageRepresenter < ::API::Decorators::Single
    include API::Decorators::DateProperty
    include API::Decorators::LinkedResource

    defaults render_nil: true

    self_link(title: false)

    property :id
    date_time_property :created_at
    date_time_property :updated_at
    property :project_folder_mode

    link :projectFolder do
      next if represented.project_folder_id.blank?

      { href: api_v3_paths.storage_file(represented.storage.id, represented.project_folder_id) }
    end

    link :open do
      next unless show_open_storage_links

      { href: api_v3_paths.project_storage_open(represented.id) }
    end

    link :openWithConnectionEnsured do
      next unless show_open_storage_links

      { href: represented.open_with_connection_ensured }
    end

    associated_resource :storage, skip_render: ->(*) { true }, skip_link: ->(*) { false }
    associated_resource :project, skip_render: ->(*) { true }, skip_link: ->(*) { false }
    associated_resource :creator,
                        v3_path: :user,
                        representer: ::API::V3::Users::UserRepresenter,
                        skip_render: ->(*) { true },
                        skip_link: ->(*) { false }

    def _type
      "ProjectStorage"
    end

    private

    def show_open_storage_links
      if represented.project_folder_automatic?
        return current_user.allowed_in_project?(:read_files, represented.project)
      end

      true
    end
  end
end
