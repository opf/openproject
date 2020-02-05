#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

module Queries::Filters::Strategies
  class BaseStrategy
    attr_accessor :filter

    class_attribute :supported_operators,
                    :default_operator

    delegate :values,
             :errors,
             to: :filter

    def initialize(filter)
      self.filter = filter
    end

    def validate; end

    def operator
      operator_map
        .slice(*self.class.supported_operators)[filter.operator]
    end

    def valid_values!; end

    def supported_operator_classes
      operator_map
        .slice(*self.class.supported_operators)
        .map(&:last)
        .sort_by { |o| self.class.supported_operators.index o.symbol.to_s }
    end

    def default_operator_class
      operator = self.class.default_operator || self.class.available_operators.first
      operator_map[operator]
    end

    private

    def operator_map
      ::Queries::Operators::OPERATORS
    end
  end
end
