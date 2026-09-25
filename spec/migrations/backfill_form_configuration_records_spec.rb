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
require Rails.root.join("db/migrate/20260925100100_backfill_form_configuration_records")

RSpec.describe BackfillFormConfigurationRecords, type: :model do
  def variant_with(groups)
    create(:type).default_variant.tap { |variant| variant.update_column(:attribute_groups, groups) }
  end

  def migrate!(direction = :up)
    ActiveRecord::Migration.suppress_messages { described_class.migrate(direction) }
  end

  def check_deferred_constraints!
    ActiveRecord::Base.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
  end

  def update_raw_attribute_groups(variant, yaml)
    connection = ActiveRecord::Base.connection
    connection.execute("UPDATE type_variants SET attribute_groups = #{connection.quote(yaml)} WHERE id = #{variant.id}")
  end

  def tuples(variant)
    variant.form_groups.reload.map do |group|
      key = group.default_key ? group.default_key.to_sym : group.label
      members = group.query? ? [:"query_#{group.query_id}"] : group.members.map(&:key)
      [key, members]
    end
  end

  before { RequestStore.clear! }

  it "materializes defaults for an implicit configuration" do
    variant = variant_with(nil)

    migrate!
    check_deferred_constraints!

    expect(tuples(variant)).to eq variant.default_attribute_groups
    expect(variant.form_attributes.inactive).not_to be_empty
  end

  it "converts customized groups, keeping order, members and labels" do
    variant = variant_with(
      [["Bug details", %w[assignee date]], [:people, %w[responsible]], [:details, %w[priority], "Extras"]]
    )

    migrate!
    check_deferred_constraints!

    expect(tuples(variant))
      .to eq [["Bug details", %w[assignee date]], [:people, %w[responsible]], [:details, %w[priority]]]
    expect(variant.form_groups.find_by(default_key: "details").label).to eq "Extras"
    expect(variant.form_groups.find_by(default_key: "details").translated_label).to eq "Extras"
    expect(variant.form_groups.find_by(label: "Bug details").default_key).to be_nil
  end

  it "keeps unicode and punctuation labels and case-sensitive siblings" do
    variant = variant_with([["Ünïcödé / a.b", %w[assignee]], ["details", %w[date]], ["Details", %w[priority]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:label)).to eq ["Ünïcödé / a.b", "details", "Details"]
  end

  it "converts the empty sentinel into no groups with everything inactive" do
    variant = variant_with([[:__empty, []]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups).to be_empty
    expect(variant.form_attributes.active).to be_empty
    expect(variant.form_attributes.inactive.count).to eq variant.work_package_attributes.keys.size
  end

  it "names blank-keyed groups like the contract does" do
    variant = variant_with([["", %w[assignee]], [nil, %w[date]], ["Untitled group", %w[priority]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:label)).to eq ["Untitled group 2", "Untitled group 3", "Untitled group"]
  end

  it "stores custom fields by foreign key" do
    custom_field = create(:wp_custom_field)
    variant = variant_with([["Fields", ["custom_field_#{custom_field.id}"]]])

    migrate!
    check_deferred_constraints!

    member = variant.form_groups.first.members.first
    expect(member.custom_field).to eq custom_field
    expect(member.attribute_key).to be_nil
  end

  it "converts query groups referencing the existing query" do
    query = create(:query)
    variant = variant_with([["Related", [:"query_#{query.id}"]]])

    migrate!
    check_deferred_constraints!

    group = variant.form_groups.first
    expect(group).to be_query
    expect(group.query).to eq query
    expect(group.label).to eq "Related"
    expect(group.default_key).to be_nil
    expect(group.members).to be_empty
    expect(Query.where(id: query.id)).to exist
  end

  it "keeps the default identity of a symbolic query group and its label override" do
    children = create(:query)
    overridden = create(:query)
    variant = variant_with([[:children, [:"query_#{children.id}"]], [:people, [:"query_#{overridden.id}"], "Team"]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:default_key, :label)).to eq [["children", nil], ["people", "Team"]]
    expect(variant.form_groups.first.translated_label).to eq I18n.t("activerecord.attributes.work_package.children")
    expect(variant.form_groups.second.translated_label).to eq "Team"
  end

  it "names blank-keyed query groups like blank-keyed attribute groups" do
    query = create(:query)
    variant = variant_with([["", [:"query_#{query.id}"]], [nil, %w[assignee]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:kind, :label))
      .to eq [["query", "Untitled group"], ["attribute", "Untitled group 2"]]
  end

  it "keeps a plugin key the catalog does not know as a dormant active membership" do
    variant = variant_with([["Agile", %w[story_points_from_removed_plugin assignee]]])

    migrate!
    check_deferred_constraints!

    members = variant.form_groups.first.members
    expect(members.map(&:key)).to eq %w[story_points_from_removed_plugin assignee]
    expect(members.first.position).to eq 1
  end

  it "drops a reference to a deleted custom field, prunes it from required attributes and logs it" do
    deleted_id = create(:wp_custom_field).tap(&:destroy!).id
    variant = variant_with([["Fields", ["custom_field_#{deleted_id}", "assignee"]]])
    variant.update_column(:required_attributes, ["custom_field_#{deleted_id}", "assignee"])

    expect { described_class.migrate(:up) }.to output(/custom_field_#{deleted_id}/).to_stdout
    check_deferred_constraints!

    expect(variant.form_groups.first.members.map(&:key)).to eq %w[assignee]
    expect(variant.reload[:required_attributes]).to eq %w[assignee]
  end

  it "drops a query group whose query no longer exists and logs it" do
    missing_id = create(:query).tap(&:destroy!).id
    variant = variant_with([["Related", [:"query_#{missing_id}"]], [:details, %w[assignee]]])

    expect { described_class.migrate(:up) }.to output(/query_#{missing_id}/).to_stdout
    check_deferred_constraints!

    expect(tuples(variant)).to eq [[:details, %w[assignee]]]
  end

  it "drops a blank-keyed missing query group without consuming an untitled number" do
    missing_id = create(:query).tap(&:destroy!).id
    variant = variant_with([["", [:"query_#{missing_id}"]], [nil, %w[assignee]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:label)).to eq ["Untitled group"]
  end

  it "drops a missing query group without consuming its default key" do
    missing_id = create(:query).tap(&:destroy!).id
    variant = variant_with([[:children, [:"query_#{missing_id}"]], [:children, %w[assignee]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:default_key, :label)).to eq [["children", nil]]
    expect(tuples(variant)).to eq [[:children, %w[assignee]]]
  end

  it "rebuilds a query another configuration already references, so each group owns its query" do
    query = create(:query)
    first = variant_with([["Related", [:"query_#{query.id}"]]])
    second = variant_with([["Related", [:"query_#{query.id}"]]])

    expect { migrate! }.to change(Query, :count).by(1)
    check_deferred_constraints!

    first_group = first.form_groups.first
    second_group = second.form_groups.first
    expect([first_group, second_group]).to all(be_query)
    expect(first_group.query_id).not_to eq second_group.query_id

    first_group.destroy!
    expect(second_group.reload.query).to be_present
  end

  it "keeps the first placement of an attribute listed in two groups and logs the second" do
    variant = variant_with([["a", %w[assignee date]], ["b", %w[date priority]]])

    expect { described_class.migrate(:up) }.to output(/repeated attribute date/).to_stdout
    check_deferred_constraints!

    expect(tuples(variant)).to eq [["a", %w[assignee date]], ["b", %w[priority]]]
  end

  it "turns a repeated default key into a custom group carrying the translated label" do
    variant = variant_with([[:details, %w[assignee]], [:details, %w[date]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:default_key, :label)).to eq [["details", nil], [nil, I18n.t(:label_details)]]
  end

  it "stops with the owning variant on unparseable data and writes nothing for it" do
    variant = variant_with([["ok", %w[assignee]], "not a tuple"])

    expect { migrate! }.to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}/)
    expect(variant.form_groups).to be_empty
  end

  it "stops with the owning variant when attribute_groups is not an array" do
    variant = create(:type).default_variant
    update_raw_attribute_groups(variant, { "a" => 1 }.to_yaml)

    expect { migrate! }
      .to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}: attribute_groups is not an array/)
    expect(variant.form_groups).to be_empty
  end

  it "stops with the owning variant when attribute_groups is not valid YAML" do
    variant = create(:type).default_variant
    update_raw_attribute_groups(variant, "- [a")

    expect { migrate! }
      .to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}: attribute_groups is not parseable/)
    expect(variant.form_groups).to be_empty
  end

  it "stops with the owning variant when attribute_groups holds a disallowed object" do
    variant = create(:type).default_variant
    update_raw_attribute_groups(variant, "--- !ruby/object:Query {}\n")

    expect { migrate! }
      .to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}: attribute_groups is not parseable/)
    expect(variant.form_groups).to be_empty
  end

  it "names the owning variant when a record cannot be saved" do
    variant = variant_with([["Bug details", %w[assignee]]])
    allow(FormConfigurationGroup).to receive(:new).and_wrap_original do |original, *args, &block|
      original.call(*args, &block).tap do |group|
        next unless group.type_variant_id == variant.id

        group.errors.add(:label, :blank)
        allow(group).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(group))
      end
    end

    expect { migrate! }
      .to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}: Validation failed/)
  end

  it "stops with the owning variant when the stored records do not match the legacy groups" do
    variant = variant_with([["Bug details", %w[assignee]]])
    expectation = instance_double(described_class::LegacyExpectation, call: [["Other", %w[assignee]]])
    allow(described_class::LegacyExpectation).to receive(:new).and_return(expectation)

    expect { migrate! }
      .to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}: verification failed/)
  end

  it "stops with the owning variant on a member that is neither a string nor a symbol" do
    variant = variant_with([["a", [1]]])

    expect { migrate! }.to raise_error(described_class::Unconvertible, /type_variants ##{variant.id}/)
    expect(variant.form_groups).to be_empty
  end

  it "skips linked variants even when their own column still holds stale groups" do
    type = create(:type)
    linked = create(:type_variant, type:)
    linked.update_column(:attribute_groups, [["Stale", %w[assignee]]])
    linked.link!(TypeVariant::FORM_CONFIGURATION)

    migrate!
    check_deferred_constraints!

    expect(linked.form_groups).to be_empty
    expect(linked.form_attributes).to be_empty
    expect(type.default_variant.form_groups).not_to be_empty
  end

  it "converts an independent named variant" do
    type = create(:type)
    independent = create(:type_variant, type:)
    independent.update_column(:attribute_groups, [["Own", %w[assignee]]])

    migrate!
    check_deferred_constraints!

    expect(tuples(independent)).to eq [["Own", %w[assignee]]]
  end

  it "is retry-safe: a second run allocates no new identities" do
    variant = variant_with([["Bug details", %w[assignee date]]])
    migrate!
    group_ids = variant.form_groups.pluck(:id)
    attribute_ids = variant.form_attributes.order(:id).pluck(:id)

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.reload.pluck(:id)).to eq group_ids
    expect(variant.form_attributes.reload.order(:id).pluck(:id)).to eq attribute_ids
  end

  it "writes translated labels in the instance's default language", with_settings: { default_language: "de" } do
    variant = variant_with([[:people, %w[assignee]], [:people, %w[responsible]]])

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.second.label).to eq "Personen"
  end

  it "removes the derived records when rolled back" do
    variant_with([["Bug details", %w[assignee]]])
    migrate!
    check_deferred_constraints!

    migrate!(:down)

    expect(FormConfigurationGroup.count).to eq 0
    expect(FormConfigurationAttribute.count).to eq 0
  end

  it "honours the milestone rule when materializing defaults" do
    variant = create(:type, is_milestone: true).default_variant

    migrate!
    check_deferred_constraints!

    expect(variant.form_groups.pluck(:default_key)).not_to include "estimates_and_progress"
  end
end
