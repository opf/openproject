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

module DemoData
  module References
    module_function

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticRouter.new.url_helpers
    end

    def api_url_helpers
      API::V3::Utilities::PathHelper::ApiV3Path
    end

    ##
    # Turns ##<tag>:<ref_name> into a link to the referenced object, and
    # ##<tag>.id:<ref_name> into its record id.
    #
    # - `<tag>` can be one of `query`, `sprint`, or `wp`.
    # - `<ref_name>` is a reference which was used to register the object.
    #
    # For instance:
    # - Turns `##sprint:sprint_backlog` into
    #   `/projects/demo-project/sprints/23/taskboard` given there is a sprint
    #   referenced with :sprint_backlog and its ID here is 23.
    #
    #   Alternatively `##sprint.id:sprint_backlog` is translated into just the
    #   id.
    #
    # - Turns `##query:gantt_chart` into
    #   `/projects/demo-project/work_packages?query_id=1` given there is a query
    #   referenced with :gantt_chart and its ID here is 1.
    #
    #   Alternatively `##query.id:gantt_chart` is translated into just the ID.
    #
    # - Turns `##wp:some_subject` into
    #   `/projects/demo-project/work_packages/42/activity` given there is a work
    #   package referenced with :some_subject and ID here is 42.
    #
    #   Alternatively `##wp.id:some_subject` is translated into just the ID.
    def with_references(str)
      return str if str.blank?

      str.gsub(/##(query|sprint|wp)(\.id)?:[a-z_0-9]+/) do |match|
        tag, reference = match.delete("#").split(":", 2)
        instance = seed_data.find_reference(reference.to_sym)
        if match.include?(".id")
          instance.id
        else
          link(tag, instance)
        end
      end
    end

    ##
    # Links attachments from the given set of attachments, referenced via name.
    # For instance:
    #
    #   `##attachment:"picture.jpg"`
    #
    # @param str [String] String in which to substitute attachment references.
    # @param attachments [ActiveRecord::QueryMethods] Query to set of attachments which can be referenced.
    def link_attachments(str, attachments)
      return str if str.blank?

      str.gsub(/##attachment(\.id)?:"[^"]+"/) do |match|
        file = match.split(":", 2).last[1..-2] # strip quotes of part behind :
        attachment = attachments.where(file:).first!

        if match.include?(".id")
          attachment.id
        else
          api_url_helpers.attachment_content attachment.id
        end
      end
    end

    def link(tag, instance)
      case tag
      when "query"
        query_link(instance)
      when "sprint"
        sprint_link(instance)
      when "wp"
        work_package_link(instance)
      else
        raise ArgumentError, "cannot create link for #{tag.inspect}"
      end
    end

    def query_link(query)
      url_helpers.project_work_packages_path(
        project_id: query.project.identifier,
        query_id: query.id
      )
    end

    def sprint_link(sprint)
      url_helpers.backlogs_project_sprint_taskboard_path(
        sprint_id: sprint.id,
        project_id: sprint.project.identifier
      )
    end

    def work_package_link(work_package)
      url_helpers.project_work_package_path(
        id: work_package.id,
        project_id: work_package.project.identifier,
        state: "activity"
      )
    end
  end
end
