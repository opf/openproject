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

module Statuses
  # Captions and row cells sit on two separate CSS grids, so they only stay
  # aligned while both render the same columns. Both take the set from here.
  module ListColumns
    Column = Data.define(:area, :caption, :predicate)

    def columns
      [
        column(:name, Status.human_attribute_name(:name)),
        (column(:"done-ratio", WorkPackage.human_attribute_name(:done_ratio)) if show_done_ratio?),
        *flag_columns
      ].compact
    end

    def flag_columns
      [
        column(:"is-default", t("statuses.index.headers.is_default"), predicate: :is_default?),
        column(:"is-closed", t("statuses.index.headers.is_closed"), predicate: :is_closed?),
        column(:"is-readonly", t("statuses.index.headers.is_readonly"), predicate: :is_readonly?)
      ]
    end

    def show_done_ratio?
      WorkPackage.status_based_mode?
    end

    def grid_modifier_class(element)
      "op-statuses-list--#{element}_without-done-ratio" unless show_done_ratio?
    end

    private

    def column(area, caption, predicate: nil)
      Column.new(area:, caption:, predicate:)
    end
  end
end
