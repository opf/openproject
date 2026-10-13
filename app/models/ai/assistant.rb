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

module AI
  class Assistant < ApplicationRecord
    # A personal assistant belongs to its user; a global one has no user.
    belongs_to :user, optional: true

    has_many :skills,
             -> { order(:position, :id) },
             class_name: "AI::AssistantSkill",
             inverse_of: :assistant,
             dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :user_id }, length: { maximum: 255 }
    validates :icon, length: { maximum: 255 }

    attr_readonly :user_id

    scope :active, -> { where(active: true) }
    scope :global, -> { where(user_id: nil) }
    scope :personal, -> { where.not(user_id: nil) }
    scope :visible_to, ->(user) { where(user_id: [nil, user.id]) }
    # Global assistants first, then personal ones.
    scope :ordered, -> { order(Arel.sql("ai_assistants.user_id IS NOT NULL"), :position, :id) }

    def personal?
      user_id.present?
    end

    # A personal assistant is offered only while its owner may manage their own.
    def usable?
      !personal? || user.allowed_globally?(:manage_own_ai_assistants)
    end
  end
end
