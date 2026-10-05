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

class Screen < ApplicationRecord
  self.table_name = "screens"

  TYPES = %w[create edit view transition].freeze
  MAX_SECTIONS = 20
  MAX_ITEMS = 100

  has_many :sections, -> { order(:position, :id) },
           class_name: "ScreenSection",
           inverse_of: :screen,
           dependent: :delete_all,
           autosave: true
  has_many :items, class_name: "ScreenItem", inverse_of: :screen, dependent: :delete_all

  validates :name, presence: true, uniqueness: true, length: { maximum: 255 }
  validates :description, length: { maximum: 5000 }
  validates :screen_type, presence: true, inclusion: { in: TYPES }

  attr_readonly :screen_type

  before_destroy :prevent_destroy
  after_save { ::Screens::Resolver.reset_cache }
  after_destroy { ::Screens::Resolver.reset_cache }

  scope :active, -> { where(active: true) }

  TYPES.each do |type|
    define_method(:"#{type}?") { screen_type == type }
  end

  def in_use?
    ScreenSchemeItem
      .where(create_screen_id: id).or(ScreenSchemeItem.where(edit_screen_id: id))
      .or(ScreenSchemeItem.where(view_screen_id: id))
      .or(ScreenSchemeItem.where(transition_screen_id: id))
      .exists?
  end

  def subject_visible?
    items.any? { |item| item.field_key == "subject" && item.visible }
  end

  private

  def prevent_destroy
    errors.add(:base, :cannot_be_deleted)
    throw :abort
  end
end
