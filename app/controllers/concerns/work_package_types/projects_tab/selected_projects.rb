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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module WorkPackageTypes
  module ProjectsTab
    module SelectedProjects
      extend ActiveSupport::Concern

      private

      # Only projects that use the type: an id the table never showed must not have the type
      # switched or removed through a crafted request.
      def selected_projects
        @selected_projects ||= ::Project
                                 .where(id: Array(params[:project_ids]))
                                 .where(id: ::ProjectType.where(type_id: @type.id).select(:project_id))
                                 .order(:lft)
      end

      # Decided by what was submitted, not by what survives the filter above: a bulk dialog
      # stays a bulk dialog even when only one of its projects remains.
      def bulk_selection? = Array(params[:project_ids]).many?
    end
  end
end
