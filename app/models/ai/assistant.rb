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
    # The owner: none for a global assistant, a user for a personal one, a group for the
    # assistants of its members. Other principal types can be added later.
    OWNER_TYPES = %w[User Group].freeze

    belongs_to :principal, optional: true

    has_many :skills,
             -> { order(:position, :id) },
             class_name: "AI::AssistantSkill",
             inverse_of: :assistant,
             dependent: :destroy

    validates :name, presence: true, uniqueness: { scope: :principal_id }, length: { maximum: 255 }
    validates :icon, length: { maximum: 255 }
    validates :instructions, length: { maximum: 20_000 }
    validate :owner_type_supported

    attr_readonly :principal_id

    scope :active, -> { where(active: true) }
    scope :global, -> { where(principal_id: nil) }
    scope :for_groups, -> { where(principal_id: Group.select(:id)) }
    scope :personal, -> { where.not(principal_id: nil).where.not(principal_id: Group.select(:id)) }
    # Global assistants, the user's own, and those of the user's groups.
    scope :visible_to, ->(user) { where(principal_id: [nil, user.id, *user.group_ids]) }
    # Global assistants first, then owned ones.
    scope :ordered, -> { order(Arel.sql("ai_assistants.principal_id IS NOT NULL"), :position, :id) }

    def owned?
      principal_id.present?
    end

    def personal?
      principal.is_a?(User)
    end

    def group?
      principal.is_a?(Group)
    end

    # The assistant's own model when the connection still offers it, otherwise the
    # connection's default chat model.
    def effective_model_id
      connection = LlmConnection.active_connection
      return model_id if model_id.present? && connection.available_model_ids.include?(model_id)

      connection.default_chat_model&.external_id
    end

    # A personal assistant is offered only while its owner may manage their own. Global
    # and group assistants are an admin's.
    def usable?
      !personal? || principal.allowed_globally?(:manage_own_ai_assistants)
    end

    private

    def owner_type_supported
      errors.add(:principal, :inclusion) if principal && OWNER_TYPES.exclude?(principal.type)
    end
  end
end
