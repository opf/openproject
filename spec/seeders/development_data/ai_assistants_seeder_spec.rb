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

require "spec_helper"

RSpec.describe DevelopmentData::AiAssistantsSeeder do
  subject(:seeder) { described_class.new(seed_data) }

  let(:group) { create(:group, lastname: "COMMS") }
  let(:admin) { create(:admin) }
  let(:seed_data) do
    Source::SeedData.new(data_hash).tap do |data|
      data.store_reference(:team__comms, group)
      data.store_reference(:openproject_admin, admin)
    end
  end
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      development_ai_assistants:
      - reference: :ai_assistant_pm
        name: PM assistant
        position: 2
        skills:
          - skill_key: prompt
            label: Find risks
            prompt: List them.
      - reference: :ai_assistant_comms
        principal: :team__comms
        name: COMMS assistant
        icon: megaphone
        position: 1
        skills:
          - skill_key: prompt
            label: Write a test plan
            prompt: Draft it.
          - skill_key: chat
      - reference: :ai_assistant_tom
        principal: :openproject_admin
        name: Tom's assistant
        position: 1
        skills:
          - skill_key: chat
    SEEDING_DATA_YAML
  end

  it "creates a global, a group and a personal assistant with their skills" do
    seeder.seed!

    expect(AI::Assistant.global.sole).to have_attributes(name: "PM assistant", position: 2)
    expect(AI::Assistant.for_groups.sole).to have_attributes(name: "COMMS assistant", principal: group)
    expect(AI::Assistant.personal.sole).to have_attributes(name: "Tom's assistant", principal: admin)
    expect(AI::Assistant.for_groups.sole.skills.map(&:skill_key)).to eq(%w[prompt chat])
  end

  it "does not seed a second time" do
    create(:ai_assistant, name: "COMMS assistant", principal: group)

    expect(seeder).not_to be_applicable
  end

  it "does not seed without the group" do
    seeder = described_class.new(Source::SeedData.new(data_hash).tap { it.store_reference(:openproject_admin, admin) })

    expect(seeder).not_to be_applicable
  end
end
