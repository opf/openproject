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

RSpec.describe Projects::IdentifierValidator do
  subject(:project) { build(:project, identifier:) }

  def validate!
    project.valid?
    project.errors[:identifier]
  end

  # Mode-agnostic behaviours — validator runs the same checks before mode dispatch
  # (blank short-circuit, reserved keyword) and after it (historical reservation).
  # Each mode context below includes these shared examples to confirm both branches
  # exercise them.
  shared_examples "skips validation when blank" do
    let(:identifier) { "" }

    it "adds no validator-specific errors" do
      project.valid?
      expect(project.errors[:identifier]).not_to include(I18n.t("activerecord.errors.messages.invalid"))
    end
  end

  shared_examples "rejects reserved keywords" do
    %w[new menu queries filters identifier_update_dialog identifier_suggestion].each do |reserved|
      it "rejects '#{reserved}' (exact match)" do
        project.identifier = reserved
        expect(validate!).to include(I18n.t("activerecord.errors.messages.exclusion"))
      end

      it "rejects '#{reserved.upcase}' (case-insensitive)" do
        project.identifier = reserved.upcase
        expect(validate!).to include(I18n.t("activerecord.errors.messages.exclusion"))
      end
    end
  end

  shared_examples "enforces historical reservation" do
    it "rejects an identifier previously used by another project" do
      other = create(:project, identifier: previous_identifier)
      other.update!(identifier: replacement_identifier)

      project.identifier = previous_identifier
      validate!
      expect(project.errors[:identifier]).to include(I18n.t("activerecord.errors.messages.taken"))
    end

    it "matches historical slugs case-insensitively" do
      other = create(:project, identifier: previous_identifier)
      other.update!(identifier: replacement_identifier)

      project.identifier = previous_identifier.swapcase
      project.valid?
      expect(project.errors[:identifier]).to include(I18n.t("activerecord.errors.messages.taken"))
    end

    it "allows a project to revert to its own former identifier" do
      reverting = create(:project, identifier: previous_identifier)
      reverting.update!(identifier: replacement_identifier)

      reverting.identifier = previous_identifier
      expect(reverting).to be_valid
    end

    it "does not double-add :taken when uniqueness already flagged the same value" do
      create(:project, identifier: previous_identifier)

      project.identifier = previous_identifier
      project.valid?
      expect(project.errors.where(:identifier, :taken).count).to eq(1)
    end
  end

  context "in classic mode", with_settings: { work_packages_identifier: "classic" } do
    let(:identifier) { "valid-id" }
    let(:previous_identifier)    { "former-id" }
    let(:replacement_identifier) { "renamed-id" }

    include_examples "skips validation when blank"
    include_examples "rejects reserved keywords"
    include_examples "enforces historical reservation"

    describe "format" do
      it "accepts a slug-style identifier" do
        expect(validate!).to be_empty
      end

      it "rejects uppercase characters" do
        project.identifier = "INVALID"
        expect(validate!).to include(I18n.t("activerecord.errors.messages.invalid"))
      end

      it "rejects an all-numeric identifier" do
        project.identifier = "12345"
        expect(validate!).to include(I18n.t("activerecord.errors.messages.invalid"))
      end

      it "rejects identifiers with whitespace or special chars" do
        project.identifier = "bad name!"
        expect(validate!).to include(I18n.t("activerecord.errors.messages.invalid"))
      end

      it "rejects identifiers exceeding 100 characters" do
        project.identifier = "a" * 101
        validate!
        expect(project.errors[:identifier]).to include(I18n.t("activerecord.errors.messages.too_long",
                                                              count: 100))
      end
    end
  end

  context "in semantic mode", with_settings: { work_packages_identifier: "semantic" } do
    let(:identifier) { "PROJ" }
    let(:previous_identifier)    { "FORMER" }
    let(:replacement_identifier) { "RENAMED" }

    include_examples "skips validation when blank"
    include_examples "rejects reserved keywords"
    include_examples "enforces historical reservation"

    describe "format" do
      it "accepts an uppercase letter-led identifier" do
        expect(validate!).to be_empty
      end

      it "rejects identifiers not starting with a letter" do
        project.identifier = "1PROJ"
        validate!
        expect(project.errors.where(:identifier, :must_start_with_letter)).to be_present
      end

      it "rejects lowercase letters" do
        project.identifier = "Proj"
        validate!
        expect(project.errors.where(:identifier, :no_special_characters)).to be_present
      end

      it "rejects identifiers exceeding 10 characters" do
        project.identifier = "ABCDEFGHIJK"
        validate!
        expect(project.errors[:identifier]).to include(I18n.t("activerecord.errors.messages.too_long",
                                                              count: 10))
      end

      it "accepts uppercase + digits + underscore" do
        project.identifier = "P_ROJ_1"
        expect(validate!).to be_empty
      end
    end
  end

  # Tests the override-from-classic behaviour wired through the concern's
  # `validation_context` getter. Stays its own block (not a mode context)
  # because the point is precisely that the global mode is classic.
  describe ":semantic_conversion validation context",
           with_settings: { work_packages_identifier: "classic" } do
    let!(:project) { create(:project, identifier: "classic-id") }

    it "rejects a semantic identifier under the default classic-mode validation" do
      project.identifier = "PROJ"
      expect(project).not_to be_valid
      expect(project.errors[:identifier]).to be_present
    end

    it "accepts a semantic identifier when validated with :semantic_conversion context" do
      project.identifier = "PROJ"
      expect(project.valid?(:semantic_conversion)).to be(true)
    end

    it "still rejects an invalid semantic identifier under :semantic_conversion context" do
      project.identifier = "bad-format"
      expect(project.valid?(:semantic_conversion)).to be(false)
      expect(project.errors[:identifier]).to be_present
    end

    it "persists the semantic identifier when saved with :semantic_conversion context" do
      project.identifier = "PROJ"
      project.save!(context: :semantic_conversion)
      expect(project.reload.identifier).to eq("PROJ")
    end

    it "rejects a semantic identifier reserved by another project's slug history" do
      other = create(:project, identifier: "other-id")
      FriendlyId::Slug.create!(sluggable: other, slug: "PROJ")

      project.identifier = "PROJ"
      expect(project.valid?(:semantic_conversion)).to be(false)
      expect(project.errors[:identifier]).to include(I18n.t("activerecord.errors.messages.taken"))
    end
  end
end
