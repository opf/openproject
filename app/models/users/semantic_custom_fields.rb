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

module Users::SemanticCustomFields
  extend ActiveSupport::Concern

  class_methods do
    def job_title_custom_field_id
      RequestStore.fetch(:job_title_custom_field_id) do
        UserCustomField.for_semantic_key(:job_title)&.id
      end
    end
  end

  def job_title
    job_title_values
      .filter_map { |custom_value| custom_value.formatted_value.presence }
      .join(", ")
      .presence
  end

  private

  def job_title_values
    field_id = self.class.job_title_custom_field_id
    return [] if field_id.blank?

    if custom_values.loaded?
      custom_values.select { |custom_value| custom_value.custom_field_id == field_id }
    else
      custom_values.where(custom_field_id: field_id).includes(:custom_field)
    end
  end
end
