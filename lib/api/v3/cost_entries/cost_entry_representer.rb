#-- copyright
# OpenProject Costs Plugin
#
# Copyright (C) 2009 - 2014 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 3.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#++

module API
  module V3
    module CostEntries
      class CostEntryRepresenter < ::API::Decorators::Single
        self_link title_getter: ->(*) { nil }
        linked_property :project, embed_as: ::API::V3::Projects::ProjectRepresenter
        linked_property :user, embed_as: ::API::V3::Users::UserRepresenter
        linked_property :cost_type, embed_as: ::API::V3::CostTypes::CostTypeRepresenter

        # for now not embedded, because work packages are quite large
        linked_property :work_package, title_getter: ->(*) { represented.work_package.subject }

        property :id, render_nil: true
        property :units, as: :spentUnits
        property :spent_on,
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_date(represented.spent_on) }
        property :created_on,
                 as: 'createdAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_on) }
        property :updated_on,
                 as: 'updatedAt',
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_on) }

        def _type
          'CostEntry'
        end
      end
    end
  end
end
