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
require Rails.root.join("db/migrate/20231123111357_create_custom_field_sections.rb")

RSpec.describe CreateCustomFieldSections, type: :model do
  # Silencing migration logs, since we are not interested in that during testing
  subject(:run_migration) do
    ActiveRecord::Migration.suppress_messages { described_class.new.tap(&:down).tap(&:up) }
  end

  it "creates the custom field section" do
    create_list(:project_custom_field, 2)
    create_list(:wp_custom_field, 2)

    run_migration

    expect(ProjectCustomFieldSection.count).to eq 1
    expect(ProjectCustomFieldSection.first.name).to eq "Project attributes"
    expect(WorkPackageCustomField.pluck(:custom_field_section_id)).to all be_nil
    expect(WorkPackageCustomField.pluck(:position_in_custom_field_section)).to all be_nil
    expect(ProjectCustomField.pluck(:custom_field_section_id))
      .to all eq ProjectCustomFieldSection.first.id
    expect(ProjectCustomField.pluck(:position_in_custom_field_section)).to eq [1, 2]
  end
end
