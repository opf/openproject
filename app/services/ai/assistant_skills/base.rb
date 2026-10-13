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
  module AssistantSkills
    class Base
      class << self
        def key
          raise SubclassResponsibilityError
        end

        def icon
          raise SubclassResponsibilityError
        end

        def label
          I18n.t("ai_assistance.skills.#{key}.label")
        end

        def description
          I18n.t("ai_assistance.skills.#{key}.description")
        end

        # The work package attributes this skill type can propose changes to, as Automations
        # action keys. The skill's proposal scope can narrow them (AI::AssistantSkill).
        def changeable_attributes
          AI::Assistance::ChangeOptions::ATTRIBUTE_KEYS
        end

        # A chat: the user writes the questions.
        def chat?
          false
        end

        # Answered in a conversation (AI::AssistantChat) instead of a run with findings.
        # A run skill type also defines rules, build_context and review_class.
        def conversation?
          false
        end

        # Preset: one click, fixed instructions. Chat: questions in free form.
        def kind
          chat? ? "chat" : "preset"
        end

        def kind_label
          I18n.t("admin.ai_assistants.skills.types.#{kind}")
        end

        # Whether the skill is offered only when an admin set its instructions.
        def prompt_required?
          false
        end
      end
    end
  end
end
