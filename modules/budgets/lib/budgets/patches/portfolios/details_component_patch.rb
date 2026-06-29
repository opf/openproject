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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module Budgets::Patches::Portfolios::DetailsComponentPatch
  def self.included(base) # :nodoc:
    base.prepend InstanceMethods
  end

  class PortfolioBudgets
    attr_reader :portfolio

    def initialize(portfolio)
      @portfolio = portfolio
    end

    delegate :any?, to: :budgets

    def total_planned
      @total_planned ||= budgets.sum(&:budget)
    end

    def total_spent
      @total_spent ||= budgets.sum(&:spent)
    end

    def budgets
      @budgets ||= portfolio.budgets.to_a
    end
  end

  module InstanceMethods
    def has_budget?
      with_portfolio_budgets(&:any?)
    end

    def total_budget
      with_portfolio_budgets do |portfolio_budgets|
        number_to_currency(portfolio_budgets.total_planned, precision: 0)
      end
    end

    def spent_budget
      with_portfolio_budgets do |portfolio_budgets|
        number_to_currency(portfolio_budgets.total_spent, precision: 0)
      end
    end

    def with_portfolio_budgets
      @portfolio_budgets ||= PortfolioBudgets.new(portfolio)
      return unless @portfolio_budgets.any?
      return unless User.current.allowed_in_project?(:view_budgets, portfolio)

      yield @portfolio_budgets
    end
  end
end
