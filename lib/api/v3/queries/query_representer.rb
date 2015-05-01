#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
require 'roar/json/hal'

module API
  module V3
    module Queries
      class QueryRepresenter < ::API::Decorators::Single
        link :self do
          {
            href: api_v3_paths.query(represented.id),
            title: "#{represented.name}"
          }
        end

        property :id, render_nil: true
        property :name, render_nil: true
        property :project_id, getter: -> (*) { project.id }
        property :project_name, getter: -> (*) { project.try(:name) }
        property :user_id, getter: -> (*) { user.try(:id) }, render_nil: true
        property :user_name, getter: -> (*) { user.try(:name) }, render_nil: true
        property :user_login, getter: -> (*) { user.try(:login) }, render_nil: true
        property :user_mail, getter: -> (*) { user.try(:mail) }, render_nil: true
        property :filters, render_nil: true
        property :is_public, getter: -> (*) { is_public.to_s }, render_nil: true
        property :column_names, render_nil: true
        property :sort_criteria, render_nil: true
        property :group_by, render_nil: true
        property :display_sums, getter: -> (*) { display_sums.to_s }, render_nil: true
        property :is_starred, getter: -> (*) { (!query_menu_item.nil?).to_s }

        def _type
          'Query'
        end
      end
    end
  end
end
