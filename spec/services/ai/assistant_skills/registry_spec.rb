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

RSpec.describe AI::AssistantSkills::Registry do
  it "lists the health check, the custom prompt and the chat" do
    expect(described_class.keys).to eq(%w[health_check prompt chat])
  end

  it "fetches a skill by key" do
    expect(described_class.fetch(:health_check)).to eq(AI::AssistantSkills::HealthCheck::Skill)
  end

  it "returns nil for an unknown key" do
    expect(described_class.fetch("unknown")).to be_nil
  end

  it "has a label and an icon for each skill" do
    described_class.skills.each do |skill|
      expect(skill.label).not_to include("translation missing")
      expect(skill.icon).to be_present
    end
  end
end
