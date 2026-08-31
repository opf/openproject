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

module Queries::Users::CustomFieldContext
  class << self
    def custom_field_class
      ::UserCustomField
    end

    def model
      ::User
    end

    # User / Group / PlaceholderUser all persist as Principal in
    # custom_values.customized_type (STI base class). Constraining the
    # join by `custom_field_id` to a UserCustomField scopes us to user CFs.
    def customized_type
      "Principal"
    end

    def custom_fields(_context = nil)
      custom_field_class.visible
    end

    def find_custom_field(id)
      custom_field_cache.fetch(id.to_i) do |key|
        custom_field_cache[key] = custom_fields.where(id: key).first
      end
    end

    def where_subselect_joins(custom_field)
      # Custom values are stored against Principal (the STI base class of User / Group /
      # PlaceholderUser), all sharing the `users` table. Constraining the join by
      # `custom_field_id` to a UserCustomField is what scopes the rows to users.
      <<~SQL.squish
        LEFT OUTER JOIN #{cv_db_table}
          ON #{cv_db_table}.customized_type = 'Principal'
          AND #{cv_db_table}.customized_id = #{users_db_table}.id
          AND #{cv_db_table}.custom_field_id = #{custom_field.id}
      SQL
    end

    def where_subselect_conditions
      nil
    end

    private

    def cv_db_table = CustomValue.table_name
    def users_db_table = User.table_name
    def custom_field_cache = RequestStore.fetch("Queries::Users::CustomFieldContext/cache") { {} }
  end
end
