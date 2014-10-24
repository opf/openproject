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
    module Users
      class UserRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers
        include AvatarHelper

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {}, *expand)
          @current_user = options[:current_user]
          @work_package = options[:work_package]
          @expand = expand

          super(model)
        end

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_path}api/v3/users/#{represented.model.id}", title: "#{represented.model.name} - #{represented.model.login}" }
        end

        link :removeWatcher do
          {
            href: "#{root_path}api/v3/work_packages/#{@work_package.id}/watchers/#{represented.model.id}",
            method: :delete,
            title: 'Remove watcher'
          } if @work_package && current_user_allowed_to(:delete_work_package_watchers, @work_package)
        end

        property :id, getter: -> (*) { model.id }, render_nil: true
        property :login, render_nil: true
        property :subtype, getter: -> (*) { model.type }, render_nil: true
        property :firstname, as: :firstName, render_nil: true
        property :lastname, as: :lastName, render_nil: true
        property :name, getter: -> (*) { model.try(:name) }, render_nil: true
        property :mail, render_nil: true
        property :avatar, getter: -> (*) { avatar_url(represented) },
                          render_nil: true,
                          exec_context: :decorator
        property :created_at, getter: -> (*) { model.created_on.utc.iso8601 }, render_nil: true
        property :updated_at, getter: -> (*) { model.updated_on.utc.iso8601 }, render_nil: true
        property :status, getter: -> (*) { model.status }, render_nil: true

        def _type
          'User'
        end

        def current_user_allowed_to(permission, work_package)
          @current_user && @current_user.allowed_to?(permission, work_package.project)
        end
      end
    end
  end
end
