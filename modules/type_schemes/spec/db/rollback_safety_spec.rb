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
require Rails.root.join("modules/type_schemes/db/migrate/20261002100000_create_type_schemes").to_s

RSpec.describe CreateTypeSchemes do
  it "drops only its own tables on rollback and keeps types and work packages" do
    story = create(:type)
    project = create(:project, types: [story])
    create(:work_package, project:, type: story)
    counts = [Type.count, WorkPackage.count, Project.count]

    migration = described_class.new
    migration.migrate(:down)
    begin
      %w[type_schemes type_scheme_items project_type_schemes].each do |table|
        expect(ActiveRecord::Base.connection.table_exists?(table)).to be false
      end
      expect([Type.count, WorkPackage.count, Project.count]).to eq counts
    ensure
      migration.migrate(:up)
      [TypeScheme, TypeSchemeItem, ProjectTypeScheme].each(&:reset_column_information)
    end
  end
end
