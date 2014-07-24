#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/representer/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {}, *expand)
          @current_user = options[:current_user]
          @expand = expand

          super(model)
        end

        property :_type, exec_context: :decorator

        link :self do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}",
            title: "#{represented.subject}"
          }
        end

        link :author do
          {
            href: "#{root_url}api/v3/users/#{represented.work_package.author.id}",
            title: "#{represented.work_package.author.name} - #{represented.work_package.author.login}"
          } unless represented.work_package.author.nil?
        end

        link :responsible do
          {
            href: "#{root_url}api/v3/users/#{represented.work_package.responsible.id}",
            title: "#{represented.work_package.responsible.name} - #{represented.work_package.responsible.login}"
          } unless represented.work_package.responsible.nil?
        end

        link :assignee do
          {
            href: "#{root_url}api/v3/users/#{represented.work_package.assigned_to.id}",
            title: "#{represented.work_package.assigned_to.name} - #{represented.work_package.assigned_to.login}"
          } unless represented.work_package.assigned_to.nil?
        end

        link :availableStatuses do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}/available_statuses",
            title: 'Available Statuses'
          } if @current_user.allowed_to?({ controller: :work_packages, action: :update },
                                         represented.work_package.project)
        end

        link :availableWatchers do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}/available_watchers",
            title: 'Available Watchers'
          }
        end

        link :watch do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}/watchers",
            method: :post,
            data: { user_id: @current_user.id },
            title: 'Watch work package'
          } if !@current_user.anonymous? &&
             current_user_allowed_to(:view_work_packages, represented.work_package) &&
            !represented.work_package.watcher_users.include?(@current_user)
        end

        link :unwatch do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}/watchers/#{@current_user.id}",
            method: :delete,
            title: 'Unwatch work package'
          } if current_user_allowed_to(:view_work_packages, represented.work_package) && represented.work_package.watcher_users.include?(@current_user)
        end

        link :addWatcher do
          {
            href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}/watchers{?user_id}",
            method: :post,
            title: 'Add watcher',
            templated: true
          } if current_user_allowed_to(:add_work_package_watchers, represented.work_package)
        end

        property :id, getter: -> (*) { work_package.id }, render_nil: true
        property :subject, render_nil: true
        property :type, render_nil: true
        property :description, render_nil: true
        property :raw_description, render_nil: true
        property :status, render_nil: true
        property :priority, render_nil: true
        property :start_date, getter: -> (*) { work_package.start_date }, render_nil: true
        property :due_date, getter: -> (*) { work_package.due_date }, render_nil: true
        property :estimated_time, render_nil: true
        property :percentage_done, render_nil: true
        property :version_id, getter: -> (*) { work_package.fixed_version.try(:id) }, render_nil: true
        property :version_name,  getter: -> (*) { work_package.fixed_version.try(:name) }, render_nil: true
        property :project_id, getter: -> (*) { work_package.project.id }
        property :project_name, getter: -> (*) { work_package.project.try(:name) }
        property :created_at, getter: -> (*) { work_package.created_at.utc.iso8601}, render_nil: true
        property :updated_at, getter: -> (*) { work_package.updated_at.utc.iso8601}, render_nil: true

        collection :custom_properties, exec_context: :decorator, render_nil: true

        property :author, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !author.nil? }
        property :responsible, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !responsible.nil? }
        property :assignee, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !assignee.nil? }

        collection :activities, embedded: true, class: ::API::V3::Activities::ActivityModel, decorator: ::API::V3::Activities::ActivityRepresenter
        property :watchers, embedded: true, exec_context: :decorator
        # collection :watchers, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter
        collection :attachments, embedded: true, class: ::API::V3::Attachments::AttachmentModel, decorator: ::API::V3::Attachments::AttachmentRepresenter

        def _type
          'WorkPackage'
        end

        def watchers
          represented.watchers.map{ |watcher| ::API::V3::Users::UserRepresenter.new(watcher, work_package: represented.work_package, current_user: @current_user) }
        end

        def custom_properties
            values = represented.work_package.custom_field_values
            values.map { |v| { name: v.custom_field.name, format: v.custom_field.field_format, value: v.value }}
        end

        def current_user_allowed_to(permission, work_package)
          @current_user && @current_user.allowed_to?(permission, work_package.project)
        end
      end
    end
  end
end
