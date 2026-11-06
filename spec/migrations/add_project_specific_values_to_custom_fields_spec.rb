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
require Rails.root.join("db/migrate/20261105092030_add_project_specific_values_to_custom_fields")

RSpec.describe AddProjectSpecificValuesToCustomFields, type: :model do
  let(:conn) { ActiveRecord::Base.connection }
  let(:models) { [CustomField, CustomOption, CustomField::Hierarchy::Item] }

  after do
    ActiveRecord::Migration.suppress_messages do
      described_class.migrate(:up) unless conn.column_exists?(:custom_fields, :settings)
    end

    # The migrations above change columns without refreshing ActiveRecord's cached
    # column lists; reset them so later specs build SQL against the restored schema.
    models.each(&:reset_column_information)
  end

  describe "up migration" do
    subject(:migrate_up) do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
      models.each(&:reset_column_information)
    end

    let(:readonly_user_custom_field_id) do
      conn.select_value(<<~SQL.squish)
        INSERT INTO custom_fields (type, field_format, name, editable)
        VALUES ('UserCustomField', 'string', 'Employee ID', false)
        RETURNING id
      SQL
    end
    let(:editable_user_custom_field_id) do
      conn.select_value(<<~SQL.squish)
        INSERT INTO custom_fields (type, field_format, name, editable)
        VALUES ('UserCustomField', 'string', 'Nickname', true)
        RETURNING id
      SQL
    end
    let(:work_package_custom_field_id) do
      conn.select_value(<<~SQL.squish)
        INSERT INTO custom_fields
          (type, field_format, name, editable, regexp, min_length, max_length, default_value, content_right_to_left)
        VALUES ('WorkPackageCustomField', 'text', 'Notes', false, '^[a-z]+$', 2, 20, 'abc', true)
        RETURNING id
      SQL
    end
    let(:numeric_custom_field_id) do
      conn.select_value(<<~SQL.squish)
        INSERT INTO custom_fields (type, field_format, name, min_value, max_value)
        VALUES ('WorkPackageCustomField', 'float', 'Ratio', 0.5, 10.25)
        RETURNING id
      SQL
    end
    let(:version_custom_field_id) do
      conn.select_value(<<~SQL.squish)
        INSERT INTO custom_fields (type, field_format, name, allow_non_open_versions)
        VALUES ('WorkPackageCustomField', 'version', 'Release', true)
        RETURNING id
      SQL
    end

    before do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }
      models.each(&:reset_column_information)
    end

    it "moves editable of user custom fields to user_self_editable" do
      readonly_user_custom_field_id
      editable_user_custom_field_id

      migrate_up

      expect(UserCustomField.find(readonly_user_custom_field_id).user_self_editable?).to be(false)
      expect(UserCustomField.find(editable_user_custom_field_id).user_self_editable?).to be(true)
    end

    it "drops editable for other custom field types" do
      work_package_custom_field_id

      migrate_up

      expect(CustomField.find(work_package_custom_field_id).settings_before_type_cast).not_to include("user_self_editable")
    end

    it "moves the remaining attributes into settings" do
      work_package_custom_field_id
      numeric_custom_field_id
      version_custom_field_id

      migrate_up

      expect(CustomField.find(work_package_custom_field_id))
        .to have_attributes(regexp: "^[a-z]+$", min_length: 2, max_length: 20,
                            default_value: "abc", content_right_to_left: true)
      expect(CustomField.find(numeric_custom_field_id)).to have_attributes(min_value: 0.5, max_value: 10.25)
      expect(CustomField.find(version_custom_field_id)).to have_attributes(allow_non_open_versions: true)
    end

    it "removes the moved columns" do
      migrate_up

      expect(conn.columns(:custom_fields).map(&:name))
        .not_to include("regexp", "min_length", "max_length", "min_value", "max_value", "default_value",
                        "content_right_to_left", "allow_non_open_versions", "editable")
    end

    it "adds project references to options and hierarchy items" do
      migrate_up

      expect(conn.column_exists?(:custom_options, :project_id)).to be(true)
      expect(conn.column_exists?(:hierarchical_items, :project_id)).to be(true)
    end
  end

  describe "down migration" do
    subject(:migrate_down) do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }
      models.each(&:reset_column_information)
    end

    let!(:readonly_user_custom_field) { create(:user_custom_field, :string, user_self_editable: false) }
    let!(:text_custom_field) do
      create(:wp_custom_field, :text, regexp: "^[a-z]+$", min_length: 2, max_length: 20, content_right_to_left: true)
    end

    it "restores the columns from settings" do
      migrate_down

      rows = conn.select_rows(<<~SQL.squish).to_h { |id, *values| [id, values] }
        SELECT id, editable, regexp, min_length, max_length, content_right_to_left
        FROM custom_fields
        WHERE id IN (#{readonly_user_custom_field.id}, #{text_custom_field.id})
      SQL

      expect(rows[readonly_user_custom_field.id]).to eq([false, "", 0, 0, false])
      expect(rows[text_custom_field.id]).to eq([true, "^[a-z]+$", 2, 20, true])
    end

    it "removes settings and the project references" do
      migrate_down

      expect(conn.column_exists?(:custom_fields, :settings)).to be(false)
      expect(conn.column_exists?(:custom_options, :project_id)).to be(false)
      expect(conn.column_exists?(:hierarchical_items, :project_id)).to be(false)
    end
  end
end
