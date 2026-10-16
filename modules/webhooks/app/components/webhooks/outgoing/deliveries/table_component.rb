#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module ::Webhooks
  module Outgoing
    module Deliveries
      class TableComponent < ::TableComponent
        columns :id, :event_name, :time, :response_code, :response_body

        def sortable?
          false
        end

        def empty_row_message
          I18n.t "webhooks.outgoing.deliveries.no_results_table"
        end

        def headers
          [
            ["id", { caption: I18n.t("attributes.id") }],
            ["event_name", { caption: ::Webhooks::Log.human_attribute_name("event_name") }],
            ["time", { caption: I18n.t("webhooks.outgoing.deliveries.time") }],
            ["response_code", { caption: ::Webhooks::Log.human_attribute_name("response_code") }],
            ["response_body", { caption: ::Webhooks::Log.human_attribute_name("response_body") }]
          ]
        end
      end
    end
  end
end
