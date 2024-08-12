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
module Projects::Exports
  class QueryExporter < Exports::Exporter
    self.model = Project

    alias :query :object

    def columns
      @columns ||= (forced_columns + selected_columns)
    end

    def page
      options[:page] || 1
    end

    def projects
      @projects ||= query
        .results
        .with_required_storage
        .with_latest_activity
        .includes(:custom_values)
        .page(page)
        .per_page(Setting.work_packages_projects_export_limit.to_i)
    end

    private

    def forced_columns
      [
        { name: :id, caption: Project.human_attribute_name(:id) },
        { name: :identifier, caption: Project.human_attribute_name(:identifier) }
      ]
    end

    def selected_columns
      query
        .selects
        .reject { |s| s.is_a?(Queries::Selects::NotExistingSelect) }
        .map { |s| { name: s.attribute, caption: s.caption } }
    end
  end
end
