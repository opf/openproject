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
require Rails.root.join("db/migrate/20261002090000_merge_hierarchy_custom_fields_into_lists")

RSpec.describe MergeHierarchyCustomFieldsIntoLists, type: :model do
  let(:conn) { ActiveRecord::Base.connection }

  def stored(custom_field)
    conn.select_one("SELECT field_format, was_list FROM custom_fields WHERE id = #{custom_field.id}")
  end

  # The factories already describe the merged formats, so the pre-migration ones are set by hand.
  def as_before_the_merge(custom_field, field_format)
    conn.execute("UPDATE custom_fields SET field_format = '#{field_format}' WHERE id = #{custom_field.id}")
    custom_field
  end

  it "flags former lists and turns hierarchies into lists that may nest" do
    list = as_before_the_merge(create(:list_wp_custom_field), "list")
    hierarchy = as_before_the_merge(create(:list_wp_custom_field), "hierarchy")

    ActiveRecord::Migration.suppress_messages do
      described_class.migrate(:down)
      described_class.migrate(:up)
    end

    expect(stored(list)).to eq("field_format" => "list", "was_list" => true)
    expect(stored(hierarchy)).to eq("field_format" => "list", "was_list" => false)
  end

  it "turns lists that may nest back into hierarchies on the way down" do
    nested = create(:list_wp_custom_field, was_list: false)

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }

    expect(conn.select_value("SELECT field_format FROM custom_fields WHERE id = #{nested.id}")).to eq("hierarchy")
  end
end
