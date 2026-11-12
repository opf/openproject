# frozen_string_literal: true

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
    module Webhooks
      class TableComponent < ::TableComponent
        columns :name, :enabled, :selected_projects, :events, :description

        def initial_sort
          %i[id asc]
        end

        def target_controller
          "webhooks/outgoing/admin"
        end

        def sortable?
          false
        end

        def inline_create_link
          link_to({ controller: target_controller, action: :new },
                  class: "webhooks--add-row wp-inline-create--add-link",
                  title: I18n.t("webhooks.outgoing.label_add_new")) do
            helpers.op_icon("icon icon-add")
          end
        end

        def empty_row_message
          I18n.t "webhooks.outgoing.no_results_table"
        end

        def headers
          [
            ["name", { caption: I18n.t("attributes.name") }],
            ["enabled", { caption: I18n.t(:label_active) }],
            ["selected_projects", { caption: ::Webhooks::Webhook.human_attribute_name(:projects) }],
            ["events", { caption: ::Webhooks::Webhook.human_attribute_name(:events) }],
            ["description", { caption: I18n.t("attributes.description") }]
          ]
        end
      end
    end
  end
end
