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
end
