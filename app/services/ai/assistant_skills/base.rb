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

        def rules
          []
        end

        def build_context(work_package:, user:)
          raise SubclassResponsibilityError
        end

        # The work package attributes this skill type can propose changes to, as Automations
        # action keys. An admin can make a skill read-only.
        def changeable_attributes
          []
        end

        # The class that builds the AI judgement for a run, or nil for rules only.
        def judgement_class
          nil
        end

        def available?(_work_package, _user)
          true
        end
      end
    end
  end
end
