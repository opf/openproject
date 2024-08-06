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

module WorkPackages::Scopes::IncludeDerivedDates
  extend ActiveSupport::Concern

  class_methods do
    def include_derived_dates
      joins(derived_dates_join_statement)
        .select(*derived_dates_select_statement)
        .group(:id)
    end

    private

    def derived_dates_select_statement
      ["LEAST(MIN(#{descendants_alias}.start_date), MIN(#{descendants_alias}.due_date)) AS derived_start_date",
       "GREATEST(MAX(#{descendants_alias}.start_date), MAX(#{descendants_alias}.due_date)) AS derived_due_date"]
    end

    def derived_dates_join_statement
      <<~SQL.squish
        LEFT JOIN work_package_hierarchies wp_hierarchies
        ON wp_hierarchies.ancestor_id = work_packages.id AND wp_hierarchies.generations > 0
        LEFT JOIN work_packages #{descendants_alias}
        ON wp_hierarchies.descendant_id = #{descendants_alias}.id
      SQL
    end

    def descendants_alias
      "descendants_work_packages"
    end
  end
end
