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
    module Conversation
      # The one skill type in core. A skill's settings decide how it starts and what its
      # answers hold (AI::AssistantSkill); the instructions decide what it is for.
      class Skill < AI::AssistantSkills::Base
        class << self
          def key
            "conversation"
          end

          def build_context(work_package:, user:)
            HealthCheck::Context.new(work_package:, user:)
          end

          def review_class
            HealthCheck::Review
          end

          # The built-in consistency checks, for skills that answer with findings.
          def rules
            [
              HealthCheck::Rules::ClosedWithOpenDescendants,
              HealthCheck::Rules::OpenWithAllDescendantsClosed,
              HealthCheck::Rules::ClosedDescendantWithOpenBelow,
              HealthCheck::Rules::StaleOpenDescendants,
              HealthCheck::Rules::ClosedWithOpenPrerequisites,
              HealthCheck::Rules::OpenDuplicateOfClosed,
              HealthCheck::Rules::StaleWorkPackage,
              HealthCheck::Rules::MergedPullRequestDefaultStatus,
              HealthCheck::Rules::ClosedWithOpenPullRequest
            ]
          end
        end
      end
    end
  end
end
