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

class ScreenSchemeItem < ApplicationRecord
  self.table_name = "screen_scheme_items"

  SLOT_TYPES = { create_screen: "create", edit_screen: "edit",
                 view_screen: "view", transition_screen: "transition" }.freeze

  belongs_to :scheme, class_name: "ScreenScheme", inverse_of: :items
  belongs_to :type
  belongs_to :create_screen, class_name: "Screen", optional: true
  belongs_to :edit_screen, class_name: "Screen", optional: true
  belongs_to :view_screen, class_name: "Screen", optional: true
  belongs_to :transition_screen, class_name: "Screen", optional: true

  validates :type_id, uniqueness: { scope: :scheme_id }
  validate :at_least_one_screen
  validate :slots_match_screen_types

  after_save { ::Screens::Resolver.reset_cache }
  after_destroy { ::Screens::Resolver.reset_cache }

  def screen_for(context)
    public_send(ScreenScheme::SLOTS.fetch(context.to_sym))
  end

  def screens
    SLOT_TYPES.keys.filter_map { |slot| public_send(slot) }
  end

  private

  def at_least_one_screen
    errors.add(:base, :at_least_one_screen) if screens.empty?
  end

  def slots_match_screen_types
    SLOT_TYPES.each do |slot, expected_type|
      screen = public_send(slot)
      next if screen.nil? || screen.screen_type == expected_type

      errors.add(slot, :context_mismatch)
    end
  end
end
