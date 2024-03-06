# frozen_string_literal: true

# -- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2010-2023 the OpenProject GmbH
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

class Projects::IndexPageHeaderComponent < ApplicationComponent
  include OpPrimer::ComponentHelpers
  include Primer::FetchOrFallbackHelper

  attr_accessor :current_user,
                :query,
                :state,
                :params

  BUTTON_MARGIN_RIGHT = 2

  STATE_DEFAULT = :show
  STATE_EDIT = :edit
  STATE_OPTIONS = [STATE_DEFAULT, STATE_EDIT].freeze

  def initialize(current_user:, query:, params:, state: :show)
    super

    self.current_user = current_user
    self.query = query
    self.state = fetch_or_fallback(STATE_OPTIONS, state)
    self.params = params
  end

  def gantt_portfolio_query_link
    generator = ::Projects::GanttQueryGeneratorService.new(gantt_portfolio_project_ids)
    gantt_index_path query_props: generator.call
  end

  def gantt_portfolio_project_ids
    @gantt_portfolio_project_ids ||= @query
                                     .results
                                     .where(active: true)
                                     .select(:id)
                                     .uniq
                                     .pluck(:id)
  end

  def page_title
    query.name || t(:label_project_plural)
  end

  def query_saveable?
    current_user.logged? && query.name.blank?
  end

  def show_state?
    state == :show
  end
end
