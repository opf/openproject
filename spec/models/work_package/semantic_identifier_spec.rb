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

RSpec.describe WorkPackage::SemanticIdentifier do
  let(:project) { create(:project, identifier: "MYPROJ") }
  # Creating a WP in alphanumeric mode auto-registers it: gets sequence_number 1 and entry "MYPROJ-1".
  let(:work_package) { create(:work_package, project:) }

  before do
    # "MYPROJ" is only valid as a project identifier in semantic mode, and the WP
    # after_create callback only assigns an identifier when semantic mode is active.
    # Stub both during setup, then restore so each context's with_settings: controls
    # the mode under test without the stub overriding it.
    allow(Setting::WorkPackageIdentifier).to receive_messages(semantic?: true, classic?: false)
    work_package
    allow(Setting::WorkPackageIdentifier).to receive(:semantic?).and_call_original
    allow(Setting::WorkPackageIdentifier).to receive(:classic?).and_call_original
  end

  describe ".semantically_sequenced" do
    it "includes work packages with a sequence number" do
      expect(WorkPackage.semantically_sequenced).to include(work_package)
    end

    it "excludes work packages without a sequence number" do
      wp = create(:work_package, project:)
      wp.update_columns(sequence_number: nil)
      expect(WorkPackage.semantically_sequenced).not_to include(wp)
    end
  end

  describe ".non_semantic_of" do
    it "excludes work packages whose identifier matches the expected semantic format" do
      expect(WorkPackage.non_semantic_of(project)).not_to include(work_package)
    end

    it "includes work packages with a stale identifier" do
      work_package.update_columns(identifier: "OLDPROJ-1")
      expect(WorkPackage.non_semantic_of(project)).to include(work_package)
    end

    it "excludes work packages without a sequence number" do
      wp = create(:work_package, project:)
      wp.update_columns(sequence_number: nil, identifier: nil)
      expect(WorkPackage.non_semantic_of(project)).not_to include(wp)
    end
  end

  describe ".for_slug_prefix" do
    it "matches work packages whose identifier is of the form <slug>-<digits>" do
      expect(WorkPackage.for_slug_prefix("MYPROJ")).to include(work_package)
    end

    it "does not over-match when another slug starts with the given slug plus a dash" do
      work_package.update_columns(identifier: "my-project-42")
      expect(WorkPackage.for_slug_prefix("my")).not_to include(work_package)
    end

    it "matches case-sensitively" do
      expect(WorkPackage.for_slug_prefix("myproj")).not_to include(work_package)
    end
  end

  describe ".resolving_via_slug_prefix" do
    # The auto-registered work_package carries the prefix both in its
    # identifier column and as an alias row.
    it "returns work packages matched via column and alias exactly once" do
      expect(WorkPackage.resolving_via_slug_prefix("MYPROJ")).to contain_exactly(work_package)
    end

    it "includes work packages matched only via an alias row" do
      work_package.update_columns(identifier: nil, sequence_number: nil)
      expect(WorkPackage.resolving_via_slug_prefix("MYPROJ")).to contain_exactly(work_package)
    end

    it "includes work packages matched only via the identifier column" do
      work_package.semantic_aliases.delete_all
      expect(WorkPackage.resolving_via_slug_prefix("MYPROJ")).to contain_exactly(work_package)
    end
  end

  describe "after_create registration", with_settings: { work_packages_identifier: "semantic" } do
    it "assigns a sequence number" do
      expect(work_package.reload.sequence_number).to eq(1)
    end

    it "sets identifier on the work package" do
      expect(work_package.reload.identifier).to eq("MYPROJ-1")
    end

    it "creates a registry entry for the initial identifier" do
      expect(work_package.semantic_aliases.pluck(:identifier)).to contain_exactly("MYPROJ-1")
    end

    it "increments the counter for each successive WP" do
      wp2 = create(:work_package, project:)
      expect(wp2.reload.sequence_number).to eq(2)
      expect(wp2.reload.identifier).to eq("MYPROJ-2")
    end
  end

  describe "WorkPackage.find" do
    context "with a numeric id" do
      it "finds by primary key" do
        expect(WorkPackage.find(work_package.id)).to eq(work_package)
      end

      it "raises RecordNotFound for unknown numeric id" do
        expect { WorkPackage.find(9_999_999) }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a numeric string" do
      it "falls through to standard AR find" do
        expect(WorkPackage.find(work_package.id.to_s)).to eq(work_package)
      end

      it "strips whitespace before dispatching" do
        expect(WorkPackage.find(" #{work_package.id} ")).to eq(work_package)
      end
    end

    context "with a semantic identifier string" do
      it "resolves via the semantic identifier" do
        expect(WorkPackage.find("MYPROJ-1")).to eq(work_package)
      end

      it "raises RecordNotFound for unknown semantic id" do
        expect { WorkPackage.find("MYPROJ-999") }.to raise_error(ActiveRecord::RecordNotFound)
      end

      it "resolves via historic alias" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package:)
        expect(WorkPackage.find("OLDPROJ-1")).to eq(work_package)
      end
    end

    context "with multiple ids" do
      let(:work_package2) { create(:work_package, project:) }

      it "delegates to standard AR find for an array of numeric ids" do
        expect(WorkPackage.find([work_package.id, work_package2.id])).to contain_exactly(work_package, work_package2)
      end

      it "delegates to standard AR find for multiple numeric id arguments" do
        expect(WorkPackage.find(work_package.id, work_package2.id)).to contain_exactly(work_package, work_package2)
      end

      it "raises UnsupportedLookup for a single-element array with a semantic id" do
        expect { WorkPackage.find(["MYPROJ-1"]) }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup, /primary keys for multi-argument/)
      end

      it "raises UnsupportedLookup for multiple semantic ids" do
        expect { WorkPackage.find("MYPROJ-1", "MYPROJ-2") }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup, /primary keys for multi-argument/)
      end

      it "raises UnsupportedLookup for mixed numeric and semantic ids" do
        expect { WorkPackage.find([work_package.id, "MYPROJ-2"]) }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup, /primary keys for multi-argument/)
      end

      it "is rescuable as ArgumentError for backwards compatibility" do
        expect { WorkPackage.find("MYPROJ-1", "MYPROJ-2") }.to raise_error(ArgumentError)
      end
    end

    context "with visibility scoping" do
      let(:member_user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
      let(:non_member_user) { create(:user) }

      it "respects the scope for semantic ids" do
        expect(WorkPackage.visible(member_user).find("MYPROJ-1")).to eq(work_package)
      end

      it "raises RecordNotFound when the user cannot see it" do
        expect { WorkPackage.visible(non_member_user).find("MYPROJ-1") }
          .to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "WorkPackage.exists?" do
    context "with a numeric id" do
      it "returns true for existing record" do
        expect(WorkPackage.exists?(work_package.id)).to be true
      end

      it "returns false for non-existing record" do
        expect(WorkPackage.exists?(9_999_999)).to be false
      end
    end

    context "with a numeric string" do
      it "falls through to standard AR exists?" do
        expect(WorkPackage.exists?(work_package.id.to_s)).to be true
      end
    end

    context "with a semantic identifier string" do
      it "checks the identifier column" do
        expect(WorkPackage.exists?("MYPROJ-1")).to be true
      end

      it "returns false for unknown semantic id" do
        expect(WorkPackage.exists?("MYPROJ-999")).to be false
      end

      it "checks the alias table for historical identifiers" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package:)
        expect(WorkPackage.exists?("OLDPROJ-1")).to be true
      end
    end

    context "with hash conditions" do
      it "passes through to standard AR exists?" do
        expect(WorkPackage.exists?(subject: work_package.subject)).to be true
      end
    end

    context "with visibility scoping" do
      let(:member_user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
      let(:non_member_user) { create(:user) }

      it "respects the scope for semantic ids" do
        expect(WorkPackage.visible(member_user).exists?("MYPROJ-1")).to be true
      end

      it "returns false when the user cannot see it" do
        expect(WorkPackage.visible(non_member_user).exists?("MYPROJ-1")).to be false
      end

      it "respects the scope for historical aliases" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package:)
        expect(WorkPackage.visible(member_user).exists?("OLDPROJ-1")).to be true
        expect(WorkPackage.visible(non_member_user).exists?("OLDPROJ-1")).to be false
      end
    end
  end

  describe "WorkPackage.find_by" do
    context "with id: keyword and semantic identifier" do
      it "raises UnsupportedLookup (an ArgumentError subclass) pointing to find_by_display_id" do
        expect { WorkPackage.find_by(id: "MYPROJ-1") }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup, /find_by_display_id/)
      end

      it "is rescuable as ArgumentError for backwards compatibility" do
        expect { WorkPackage.find_by(id: "MYPROJ-1") }.to raise_error(ArgumentError)
      end
    end

    context "with identifier: keyword and semantic identifier" do
      it "raises ArgumentError pointing to find_by_display_id" do
        expect { WorkPackage.find_by(identifier: "MYPROJ-1") }
          .to raise_error(ArgumentError, /find_by_display_id/)
      end
    end

    context "with string-keyed hash (AR internal representation)" do
      it "raises ArgumentError for string 'id' key with semantic value" do
        expect { WorkPackage.find_by("id" => "MYPROJ-1") }
          .to raise_error(ArgumentError, /find_by_display_id/)
      end

      it "raises ArgumentError for string 'identifier' key with semantic value" do
        expect { WorkPackage.find_by("identifier" => "MYPROJ-1") }
          .to raise_error(ArgumentError, /find_by_display_id/)
      end
    end

    context "with id: keyword and numeric string" do
      it "falls through to standard AR find_by" do
        expect(WorkPackage.find_by(id: work_package.id.to_s)).to eq(work_package)
      end
    end

    context "with id: keyword and blank string" do
      it "does not treat an empty id as a semantic identifier" do
        expect { WorkPackage.find_by(id: "") }.not_to raise_error
        expect(WorkPackage.find_by(id: "")).to be_nil
      end

      it "does not treat whitespace-only id as semantic" do
        expect { WorkPackage.find_by(id: "  \t  ") }.not_to raise_error
        expect(WorkPackage.find_by(id: "  \t  ")).to be_nil
      end
    end

    context "with id: keyword and an array" do
      let(:work_package2) { create(:work_package, project:) }

      it "falls through to standard AR find_by for an all-numeric array" do
        expect(WorkPackage.find_by(id: [work_package.id, work_package2.id])).to eq(work_package)
      end

      it "raises UnsupportedLookup when the array contains a semantic identifier" do
        expect { WorkPackage.find_by(id: [work_package.id, "MYPROJ-2"]) }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup, /does not support semantic identifiers/)
      end
    end

    context "with non-id keywords" do
      it "passes through to standard AR find_by" do
        expect(WorkPackage.find_by(subject: work_package.subject)).to eq(work_package)
      end
    end

    context "with multiple keywords including id:" do
      it "passes through to standard AR find_by" do
        expect(WorkPackage.find_by(id: work_package.id, project:)).to eq(work_package)
      end

      it "raises UnsupportedLookup when id: is semantic even among other keywords" do
        expect { WorkPackage.find_by(subject: "anything", id: "MYPROJ-1") }
          .to raise_error(WorkPackage::SemanticIdentifier::UnsupportedLookup)
      end
    end

    context "with an unparseable semantic string" do
      it "raises ArgumentError" do
        expect { WorkPackage.find_by(id: "not-an-identifier!") }
          .to raise_error(ArgumentError, /find_by_display_id/)
      end
    end
  end

  # rubocop:disable Rails/FindById -- testing find_by! override specifically, not suggesting find()
  describe "WorkPackage.find_by!" do
    context "with id: keyword and semantic identifier" do
      it "raises ArgumentError pointing to find_by_display_id" do
        expect { WorkPackage.find_by!(id: "MYPROJ-1") }
          .to raise_error(ArgumentError, /find_by_display_id/)
      end
    end

    context "with non-id keywords" do
      it "passes through to standard AR find_by!" do
        expect(WorkPackage.find_by!(subject: work_package.subject)).to eq(work_package)
      end
    end
  end
  # rubocop:enable Rails/FindById

  describe "WorkPackage.find_by_display_id" do
    context "with a semantic identifier" do
      it "resolves via the semantic identifier" do
        expect(WorkPackage.find_by_display_id("MYPROJ-1")).to eq(work_package)
      end

      it "returns nil for unknown semantic id" do
        expect(WorkPackage.find_by_display_id("MYPROJ-999")).to be_nil
      end

      it "resolves via historic alias" do
        WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package:)
        expect(WorkPackage.find_by_display_id("OLDPROJ-1")).to eq(work_package)
      end

      it "resolves when identifier column differs but alias row exists" do
        work_package.update_columns(identifier: "OTHER-99")
        expect(WorkPackage.find_by_display_id("MYPROJ-1")).to eq(work_package)
      end
    end

    context "with a numeric string" do
      it "falls through to standard AR find_by" do
        expect(WorkPackage.find_by_display_id(work_package.id.to_s)).to eq(work_package)
      end

      it "returns nil for unknown numeric id" do
        expect(WorkPackage.find_by_display_id("9999999")).to be_nil
      end
    end

    context "with visibility scoping" do
      let(:member_user) { create(:user, member_with_permissions: { project => [:view_work_packages] }) }
      let(:non_member_user) { create(:user) }

      it "respects the scope for semantic ids" do
        expect(WorkPackage.visible(member_user).find_by_display_id("MYPROJ-1")).to eq(work_package)
      end

      it "returns nil when the user cannot see it" do
        expect(WorkPackage.visible(non_member_user).find_by_display_id("MYPROJ-1")).to be_nil
      end

      it "also scopes numeric lookup" do
        expect(WorkPackage.visible(non_member_user).find_by_display_id(work_package.id.to_s)).to be_nil
      end
    end
  end

  describe "WorkPackage.where_display_id_in", with_settings: { work_packages_identifier: "semantic" } do
    let(:work_package2) { create(:work_package, project:) }
    let(:work_package3) { create(:work_package, project:) }
    let(:other_project) { create(:project, identifier: "OTHER") }
    let(:other_wp) { create(:work_package, project: other_project) }

    before do
      work_package2
      work_package3
      other_wp
    end

    it "returns a chainable ActiveRecord relation" do
      expect(WorkPackage.where_display_id_in(["MYPROJ-1"])).to be_a(ActiveRecord::Relation)
    end

    it "returns an empty relation for an empty input" do
      expect(WorkPackage.where_display_id_in([])).to be_empty
    end

    it "treats a blank string as no input" do
      relation = WorkPackage.where_display_id_in("")
      expect(relation).to be_empty
      # Without filtering, "".to_i would build WHERE id = 0 — semantically wrong
      # even though no row matches in practice.
      expect(relation.to_sql).not_to match(/"id"\s*=\s*0\b/)
      expect(relation.to_sql).not_to match(/"id"\s+IN\s*\(0\)/)
    end

    it "treats whitespace-only strings as no input" do
      expect(WorkPackage.where_display_id_in("   ")).to be_empty
    end

    it "drops blank entries from arrays without poisoning the rest of the set" do
      expect(WorkPackage.where_display_id_in(["MYPROJ-1", "", "  ", nil]))
        .to contain_exactly(work_package)
    end

    it "wraps a single non-array value" do
      expect(WorkPackage.where_display_id_in("MYPROJ-1")).to contain_exactly(work_package)
    end

    it "accepts identifiers as varargs" do
      expect(WorkPackage.where_display_id_in("MYPROJ-1", "MYPROJ-2"))
        .to contain_exactly(work_package, work_package2)
    end

    it "resolves a single numeric string" do
      expect(WorkPackage.where_display_id_in([work_package.id.to_s])).to contain_exactly(work_package)
    end

    it "resolves multiple numeric strings" do
      expect(WorkPackage.where_display_id_in([work_package.id.to_s, work_package2.id.to_s]))
        .to contain_exactly(work_package, work_package2)
    end

    it "resolves a single semantic identifier via the identifier column" do
      expect(WorkPackage.where_display_id_in(["MYPROJ-1"])).to contain_exactly(work_package)
    end

    it "resolves multiple semantic identifiers via the identifier column" do
      expect(WorkPackage.where_display_id_in(["MYPROJ-1", "MYPROJ-2"]))
        .to contain_exactly(work_package, work_package2)
    end

    it "resolves a semantic identifier via the alias table for historical ids" do
      WorkPackageSemanticAlias.create!(identifier: "OLDPROJ-1", work_package:)
      expect(WorkPackage.where_display_id_in(["OLDPROJ-1"])).to contain_exactly(work_package)
    end

    it "resolves a mix of numeric and semantic identifiers in one query" do
      expect(WorkPackage.where_display_id_in([work_package.id.to_s, "MYPROJ-2", "OTHER-1"]))
        .to contain_exactly(work_package, work_package2, other_wp)
    end

    it "drops unknown values without poisoning the rest of the set" do
      expect(WorkPackage.where_display_id_in(["MYPROJ-1", "MYPROJ-999", "ZZZ-1"]))
        .to contain_exactly(work_package)
    end

    it "is composable with includes and order" do
      relation = WorkPackage.where_display_id_in(["MYPROJ-1", "MYPROJ-2"])
                            .includes(:project)
                            .order(id: :asc)
      expect(relation.to_a).to eq([work_package, work_package2])
    end

    it "respects upstream visibility scoping" do
      member_user = create(:user, member_with_permissions: { project => [:view_work_packages] })
      expect(WorkPackage.visible(member_user).where_display_id_in(["MYPROJ-1", "OTHER-1"]))
        .to contain_exactly(work_package)
    end
  end

  describe "WorkPackage.find_by_display_id!" do
    context "with a semantic identifier" do
      it "resolves via the semantic identifier" do
        expect(WorkPackage.find_by_display_id!("MYPROJ-1")).to eq(work_package)
      end

      it "raises RecordNotFound for unknown semantic id" do
        expect { WorkPackage.find_by_display_id!("MYPROJ-999") }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "with a numeric string" do
      it "falls through to standard AR find" do
        expect(WorkPackage.find_by_display_id!(work_package.id.to_s)).to eq(work_package)
      end
    end
  end

  describe "ID_ROUTE_CONSTRAINT" do
    # Rails wraps route-constraint regexps with `\A…\z` when matching a path
    # segment, so the spec uses an anchored regex to model the way the
    # constant is actually used. This pins the composition with
    # SEMANTIC_ID_PATTERN so a future change to the upstream prefix or
    # sequence shape can't silently widen what the routes accept.
    let(:anchored) { /\A(?:#{described_class::ID_ROUTE_CONSTRAINT.source})\z/ }

    it "matches numeric work package ids" do
      expect(anchored.match?("123")).to be true
    end

    it "matches semantic work package identifiers" do
      expect(anchored.match?("PROJ-7")).to be true
    end

    it "rejects lowercased semantic shapes" do
      expect(anchored.match?("proj-7")).to be false
    end
  end

  describe ".numeric_id? and .semantic_id?" do
    # `numeric_id?` answers a shape question (canonical numeric ID),
    # `semantic_id?` answers a routing question (needs identifier/alias
    # lookup). For Strings the two are mutually exclusive; Integers are
    # numeric-only (no string-lookup routing applies).
    [
      ["123",     :numeric],
      ["0",       :numeric],
      [" 123 ",   :numeric],
      [123,       :numeric],
      [0,         :numeric],
      ["0123",    :semantic],
      ["00",      :semantic],
      ["PROJ-1",  :semantic],
      ["abc",     :semantic],
      ["",        :neither],
      [nil,       :neither],
      [{},        :neither]
    ].each do |value, classification|
      it "routes #{value.inspect} to #{classification}" do
        case classification
        when :numeric
          expect(described_class.numeric_id?(value)).to be true
          expect(described_class.semantic_id?(value)).to be false
        when :semantic
          expect(described_class.semantic_id?(value)).to be true
          expect(described_class.numeric_id?(value)).to be false
        when :neither
          expect(described_class.numeric_id?(value)).to be false
          expect(described_class.semantic_id?(value)).to be false
        end
      end
    end
  end

  describe "#display_id" do
    context "when semantic mode is active",
            with_settings: { work_packages_identifier: "semantic" } do
      it "returns the semantic identifier" do
        expect(work_package.display_id).to eq("MYPROJ-1")
      end
    end

    context "when semantic mode is active but identifier is nil",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: nil) }

      it "falls back to the numeric id" do
        expect(work_package.display_id).to eq(work_package.id)
      end
    end

    context "when semantic mode is not active",
            with_settings: { work_packages_identifier: "classic" } do
      it "returns the numeric id" do
        expect(work_package.display_id).to eq(work_package.id)
      end
    end
  end

  describe "#formatted_id" do
    context "when semantic mode is active",
            with_settings: { work_packages_identifier: "semantic" } do
      it "returns the semantic identifier without hash prefix" do
        expect(work_package.formatted_id).to eq("MYPROJ-1")
      end
    end

    context "when semantic mode is active but identifier is nil",
            with_settings: { work_packages_identifier: "semantic" } do
      before { work_package.update_columns(identifier: nil) }

      it "falls back to hash-prefixed numeric id" do
        expect(work_package.formatted_id).to eq("##{work_package.id}")
      end
    end

    context "when semantic mode is not active",
            with_settings: { work_packages_identifier: "classic" } do
      it "returns hash-prefixed numeric id" do
        expect(work_package.formatted_id).to eq("##{work_package.id}")
      end
    end
  end

  describe ".format_display_id" do
    it "returns the semantic identifier unchanged when it carries letters" do
      expect(described_class.format_display_id("MYPROJ-1")).to eq("MYPROJ-1")
    end

    it "hash-prefixes a numeric integer" do
      expect(described_class.format_display_id(42)).to eq("#42")
    end

    it "hash-prefixes a numeric string" do
      expect(described_class.format_display_id("42")).to eq("#42")
    end
  end

  describe "#to_param" do
    include Rails.application.routes.url_helpers

    context "when semantic mode is active",
            with_settings: { work_packages_identifier: "semantic" } do
      it "returns the semantic identifier" do
        expect(work_package.to_param).to eq("MYPROJ-1")
      end

      it "falls back to the numeric id when identifier is missing" do
        work_package.update_columns(identifier: nil, sequence_number: nil)
        expect(work_package.to_param).to eq(work_package.id.to_s)
      end

      it "makes work_package_path produce a semantic URL" do
        expect(work_package_path(work_package)).to end_with("/work_packages/MYPROJ-1")
      end

      it "returns nil for new (unsaved) records" do
        expect(WorkPackage.new.to_param).to be_nil
      end
    end

    context "when classic mode is active",
            with_settings: { work_packages_identifier: "classic" } do
      it "returns the numeric id as a string" do
        expect(work_package.to_param).to eq(work_package.id.to_s)
      end

      it "makes work_package_path produce a numeric URL" do
        expect(work_package_path(work_package)).to end_with("/work_packages/#{work_package.id}")
      end

      it "returns nil for new (unsaved) records" do
        expect(WorkPackage.new.to_param).to be_nil
      end
    end
  end

  describe "semantic_identifier_fields_consistent validation" do
    subject(:wp) { build(:work_package, project:, sequence_number: nil, identifier: nil) }

    it "is valid when both are nil" do
      expect(wp).to be_valid
    end

    it "is valid when both are set" do
      wp.sequence_number = 1
      wp.identifier = "MYPROJ-1"
      expect(wp).to be_valid
    end

    it "is invalid when identifier is set but sequence_number is nil" do
      wp.identifier = "MYPROJ-1"
      expect(wp).not_to be_valid
      expect(wp.errors[:identifier]).to include(a_string_matching(/sequence_number/))
    end

    it "is invalid when sequence_number is set but identifier is nil" do
      wp.sequence_number = 1
      expect(wp).not_to be_valid
      expect(wp.errors[:identifier]).to include(a_string_matching(/sequence_number/))
    end

    context "when classic mode is active", with_settings: { work_packages_identifier: "classic" } do
      it "still enforces consistency" do
        wp.identifier = "MYPROJ-1"
        expect(wp).not_to be_valid
        expect(wp.errors[:identifier]).to include(a_string_matching(/sequence_number/))
      end
    end
  end

  describe "semantic_identifier_fields_not_accidentally_changed validation" do
    it "forbids changing the identifier in the default validation context" do
      work_package.identifier = "MYPROJ-99"
      work_package.sequence_number = 99

      expect(work_package).not_to be_valid
      expect(work_package.errors[:identifier]).to include(a_string_matching(/must not be changed manually/))
      expect(work_package.errors[:identifier]).to include(a_string_matching(/identifier_rewrite/))
    end

    it "forbids changing the sequence_number" do
      work_package.sequence_number = 99

      expect(work_package).not_to be_valid
      expect(work_package.errors[:sequence_number]).to include(a_string_matching(/must not be changed manually/))
    end

    it "forbids clearing the identifier fields" do
      work_package.identifier = nil
      work_package.sequence_number = nil

      expect(work_package).not_to be_valid
    end

    it "allows clearing the fields as part of a project move" do
      work_package.project = create(:project)
      work_package.identifier = nil
      work_package.sequence_number = nil

      work_package.validate
      expect(work_package.errors[:identifier]).to be_empty
      expect(work_package.errors[:sequence_number]).to be_empty
    end

    it "allows the change when saved with the rewrite context" do
      work_package.identifier = "MYPROJ-99"
      work_package.sequence_number = 99

      expect(work_package.save(context: WorkPackage::SemanticIdentifier::IDENTIFIER_REWRITE_CONTEXT)).to be(true)
      expect(work_package.reload.identifier).to eq("MYPROJ-99")
      expect(work_package.reload.sequence_number).to eq(99)
    end

    it "does not interfere with unrelated changes" do
      work_package.subject = "Updated subject"

      expect(work_package).to be_valid
    end

    it "does not apply to new records" do
      wp = build(:work_package, project:, identifier: "MYPROJ-5", sequence_number: 5)

      expect(wp).to be_valid
    end
  end

  describe "#allocate_and_register_semantic_id", with_settings: { work_packages_identifier: "semantic" } do
    let(:project) { create(:project, identifier: "PROJ", wp_sequence_counter: 0) }
    let(:target_project) { create(:project, identifier: "OTHER", wp_sequence_counter: 0) }

    before do
      work_package.update_columns(project_id: target_project.id)
    end

    it "preserves the old identifier as a historical alias (written at creation)" do
      work_package.allocate_and_register_semantic_id
      expect(WorkPackageSemanticAlias.find_by(identifier: "PROJ-1")).to be_present
    end

    it "updates sequence_number and identifier to the target project's values" do
      work_package.allocate_and_register_semantic_id
      expect(work_package.reload.sequence_number).to eq(1)
      expect(work_package.reload.identifier).to eq("OTHER-1")
    end

    it "adds the new identifier to the alias table" do
      work_package.allocate_and_register_semantic_id
      expect(WorkPackageSemanticAlias.find_by(identifier: "OTHER-1")).to be_present
    end
  end
end
