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

module DevelopmentData
  # Custom actions (automations with a button) that the work packages of the AI Assistance
  # demo offer. Runs after the demo data, which creates the statuses and priorities.
  class CustomActionsSeeder < Seeder
    def seed_data!
      print_status "   -Creating the custom actions" do
        User.execute_as(admin_user) do
          custom_actions.each { |custom_action| create_custom_action(custom_action) }
        end
      end
    end

    def applicable?
      custom_actions.any? && Automation.where(name: custom_actions.pluck("name")).none?
    end

    private

    def create_custom_action(custom_action)
      name = custom_action["name"]
      attributes = {
        name:,
        actions: custom_action["actions"].transform_values { |value| [action_value(value)] },
        triggers_attributes: [{ type: Automations::Triggers::Button.name, button_label: name }]
      }

      Automations::CreateService.new(user: admin_user)
                                .call(attributes: attributes.with_indifferent_access)
                                .on_failure { |result| raise "#{name}: #{result.errors.full_messages.to_sentence}" }
    end

    def action_value(value)
      seed_data.find_reference(value, default: nil)&.id&.to_s || value
    end

    def custom_actions
      Array(seed_data.lookup("development_custom_actions"))
    end
  end
end
