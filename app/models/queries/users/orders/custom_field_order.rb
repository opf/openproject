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

class Queries::Users::Orders::CustomFieldOrder < Queries::Orders::Base
  self.model = User.all

  EXCLUDED_CUSTOM_FIELD_TYPES = %w[text].freeze

  validates :custom_field, presence: { message: I18n.t(:"activerecord.errors.messages.does_not_exist") }

  def self.key
    valid_ids = RequestStore.fetch(:custom_sortable_user_custom_fields) do
      scope.pluck(:id)
    end

    /\Acf_(#{valid_ids.join('|')})\z/
  end

  def self.scope
    UserCustomField.where.not(field_format: EXCLUDED_CUSTOM_FIELD_TYPES).visible
  end

  def custom_field
    return @custom_field if defined?(@custom_field)

    @custom_field = self.class.scope.find_by(id: attribute[/\Acf_(\d+)\z/, 1])
  end

  def available?
    custom_field.present?
  end

  private

  def order(scope)
    with_raise_on_invalid do
      if (join_statement = custom_field.order_join_statement)
        scope = scope.joins(join_statement)
      end

      if (order_statement = custom_field.order_statement)
        # `direction` is validated by the base class and re-checked above; pin the
        # SQL fragment to a literal here so static analysis (Brakeman) can prove
        # no user input flows into the interpolation.
        direction_sql = direction == :desc ? "DESC" : "ASC"
        order_clause = "#{order_statement} #{direction_sql}"

        if (null_handling = custom_field.order_null_handling(direction == :asc))
          order_clause = "#{order_clause} #{null_handling}"
        end

        scope = scope.order(Arel.sql(order_clause))
      end

      scope
    end
  end
end
