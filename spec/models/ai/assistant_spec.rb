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

RSpec.describe AI::Assistant do
  subject(:assistant) { build(:ai_assistant) }

  it "requires a unique name" do
    create(:ai_assistant, name: "QA assistance")
    assistant.name = "QA assistance"

    expect(assistant).not_to be_valid
    expect(assistant.errors.symbols_for(:name)).to include(:taken)
  end

  it "destroys its skills" do
    skill = create(:ai_assistant_skill, assistant: create(:ai_assistant))

    skill.assistant.destroy

    expect(AI::AssistantSkill.exists?(skill.id)).to be(false)
  end

  it "allows several variants of one skill type on an assistant" do
    skill = create(:ai_assistant_skill)
    variant = build(:ai_assistant_skill, assistant: skill.assistant, skill_key: skill.skill_key,
                                             label: "Check scope")

    expect(variant).to be_valid
  end

  describe "owners" do
    let(:owner) { create(:user) }
    let!(:global_assistant) { create(:ai_assistant, position: 2) }
    let!(:personal_assistant) { create(:ai_assistant, user: owner, position: 1) }

    it "orders global assistants before personal ones" do
      expect(described_class.ordered).to eq([global_assistant, personal_assistant])
    end

    it "shows a personal assistant only to its owner" do
      expect(described_class.visible_to(owner)).to contain_exactly(global_assistant, personal_assistant)
      expect(described_class.visible_to(create(:user))).to contain_exactly(global_assistant)
    end

    it "requires a unique name for each owner" do
      expect(build(:ai_assistant, name: global_assistant.name, user: owner)).to be_valid
      expect(build(:ai_assistant, name: personal_assistant.name, user: owner)).not_to be_valid
      expect(build(:ai_assistant, name: personal_assistant.name)).to be_valid
    end

    it "never changes its owner" do
      expect { personal_assistant.update(user: create(:user)) }.to raise_error(ActiveRecord::ReadonlyAttributeError)
    end

    it "is deleted with its owner" do
      owner.destroy

      expect(described_class.exists?(personal_assistant.id)).to be(false)
      expect(described_class.exists?(global_assistant.id)).to be(true)
    end

    it "is usable only while its owner may manage their own assistants" do
      expect(global_assistant).to be_usable
      expect(personal_assistant).not_to be_usable

      allowed = create(:user, global_permissions: %i[manage_own_ai_assistants])
      expect(create(:ai_assistant, user: allowed)).to be_usable
    end
  end
end
