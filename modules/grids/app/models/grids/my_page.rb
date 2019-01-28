#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module Grids
  class MyPage < Grid
    belongs_to :user

    def self.new_default(user)
      new(
        user: user,
        row_count: 7,
        column_count: 4,
        widgets: [
          Grids::Widget.new(
            identifier: 'work_packages_assigned',
            start_row: 1,
            end_row: 7,
            start_column: 1,
            end_column: 3
          ),
          Grids::Widget.new(
            identifier: 'work_packages_created',
            start_row: 1,
            end_row: 7,
            start_column: 3,
            end_column: 5
          )
        ]
      )
    end

    def self.visible_scope
      where(user_id: User.current.id)
    end
  end
end
