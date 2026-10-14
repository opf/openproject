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

RSpec.describe OpenProject::Avatars::InitialsSvg do
  describe ".initials_for" do
    it "uses the first letters of first and last name" do
      expect(described_class.initials_for("John Doe")).to eq "JD"
    end

    it "uses a single initial when there is no last name" do
      expect(described_class.initials_for("Madonna")).to eq "M"
    end

    it "keeps emoji first names as complete code points" do
      expect(described_class.initials_for("🤖 Oliver")).to eq "🤖O"
    end

    it "returns an empty string for a blank name" do
      expect(described_class.initials_for("")).to eq ""
    end
  end

  describe ".color_for" do
    it "uses the user's custom avatar color when set" do
      user = build_stubbed(:user, id: 42, firstname: "Jane", lastname: "Doe")
      user.pref.avatar_color = "#AABBCC"

      expect(described_class.color_for(user)).to eq "#AABBCC"
    end

    it "is deterministic for the same id and name" do
      user = build_stubbed(:user, id: 42, firstname: "Jane", lastname: "Doe")

      first_call = described_class.color_for(user)
      second_call = described_class.color_for(user)

      expect(first_call).to eq second_call
    end

    it "differs for users with the same name but different ids" do
      first = build_stubbed(:user, id: 1, firstname: "Jane", lastname: "Doe")
      second = build_stubbed(:user, id: 2, firstname: "Jane", lastname: "Doe")

      expect(described_class.color_for(first)).not_to eq described_class.color_for(second)
    end

    it "renders as an hsl() color" do
      user = build_stubbed(:user, id: 1, firstname: "Jane", lastname: "Doe")

      expect(described_class.color_for(user)).to match(/\Ahsl\(\d+, 50%, 30%\)\z/)
    end
  end

  describe ".render" do
    it "renders an SVG document containing the color and initials" do
      user = build_stubbed(:user, id: 1, firstname: "Jane", lastname: "Doe")

      svg = described_class.render(user)

      expect(svg).to include("<svg")
      expect(svg).to include(described_class.color_for(user))
      expect(svg).to include(">JD<")
    end

    it "escapes the initials to avoid breaking the markup" do
      user = build_stubbed(:user, id: 1, firstname: "<script>", lastname: "Doe")

      svg = described_class.render(user)

      expect(svg).not_to include("<script>")
    end
  end
end
