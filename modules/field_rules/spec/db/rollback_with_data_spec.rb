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
require Rails.root.join("modules/field_rules/db/migrate/20261003200000_create_field_rules").to_s

RSpec.describe CreateFieldRules, "with data" do
  let(:tables) { %w[field_rule_sets field_rules field_rule_schemes field_rule_scheme_items project_field_rule_schemes] }
  let(:type) { create(:type) }
  let(:project) { create(:project, types: [type]) }

  def reset_columns
    [FieldRuleSet, FieldRule, FieldRuleScheme, FieldRuleSchemeItem, ProjectFieldRuleScheme].each(&:reset_column_information)
  end

  it "rolls back with rules, items and assignments present and leaves core data untouched" do
    rule_set = create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true }])
    scheme = create(:field_rule_scheme, mapping: { type => rule_set })
    ProjectFieldRuleScheme.create!(project:, scheme:)
    work_package = create(:work_package, project:, type:)
    core_counts = [Type.count, Project.count, WorkPackage.count, ProjectType.count]

    migration = described_class.new
    expect { migration.migrate(:down) }.not_to raise_error
    begin
      tables.each { |table| expect(ActiveRecord::Base.connection.table_exists?(table)).to be false }
      expect([Type.count, Project.count, WorkPackage.count, ProjectType.count]).to eq core_counts
      expect(WorkPackage.find(work_package.id).type_id).to eq type.id
    ensure
      migration.migrate(:up)
      reset_columns
    end
  end

  it "comes back empty after rollback and migrate again, so a restore from backup is needed for old rules" do
    rule_set = create(:field_rule_set, rule_attributes: [{ field_key: "description", required: true }])
    create(:field_rule_scheme, mapping: { type => rule_set })

    migration = described_class.new
    migration.migrate(:down)
    migration.migrate(:up)
    reset_columns

    expect([FieldRuleSet.count, FieldRule.count, FieldRuleScheme.count, FieldRuleSchemeItem.count]).to eq [0, 0, 0, 0]
  end

  it "does not touch the schema of core tables" do
    core_columns = %w[types projects work_packages project_types].index_with do |table|
      ActiveRecord::Base.connection.columns(table).map(&:name)
    end

    migration = described_class.new
    migration.migrate(:down)
    migration.migrate(:up)
    reset_columns

    core_columns.each do |table, columns|
      expect(ActiveRecord::Base.connection.columns(table).map(&:name)).to eq columns
    end
  end

  it "declares the indexes and foreign keys the resolver and cascades rely on" do
    connection = ActiveRecord::Base.connection

    expect(connection.index_exists?(:field_rules, %i[rule_set_id field_key], unique: true)).to be true
    expect(connection.index_exists?(:field_rule_scheme_items, %i[scheme_id type_id], unique: true)).to be true
    expect(connection.index_exists?(:project_field_rule_schemes, :project_id, unique: true)).to be true
    expect(connection.index_exists?(:field_rule_sets, :name, unique: true)).to be true
    expect(connection.index_exists?(:field_rule_schemes, :name, unique: true)).to be true
    expect(connection.index_exists?(:field_rule_scheme_items, :rule_set_id)).to be true
    expect(connection.index_exists?(:project_field_rule_schemes, :scheme_id)).to be true

    cascades = connection.foreign_keys(:field_rule_scheme_items).to_h { |fk| [fk.column, fk.on_delete] }
    expect(cascades).to include("scheme_id" => :cascade, "type_id" => :cascade)
    expect(cascades["rule_set_id"]).to be_nil
    expect(connection.foreign_keys(:project_field_rule_schemes).to_h { |fk| [fk.column, fk.on_delete] })
      .to include("project_id" => :cascade)
  end
end
