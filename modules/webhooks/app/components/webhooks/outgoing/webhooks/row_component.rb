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
      class RowComponent < ::RowComponent
        include OpPrimer::ComponentHelpers

        property :description

        delegate :event_names, to: :webhook

        def webhook
          model
        end

        def name
          link_to webhook.name,
                  { controller: table.target_controller, action: :show, webhook_id: webhook.id }
        end

        def enabled
          if webhook.enabled?
            helpers.op_icon "icon-yes"
          end
        end

        def events
          return render_warning(t(:"webhooks.outgoing.label_x_events", count: 0).capitalize) if event_names.empty?

          event_names
            .map { OpenProject::Webhooks::EventResources.lookup_resource_name(it) }
            .group_by(&:first)
            .transform_values { |pairs| pairs.map(&:last).sort }
            .then { render_events_list(it) }
        end

        def selected_projects
          return t(:"webhooks.outgoing.form.project_ids.all") if webhook.all_projects?
          return render_warning(t(:label_x_projects, count: 0).capitalize) if webhook.projects.empty?

          t(:label_x_projects, count: webhook.projects.size)
        end

        def row_css_class
          [
            "webhooks--outgoing-webhook-row",
            "webhooks--outgoing-webhook-row-#{model.id}"
          ].join(" ")
        end

        ###

        def button_links
          [edit_link, delete_link]
        end

        def edit_link
          link_to(
            helpers.op_icon("icon icon-edit button--link"),
            { controller: table.target_controller, action: :edit, webhook_id: webhook.id },
            title: t(:button_edit)
          )
        end

        def delete_link
          link_to(
            helpers.op_icon("icon icon-delete button--link"),
            { controller: table.target_controller, action: :destroy, webhook_id: webhook.id },
            data: { turbo_method: :delete, turbo_confirm: I18n.t(:text_are_you_sure) },
            title: t(:button_delete)
          )
        end

        private

        def render_warning(text)
          render Primer::OpenProject::InlineMessage.new(scheme: :warning).with_content(text)
        end

        def render_events_list(items)
          render(OpPrimer::ListComponent.new(ml: 0)) do |list|
            items.each do |resource, events|
              list.with_item do
                component_collection do |list_item_parts|
                  list_item_parts.with_component(Primer::Beta::Text.new.with_content(resource))
                  list_item_parts.with_component(Primer::Beta::Text.new(font_size: :small, color: :muted)) do
                    events.join(t(:"support.array.words_connector", default: ", ")).then { "(#{it})" }
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
