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

module Portfolios
  class DetailsComponent < ApplicationComponent
    include ApplicationHelper
    include OpPrimer::ComponentHelpers
    include WorkspaceHelper

    attr_reader :current_user, :portfolio

    delegate :archived?, to: :portfolio

    def initialize(portfolio:, current_user:)
      super
      @portfolio = portfolio
      @current_user = current_user
    end

    def name_caption
      if archived?
        "#{@portfolio.name} (#{t('project.archive.archived')})"
      else
        @portfolio.name
      end
    end

    def currently_favorited?
      @currently_favorited ||= portfolio.favorited?
    end

    def all_subprograms
      all_descendants.program
    end

    def all_subprojects
      all_descendants.project
    end

    def render_sub_status_bar?
      !archived?
    end

    def sub_statuses_with_percentages
      @sub_statuses_with_percentages ||=
        begin
          total = sub_statuses.values.sum

          sub_statuses.map do |code, count|
            percentage = (count.fdiv(total) * 100).round(1)

            { code:, count:, percentage: }
          end
        end
    end

    def sub_status_bar_contents
      if sub_statuses_with_percentages.empty?
        [{ code: "not_set", percentage: 100 }]
      else
        sub_statuses_with_percentages
      end
    end

    def sub_status_hover_card_id
      "portfolio-progress-hover-card-#{portfolio.id}"
    end

    # If the budget module is enabled, this method will be overridden by the patch
    # in modules/budgets/lib/budgets/patches/portfolios/details_component_patch.rb
    def has_budget?
      false
    end

    private

    def all_descendants
      @all_descendants ||= portfolio
                             .descendants
                             .where(workspace_type: %w[project program])
                             .visible
    end

    def sub_statuses
      @sub_statuses ||= all_descendants
                          .reorder(:status_code)
                          .pluck(:status_code)
                          .tally
    end

    # Will return a hash with Primer style options if the portfolio is archived.
    # Will return an empty hash if the portfolio is active.
    #
    # Intended to be injected into a Primer component's `**options` parameter that relies on the archived
    # state of a portfolio to decide the display style.
    def archived_style
      archived? ? { color: :muted } : {}
    end
  end
end
