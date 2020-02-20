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
    module CostEntries
      class CostEntryRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        self_link title_getter: ->(*) { nil }
        associated_resource :project
        associated_resource :user
        associated_resource :cost_type

        # for now not embedded, because work packages are quite large
        associated_resource :work_package,
                            getter: ->(*) {},
                            link_title_attribute: :subject

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
