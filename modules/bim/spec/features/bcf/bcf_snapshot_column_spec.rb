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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe "BCF snapshot column", :js,
               with_config: { edition: "bim" } do
  let(:project) { create(:project, enabled_module_names: %w[bim work_package_tracking]) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }
  let(:permissions) { %i[add_work_packages view_work_packages view_linked_issues] }
  let!(:work_package) { create(:work_package, project:) }
  let!(:bcf_issue) { create(:bcf_issue_with_viewpoint, work_package:) }
  let(:user) do
    create(:user,
           member_with_permissions: { project => permissions })
  end
  let!(:query) do
    query              = build(:query, user:, project:)
    query.column_names = ["subject", "bcf_thumbnail"]
    query.filters.clear
    query.show_hierarchies = false

    query.save!
    query
  end

  before do
    login_as(user)
  end

  it "shows BCF snapshot column correctly (Regression)" do
    wp_table.visit_query query
    wp_table.expect_work_package_listed(work_package)

    page.within(".wp-row-#{work_package.id} td.bcfThumbnail") do
      image_path = "/api/bcf/2.1/projects/#{project.identifier}/topics/#{bcf_issue.uuid}/viewpoints/#{bcf_issue.viewpoints.first.uuid}/snapshot"
      expect(page).to have_css("img[src=\"#{image_path}\"]")
    end
  end
end
