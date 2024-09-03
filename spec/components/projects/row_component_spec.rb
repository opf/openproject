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
#
require "rails_helper"

RSpec.describe Projects::RowComponent, type: :component do
  describe "#name" do
    it "renders the project name as a link" do
      project = build_stubbed(:project, name: "My Project No. 1", identifier: "myproject_no_1")

      table = instance_double(Projects::TableComponent, columns: [Queries::Projects::Selects::Default.new(:name)],
                                                        favored_project_ids: [])
      component = described_class.new(row: [project, 0], table:)

      render_inline(component)

      expect(page).to have_css(
        "a[data-turbo='false'][href='/projects/myproject_no_1']",
        text: "My Project No. 1"
      )
    end
  end
end
