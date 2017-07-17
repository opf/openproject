#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See doc/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Utilities
      module PathHelper
        include API::Utilities::UrlHelper

        class ApiV3Path
          extend API::Utilities::UrlHelper

          # Determining the root_path on every url we want to render is
          # expensive. As the root_path will not change within a
          # request, we can cache the first response on each request.
          def self.root_path
            RequestStore.store[:cached_root_path] ||= super
          end

          def self.root
            "#{root_path}api/v3"
          end

          def self.activity(id)
            "#{root}/activities/#{id}"
          end

          def self.attachment(id)
            "#{root}/attachments/#{id}"
          end

          def self.attachment_download(id, filename = nil)
            download_attachment_path(id, filename)
          end

          def self.attachments_by_work_package(id)
            "#{work_package(id)}/attachments"
          end

          def self.available_assignees(project_id)
            "#{project(project_id)}/available_assignees"
          end

          def self.available_responsibles(project_id)
            "#{project(project_id)}/available_responsibles"
          end

          def self.available_watchers(work_package_id)
            "#{work_package(work_package_id)}/available_watchers"
          end

          def self.available_projects_on_edit(work_package_id)
            "#{work_package(work_package_id)}/available_projects"
          end

          def self.available_projects_on_create
            "#{work_packages}/available_projects"
          end

          def self.available_relation_candidates(work_package_id)
            "#{work_package(work_package_id)}/available_relation_candidates"
          end

          def self.categories(project_id)
            "#{project(project_id)}/categories"
          end

          def self.category(id)
            "#{root}/categories/#{id}"
          end

          def self.configuration
            "#{root}/configuration"
          end

          def self.create_work_package_form
            "#{work_packages}/form"
          end

          def self.create_project_work_package_form(project_id)
            "#{work_packages_by_project(project_id)}/form"
          end

          def self.custom_option(id)
            "#{root}/custom_options/#{id}"
          end

          def self.help_texts
            "#{root}/help_texts"
          end

          def self.help_text(id)
            "#{root}/help_texts/#{id}"
          end

          def self.my_preferences
            "#{root}/my_preferences"
          end

          def self.principals
            "#{root}/principals"
          end

          def self.priorities
            "#{root}/priorities"
          end

          def self.priority(id)
            "#{priorities}/#{id}"
          end

          class << self
            alias :issue_priorities :priorities
            alias :issue_priority :priority
          end

          def self.projects
            "#{root}/projects"
          end

          def self.project(id)
            "#{projects}/#{id}"
          end

          def self.queries
            "#{root}/queries"
          end

          def self.query(id)
            "#{queries}/#{id}"
          end

          def self.query_default
            "#{queries}/default"
          end

          def self.query_project_default(id)
            "#{project(id)}/queries/default"
          end

          def self.create_query_form
            "#{queries}/form"
          end

          def self.query_form(id)
            "#{query(id)}/form"
          end

          def self.query_star(id)
            "#{query(id)}/star"
          end

          def self.query_unstar(id)
            "#{query(id)}/unstar"
          end

          def self.query_column(name)
            "#{queries}/columns/#{name}"
          end

          def self.query_group_by(name)
            "#{queries}/group_bys/#{name}"
          end

          def self.query_sort_by(name, direction)
            "#{queries}/sort_bys/#{name}-#{direction}"
          end

          def self.query_filter(name)
            "#{queries}/filters/#{name}"
          end

          def self.query_filter_instance_schemas
            "#{queries}/filter_instance_schemas"
          end

          def self.query_filter_instance_schema(id)
            "#{queries}/filter_instance_schemas/#{id}"
          end

          def self.query_project_form(id)
            "#{project(id)}/queries/form"
          end

          def self.query_project_filter_instance_schemas(id)
            "#{project(id)}/queries/filter_instance_schemas"
          end

          def self.query_operator(name)
            "#{queries}/operators/#{name}"
          end

          def self.query_schema
            "#{queries}/schema"
          end

          def self.query_project_schema(id)
            "#{project(id)}/queries/schema"
          end

          def self.query_available_projects
            "#{queries}/available_projects"
          end

          def self.relation(id)
            "#{root}/relations/#{id}"
          end

          def self.relations
            "#{root}/relations"
          end

          def self.revision(id)
            "#{root}/revisions/#{id}"
          end

          def self.render_markup(format: nil, link: nil)
            format = format || Setting.text_formatting
            format = 'plain' if format == '' # Setting will return '' for plain

            path = "#{root}/render/#{format}"
            path += "?context=#{link}" if link

            path
          end

          def self.roles
            "#{root}/roles"
          end

          def self.role(id)
            "#{root}/roles/#{id}"
          end

          def self.show_revision(project_id, identifier)
            show_revision_project_repository_path(project_id, identifier)
          end

          def self.show_user(user_id)
            user_path(user_id)
          end

          def self.statuses
            "#{root}/statuses"
          end

          def self.status(id)
            "#{statuses}/#{id}"
          end

          def self.string_object(value)
            val = ::ERB::Util::url_encode(value)
            "#{root}/string_objects?value=#{val}"
          end

          def self.types
            "#{root}/types"
          end

          def self.types_by_project(project_id)
            "#{project(project_id)}/types"
          end

          def self.type(id)
            "#{types}/#{id}"
          end

          def self.users
            "#{root}/users"
          end

          def self.user(id)
            "#{users}/#{id}"
          end

          class << self
            alias :groups :users
            alias :group :user
          end

          def self.user_lock(id)
            "#{user(id)}/lock"
          end

          def self.version(version_id)
            "#{root}/versions/#{version_id}"
          end

          def self.versions
            "#{root}/versions"
          end

          def self.versions_by_project(project_id)
            "#{project(project_id)}/versions"
          end

          def self.projects_by_version(version_id)
            "#{version(version_id)}/projects"
          end

          def self.watcher(id, work_package_id)
            "#{work_package_watchers(work_package_id)}/#{id}"
          end

          def self.work_packages
            "#{root}/work_packages"
          end

          def self.work_package(id)
            "#{work_packages}/#{id}"
          end

          def self.work_package_activities(id)
            "#{work_package(id)}/activities"
          end

          def self.work_package_form(id)
            "#{work_package(id)}/form"
          end

          def self.work_package_relations(id)
            "#{work_package(id)}/relations"
          end

          def self.work_package_relation(id, work_package_id)
            "#{work_package_relations(work_package_id)}/#{id}"
          end

          def self.work_package_revisions(id)
            "#{work_package(id)}/revisions"
          end

          def self.work_package_schema(project_id, type_id)
            "#{root}/work_packages/schemas/#{project_id}-#{type_id}"
          end

          def self.work_package_schemas(*args)
            path = "#{root}/work_packages/schemas"
            if args.empty?
              path
            else
              values = args.map do |project_id, type_id|
                "#{project_id}-#{type_id}"
              end

              filter = [{ id: { operator: '=', values: values } }]

              path + "?filters=#{CGI.escape(filter.to_s)}"
            end
          end

          def self.work_package_sums_schema
            "#{root}/work_packages/schemas/sums"
          end

          def self.work_package_watchers(id)
            "#{work_package(id)}/watchers"
          end

          def self.work_packages_by_project(project_id)
            "#{project(project_id)}/work_packages"
          end
        end

        def api_v3_paths
          ApiV3Path
        end
      end
    end
  end
end
