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

class Queries::Projects::Orders::CustomFieldOrder < Queries::Orders::Base
  self.model = Project.all

  EXCLUDED_CUSTOM_FIELD_TYPES = %w(text)
  KEY_FORMAT = /cf_(\d+)/

  validates :custom_field, presence: { message: I18n.t(:"activerecord.errors.messages.does_not_exist") }

  def self.key
    valid_ids = RequestStore.fetch(:custom_sortable_project_custom_fields) do
      ProjectCustomField.where.not(field_format: EXCLUDED_CUSTOM_FIELD_TYPES).visible.pluck(:id).join("|")
    end

    /cf_(#{valid_ids})/
  end

  def custom_field
    @custom_field ||= begin
      id = KEY_FORMAT.match(attribute)[1]

      ProjectCustomField
      .where.not(field_format: EXCLUDED_CUSTOM_FIELD_TYPES)
      .visible
      .find_by(id:)
    end
  end

  def apply_to(_query_scope)
    super.select(custom_field.order_statements)
  end

  def available?
    custom_field.present?
  end

  private

  def order(scope)
    joined_statement = custom_field.order_statements.map do |statement|
      Arel.sql("#{statement} #{direction}")
    end

    scope.order(joined_statement)
  end
end
