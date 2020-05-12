#-- encoding: UTF-8
#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module API
  module V3
    module Utilities
      module PathHelper
        include API::Utilities::UrlHelper

        class ApiV3Path
          extend API::Utilities::UrlHelper

          def self.index(name, path = nil)
            plural_name = name.to_s.pluralize

            path ||= plural_name

            define_singleton_method(plural_name) do
              "#{root}/#{path}"
            end
          end
          private_class_method :index

          def self.show(name)
            define_singleton_method(name) do |id|
              "#{send(name.to_s.pluralize)}/#{id}"
            end
          end
          private_class_method :show

          def self.create_form(name)
            define_singleton_method(:"create_#{name}_form") do
              "#{send(name.to_s.pluralize)}/form"
            end
          end
          private_class_method :create_form

          def self.update_form(name)
            define_singleton_method(:"#{name}_form") do |id|
              "#{send(name, id)}/form"
            end
          end
          private_class_method :update_form

          def self.schema(name)
            define_singleton_method(:"#{name}_schema") do
              "#{send(name.to_s.pluralize)}/schema"
            end
          end
          private_class_method :schema

          def self.resources(name,
                             except: [],
                             only: %i[index show create_form update_form schema])

            (Array(only) - Array(except)).each do |method|
              send(method, name)
            end
          end
          private_class_method :resources

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

          index :attachment
          show :attachment

          def self.attachment_content(id)
            "#{root}/attachments/#{id}/content"
          end

          def self.attachments_by_post(id)
            "#{post(id)}/attachments"
          end

          def self.attachments_by_work_package(id)
            "#{work_package(id)}/attachments"
          end

          def self.attachments_by_wiki_page(id)
            "#{wiki_page(id)}/attachments"
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

          def self.available_projects_on_create(type_id)
            if type_id.to_i.zero?
              "#{work_packages}/available_projects"
            else
              "#{work_packages}/available_projects?for_type=#{type_id}"
            end
          end

          def self.available_relation_candidates(work_package_id)
            "#{work_package(work_package_id)}/available_relation_candidates"
          end

          index :category
          show :category

          def self.categories_by_project(id)
            "#{project(id)}/categories"
          end

          def self.configuration
            "#{root}/configuration"
          end

          def self.create_project_work_package_form(project_id)
            "#{work_packages_by_project(project_id)}/form"
          end

          def self.custom_action(id)
            "#{root}/custom_actions/#{id}"
          end

          def self.custom_action_execute(id)
            "#{custom_action(id)}/execute"
          end

          def self.custom_option(id)
            "#{root}/custom_options/#{id}"
          end

          index :help_text
          show :help_text

          resources :grid

          resources :membership

          def self.memberships_available_projects
            "#{memberships}/available_projects"
          end

          index :message
          show :message

          index :my_preferences

          index :newses, :news

          def self.news(id)
            "#{newses}/#{id}"
          end

          index :post
          show :post

          index :principal

          index :priorities
          show :priority

          class << self
            alias :issue_priorities :priorities
            alias :issue_priority :priority
          end

          resources :project

          def self.projects_available_parents
            "#{projects}/available_parent_projects"
          end

          def self.projects_schema
            "#{projects}/schema"
          end

          resources :query

          def self.query_default
            "#{queries}/default"
          end

          def self.query_project_default(id)
            "#{project(id)}/queries/default"
          end

          def self.query_star(id)
            "#{query(id)}/star"
          end

          def self.query_unstar(id)
            "#{query(id)}/unstar"
          end

          def self.query_order(id)
            "#{query(id)}/order"
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

          def self.query_project_schema(id)
            "#{project(id)}/queries/schema"
          end

          def self.query_available_projects
            "#{queries}/available_projects"
          end

          index :relations
          show :relation

          index :revision
          show :revision

          def self.render_markup(link: nil, plain: false)
            format = if plain
                       OpenProject::TextFormatting::Formats.plain_format
                     else
                       OpenProject::TextFormatting::Formats.rich_format
                     end

            path = "#{root}/render/#{format}"
            path += "?context=#{link}" if link

            path
          end

          index :role
          show :role

          def self.show_revision(project_id, identifier)
            show_revision_project_repository_path(project_id, identifier)
          end

          def self.show_user(user_id)
            user_path(user_id)
          end

          index :status
          show :status

          def self.string_object(value)
            val = ::ERB::Util::url_encode(value)
            "#{root}/string_objects?value=#{val}"
          end

          resources :time_entry

          def self.time_entries_activity(activity_id)
            "#{root}/time_entries/activities/#{activity_id}"
          end

          def self.time_entries_available_projects
            "#{time_entries}/available_projects"
          end

          def self.time_entries_available_work_packages_on_create
            "#{time_entries}/available_work_packages"
          end

          def self.time_entries_available_work_packages_on_edit(time_entry_id)
            "#{time_entry(time_entry_id)}/available_work_packages"
          end

          index :type
          show :type

          def self.types_by_project(project_id)
            "#{project(project_id)}/types"
          end

          index :user
          show :user

          class << self
            alias :groups :users
          end

          def self.user_lock(id)
            "#{user(id)}/lock"
          end

          def self.group(id)
            "#{root}/groups/#{id}"
          end

          resources :version

          def self.versions_available_projects
            "#{versions}/available_projects"
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

          def self.wiki_page(id)
            "#{root}/wiki_pages/#{id}"
          end

          resources :work_package, except: :schema

          def self.work_package_schema(project_id, type_id)
            "#{root}/work_packages/schemas/#{project_id}-#{type_id}"
          end

          def self.work_package_activities(id)
            "#{work_package(id)}/activities"
          end

          def self.work_package_relations(id)
            "#{work_package(id)}/relations"
          end

          def self.work_package_relation(id, work_package_id)
            "#{work_package_relations(work_package_id)}/#{id}"
          end

          def self.work_package_available_relation_candidates(id)
            "#{work_package(id)}/available_relation_candidates"
          end

          def self.work_package_revisions(id)
            "#{work_package(id)}/revisions"
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

          def self.path_for(path, filters: nil, sort_by: nil, page_size: nil)
            query_params = {
              filters: filters&.to_json,
              sortBy: sort_by&.to_json,
              pageSize: page_size
            }.reject { |_, v| v.blank? }

            if query_params.any?
              "#{send(path)}?#{query_params.to_query}"
            else
              send(path)
            end
          end

          def self.url_for(path, arguments = nil)
            duplicate_regexp = if OpenProject::Configuration.rails_relative_url_root
                                 Regexp.new("#{OpenProject::Configuration.rails_relative_url_root}/$")
                               else
                                 Regexp.new("/$")
                               end

            root_url = OpenProject::StaticRouting::StaticUrlHelpers.new.root_url

            root_url.gsub(duplicate_regexp, '') + send(path, arguments)
          end
        end

        def api_v3_paths
          ::API::V3::Utilities::PathHelper::ApiV3Path
        end
      end
    end
  end
end
