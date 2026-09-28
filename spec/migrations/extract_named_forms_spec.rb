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

RSpec.describe ExtractNamedForms, type: :model do
  subject(:migrate_up) { ActiveRecord::Migration.suppress_messages { described_class.new.up } }

  shared_let(:field_a) { create(:integer_wp_custom_field) }
  shared_let(:field_b) { create(:integer_wp_custom_field) }

  let(:bug) { create(:type, name: "Bug") }
  let(:base) { bug.default_variant }
  let(:inheriting) { create(:type_variant, type: bug, variant_name: "Hardware") }
  let(:owning) { create(:type_variant, type: bug, variant_name: "Software") }
  let(:namesake) { create(:type, name: "Bug: Software").default_variant }

  let(:connection) { ActiveRecord::Base.connection }

  before do
    [base, inheriting, owning, namesake]
    ActiveRecord::Migration.suppress_messages { described_class.new.down }

    execute <<~SQL.squish
      UPDATE type_variants
      SET attribute_groups = '#{[['details', [field_a.attribute_name, field_b.attribute_name]]].to_yaml}',
          required_attributes = '{#{field_a.attribute_name},#{field_b.attribute_name}}'
      WHERE id = #{base.id}
    SQL
    execute <<~SQL.squish
      UPDATE type_variants
      SET linked_aspects = '{form_configuration}',
          form_configuration_source_id = #{base.id},
          form_configuration_excluded_elements = '{#{field_a.attribute_name}}'
      WHERE id = #{inheriting.id}
    SQL
    execute <<~SQL.squish
      UPDATE type_variants SET form_configuration_excluded_elements = '{assignee}' WHERE id = #{owning.id}
    SQL
    execute "DELETE FROM custom_fields_types"
    execute <<~SQL.squish
      INSERT INTO custom_fields_types (custom_field_id, type_variant_id)
      VALUES (#{field_a.id}, #{base.id}), (#{field_b.id}, #{base.id}), (#{field_b.id}, #{inheriting.id})
    SQL
  end

  after do
    [TypeVariant, FormConfiguration, WorkPackageCustomField].each(&:reset_column_information)
  end

  delegate :execute, to: :connection

  def column_of(variant, column)
    connection.select_value("SELECT #{column} FROM type_variants WHERE id = #{variant.id}")
  end

  def form_name_of(variant)
    connection.select_value(<<~SQL.squish)
      SELECT f.name FROM form_configurations f
      INNER JOIN type_variants v ON v.form_configuration_id = f.id
      WHERE v.id = #{variant.id}
    SQL
  end

  def custom_field_ids_of_form(form_id)
    connection.select_values("SELECT custom_field_id FROM custom_fields_types WHERE form_configuration_id = #{form_id}")
  end

  def array_of(variant, column)
    connection.select_value("SELECT array_to_json(#{column}) FROM type_variants WHERE id = #{variant.id}")
              .then { JSON.parse(it) }
  end

  it "creates a form for each variant that owns its configuration, named after it" do
    migrate_up

    expect(form_name_of(base)).to eq("Bug form")
    expect(form_name_of(owning)).to eq("Bug: Software form")
    expect(form_name_of(namesake)).to eq("Bug: Software form (2)")
  end

  it "points an inheriting variant at its type's form" do
    migrate_up

    expect(column_of(inheriting, :form_configuration_id)).to eq(column_of(base, :form_configuration_id))
    expect(array_of(inheriting, :linked_aspects)).not_to include("form_configuration")
  end

  it "moves the groups onto the form" do
    migrate_up

    groups = connection.select_value(
      "SELECT attribute_groups FROM form_configurations WHERE id = #{column_of(base, :form_configuration_id)}"
    )
    expect(YAML.safe_load(groups)).to eq([["details", [field_a.attribute_name, field_b.attribute_name]]])
  end

  it "gives an inheriting variant the required attributes it showed, minus what it excluded" do
    migrate_up

    expect(array_of(inheriting, :required_attributes)).to eq([field_b.attribute_name])
    expect(array_of(inheriting, :form_configuration_excluded_elements)).to eq([field_a.attribute_name])
  end

  it "clears the exclusions of an owning variant, which never applied" do
    migrate_up

    expect(array_of(owning, :form_configuration_excluded_elements)).to eq([])
  end

  it "moves the active custom fields onto the forms and drops those an inheriting variant left behind" do
    migrate_up

    expect(custom_field_ids_of_form(column_of(base, :form_configuration_id)))
      .to contain_exactly(field_a.id, field_b.id)
    expect(connection.select_value("SELECT count(*) FROM custom_fields_types")).to eq(2)
  end

  describe "down" do
    before do
      migrate_up
      ActiveRecord::Migration.suppress_messages { described_class.new.down }
    end

    it "links a variant sharing its type's form again" do
      expect(array_of(inheriting, :linked_aspects)).to include("form_configuration")
      expect(column_of(inheriting, :form_configuration_source_id)).to eq(base.id)
    end

    it "gives the groups and active custom fields back to the owning variants" do
      expect(YAML.safe_load(column_of(base, :attribute_groups)))
        .to eq([["details", [field_a.attribute_name, field_b.attribute_name]]])
      expect(connection.select_values("SELECT custom_field_id FROM custom_fields_types WHERE type_variant_id = #{base.id}"))
        .to contain_exactly(field_a.id, field_b.id)
    end
  end
end
