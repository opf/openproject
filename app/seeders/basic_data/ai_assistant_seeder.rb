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

module BasicData
  class AiAssistantSeeder < ModelSeeder
    self.model_class = AI::Assistant
    self.seed_data_model_key = "ai_assistants"
    self.attribute_names_for_lookups = %i[name principal_id]

    # Personal assistants do not count: the seed is about the global ones.
    def applicable?
      AI::Assistant.global.none? && seed_data.all_references_exist?(all_required_references)
    end

    def create_model!(model_data)
      super.tap do |assistant|
        Array(model_data["skills"]).each_with_index do |skill_data, index|
          assistant.skills.create!(**skill_attributes(skill_data), position: index + 1)
        end
      end
    end

    def skill_attributes(skill_data)
      skill_data
        .slice("skill_key", "label", "description", "prompt", "proposal_scope")
        .compact
        .symbolize_keys
    end

    def model_attributes(assistant_data)
      {
        name: assistant_data["name"],
        principal_id: nil,
        description: assistant_data["description"],
        instructions: assistant_data["instructions"],
        icon: assistant_data["icon"],
        position: assistant_data["position"]
      }
    end
  end
end
