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

module OpenProject
  module ActiveRecordExtensions
    class ProviderStatement < Arel::Nodes::SelectStatement
      attr_accessor :provided_cte,
                    :provided_cte_params,
                    :provided_cte_body,
                    :provided_cte_collected

      def initialize(cte_name, params = {}, body = nil)
        super()
        @cores = []
        self.provided_cte = cte_name
        self.provided_cte_params = params
        self.provided_cte_body = body
        self.provided_cte_collected = false
      end

      def collect_provided_cte!
        self.provided_cte_collected = true
        provided_cte
      end

      # The CTE body: the inline body when present, otherwise the registered
      # template rendered with the stored params.
      def provided_cte_sql
        provided_cte_body ||
          OpenProject::ActiveRecordExtensions::Cte::Aggregation
            .registered[provided_cte]
            .call(provided_cte_params)
      end

      # Identify providers by their CTE (name/params/body) rather than by the empty
      # SelectStatement they inherit from. Without this two different providers compare
      # equal, and ActiveRecord's `.or` (which ORs only the non-common predicates)
      # collapses `where(id: provider_a).or(where(id: provider_b))` down to one branch.
      def hash
        [self.class, provided_cte, provided_cte_params, provided_cte_body].hash
      end

      def eql?(other)
        other.is_a?(ProviderStatement) &&
          provided_cte == other.provided_cte &&
          provided_cte_params == other.provided_cte_params &&
          provided_cte_body == other.provided_cte_body
      end
      alias_method :==, :eql?

      alias_method :provided_cte_collected?, :provided_cte_collected
    end
  end
end
