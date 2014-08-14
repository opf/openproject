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
    module Queries
      class QueryRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = API::Utilities::CamelCasingStrategy.new

        property :_type, exec_context: :decorator

        link :self do
          { href: "#{root_path}api/v3/queries/#{represented.model.id}", title: "#{represented.name}" }
        end

        property :id, getter: -> (*) { model.id }, render_nil: true
        property :name, render_nil: true
        property :project_id, getter: -> (*) { model.project.id }
        property :project_name, getter: -> (*) { model.project.try(:name) }
        property :user_id, getter: -> (*) { model.user.try(:id) }, render_nil: true
        property :user_name, getter: -> (*) { model.user.try(:name) }, render_nil: true
        property :user_login, getter: -> (*) { model.user.try(:login) }, render_nil: true
        property :user_mail, getter: -> (*) { model.user.try(:mail) }, render_nil: true
        property :filters, render_nil: true
        property :is_public, getter: -> (*) { model.is_public.to_s }, render_nil: true
        property :column_names, render_nil: true
        property :sort_criteria, render_nil: true
        property :group_by, render_nil: true
        property :display_sums, getter: -> (*) { model.display_sums.to_s }, render_nil: true
        property :is_starred, getter: -> (*) { is_starred.to_s }, exec_context: :decorator

        def _type
          "Query"
        end

        def is_starred
            return true if !represented.model.query_menu_item.nil?
            false
        end
      end
    end
  end
end
