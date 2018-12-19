#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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
    module Grids
      class GridRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        resource_link :page,
                      getter: ->(*) {
                        path = ::Grids::Configuration.grid_for_class(represented.class)

                        next unless path

                        {
                          href: path,
                          type: 'text/html'
                        }
                      },
                      setter: ->(fragment:, **) {
                        represented.page = fragment['href']
                      }

        self_link title_getter: ->(*) { nil }

        link :updateImmediately do
          {
            href: api_v3_paths.grid(represented.id),
            method: :patch
          }
        end

        link :update do
          {
            href: api_v3_paths.grid_form(represented.id),
            method: :post
          }
        end

        property :id

        property :row_count

        property :column_count

        property :widgets,
                 exec_context: :decorator,
                 getter: ->(*) do
                   represented.widgets.map do |widget|
                     WidgetRepresenter.new(widget, current_user: current_user)
                   end
                 end,
                 setter: ->(fragment:, **) do
                   represented.widgets = fragment.map do |widget_fragment|
                     WidgetRepresenter
                       .new(::Grids::Widget.new, current_user: current_user)
                       .from_hash(widget_fragment.with_indifferent_access)
                   end
                 end

        property :created_at,
                 exec_context: :decorator,
                 writeable: false,
                 getter: ->(*) {
                   next unless represented.created_at
                   datetime_formatter.format_datetime(represented.created_at)
                 }

        property :updated_at,
                 exec_context: :decorator,
                 writeable: false,
                 getter: ->(*) {
                   next unless represented.updated_at
                   datetime_formatter.format_datetime(represented.updated_at)
                 }

        def _type
          'Grid'
        end
      end
    end
  end
end
