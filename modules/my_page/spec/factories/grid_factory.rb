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

FactoryBot.define do
  factory :my_page, class: "Grids::MyPage" do
    user
    row_count { 7 }
    column_count { 4 }
    widgets do
      [
        Grids::Widget.new(
          identifier: "news",
          start_row: 1,
          end_row: 7,
          start_column: 1,
          end_column: 3
        ),
        Grids::Widget.new(
          identifier: "documents",
          start_row: 1,
          end_row: 7,
          start_column: 3,
          end_column: 5
        )
      ]
    end

    trait :empty do
      widgets { [] }
      row_count { 1 }
      column_count { 1 }
    end
  end
end
