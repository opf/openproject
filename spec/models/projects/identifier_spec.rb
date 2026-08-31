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

RSpec.describe Projects::Identifier do
  describe "validations" do
    subject { create(:project) }

    it { is_expected.to validate_uniqueness_of(:identifier).case_insensitive }

    context "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
      it { is_expected.to validate_length_of(:identifier).is_at_most(100) }
    end

    context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
      subject { build(:project, identifier: "PROJ") }

      it { is_expected.to validate_length_of(:identifier).is_at_most(10) }
    end
  end

  describe "database indexes" do
    subject { Project.new }

    it { is_expected.to have_db_index("lower((identifier)::text)").unique(true) }
  end

  describe "identifier normalization" do
    subject { Project.new }

    it_behaves_like "strips invisible characters", :identifier
  end

  describe "url identifier", with_settings: { work_packages_identifier: "classic" } do
    let(:reserved) do
      Rails.application.routes.routes
        .map { |route| route.path.spec.to_s }
        .filter_map { |path| path[%r{^/projects/(\w+)\(\.:format\)$}, 1] }
        .uniq
    end

    it "is set from name" do
      project = Project.new(name: "foo")

      project.validate

      expect(project.identifier).to eq("foo")
    end

    it "generates a valid identifier for an all-numeric name" do
      project = Project.new(name: "12345")

      project.validate

      expect(project.identifier).to match(Projects::Identifier::CLASSIC_FORMAT)
    end

    it "is not allowed to clash with projects routing" do
      expect(reserved).not_to be_empty

      reserved.each do |word|
        project = Project.new(name: word)

        project.validate

        expect(project.identifier).not_to eq(word)
      end
    end

    it "is not allowed to clash with another project" do
      create(:project, identifier: "existing")

      project = build(:project, identifier: "existing")
      expect(project).not_to be_valid
      expect(project.errors[:identifier]).to include("has already been taken.")
    end

    it "is not allowed to clash with another project case-insensitively" do
      create(:project, identifier: "existing")

      expect do
        Project.where(id: create(:project).id).update_all(identifier: "EXISTING")
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    # The identifier-generation callback fires on :create and is not automatically called when
    # validating with a custom context. The validation_context override ensures it still runs
    # when the validations are called with the :saving_custom_fields context.
    context "when validating with :saving_custom_fields context" do
      it "is set from name" do
        project = Project.new(name: "foo")

        project.validate(:saving_custom_fields)

        expect(project.identifier).to eq("foo")
      end

      it "is not allowed to clash with projects routing" do
        expect(reserved).not_to be_empty

        reserved.each do |word|
          project = Project.new(name: word)

          project.validate(:saving_custom_fields)

          expect(project.identifier).not_to eq(word)
        end
      end
    end

    context "with history" do
      let!(:project) { create(:project, identifier: "sc") }

      it "records the old identifier in friendly_id_slugs when identifier changes" do
        project.update!(identifier: "scp")
        expect(FriendlyId::Slug.where(sluggable: project).pluck(:slug)).to include("sc")
      end

      it "can still find the project via its old identifier" do
        project.update!(identifier: "scp")
        expect(Project.friendly.find("sc")).to eq(project)
      end

      it "returns the project with its current identifier when found via old identifier" do
        project.update!(identifier: "scp")
        found = Project.friendly.find("sc")
        expect(found.identifier).to eq("scp")
      end

      it "locks old identifier to the original project (not reusable by others)" do
        project.update!(identifier: "scp")
        slug = FriendlyId::Slug.find_by(slug: "sc")
        expect(slug.sluggable_id).to eq(project.id)
      end

      it "allows the project to revert to a previously used identifier" do
        project.update!(identifier: "scp")
        expect { project.update!(identifier: "sc") }.not_to raise_error
        expect(project.identifier).to eq("sc")
      end

      it "is valid when reverting to own historical identifier" do
        project.update!(identifier: "scp")
        project.identifier = "sc"
        expect(project).to be_valid
      end
    end
  end

  describe ".suggest_identifier" do
    context "with semantic identifiers", with_settings: { work_packages_identifier: "semantic" } do
      it "delegates to ProjectIdentifierSuggestionGenerator with an exclusion set" do
        allow(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
          .to receive(:suggest_identifier).and_return("MP")
        expect(Project.suggest_identifier("My Project")).to eq("MP")
        expect(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
          .to have_received(:suggest_identifier).with("My Project", exclude: a_kind_of(Set))
      end
    end

    context "with classic identifiers", with_settings: { work_packages_identifier: "classic" } do
      it "returns a slugified lowercase identifier" do
        expect(Project.suggest_identifier("My Cool Project")).to eq("my-cool-project")
      end

      it "returns a unique project-NNNNN fallback when the name produces no slug" do
        result = Project.suggest_identifier("!!!")
        expect(result).to match(/\Aproject-[a-z0-9]{5}\z/)
      end
    end

    context "with explicit mode: parameter" do
      context "when mode: semantic overrides a classic setting",
              with_settings: { work_packages_identifier: "classic" } do
        it "uses the semantic generator" do
          allow(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
            .to receive(:suggest_identifier).and_return("MP")

          Project.suggest_identifier("My Project", mode: Setting::WorkPackageIdentifier::SEMANTIC)

          expect(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
            .to have_received(:suggest_identifier).with("My Project", exclude: a_kind_of(Set))
        end
      end

      context "when mode: classic overrides a semantic setting",
              with_settings: { work_packages_identifier: "semantic" } do
        it "uses the classic generator" do
          generator = instance_double(ProjectIdentifiers::ClassicIdentifierSuggestionGenerator)
          allow(ProjectIdentifiers::ClassicIdentifierSuggestionGenerator).to receive(:new).and_return(generator)
          allow(generator).to receive(:suggest_identifier).and_return("my-project")

          result = Project.suggest_identifier("My Project", mode: Setting::WorkPackageIdentifier::CLASSIC)

          expect(result).to eq("my-project")
        end
      end
    end
  end

  describe "#suggest_identifier" do
    subject(:project) { build(:project, name: "My Project") }

    context "with no mode argument", with_settings: { work_packages_identifier: "classic" } do
      it "delegates to the class method using the current setting" do
        expect(project.suggest_identifier).to eq(Project.suggest_identifier("My Project"))
      end
    end

    context "with explicit mode: semantic", with_settings: { work_packages_identifier: "classic" } do
      it "passes the mode through to the class method" do
        allow(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
          .to receive(:suggest_identifier).and_return("MP")

        project.suggest_identifier(mode: Setting::WorkPackageIdentifier::SEMANTIC)

        expect(ProjectIdentifiers::IdentifierAutofix::ProjectIdentifierSuggestionGenerator)
          .to have_received(:suggest_identifier).with("My Project", exclude: a_kind_of(Set))
      end
    end

    context "with explicit mode: classic", with_settings: { work_packages_identifier: "semantic" } do
      it "passes the mode through to the class method" do
        result = project.suggest_identifier(mode: Setting::WorkPackageIdentifier::CLASSIC)

        expect(result).to eq("my-project")
      end
    end
  end

  describe ".identifier_slugs scopes" do
    let!(:active_project) { create(:project, identifier: "active-id") }
    let!(:renamed_project) { create(:project, identifier: "current-id") }

    before do
      # Slug history mirrors active identifiers for both projects (FriendlyId :history records the
      # current slug on save). Add an extra historical slug for renamed_project to exercise the
      # `historically_reserved` filter — it doesn't match any active project's identifier.
      FriendlyId::Slug.create!(sluggable: renamed_project, slug: "old-slug")
    end

    describe "#historically_reserved" do
      it "returns slugs whose lowercase value isn't any active project's identifier" do
        slugs = Project.identifier_slugs.historically_reserved.pluck(:slug)
        expect(slugs).to contain_exactly("old-slug")
      end
    end

    describe "#for_identifier" do
      it "returns slugs whose lowercase equals the lowercased input" do
        match = Project.identifier_slugs.for_identifier("OLD-SLUG")
        expect(match.pluck(:slug)).to contain_exactly("old-slug")
      end

      it "matches case-insensitively when stored slug differs in case" do
        FriendlyId::Slug.create!(sluggable: renamed_project, slug: "MixedCase")
        match = Project.identifier_slugs.for_identifier("mixedcase")
        expect(match.pluck(:slug)).to contain_exactly("MixedCase")
      end
    end

    describe "#upcased_values" do
      it "returns uppercased slugs as a plain array" do
        values = Project.identifier_slugs.upcased_values
        expect(values).to contain_exactly("ACTIVE-ID", "CURRENT-ID", "OLD-SLUG")
      end
    end

    describe "#downcased_values" do
      it "returns downcased slugs as a plain array" do
        FriendlyId::Slug.create!(sluggable: renamed_project, slug: "MixedCase")
        values = Project.identifier_slugs.downcased_values
        expect(values).to include("active-id", "current-id", "old-slug", "mixedcase")
      end
    end

    describe "#raw_values" do
      it "returns slug values verbatim (no case folding)" do
        FriendlyId::Slug.create!(sluggable: renamed_project, slug: "MixedCase")
        values = Project.identifier_slugs.raw_values
        expect(values).to contain_exactly("active-id", "current-id", "old-slug", "MixedCase")
      end
    end

    describe "#excluding_project" do
      it "drops the given project's slug history from the relation" do
        values = Project.identifier_slugs.excluding_project(renamed_project).raw_values
        expect(values).to contain_exactly("active-id")
      end

      it "is a no-op when project is nil" do
        values = Project.identifier_slugs.excluding_project(nil).raw_values
        expect(values).to contain_exactly("active-id", "current-id", "old-slug")
      end
    end

    it "composes scopes (historically_reserved + upcased_values)" do
      values = Project.identifier_slugs.historically_reserved.upcased_values
      expect(values).to contain_exactly("OLD-SLUG")
    end
  end
end
