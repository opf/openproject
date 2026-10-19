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

module Saml
  module Providers
    class RowComponent < ::OpPrimer::BorderBoxRowComponent
      def provider
        model
      end

      def name
        concat render(Primer::Beta::Link.new(
                        font_weight: :bold,
                        href: url_for(action: :show, id: provider.id)
                      )) { provider.display_name || provider.name }

        render_availability_label
      end

      def render_availability_label
        unless provider.available?
          render(Primer::Beta::Label.new(ml: 2, scheme: :attention, size: :medium)) { t(:label_incomplete) }
        end
      end

      def button_links
        [edit_link, delete_link].compact
      end

      def edit_link
        link_to(
          helpers.op_icon("icon icon-edit button--link"),
          url_for(action: :edit, id: provider.id),
          title: t(:button_edit)
        )
      end

      def users
        provider.user_count.to_s
      end

      def creator
        helpers.avatar(provider.creator, size: :mini, hide_name: false)
      end

      def created_at
        helpers.format_time provider.created_at
      end

      def delete_link
        return if provider.readonly

        link_to(
          helpers.op_icon("icon icon-delete button--link"),
          url_for(action: :confirm_destroy, id: provider.id),
          data: { turbo_stream: true },
          title: t(:button_delete)
        )
      end
    end
  end
end
