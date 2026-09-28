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
require Rails.root.join("db/migrate/20260925100000_extract_named_forms.rb")

RSpec.describe ExtractNamedForms, "converting groups to rows", type: :model, with_settings: { default_language: "en" } do
  let!(:owner) { create(:type, name: "Bug").default_variant }
  let!(:other_owner) { create(:type, name: "Task").default_variant }
  let!(:milestone_owner) { create(:type_milestone).default_variant }
  let!(:query) { create(:query) }
  let!(:missing_query_id) { create(:query).tap(&:destroy).id }

  let(:connection) { ActiveRecord::Base.connection }

  before do
    ActiveRecord::Migration.suppress_messages { described_class.new.down }
    connection.clear_cache!
    described_class::MigratedTypeVariant.reset_column_information
    RequestStore.clear!
  end

  after do
    [described_class::MigratedTypeVariant, TypeVariant, FormConfiguration, FormConfigurationGroup,
     FormConfigurationAttribute, WorkPackageCustomField].each(&:reset_column_information)
  end

  def groups_of(variant, groups)
    described_class::MigratedTypeVariant.find(variant.id).update_column(:attribute_groups, groups)
  end

  def raw_groups_of(variant, yaml)
    connection.execute("UPDATE type_variants SET attribute_groups = #{connection.quote(yaml)} WHERE id = #{variant.id}")
  end

  def migrate_up
    ActiveRecord::Migration.suppress_messages { described_class.new.up }
    connection.clear_cache!
    connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
  end

  def form_of(variant)
    connection.clear_cache!
    FormConfiguration.find(TypeVariant.find(variant.id).form_configuration_id)
  end

  def tuples(variant)
    form_of(variant).form_groups.reload.map do |group|
      key = group.default_key ? group.default_key.to_sym : group.label
      [key, group.query? ? [:"query_#{group.query_id}"] : group.members.map(&:key)]
    end
  end

  it "writes a variant's default groups for an owner that had none" do
    groups_of(owner, nil)

    migrate_up

    expect(tuples(owner)).to eq(TypeVariant.find(owner.id).default_attribute_groups.map { |key, members| [key, members] })
    expect(form_of(owner).form_attributes.inactive).not_to be_empty
  end

  it "honours the milestone rule when it writes the defaults" do
    groups_of(milestone_owner, nil)

    migrate_up

    expect(tuples(milestone_owner).map(&:first)).not_to include(:estimates_and_progress)
  end

  it "keeps the order, members and labels of customized groups" do
    groups_of(owner, [["Bug details", %w[assignee date]], [:people, %w[responsible]], [:details, %w[priority], "Extras"]])

    migrate_up

    expect(tuples(owner)).to eq([["Bug details", %w[assignee date]], [:people, %w[responsible]], [:details, %w[priority]]])
    expect(form_of(owner).form_groups.find_by(default_key: "details").label).to eq("Extras")
  end

  it "turns the empty sentinel into no groups with every attribute inactive" do
    groups_of(owner, [[:__empty, []]])

    migrate_up

    expect(form_of(owner).form_groups).to be_empty
    expect(form_of(owner).form_attributes.active).to be_empty
  end

  it "names blank-keyed groups like the contract does" do
    groups_of(owner, [["", %w[assignee]], [nil, %w[date]], ["Untitled group", %w[priority]]])

    migrate_up

    expect(form_of(owner).form_groups.pluck(:label)).to eq(["Untitled group 2", "Untitled group 3", "Untitled group"])
  end

  it "stores a custom field by its foreign key" do
    custom_field = create(:wp_custom_field)
    groups_of(owner, [["Fields", [custom_field.attribute_name]]])

    migrate_up

    member = form_of(owner).form_groups.first.members.first
    expect(member.custom_field).to eq(custom_field)
    expect(member.attribute_key).to be_nil
  end

  it "keeps the query of a query group" do
    groups_of(owner, [["Related", [:"query_#{query.id}"]]])

    migrate_up

    group = form_of(owner).form_groups.first
    expect(group).to be_query
    expect(group.query).to eq(query)
  end

  it "drops a deleted custom field, prunes it from the required attributes and logs it" do
    deleted_id = create(:wp_custom_field).tap(&:destroy).id
    groups_of(owner, [["Fields", ["custom_field_#{deleted_id}", "assignee"]]])
    connection.execute("UPDATE type_variants SET required_attributes = '{custom_field_#{deleted_id}}' WHERE id = #{owner.id}")

    expect { described_class.new.up }.to output(/custom_field_#{deleted_id}/).to_stdout

    expect(tuples(owner)).to eq([["Fields", %w[assignee]]])
    expect(form_of(owner).type_variants.find(owner.id)[:required_attributes]).to eq([])
  end

  it "drops a query group whose query no longer exists and logs it" do
    groups_of(owner, [["Related", [:"query_#{missing_query_id}"]], ["Fields", %w[assignee]]])

    expect { described_class.new.up }.to output(/query_#{missing_query_id}/).to_stdout

    expect(tuples(owner)).to eq([["Fields", %w[assignee]]])
  end

  it "rebuilds a query another form already holds, so each group owns its query" do
    groups_of(owner, [["Related", [:"query_#{query.id}"]]])
    groups_of(other_owner, [["Related", [:"query_#{query.id}"]]])

    migrate_up

    query_ids = [owner, other_owner].map { form_of(it).form_groups.first.query_id }
    expect(query_ids.uniq.size).to eq(2)
  end

  it "keeps the first placement of an attribute listed twice and logs the second" do
    groups_of(owner, [["First", %w[date]], ["Second", %w[date assignee]]])

    expect { described_class.new.up }.to output(/repeated attribute date/).to_stdout

    expect(tuples(owner)).to eq([["First", %w[date]], ["Second", %w[assignee]]])
  end

  it "stops on unparseable data, naming the form and its owning variant" do
    raw_groups_of(owner, "--- [unterminated")

    expect { migrate_up }.to raise_error(described_class::Unconvertible, /type_variants ##{owner.id}/)
  end
end
