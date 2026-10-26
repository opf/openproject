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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraCreateProjectJob::CustomFieldNames do
  describe ".candidates" do
    subject(:candidates) { described_class.candidates("Resolution") }

    it "finds a custom field with a matching name regardless of case" do
      upcased = create(:string_wp_custom_field, name: "RESOLUTION")

      expect(candidates).to eq([upcased])
    end

    it "finds fields with a matching name and a suffix in parentheses" do
      create(:string_wp_custom_field, name: "Resolution Date")
      create(:string_wp_custom_field, name: "Old Resolution")
      create(:string_wp_custom_field, name: "Resolution 2")
      numbered = create(:string_wp_custom_field, name: "Resolution (2)")
      project_keys = create(:string_wp_custom_field, name: "Resolution (XYZ)")

      expect(candidates).to contain_exactly(numbered, project_keys)
    end

    it "orders the results by id" do
      first = create(:string_wp_custom_field, name: "Resolution (2)")
      second = create(:string_wp_custom_field, name: "Resolution")

      expect(candidates).to eq([first, second])
    end

    it "ignores wildcards in the name" do
      create(:string_wp_custom_field, name: "50 percent (2)")
      create(:string_wp_custom_field, name: "50_ (2)")
      percent = create(:string_wp_custom_field, name: "50% (2)")

      expect(described_class.candidates("50%")).to eq([percent])
    end
  end

  describe ".same_field?" do
    it "matches the same name regardless of case" do
      expect(described_class).to be_same_field("Story Points", "STORY POINTS")
    end

    it "matches a stored name carrying the counter unique_name appends" do
      expect(described_class).to be_same_field("Story Points (2)", "Story Points")
      expect(described_class).to be_same_field("Story Points (12)", "Story Points")
    end

    it "strips the counter from the stored name only" do
      expect(described_class).not_to be_same_field("Story Points", "Story Points (2)")
    end

    it "matches a Jira field whose own name ends in a number against its renamed field" do
      expect(described_class).to be_same_field("Story Points (2) (2)", "Story Points (2)")
    end

    it "keeps a project key suffix apart from the counter" do
      expect(described_class).not_to be_same_field("Story Points (XYZ)", "Story Points")
    end

    it "matches a project key suffix with itself despite a counter" do
      expect(described_class).to be_same_field("Story Points (XYZ) (2)", "Story Points (XYZ)")
    end

    it "does not match a different name" do
      expect(described_class).not_to be_same_field("Story Points Estimate", "Story Points")
      expect(described_class).not_to be_same_field("Story Points 2", "Story Points")
    end
  end

  describe ".unique_name" do
    subject(:unique_name) { described_class.unique_name("Resolution") }

    context "with no field with the same name" do
      it { is_expected.to eq("Resolution") }
    end

    context "with an existing field with the same name" do
      before { create(:string_wp_custom_field, name: "Resolution") }

      it { is_expected.to eq("Resolution (2)") }
    end

    context "with an existing field with the same name in a different case" do
      before { create(:string_wp_custom_field, name: "RESOLUTION") }

      it { is_expected.to eq("Resolution (2)") }
    end

    context "with multiple existing fields with matching names" do
      before do
        create(:string_wp_custom_field, name: "Resolution")
        create(:string_wp_custom_field, name: "Resolution (2)")
      end

      it { is_expected.to eq("Resolution (3)") }
    end
  end
end
