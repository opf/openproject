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

module Types::Scopes
  module WithEffectiveConfiguration
    extend ActiveSupport::Concern

    class_methods do
      # Resolves each row's link chain for `aspect` in the same query, so iterating the
      # result doesn't run Type::ConfigurationLinkable's recursive walk per record.
      # Type#effective_source_id and Type#effective_excluded_elements pick the values up
      # from the selected columns and fall back to their own query when absent.
      #
      # The columns are suffixed with the aspect on purpose: a row loaded for one aspect
      # must not answer for another, and the suffix makes that a fallback rather than a
      # wrong answer. Several aspects can therefore be preloaded in one query by chaining.
      def with_effective_configuration(aspect)
        aspect = validated_aspect(aspect)
        lateral_alias = "effective_#{aspect}"

        joins("LEFT JOIN LATERAL (#{effective_configuration_lateral(aspect)}) #{lateral_alias} ON TRUE")
          .select("#{quoted_table_name}.*")
          .select("COALESCE(#{lateral_alias}.source_id, #{quoted_table_name}.id) AS effective_source_id_#{aspect}")
          .select("COALESCE(#{lateral_alias}.excluded, '{}'::text[]) AS effective_excluded_elements_#{aspect}")
      end

      private

      # The link chain seeded from the correlated `types.id` of the outer row. A type
      # owning the aspect resolves to itself; a pure cycle yields no row at all, which is
      # what the COALESCEs above turn back into "owns itself, excludes nothing".
      def effective_configuration_lateral(aspect)
        sanitize_sql_array([<<~SQL.squish, { aspect: }])
          #{link_chain_cte("#{quoted_table_name}.id")}
          SELECT cl.node_id AS source_id, cl.excluded AS excluded
          FROM link_chain cl
          WHERE #{terminal_node_condition}
          LIMIT 1
        SQL
      end

      # The aspect ends up in a column alias, so an unknown one must raise rather than be
      # interpolated into an identifier.
      def validated_aspect(aspect)
        aspect.to_s.tap do |candidate|
          unless Type::ConfigurationLink::ASPECTS.include?(candidate)
            raise ArgumentError, "Unknown configuration aspect #{aspect.inspect}"
          end
        end
      end
    end
  end
end
