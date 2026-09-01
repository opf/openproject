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
  class ListWorkPackageComments < SearchTool
    default_title "List work package comments"
    default_description "List comments of the given work package."

    name "list_work_package_comments"
    annotations read_only: true, idempotent: true, destructive: false
    enable_pagination

    input_schema(
      additionalProperties: false,
      required: %i[work_package_id],
      properties: {
        work_package_id: {
          type: :number,
          description: "The ID of the work package whose comments shall be listed."
        }
      }
    )

    output_filter McpOutputFilters::RemoveActivityDetails.new
    output_filter McpOutputFilters::RemoveFormattableHtml.new
    output_filter McpOutputFilters::RemoveLinks.new(%w[update addAttachment])

    def scope_param_names
      %i[work_package_id]
    end

    def base_scope(work_package_id:)
      work_package = WorkPackage.visible(current_user).find_by(id: work_package_id)
      return Failure("Can't find given work package.") if work_package.nil?

      Success(
        work_package
          .journals
          .internal_visible
          .includes(:data,
                    :customizable_journals,
                    :attachable_journals,
                    :storable_journals,
                    :bcf_comment)
          .where.not(notes: "")
          .order(created_at: :desc)
      )
    end

    def format_item(item)
      ::API::V3::Activities::ActivityRepresenter.new(item, current_user:, embed_emoji_reactions: true)
    end
  end
end
