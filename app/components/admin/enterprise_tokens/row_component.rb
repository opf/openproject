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

module Admin::EnterpriseTokens
  class RowComponent < ::OpPrimer::BorderBoxRowComponent
    alias :token :model

    def column_css_class(column)
      if column == :dates
        "#{super} -no-ellipsis"
      else
        super
      end
    end

    # Subscription column
    def subscription
      render(Primer::Box.new(classes: "d-flex flex-column gap-1")) do
        concat plan_name_with_statuses_html
        concat subscriber_html
      end
    end

    def plan_name_with_statuses_html
      render(Primer::Box.new(classes: "d-flex flex-row gap-1 flex-items-baseline")) do
        concat primer_text(plan_name, font_weight: :bold)
        token.statuses.each do |status|
          concat token_status_label_html(status)
        end
      end
    end

    def subscriber_html
      primer_text(token.subscriber, tag: :div)
    end

    def token_status_label_html(status)
      primer_label(I18n.t("admin.enterprise.status.#{status}"), scheme: status_scheme(status))
    end

    # Active users column
    def max_active_users
      count =
        if token.unlimited_users?
          I18n.t("ee.upsell.unlimited")
        else
          token.max_active_users.to_s
        end
      primer_text(count, color: :subtle)
    end

    # Domain column
    def domain
      primer_text(token.domain, color: :subtle)
    end

    # Dates column
    def dates
      capture do
        concat(primer_text(start_date, color: start_date_color))
        concat(primer_text(" – "))
        concat(primer_text(expiration_date, color: expiration_date_color))
      end
    end

    def button_links
      [
        action_menu
      ]
    end

    def action_menu
      render(Primer::Alpha::ActionMenu.new) do |menu|
        menu.with_show_button(icon: "kebab-horizontal",
                              "aria-label": t(:label_more),
                              scheme: :invisible,
                              data: {
                                "test-selector": "more-button"
                              })

        delete_action(menu)
      end
    end

    def delete_action(menu)
      menu.with_item(label: I18n.t(:button_delete),
                     scheme: :danger,
                     href: destroy_dialog_enterprise_token_path(token),
                     tag: :a,
                     content_arguments: {
                       data: { controller: "async-dialog" }
                     }) do |item|
        item.with_leading_visual_icon(icon: :trash)
      end
    end

    private

    def plan_name
      helpers.enterprise_token_plan_name(token)
    end

    def status_scheme(status)
      case status
      when :trial
        :accent
      when :invalid_domain, :expired
        :danger
      when :not_active, :expiring_soon, :in_grace_period
        :attention
      end
    end

    def start_date
      helpers.format_date(token.starts_at)
    end

    def expiration_date
      token.will_expire? ? helpers.format_date(token.expires_at) : I18n.t("ee.upsell.unlimited")
    end

    def start_date_color
      if token.started?
        :subtle
      else
        :attention
      end
    end

    def expiration_date_color
      if token.expiring_soon? || token.in_grace_period?
        :attention
      elsif token.expired?
        :danger
      else
        :subtle
      end
    end

    def primer_text(text, color: :subtle, **options)
      if color != :subtle
        options = options.reverse_merge(font_weight: :bold)
      end
      render(Primer::Beta::Text.new(color:, **options)) { text }
    end

    def primer_label(text, scheme:)
      render(Primer::Beta::Label.new(scheme:)) { text }
    end
  end
end
