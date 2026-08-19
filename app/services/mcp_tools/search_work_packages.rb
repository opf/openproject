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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module McpTools
  class SearchWorkPackages < Base
    default_title "Search work packages"
    default_description "Search work packages matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum " \
                        "of #{page_size} work packages. To get the rest of the results, call the tool again with a" \
                        "page number of 2 or higher."


    name "search_work_packages"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    # We can't use subclasses of WorkPackageFilter as filter_class, because they overwrite apply_to badly and rely on using
    # an instantiated Query to be used.
    filter :assigned_to_id
    filter :author_id
    filter :id
    filter :project_id
    filter :status_id
    filter :type_id
    filter :version_id
    filter :subject, filter_proc: ->(wps, v) { wps.where("subject ILIKE '%#{OpenProject::SqlSanitization.quoted_sanitized_sql_like(v)}%'") }

    input_schema(
      properties: {
        assigned_to_id: {
          type: %w[number null],
          description: "The ID of the user or group that is assigned to this work package. " \
                       "Pass null to search for work packages without an assignee."
        },
        author_id: { type: "number", description: "The ID of the user that created this work package." },
        id: { type: "number", description: "The ID of the work package." },
        project_id: { type: "number", description: "The ID of the project that this work package belongs to." },
        status_id: { type: "number", description: "The ID of the work package's status." },
        subject: {
          type: "string",
          description: "The subject of the work package. Accepts partial subjects, not case-sensitive."
        },
        type_id: { type: "number", description: "The ID of the work package's type." },
        version_id: {
          type: %w[number null],
          description: "The ID of the work package's version. Pass null to search for work packages without a version."
        }
      }
    )

    output_schema(
      type: :object,
      required: ["items"],
      properties: {
        items: {
          type: :array,
          items: JsonSchemaLoader.new.load("work_package_model")
        }
      }
    )

    def call(page: nil, **filters)
      filtered = apply_filters(WorkPackage.visible, filters)
      work_packages = apply_pagination(filtered, page)

      {
        items: work_packages.map { |wp| API::V3::WorkPackages::WorkPackageRepresenter.create(wp, current_user:) }
      }
    end
  end
end
