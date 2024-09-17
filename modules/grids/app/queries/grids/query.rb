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

module Grids
  class Query
    include ::Queries::BaseQuery
    include ::Queries::UnpersistedQuery

    def self.model
      Grids::Grid
    end

    ##
    # Returns the scope this query is filtered for, if any.
    def filter_scope
      scope_filter = filters.detect { |f| f.name.to_sym == :scope }
      scope_filter&.values&.first
    end

    def default_scope
      configs = ::Grids::Configuration.all

      or_scope = configs.pop.visible(User.current)

      while configs.any?
        or_scope = or_scope.or(configs.pop.visible(User.current))
      end

      # Have to use the subselect as AR will otherwise remove
      # associations not defined on the subclass
      Grids::Grid.where(id: or_scope)
    end
  end
end
