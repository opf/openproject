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

RSpec.describe ArchivedProjectsHelper do
  describe "#archived_projects_urls_for" do
    subject { helper.archived_projects_urls_for([archived_project, other_archived_project]) }

    shared_let(:archived_project) { create(:project, :archived) }
    shared_let(:other_archived_project) { create(:project, :archived) }
    shared_let(:archived_project_filters) do
      "[{\"active\":{\"operator\":\"=\",\"values\":[\"f\"]}}," \
        "{\"name_and_identifier\":{\"operator\":\"=\",\"values\":[\"#{archived_project.name}\"]}}]"
    end
    shared_let(:other_archived_project_filters) do
      "[{\"active\":{\"operator\":\"=\",\"values\":[\"f\"]}}," \
        "{\"name_and_identifier\":{\"operator\":\"=\",\"values\":[\"#{other_archived_project.name}\"]}}]"
    end

    it "returns a comma-separated list of anchor tags for each archived project" do
      expect(subject)
        .to eq(
          "<a target=\"_blank\" rel=\"noopener\" href=\"#{projects_path(filters: archived_project_filters)}\">" \
          "#{archived_project.name}" \
          "</a>, " \
          "<a target=\"_blank\" rel=\"noopener\" href=\"#{projects_path(filters: other_archived_project_filters)}\">" \
          "#{other_archived_project.name}" \
          "</a>"
        )
    end
  end
end
