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

module Queries
  module Projects
    module Filters
      class ProjectStatusFilter < ::Queries::Projects::Filters::ProjectFilter
        include ProjectStatusHelper

        def allowed_values
          @allowed_values ||= Project.status_codes.map do |code, id|
            [project_status_name_for_code(code), id.to_s]
          end
        end

        def type
          :list_optional
        end

        def where
          operator_strategy.sql_for_field(values, model.table_name, :status_code)
        end

        def self.key
          :project_status_code
        end

        def human_name
          I18n.t('js.grid.widgets.project_status.title')
        end
      end
    end
  end
end
