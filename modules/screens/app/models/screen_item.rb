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
# frozen_string_literal: true

class ScreenItem < ApplicationRecord
  self.table_name = "screen_items"

  FIELD_KEY_FORMAT = /\A[a-z_][a-z0-9_]{0,63}\z/
  WIDTHS = %w[full half].freeze

  belongs_to :screen, inverse_of: :items
  belongs_to :section, class_name: "ScreenSection", inverse_of: :items

  validates :field_key, presence: true, length: { maximum: 64 }, format: { with: FIELD_KEY_FORMAT }
  validates :field_key, uniqueness: { scope: :screen_id }
  validates :width, inclusion: { in: WIDTHS }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 100_000 }

  after_save { ::Screens::Resolver.reset_cache }
  after_destroy { ::Screens::Resolver.reset_cache }
end
