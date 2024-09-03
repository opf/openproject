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

RSpec.describe "Roadmap Filtering", :js, :with_cuprite do
  shared_let(:project) { create(:project) }
  shared_let(:sub_project) { create(:project, parent: project) }

  shared_let(:version) { create(:version, project:) }
  shared_let(:sub_project_version) { create(:version, project: sub_project) }

  shared_let(:admin) { create(:admin) }

  current_user { admin }

  let(:roadmap_page) { Pages::Versions::Roadmap.new(project:) }

  describe '"Subprojects" filter' do
    context "when visiting the project roadmap page" do
      before do
        roadmap_page.visit!
      end

      context "and Sub Projects are not set to be displayed by default",
              with_settings: { display_subprojects_work_packages: false } do
        it "does not display Sub Project versions" do
          roadmap_page.expect_filter_not_set("Subprojects")

          roadmap_page.expect_versions_listed(version)
          roadmap_page.expect_versions_not_listed(sub_project_version)
        end

        context "and I filter for Sub Project versions" do
          before do
            roadmap_page.apply_filter("Subprojects")
          end

          it "displays Sub Project versions as well" do
            roadmap_page.expect_filter_set "Subprojects"

            roadmap_page.expect_versions_listed(version,
                                                sub_project_version)
          end
        end
      end

      context "and Sub Projects are set to be displayed by default",
              with_settings: { display_subprojects_work_packages: true } do
        it "displays Sub Project versions as well" do
          roadmap_page.expect_filter_set "Subprojects"

          roadmap_page.expect_versions_listed(version,
                                              sub_project_version)
        end

        context "and I remove the Subprojects filter" do
          before do
            roadmap_page.remove_filter("Subprojects")
          end

          it "does not display Sub Project versions" do
            roadmap_page.expect_filter_not_set "Subprojects"

            roadmap_page.expect_versions_listed(version)
            roadmap_page.expect_versions_not_listed(sub_project_version)
          end
        end
      end
    end
  end
end
