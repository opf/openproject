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

# Purpose: Defines a table based on TableComponent for listing the
# Projects for a given Storage.
# See also: row_component.rb, which contains a method
# for every "column" defined below.
module Storages::ProjectStorages::Projects
  class TableComponent < Projects::TableComponent
    include OpTurbo::Streamable

    options :storage

    def columns
      @columns ||= query
        .selects
        .insert(1, ::Queries::Projects::Selects::Default.new(:project_folder_type))
    end

    def sortable?
      false
    end

    # Overwritten to avoid loading data that is not needed in this context
    def projects(query)
      @projects ||= query
        .results
        .paginate(page: helpers.page_param(params), per_page: helpers.per_page_param(params))
    end

    # Load the project_storages for the current paginated batch of projects grouped
    # by project_id to fill in other columns
    def project_storages
      @project_storages ||= Storages::ProjectStorage
        .where(storage_id: storage.id)
        .where(project_id: @projects.map(&:id))
        .index_by(&:project_id)
    end
  end
end
