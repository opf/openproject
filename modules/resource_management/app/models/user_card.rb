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

class UserCard < PersistedView
  include ResourceManagement::Categorized

  SECONDARY_INFO = %w[role email login none].freeze
  TAG_SOURCES    = %w[groups roles none].freeze
  CARD_SIZES     = %w[compact default expanded].freeze

  store_attribute :options, :secondary_info,    :string,  default: "role"
  store_attribute :options, :show_status_badge, :boolean, default: true
  store_attribute :options, :show_email,        :boolean, default: false
  store_attribute :options, :tag_source,        :string,  default: "groups"
  store_attribute :options, :tag_limit,         :integer, default: 3
  store_attribute :options, :card_size,         :string,  default: "default"
  store_attribute :options, :columns_per_row,   :integer, default: 3

  validates :secondary_info, inclusion: { in: SECONDARY_INFO }
  validates :tag_source,     inclusion: { in: TAG_SOURCES }
  validates :card_size,      inclusion: { in: CARD_SIZES }
  validates :tag_limit,       numericality: { only_integer: true, in: 0..10 }
  validates :columns_per_row, numericality: { only_integer: true, in: 1..4 }

  validate :query_must_be_user_query

  def results
    effective_query&.results
  end

  def build_default_query
    UserQuery.new(project:, principal:)
  end

  private

  def query_must_be_user_query
    resolved = effective_query
    return if resolved.nil? || resolved.is_a?(UserQuery)

    errors.add(:query, :invalid)
  end
end
