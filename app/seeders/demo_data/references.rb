#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.

module DemoData
  module References
    module_function

    def url_helpers
      @url_helpers ||= OpenProject::StaticRouting::StaticRouter.new.url_helpers
    end

    def api_url_helpers
      API::V3::Utilities::PathHelper::ApiV3Path
    end

    def with_references(str, project)
      res = link_work_packages str, project
      res = link_queries res, project
      res = link_sprints res, project

      res
    end

    ##
    # Replaces occurrences of `##child:n` with a link to the given
    # work package's nth child using the standard OpenProject work package
    # link syntax `##<id>`.
    def link_children(str, work_package)
      return str unless str.present? && str.include?("##child:")

      str.gsub(/##child:\d+/) do |match|
        index = match.split(":").last.to_i - 1

        "##" + work_package.children[index].id.to_s
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
      return str unless str.present?

      str.gsub(/##attachment(\.id)?:"[^"]+"/) do |match|
        file = match.split(":", 2).last[1..-2] # strip quotes of part behind :
        attachment = attachments.where(file: file).first!

        if match.include?(".id")
          attachment.id
        else
          api_url_helpers.attachment_content attachment.id
        end
      end
    end

    ##
    # Turns `##query:"Gantt chart"` into
    # `/projects/demo-project/work_packages?query_id=1` given there is a query
    # named "Gantt chart" (its ID here being 1).
    #
    # Alternatively `##query.id:"Gantt chart"` is translated into just the ID.`
    def link_queries(str, project)
      link_reference(
        str,
        model: Query,
        find_by: :name,
        project: project,
        link: ->(query) { query_link query }
      )
    end

    ##
    # Turns `##wp:"Some subject"` into
    # `/projects/demo-project/work_packages/42/activity` given there is a work package
    # named "Some subject" (its subject here being "Some subject").
    #
    # Alternatively `##wp.id:"Some subject"` is translated into just the ID.`
    def link_work_packages(str, project)
      link_reference(
        str,
        model: WorkPackage,
        tag: "wp",
        find_by: :subject,
        project: project,
        link: ->(wp) { work_package_link wp }
      )
    end

    def link_sprints(str, project)
      return str unless defined? OpenProject::Backlogs

      link_reference(
        str,
        model: Sprint,
        find_by: :name,
        project: project,
        link: ->(sprint) { sprint_link sprint }
      )
    end

    def link_reference(str, model:, find_by:, project:, link:, tag: nil)
      return str unless str.present?

      tag ||= model.name.downcase

      str.gsub(/###{tag}(\.id)?:"[^"]+"/) do |match|
        identifier = match.split(":", 2).last[1..-2] # strip quotes of part behind :
        instance = model.where(find_by => identifier, :project => project).first!

        if match.include?(".id")
          instance.id
        else
          link.call instance
        end
      end
    end

    def query_link(query)
      path = url_helpers.project_work_packages_path project_id: query.project.identifier

      "#{path}?query_id=#{query.id}"
    end

    def work_package_link(work_package)
      url_helpers.project_work_package_path(
        id: work_package.id,
        project_id: work_package.project.identifier,
        state: "activity"
      )
    end

    def sprint_link(sprint)
      url_helpers.backlogs_project_sprint_taskboard_path(
        sprint_id: sprint.id,
        project_id: sprint.project.identifier
      )
    end
  end
end
