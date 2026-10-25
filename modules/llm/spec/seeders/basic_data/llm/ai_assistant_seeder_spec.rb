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

require "spec_helper" require_module_spec_helper

RSpec.describe BasicData::Llm::AiAssistantSeeder do
  include_context "with basic seed data"

  subject(:seeder) { described_class.new(seed_data) }

  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new(data_hash)) }
  let(:data_hash) do
    YAML.load <<~SEEDING_DATA_YAML
      ai_assistants:
      - reference: :ai_assistant_op
        name: OP assistant
        description: Keeps work packages consistent.
        position: 1
        skills:
          - skill_key: conversation
            label: Refresh work package
            icon: sync
            prompt: Check it.
          - skill_key: conversation
            answers_at_once: false
            proposal_scope: comment_only
    SEEDING_DATA_YAML
  end

  before do
    seeder.seed!
  end

  it "creates the assistant with its skills" do
    assistant = AI::Assistant.find_by!(name: "OP assistant")

    expect(assistant).to have_attributes(active: true, position: 1)
    refresh, chat = assistant.skills.order(:position).to_a

    expect(refresh).to have_attributes(variant: "preset", prompt: "Check it.", label: "Refresh work package", icon: "sync")
    expect(chat).to have_attributes(variant: "chat", proposal_scope: "comment_only")
  end

  it "does not seed a second time" do
    described_class.new(basic_seed_data.merge(Source::SeedData.new(data_hash))).seed!

    expect(AI::Assistant.count).to eq(1)
  end

  context "when only personal assistants exist" do
    let(:owner) { create(:user) }

    before do
      AI::Assistant.destroy_all
      create(:ai_assistant, name: "OP assistant", principal: owner)
    end

    it "seeds the global assistant" do
      described_class.new(basic_seed_data.merge(Source::SeedData.new(data_hash))).seed!

      expect(AI::Assistant.global.find_by!(name: "OP assistant").skills.count).to eq(2)
      expect(AI::Assistant.personal.count).to eq(1)
    end
  end
end
