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

require_dependency 'grids/grid'

module Boards
  class Grid < ::Grids::Grid
    belongs_to :project
    validates_presence_of :name

    before_destroy :delete_queries

    set_acts_as_attachable_options view_permission: :show_board_views,
                                   delete_permission: :manage_board_views,
                                   add_permission: :manage_board_views

    def user_deletable?
      true
    end

    def contained_queries
      ::Query.where(id: contained_query_ids)
    end

    private

    def delete_queries
      contained_queries.delete_all
    end

    def contained_query_ids
      widgets
        .map { |w| w.options['queryId'] || w.options['query_id'] }
        .compact
    end
  end
end
