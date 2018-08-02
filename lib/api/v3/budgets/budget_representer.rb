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

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module Budgets
      class BudgetRepresenter < ::API::Decorators::Single
        self_link title_getter: ->(*) { represented.subject }
        include API::Caching::CachedRepresenter
        include ::API::V3::Attachments::AttachableRepresenterMixin

        link :staticPath do
          next if represented.new_record?
          {
            href: cost_object_path(represented.id)
          }
        end

        property :id, render_nil: true
        property :subject, render_nil: true

        def _type
          'Budget'
        end
      end
    end
  end
end
