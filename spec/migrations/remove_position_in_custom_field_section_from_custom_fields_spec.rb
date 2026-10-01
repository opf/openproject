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
require Rails.root.join("db/migrate/20260605094204_remove_position_in_custom_field_section_from_custom_fields")

RSpec.describe RemovePositionInCustomFieldSectionFromCustomFields, type: :model do
  let(:conn) { ActiveRecord::Base.connection }

  def position_of(cf)
    conn.select_value("SELECT position_in_custom_field_section FROM custom_fields WHERE id = #{cf.id}")&.to_i
  end

  describe "up migration" do
    let(:section) { create(:project_custom_field_section) }
    let!(:cf1) { create(:project_custom_field, project_custom_field_section: section) }
    let!(:cf2) { create(:project_custom_field, project_custom_field_section: section) }
    let!(:cf3) { create(:project_custom_field, project_custom_field_section: section) }

    before do
      # Put schema in pre-migration state: add the column and set position values.
      ActiveRecord::Migration.suppress_messages do
        conn.add_column :custom_fields, :position_in_custom_field_section, :integer
      end
      conn.execute("UPDATE custom_fields SET position_in_custom_field_section = 1 WHERE id = #{cf1.id}")
      conn.execute("UPDATE custom_fields SET position_in_custom_field_section = 2 WHERE id = #{cf2.id}")
      conn.execute("UPDATE custom_fields SET position_in_custom_field_section = 3 WHERE id = #{cf3.id}")
      section.update_column(:attribute_order, [])
    end

    after do
      ActiveRecord::Migration.suppress_messages do
        conn.remove_column :custom_fields, :position_in_custom_field_section if
          conn.column_exists?(:custom_fields, :position_in_custom_field_section)
      end

      # The raw column changes above don't refresh ActiveRecord's cached column
      # lists; reset them so later specs build SQL against the restored schema.
      [CustomField, CustomFieldSection].each(&:reset_column_information)
    end

    it "seeds attribute_order from position_in_custom_field_section" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(section.reload.attribute_order).to eq([cf1.column_name, cf2.column_name, cf3.column_name])
    end

    it "removes the position_in_custom_field_section column" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(conn.column_exists?(:custom_fields, :position_in_custom_field_section)).to be false
    end

    it "does not seed attribute_order for UserCustomFieldSection" do
      user_section = create(:user_custom_field_section)
      cf_user = create(:user_custom_field, user_custom_field_section: user_section)
      conn.execute("UPDATE custom_fields SET position_in_custom_field_section = 1 WHERE id = #{cf_user.id}")
      user_section.update_column(:attribute_order, [])

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }

      expect(user_section.reload.attribute_order).to be_empty
    end
  end

  describe "down migration" do
    let(:section) { create(:project_custom_field_section) }
    let!(:cf1) { create(:project_custom_field, project_custom_field_section: section) }
    let!(:cf2) { create(:project_custom_field, project_custom_field_section: section) }

    before do
      section.update_column(:attribute_order, [cf2.column_name, cf1.column_name])
    end

    after do
      ActiveRecord::Migration.suppress_messages do
        conn.remove_column :custom_fields, :position_in_custom_field_section if
          conn.column_exists?(:custom_fields, :position_in_custom_field_section)
      end

      # The raw column changes above don't refresh ActiveRecord's cached column
      # lists; reset them so later specs build SQL against the restored schema.
      [CustomField, CustomFieldSection].each(&:reset_column_information)
    end

    it "adds position_in_custom_field_section back" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(conn.column_exists?(:custom_fields, :position_in_custom_field_section)).to be true
    end

    it "restores positions from attribute_order" do
      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(position_of(cf2)).to eq(1)
      expect(position_of(cf1)).to eq(2)
    end

    it "does not touch user section custom fields" do
      user_section = create(:user_custom_field_section)
      cf_user = create(:user_custom_field, user_custom_field_section: user_section)
      user_section.update_column(:attribute_order, [cf_user.column_name])

      ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

      expect(position_of(cf_user)).to be_nil
    end
  end
end
