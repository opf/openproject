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
  class TrialTeaserComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(**system_arguments)
      set_system_arguments(system_arguments)

      super
    end

    private

    def set_system_arguments(system_arguments)
      @system_arguments = system_arguments
      @system_arguments[:tag] = :div
      @system_arguments[:my] = 2
      @system_arguments[:id] = "op-enterprise-banner-teaser"
      @system_arguments[:test_selector] = "op-enterprise-banner"
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        "op-enterprise-banner"
      )
    end

    def render?
      User.current.admin? && EnterpriseToken.trial_only?
    end

    def token
      @token ||= EnterpriseToken.active_trial_token
    end

    def title
      I18n.t("ee.teaser.title", count: token.days_left, trial_plan: token.plan)
    end

    def description
      helpers.t("ee.teaser.description_html", trial_plan: plan_name)
    end

    def plan_name
      render(Primer::Beta::Text.new(font_weight: :bold, classes: "upsell-colored-text")) do
        I18n.t("ee.upsell.plan_name", plan: token.plan.capitalize)
      end
    end
  end
end
