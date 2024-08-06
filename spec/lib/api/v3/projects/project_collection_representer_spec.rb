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

RSpec.describe API::V3::Projects::ProjectCollectionRepresenter do
  shared_let(:projects) { create_list(:project, 3) }

  let(:self_base_link) { "/api/v3/projects" }
  let(:current_user) { build(:user) }
  let(:representer) do
    described_class.new Project.all,
                        self_link: self_base_link,
                        current_user:
  end
  let(:total) { 3 }
  let(:page) { 1 }
  let(:page_size) { 30 }
  let(:actual_count) { 3 }
  let(:collection_inner_type) { "Project" }

  subject { representer.to_json }

  context "generation" do
    subject(:collection) { representer.to_json }

    it_behaves_like "offset-paginated APIv3 collection", 3, "projects", "Project"
  end

  describe "representation formats" do
    it_behaves_like "has a link collection" do
      let(:link) { "representations" }
      let(:hrefs) do
        [
          {
            "href" => "/projects.csv?offset=1&pageSize=30",
            "identifier" => "csv",
            "type" => "text/csv",
            "title" => "CSV"
          },
          {
            "href" => "/projects.xls?offset=1&pageSize=30",
            "identifier" => "xls",
            "type" => "application/vnd.ms-excel",
            "title" => "XLS"
          }
        ]
      end
    end
  end

  describe ".checked_permissions" do
    it "lists add_work_packages and view_projects" do
      expect(described_class.checked_permissions).to contain_exactly(:add_work_packages, :view_project)
    end
  end
end
