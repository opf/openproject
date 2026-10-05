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
require Rails.root.join("modules/screens/db/migrate/20261005210000_create_screens").to_s

RSpec.describe CreateScreens do
  it "drops only its own tables on rollback and keeps types, projects and work packages" do
    type = create(:type)
    project = create(:project, types: [type])
    create(:work_package, project:, type:)
    counts = [Type.count, WorkPackage.count, Project.count]

    migration = described_class.new
    migration.migrate(:down)
    begin
      %w[screens screen_sections screen_items screen_schemes screen_scheme_items project_screen_schemes].each do |table|
        expect(ActiveRecord::Base.connection.table_exists?(table)).to be false
      end
      expect([Type.count, WorkPackage.count, Project.count]).to eq counts
    ensure
      migration.migrate(:up)
      [Screen, ScreenSection, ScreenItem, ScreenScheme, ScreenSchemeItem, ProjectScreenScheme].each(&:reset_column_information)
    end
  end
end
