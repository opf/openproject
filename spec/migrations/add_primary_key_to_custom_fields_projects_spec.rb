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
require Rails.root.join("db/migrate/20240917105829_add_primary_key_to_custom_fields_projects.rb")

RSpec.describe AddPrimaryKeyToCustomFieldsProjects, type: :model do
  shared_association_default(:project) { create(:project) }

  it "adds an `id` primary key column with backfilled values" do
    ActiveRecord::Migration.suppress_messages { described_class.migrate(:down) }
    CustomFieldsProject.reset_column_information
    CustomFieldsProject.reset_primary_key

    create_list(:custom_fields_project, 5)

    aggregate_failures "no primary key column" do
      expect(CustomFieldsProject.column_names).not_to include("id")
      expect(CustomFieldsProject.count).to eq 5
    end

    ActiveRecord::Migration.suppress_messages { described_class.migrate(:up) }
    CustomFieldsProject.reset_column_information
    CustomFieldsProject.reset_primary_key

    aggregate_failures "primary key column added" do
      expect(CustomFieldsProject.column_names).to include("id")
      expect(CustomFieldsProject.last.id).to eq 5
    end

    aggregate_failures "next record increments the primary key" do
      expect { create(:custom_fields_project) }.to change(CustomFieldsProject, :count).by(1)
      expect(CustomFieldsProject.last.id).to eq 6
    end
  end
end
