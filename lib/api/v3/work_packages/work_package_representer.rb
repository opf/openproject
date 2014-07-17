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

        def initialize(options = {}, *expand)
          @expand = expand
          super(options)
        end

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_url}api/v3/work_packages/#{represented.work_package.id}", title: "#{represented.subject}" }
        end

        property :id, getter: -> (*) { work_package.id }, render_nil: true
        property :subject, render_nil: true
        property :type, render_nil: true
        property :description, render_nil: true
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
        property :responsible_id, getter: -> (*) { work_package.responsible.try(:id) }, render_nil: true
        property :responsible_name, getter: -> (*) { work_package.responsible.try(:name) }, render_nil: true
        property :responsible_login, getter: -> (*) { work_package.responsible.try(:login) }, render_nil: true
        property :responsible_mail, getter: -> (*) { work_package.responsible.try(:mail) }, render_nil: true
        property :responsible_avatar, getter: -> (*) {  gravatar_image_url(work_package.responsible.try(:mail)) }, render_nil: true
        property :assigned_to_id, as: :assigneeId, getter: -> (*) { work_package.assigned_to.try(:id) }, render_nil: true
        property :assignee_name, getter: -> (*) { work_package.assigned_to.try(:name) }, render_nil: true
        property :assignee_login, getter: -> (*) { work_package.assigned_to.try(:login) }, render_nil: true
        property :assignee_mail, getter: -> (*) { work_package.assigned_to.try(:mail) }, render_nil: true
        property :assignee_avatar, getter: -> (*) {  gravatar_image_url(work_package.assigned_to.try(:mail)) }, render_nil: true
        property :author_name, getter: -> (*) { work_package.author.name }, render_nil: true
        property :author_login, getter: -> (*) { work_package.author.login }, render_nil: true
        property :author_mail, getter: -> (*) { work_package.author.mail }, render_nil: true
        property :author_avatar, getter: -> (*) {  gravatar_image_url(work_package.author.try(:mail)) }, render_nil: true
        property :created_at, getter: -> (*) { work_package.created_at.utc.iso8601}, render_nil: true
        property :updated_at, getter: -> (*) { work_package.updated_at.utc.iso8601}, render_nil: true

        collection :activities, embedded: true, class: ::API::V3::Activities::ActivityModel, decorator: ::API::V3::Activities::ActivityRepresenter
        collection :watchers, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter
        collection :relations,  embedded: true, class: RelationModel, decorator: RelationRepresenter

        def _type
          'WorkPackage'
        end

      end
    end
  end
end
