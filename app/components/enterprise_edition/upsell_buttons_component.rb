# frozen_string_literal: true

# -- copyright
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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
# ++

module EnterpriseEdition
  class UpsellButtonsComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    # @param feature_key [Symbol, NilClass] The key of the feature to show the banner for.
    # @param show_buy_now [Boolean] Whether to show the "Buy now" button.
    # @param system_arguments [Hash] <%= link_to_system_arguments_docs %>
    def initialize(feature_key, show_buy_now: false, **system_arguments)
      super

      @system_arguments = system_arguments
      @system_arguments[:align_items] ||= :center
      @system_arguments[:flex_wrap] ||= :wrap
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-enterprise-banner--upsell-buttons"
      )
      @feature_key = feature_key
      @show_buy_now = show_buy_now
    end

    def call
      flex_layout(**@system_arguments) do |flex|
        buttons.each do |button|
          flex.with_column do
            button
          end
        end
      end
    end

    private

    attr_reader :feature_key

    def buttons
      [
        buy_now_button,
        free_trial_button,
        upgrade_now_button,
        more_info_button
      ].compact
    end

    def free_trial_button
      render ::EnterpriseTrials::TrialButtonComponent.new
    end

    def buy_now_button
      return unless EnterpriseToken.active?
      return unless User.current.admin?

      render(EnterpriseEdition::BuyNowButtonComponent.new)
    end

    # Allow providing a custom upgrade now button
    def upgrade_now_button
      if @show_buy_now
        button_title = t("admin.enterprise.book_now")
        render(
          Primer::Beta::Button.new(
            tag: :a,
            size: :medium,
            href: "#",
            aria: { label: button_title },
            classes: "upsell-colored-background",
            role: "button",
            data: {
              "cb-type": "checkout",
              "cb-plan-id": OpenProject::Configuration.enterprise_plan
            },
            title: button_title
          )
        ) { button_title }
      end
    end

    def more_info_button
      return if @feature_key == :teaser

      fallback_link = OpenProject::Static::Links.url_for(:enterprise_features, :default)
      helpers.static_link_to(:enterprise_features, feature_key,
                             href: fallback_link,
                             label: link_title)
    end

    def link_title
      I18n.t("ee.upsell.#{feature_key}.link_title", default: I18n.t(:label_more_information))
    end
  end
end
