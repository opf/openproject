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

class ExportSetting < ApplicationRecord
  belongs_to :query

  POSSIBLE_FORMATS = %w[csv xls pdf_table pdf_report pdf_gantt].freeze

  validates :query_id, presence: true
  validates :format, presence: true, inclusion: { in: POSSIBLE_FORMATS }
  validates :settings, presence: true

  validate :unique_format_per_query

  def settings
    # Read idiomatic symbol keys for JSONB column
    super.symbolize_keys
  end

  def settings=(value)
    # Provide database with string keys
    super(value.stringify_keys)
  end

  # Some boolean settings are saved as string. Use this method to conveniently check if they are
  # set to true.
  def true?(key, default: false)
    %w[true 1].include?(settings.fetch(key, default).to_s)
  end

  private

  def unique_format_per_query
    if ExportSetting.exists?(query_id: query_id, format: format) && (new_record? || format_changed?)
      errors.add(:format, "there already is an export setting for this query with this format")
    end
  end
end
