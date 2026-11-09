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

module Budgets
  class ProjectBudgetAggregation
    attr_reader :project

    def initialize(project)
      @project = project
    end

    delegate :any?, to: :budgets

    def total_planned
      @total_planned ||= budgets.sum(&:budget)
    end

    def total_spent
      @total_spent ||= budgets.sum(&:spent)
    end

    def total_available
      @total_available ||= budgets.sum(&:available)
    end

    def total_ratio
      @total_ratio ||= total_planned.zero? ? 0 : ((total_spent / total_planned) * 100).round
    end

    def budgets
      @budgets ||= project.budgets.to_a
    end
  end
end
