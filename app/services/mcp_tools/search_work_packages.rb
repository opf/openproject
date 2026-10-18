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

module McpTools
  class SearchWorkPackages < SearchTool
    default_title "Search work packages"
    default_description "Search work packages matching all of the passed input parameters. " \
                        "Parameters not passed are ignored. Results are limited to a maximum " \
                        "of #{page_size} work packages. To get the rest of the results, call the tool again with a " \
                        "page number of 2 or higher. The total in the result is the number of all matching work " \
                        "packages. To only count them, pass level_of_detail 'count', which returns no items. " \
                        "Pass group_by to also get the count per value of one field. Names of custom fields should " \
                        "be resolved through the corresponding tool before showing them to the user. They should " \
                        "not be rendered as 'customFieldN'."

    name "search_work_packages"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    # Both `version_id` and `target_version_id` filter on the `target_versions`
    # association, which is replacing the legacy `work_packages.version_id`
    # column. `version_id` is kept as a deprecated alias so we no longer query
    # the deprecated column.
    FILTER_ON_TARGET_VERSIONS = ->(wps, version_id) {
      version_id.nil? ? wps.without_target_version : wps.with_target_version(version_id)
    }

    # We can't use subclasses of WorkPackageFilter as filter_class, because they overwrite apply_to badly and rely on using
    # an instantiated Query to be used.
    filter :assigned_to_id
    filter :author_id
    filter :id, filter_proc: ->(wps, v) { wps.where_display_id_in(v) }
    filter :project_id
    filter :status_id, filter_proc: ->(wps, v) { wps.where(status_id: Array(v)) }
    filter :open, filter_proc: ->(wps, v) { v ? wps.with_status_open : wps.with_status_closed }
    filter :type_id
    filter :version_id, filter_proc: FILTER_ON_TARGET_VERSIONS
    filter :target_version_id, filter_proc: FILTER_ON_TARGET_VERSIONS
    filter :subject, filter_proc: ->(wps, v) { wps.where("subject ILIKE '%#{OpenProject::SqlSanitization.quoted_sanitized_sql_like(v)}%'") }

    group :status, column: "statuses.name", association: :status
    group :type, column: "types.name", association: :type
    group :priority, column: "enumerations.name", association: :priority
    group :project, column: "projects.name", association: :project
    group :assignee, with: :assignee_groups

    input_schema(
      additionalProperties: false,
      properties: {
        level_of_detail: {
          type: :string,
          enum: %w[reduced full count],
          description: "Defines how much information is returned per work package. By default a reduced representation " \
                       "is returned, but passing 'full' can return all information. Passing 'count' returns no " \
                       "work packages, only the total and the groups."
        },
        assigned_to_id: {
          type: %w[number array null],
          items: { type: "number" },
          description: "The ID of the user or group that is assigned to this work package, or a list of IDs. " \
                       "Pass null to search for work packages without an assignee."
        },
        author_id: { type: "number", description: "The ID of the user that created this work package." },
        id: { type: %w[string number], description: "The identifier of the work package." },
        project_id: { type: "number", description: "The ID of the project that this work package belongs to." },
        status_id: {
          type: %w[number array],
          items: { type: "number" },
          description: "The ID of the work package's status, or a list of status IDs."
        },
        open: {
          type: "boolean",
          description: "true: only work packages with an open status. false: only work packages with a closed status."
        },
        subject: {
          type: "string",
          description: "The subject of the work package. Accepts partial subjects, not case-sensitive."
        },
        type_id: { type: "number", description: "The ID of the work package's type." },
        version_id: {
          type: %w[number null],
          description: "Deprecated: use target_version_id instead. Matches work packages whose target versions " \
                       "include this version. Pass null to search for work packages without a version."
        },
        target_version_id: {
          type: %w[number null],
          description: "The ID of a version the work package targets. Matches work packages whose target " \
                       "versions include this version. Pass null to search for work packages without any target version."
        }
      }
    )

    output_filter McpOutputFilters::RemoveFormattableHtml.new
    output_filter McpOutputFilters::RemoveWorkPackageActionLinks.new

    def base_scope
      Success(WorkPackage.visible)
    end

    def format_item(item)
      API::V3::WorkPackages::WorkPackageRepresenter.create(item, current_user:)
    end

    # Names only principals that the user can see. Each assignee asked for by id is listed,
    # also with no work packages, so that a missing person is not a question.
    def assignee_groups(scope, filters)
      requested = Array(filters[:assigned_to_id]).compact.map(&:to_i)
      counts = scope.group(:assigned_to_id).count
      names = visible_names(counts.keys.compact | requested)

      assignee_totals(counts, requested, names)
        .map { |key, count| assignee_group(key, count, names) }
        .sort_by { -it[:count] }
    end

    def assignee_totals(counts, requested, names)
      totals = requested.select { names.key?(it) }.index_with(0)
      totals.default = 0
      counts.each { |id, count| totals[id.nil? || names.key?(id) ? id : :not_visible] += count }
      totals
    end

    def assignee_group(key, count, names)
      case key
      when nil then { name: "(none)", count: }
      when :not_visible then { name: "(not visible)", count: }
      else { id: key, name: names[key], count: }
      end
    end

    def visible_names(ids)
      Principal.visible(current_user).where(id: ids).to_h { |principal| [principal.id, principal.name] }
    end

    def condensed_attributes
      @condensed_attributes ||= %w[
        _links
        id
        displayId
        subject
        lockVersion
        date
        startDate
        dueDate
        derivedStartDate
        derivedDueDate
        createdAt
        updatedAt
      ].to_set
    end

    def condensed_links
      @condensed_links ||= %w[
        project
        status
        type
        author
        assignee
      ].to_set
    end
  end
end
