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

require "rails_helper"

RSpec.describe ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator do
  describe ".call" do
    context "when given an empty array" do
      it "returns an empty array" do
        expect(described_class.call([])).to be_empty
      end
    end

    context "when a project has a too-long identifier" do
      shared_let(:project) { create(:project, identifier: "verylongidentifier", name: "Very Long Identifier") }

      it "returns one suggestion entry for the project" do
        result = described_class.call([project])
        expect(result.size).to eq(1)
        expect(result.first[:project]).to eq(project)
        expect(result.first[:current_identifier]).to eq("verylongidentifier")
        expect(result.first[:suggested_identifier]).to be_present
        expect(result.first[:suggested_identifier].length).to be <= described_class::IDENTIFIER_LENGTH[:max]
      end
    end

    context "when a project has a special-character identifier" do
      shared_let(:project) { create(:project, identifier: "f-s", name: "Fly Sky") }

      it "returns a suggestion entry with a suggested_identifier" do
        result = described_class.call([project])
        expect(result.size).to eq(1)
        expect(result.first[:suggested_identifier]).to eq("FS")
      end
    end

    context "when multiple projects generate conflicting identifiers" do
      shared_let(:project_sc1) { create(:project, identifier: "sc-app",         name: "Stream Communicator") }
      shared_let(:project_sc2) { create(:project, identifier: "stream-channel", name: "Stream Channel") }

      it "generates unique identifiers for each project" do
        identifiers = described_class.call([project_sc1, project_sc2]).pluck(:suggested_identifier)
        expect(identifiers.uniq.size).to eq(identifiers.size)
      end

      it "resolves conflicts by widening the acronym, not numeric suffixes" do
        identifiers = described_class.call([project_sc1, project_sc2]).pluck(:suggested_identifier)
        expect(identifiers).to include("SC")
        # Second project expands to "STC" (Stream → ST, Channel → C) instead of "SC2"
        expect(identifiers).to include("STC")
      end
    end
  end

  describe "identifier generation from project name" do
    {
      # Single-word names: first IDENTIFIER_LENGTH[:single_word] (3) transliterated chars
      "Banana" => "BAN",
      "Kiwi" => "KIW",
      "Strawberry" => "STR",
      "Cécile" => "CEC",
      # Multi-word names: initials (truncated to IDENTIFIER_LENGTH[:base] = 5)
      "Flight Planning Algorithm" => "FPA",
      "Fly & Sky" => "FS",
      "Social media marketing" => "SMM",
      "Arcanos (mobile-web-app)" => "AMWA",
      "Flight Planning Training" => "FPT",
      "A B C D E F G H I J K" => "ABCDE",
      "Cécile Martin" => "CM",
      "étude de cas" => "EDC",
      # Non-Latin scripts: every initial → "?" → fallback
      "日本語プロジェクト" => "PROJ",
      # Mixed: only "Plan" survives transliteration → single-word → starts at 3 chars
      "Plan 日本" => "PLA"
    }.each do |project_name, expected_identifier|
      it "generates '#{expected_identifier}' from '#{project_name}'" do
        project = create(:project, identifier: "bad-id", name: project_name)
        expect(described_class.call([project]).first[:suggested_identifier]).to eq(expected_identifier)
      end
    end
  end

  describe "must start with a letter" do
    it "strips leading digits from generated identifiers" do
      project = create(:project, identifier: "bad-id", name: "3D Printing Lab")
      result = described_class.call([project]).first[:suggested_identifier]
      expect(result).to match(/\A[A-Z]/)
    end

    it "falls back to PROJ for all-digit names" do
      project = create(:project, identifier: "bad-id", name: "123 456")
      result = described_class.call([project]).first[:suggested_identifier]
      expect(result).to eq("PROJ")
    end
  end

  describe "minimum identifier length" do
    it "never generates identifiers shorter than MIN_IDENTIFIER_LENGTH" do
      # Single letter word — too short on its own
      project = create(:project, identifier: "bad-id", name: "A")
      result = described_class.call([project]).first[:suggested_identifier]
      expect(result.length).to be >= described_class::IDENTIFIER_LENGTH[:min]
    end
  end

  describe "collision resolution by widening" do
    it "uses the base identifier when not yet taken" do
      project = create(:project, identifier: "sc-app", name: "Stream Communicator")
      expect(described_class.call([project]).first[:suggested_identifier]).to eq("SC")
    end

    it "widens the acronym instead of appending numeric suffixes" do
      p1 = create(:project, identifier: "sc-a", name: "Stream Communicator")
      p2 = create(:project, identifier: "sc-b", name: "Stream Channel")
      p3 = create(:project, identifier: "sc-c", name: "Something Cool")
      identifiers = described_class.call([p1, p2, p3]).pluck(:suggested_identifier)
      expect(identifiers).to contain_exactly("SC", "STC", "SOC")
    end

    it "expands single-word identifiers on collision" do
      p1 = create(:project, identifier: "bad-a", name: "Banana")
      p2 = create(:project, identifier: "bad-b", name: "Banking")
      identifiers = described_class.call([p1, p2]).pluck(:suggested_identifier)
      # Both start as "BAN"; second expands to "BANK"
      expect(identifiers).to contain_exactly("BAN", "BANK")
    end

    it "keeps all identifiers within MAX_IDENTIFIER_LENGTH" do
      p1 = create(:project, identifier: "a-b-c-d-e-f-g-h-i-j", name: "A B C D E F G H I J")
      p2 = create(:project, identifier: "a-b-c-d-e-f-g-h-i-j-x", name: "A B C D E F G H I J")
      identifiers = described_class.call([p1, p2]).pluck(:suggested_identifier)
      expect(identifiers.all? { it.length <= described_class::IDENTIFIER_LENGTH[:max] }).to be true
      expect(identifiers.uniq.size).to eq(2)
    end

    it "does not suggest an identifier that is already in use (pre-seeded collision)" do
      project = create(:project, identifier: "sc-app", name: "Stream Communicator")
      result = described_class.call([project], exclude: Set["SC"])
      # "SC" is taken, so it widens to "STC" (Stream → ST, Communicator → C)
      expect(result.first[:suggested_identifier]).to eq("STC")
    end

    it "falls back to numeric suffix only when all expansion candidates are exhausted" do
      # Reserve all expansion candidates for "Go" (a 2-char word)
      project = create(:project, identifier: "bad-id", name: "Go")
      result = described_class.call([project], exclude: Set["GO"])
      # "GO" is taken, no further expansion possible, so numeric suffix
      expect(result.first[:suggested_identifier]).to eq("GO2")
    end

    it "assigns identifiers in array order — first project claims the base" do
      p1 = create(:project, identifier: "bad-a", name: "Stream Communicator")
      p2 = create(:project, identifier: "bad-b", name: "Stream Channel")
      result = described_class.call([p1, p2])

      # p1 is first in the array, so it claims "SC"; p2 gets the widened "STC"
      expect(result[0][:suggested_identifier]).to eq("SC")
      expect(result[1][:suggested_identifier]).to eq("STC")

      # Reversed order: p2 now claims "SC"
      reversed = described_class.call([p2, p1])
      expect(reversed[0][:suggested_identifier]).to eq("SC")
      expect(reversed[1][:suggested_identifier]).to eq("STC")
    end
  end

  describe ".suggest_identifier" do
    it "produces the same identifier as .call for the same name" do
      project = build_stubbed(:project, name: "Alpha Beta", identifier: "alpha-beta")
      batch_result = described_class.call([project]).first[:suggested_identifier]
      single_result = described_class.suggest_identifier("Alpha Beta")
      expect(single_result).to eq(batch_result)
    end
  end

  describe ".call result shape" do
    it "does not include error_reason (that is PreviewQuery's concern)" do
      project = create(:project, identifier: "ab-c", name: "Test")
      expect(described_class.call([project]).first).not_to have_key(:error_reason)
    end
  end
end
