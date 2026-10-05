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

class ScreenSection < ApplicationRecord
  self.table_name = "screen_sections"

  belongs_to :screen, inverse_of: :sections
  has_many :items, class_name: "ScreenItem", foreign_key: :section_id,
                   inverse_of: :section, dependent: :delete_all, autosave: true

  validates :name, presence: true, length: { maximum: 255 }
  validates :name, uniqueness: { scope: :screen_id, case_sensitive: false }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than: 100_000 }

  after_save { ::Screens::Resolver.reset_cache }
  after_destroy { ::Screens::Resolver.reset_cache }
end
