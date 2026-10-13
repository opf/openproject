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

RSpec.describe BasicData::AiAssistantSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      ai_assistants:
      - reference: :ai_assistant_qa
        name: QA assistance
        description: Checks work packages.
        icon: checklist
        position: 1
        skills:
          - skill_key: health_check
            prompt: Check it.
          - skill_key: prompt
            label: Generate test cases
            proposal_scope: comment_only
          - skill_key: chat
    SEEDING_DATA_YAML
  end

  before do
    seeder.seed!
  end

  it "creates the assistant with its skills" do
    assistant = AI::Assistant.find_by!(name: "QA assistance")

    expect(assistant).to have_attributes(icon: "checklist", active: true, position: 1)
    expect(assistant.skills.order(:position).map(&:skill_key)).to eq(%w[health_check prompt chat])
    expect(assistant.skills.find_by(skill_key: "health_check").prompt).to eq("Check it.")
    expect(assistant.skills.find_by(skill_key: "prompt"))
      .to have_attributes(label: "Generate test cases", proposal_scope: "comment_only")
  end

  it "does not seed a second time" do
    described_class.new(basic_seed_data.merge(Source::SeedData.new(data_hash))).seed!

    expect(AI::Assistant.count).to eq(1)
  end

  context "when only personal assistants exist" do
    let(:owner) { create(:user) }

    before do
      AI::Assistant.destroy_all
      create(:ai_assistant, name: "QA assistance", user: owner)
    end

    it "seeds the global assistant" do
      described_class.new(basic_seed_data.merge(Source::SeedData.new(data_hash))).seed!

      expect(AI::Assistant.global.find_by!(name: "QA assistance").skills.count).to eq(3)
      expect(AI::Assistant.personal.count).to eq(1)
    end
  end
end
