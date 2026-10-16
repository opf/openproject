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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  module Assistance
    # The label field of the skill form, with the icon menu left of the input. Choosing an
    # icon shows it on the button (ai-assistance--icon-picker).
    class SkillLabelFieldComponent < ApplicationComponent
      attr_reader :builder, :skill

      def initialize(builder:, skill:)
        super
        @builder = builder
        @skill = skill
      end

      def label = AI::AssistantSkill.human_attribute_name(:label)

      def icon_label = AI::AssistantSkill.human_attribute_name(:icon)

      def errors = skill.errors.full_messages_for(:label)

      # "default" clears the choice: Primer sends an item's label when its value is empty.
      def icon_items
        [["default", skill.default_icon, I18n.t("admin.ai_assistants.skills.icon_default")]] +
          AI::AssistantSkill::ICONS.map { |icon| [icon, icon, icon.tr("-", " ").capitalize] }
      end

      def selected?(value) = (skill.chosen_icon || "default") == value
    end
  end
end
