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

# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Field rule patches fail open" do # rubocop:disable RSpec/DescribeClass
  let(:json) { '{"description":{"required":false,"writable":true},"_attributeGroups":[{"attributes":["description"]}]}' }
  let(:project) { build_stubbed(:project) }
  let(:type) { build_stubbed(:type) }
  let(:represented) { double("represented schema work package", project:, type:) } # rubocop:disable RSpec/VerifiedDoubles

  def rule(key, **flags) = FieldRule.new(field_key: key, **flags)

  def configuration(*rules) = FieldRules::EffectiveConfiguration.from_rules(rules)

  def representer_class(&core)
    Class.new do
      attr_reader :represented

      define_method(:initialize) { |represented| @represented = represented }
      define_method(:to_json, &core)
      prepend OpenProject::FieldRules::SchemaPatch
    end
  end

  describe OpenProject::FieldRules::SchemaPatch do
    let(:representer) do
      native = json
      representer_class { |*| native }.new(represented)
    end

    before { allow(User).to receive(:current).and_return(build_stubbed(:user)) }

    it "returns the very same string without parsing when no rule applies" do
      allow(FieldRules::Resolver).to receive(:for).and_return(FieldRules::EffectiveConfiguration.empty)

      expect(representer.to_json).to equal(json)
    end

    it "returns the native schema when adjusting it fails" do
      allow(FieldRules::Resolver).to receive(:for).and_return(configuration(rule("description", required: true)))
      allow(FieldRules::Fields).to receive(:schema_key).and_raise(StandardError, "boom")

      expect(representer.to_json).to equal(json)
    end

    it "returns the native schema when the core produced something that is not JSON" do
      representer = representer_class { |*| "<<not json>>" }.new(represented)
      allow(FieldRules::Resolver).to receive(:for).and_return(configuration(rule("description", required: true)))

      expect(representer.to_json).to eq "<<not json>>"
    end

    it "survives unexpected property and attribute group shapes" do
      odd = '{"description":"scalar","priority":{"required":false},"_attributeGroups":[{"attributes":null},"x"]}'
      representer = representer_class { |*| odd }.new(represented)
      allow(FieldRules::Resolver).to receive(:for)
        .and_return(configuration(rule("description", required: true), rule("priority", hidden: true)))

      result = JSON.parse(representer.to_json)

      expect(result["description"]).to eq "scalar"
      expect(result).not_to have_key("priority")
    end

    it "does not touch the schema for the system user" do
      allow(User).to receive(:current).and_return(User.system)
      allow(FieldRules::Resolver).to receive(:for).and_return(configuration(rule("description", required: true)))

      expect(representer.to_json).to equal(json)
    end

    it "does not swallow an error raised by the core serialisation" do
      failing = representer_class { |*| raise ArgumentError, "core failure" }.new(represented)

      expect { failing.to_json }.to raise_error(ArgumentError, "core failure")
    end
  end

  describe OpenProject::FieldRules::Constraints do
    let(:variant) { double("variant", type_id: 42) } # rubocop:disable RSpec/VerifiedDoubles

    it "keeps an existing constraint of another module in charge" do
      existing = ->(_variant, project: nil) { project.nil? }
      allow(FieldRules::Resolver).to receive(:for)

      expect(described_class.wrap("priority", existing).call(variant, project:)).to be false
      expect(FieldRules::Resolver).not_to have_received(:for)
    end

    it "hides a field only when a rule hides it for that project and type" do
      allow(FieldRules::Resolver).to receive(:for).with(project, 42)
                                                  .and_return(configuration(rule("priority", hidden: true)))
      constraint = described_class.wrap("priority", nil)

      expect(constraint.call(variant, project:)).to be false
      expect(described_class.wrap("category", nil).call(variant, project:)).to be true
    end

    it "does not consult rules without a project context" do
      allow(FieldRules::Resolver).to receive(:for)

      expect(described_class.wrap("priority", nil).call(variant, project: nil)).to be true
      expect(FieldRules::Resolver).not_to have_received(:for)
    end

    it "shows the field when resolving fails" do
      allow(FieldRules::Resolver).to receive(:for).and_raise(StandardError, "boom")

      expect(described_class.wrap("priority", nil).call(variant, project:)).to be true
    end

    describe ".install" do
      around do |example|
        original = TypeVariant.attribute_constraints.dup
        example.run
      ensure
        TypeVariant.attribute_constraints.replace(original)
      end

      it "wraps instead of replacing a constraint registered earlier, also when installed twice" do
        calls = 0
        TypeVariant.add_constraint(:estimated_time, ->(_variant, project: nil) { (calls += 1) && false })
        allow(FieldRules::Resolver).to receive(:for).and_return(FieldRules::EffectiveConfiguration.empty)

        2.times { described_class.install }

        expect(TypeVariant.attribute_constraints[:estimated_time].call(variant, project:)).to be false
        expect(calls).to eq 1
      end

      it "is replaced when another module registers the same attribute afterwards (documents the single-callable limit)" do
        described_class.install
        TypeVariant.add_constraint(:category, ->(_variant, project: nil) { true })
        allow(FieldRules::Resolver).to receive(:for)
          .and_return(configuration(rule("category", hidden: true)))

        expect(TypeVariant.attribute_constraints[:category].call(variant, project:)).to be true
      end
    end
  end

  describe OpenProject::FieldRules do
    it "refuses to boot when a patched core method disappears" do
      stub_const("OpenProject::FieldRules::PATCH_TARGETS",
                 { "WorkPackages::BaseContract" => %i[writable_attributes renamed_by_core] }.freeze)

      expect { described_class.assert_patch_targets! }
        .to raise_error(/renamed_by_core/)
    end

    it "accepts private core methods" do
      stub_const("OpenProject::FieldRules::PATCH_TARGETS",
                 { "WorkPackages::BaseContract" => %i[validate_enabled_type] }.freeze)

      expect { described_class.assert_patch_targets! }.not_to raise_error
    end

    it "prepends every patch exactly once, also after code reloading in development" do
      {
        WorkPackages::BaseContract => OpenProject::FieldRules::ContractPatch,
        WorkPackages::SetAttributesService => OpenProject::FieldRules::SetAttributesServicePatch,
        API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter => OpenProject::FieldRules::SchemaPatch
      }.each do |klass, patch|
        expect(klass.ancestors.count(patch)).to eq 1
        expect(klass.ancestors.index(patch)).to be < klass.ancestors.index(klass)
      end
    end

    it "lists every core method a patch overrides in the boot guard" do
      pending "KNOWN GAP (safety review #12): SchemaPatch#json_key_dependencies overrides core but is not guarded"
      {
        "WorkPackages::BaseContract" => OpenProject::FieldRules::ContractPatch,
        "WorkPackages::SetAttributesService" => OpenProject::FieldRules::SetAttributesServicePatch,
        "API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter" => OpenProject::FieldRules::SchemaPatch
      }.each do |class_name, patch|
        below = class_name.constantize.ancestors.drop_while { |ancestor| ancestor != patch }.drop(1)
        overrides = (patch.instance_methods(false) + patch.private_instance_methods(false)).select do |name|
          below.any? { |ancestor| ancestor.method_defined?(name, false) || ancestor.private_method_defined?(name, false) }
        end

        expect(OpenProject::FieldRules::PATCH_TARGETS.fetch(class_name)).to include(*overrides)
      end
    end

    it "keeps every patched method chained down to the core implementation" do
      {
        WorkPackages::BaseContract => %i[writable_attributes validate_enabled_type],
        WorkPackages::SetAttributesService => %i[set_calculated_attributes]
      }.each do |klass, methods|
        methods.each do |name|
          method = klass.instance_method(name)
          method = method.super_method while method && method.owner != klass
          expect(method).to be_present, "#{klass}##{name} no longer reaches the core implementation"
        end
      end
    end
  end

  describe "an aborted database transaction" do
    let(:project) { create(:project) }
    let(:type) { create(:type) }

    it "is hidden by the resolver but resurfaces at the next query, so nothing is written half-way" do
      ActiveRecord::Base.transaction(requires_new: true) do
        begin
          ActiveRecord::Base.connection.execute("SELECT 1/0")
        rescue ActiveRecord::StatementInvalid
          nil
        end

        expect(FieldRules::Resolver.for(project.id, type.id)).to be_empty
        expect { User.count }.to raise_error(ActiveRecord::StatementInvalid, /transaction is aborted/)
        raise ActiveRecord::Rollback
      end
    end
  end

  describe "the request cache" do
    let(:project) { create(:project, types: [type]) }
    let(:type) { create(:type) }

    before do
      rule_set = create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true }])
      ProjectFieldRuleScheme.create!(project:, scheme: create(:field_rule_scheme, mapping: { type => rule_set }))
      FieldRules::Resolver.reset_cache
    end

    it "does not see edits made behind the models' back until the request store is cleared (jobs, console)" do
      expect(FieldRules::Resolver.for(project.id, type.id).required?("description")).to be true

      FieldRule.update_all(required: false)
      expect(FieldRules::Resolver.for(project.id, type.id).required?("description")).to be true

      RequestStore.clear!
      expect(FieldRules::Resolver.for(project.id, type.id).required?("description")).to be false
    end
  end
end
