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

module TypeVariants::Scopes
  module WithEffectiveConfiguration
    extend ActiveSupport::Concern

    class_methods do
      # Resolves each row's link chain for `aspect` in the same query, so iterating the
      # result doesn't run TypeVariant::ConfigurationLinkable's recursive walk per record.
      # TypeVariant#effective_source_id and TypeVariant#effective_excluded_elements pick the values up
      # from the selected columns and fall back to their own query when absent.
      #
      # The columns are suffixed with the aspect on purpose: a row loaded for one aspect
      # must not answer for another, and the suffix makes that a fallback rather than a
      # wrong answer. Several aspects can therefore be preloaded in one query by chaining.
      def with_effective_configuration(aspect)
        aspect = validated_configuration_aspect(aspect)
        join, source_id, excluded = effective_configuration_lateral("#{quoted_table_name}.id", aspect)

        joins(join)
          .select("#{quoted_table_name}.*")
          .select("#{source_id} AS effective_source_id_#{aspect}")
          .select("#{excluded} AS effective_excluded_elements_#{aspect}")
      end
    end
  end
end
