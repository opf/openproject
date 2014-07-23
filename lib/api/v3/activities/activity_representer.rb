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
    module Activities
      class ActivityRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {})
          @current_user = options[:current_user]

          super(model)
        end

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_url}api/v3/activities/#{represented.model.id}", title: "#{represented.model.id}" }
        end

        link :workPackage do
          { href: "#{root_url}api/v3/work_packages/#{represented.model.journable.id}", title: "#{represented.model.journable.subject}" }
        end

        link :user do
          { href: "#{root_url}api/v3/users/#{represented.model.user.id}", title: "#{represented.model.user.name} - #{represented.model.user.login}" }
        end

        link :update do
          {
              href: "#{root_url}api/v3/activities/#{represented.model.id}",
              method: :patch,
              title: "#{represented.model.id}"
          } if current_user_allowed_to(:edit_work_package_notes, represented.model.journable) && represented.model.editable_by?(@current_user)
        end

        property :id, getter: -> (*) { model.id }, render_nil: true
        property :notes, as: :comment, render_nil: true
        property :raw_notes, as: :rawComment, render_nil: true
        property :details, exec_context: :decorator, render_nil: true
        property :html_details, exec_context: :decorator, render_nil: true
        property :version, getter: -> (*) { model.version }, render_nil: true
        property :created_at, getter: -> (*) { model.created_at.utc.iso8601 }, render_nil: true

        def _type
          if represented.model.notes.blank?
            'Activity'
          else
            'Activity::Comment'
          end
        end

        def details
          render_details(represented.model, no_html: true)
        end

        def html_details
          render_details(represented.model)
        end

        private

        def current_user_allowed_to(permission, work_package)
          @current_user && @current_user.allowed_to?(permission, work_package.project)
        end

        def render_details(journal, no_html: false)
          journal.details.map{ |d| journal.render_detail(d, no_html: no_html) }
        end
      end
    end
  end
end
