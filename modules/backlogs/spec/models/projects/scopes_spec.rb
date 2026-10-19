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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Projects::Scopes, "scopes" do
  shared_let(:project_without_settings) { create(:project, sprint_sharing: nil) }
  shared_let(:project_with_empty_settings) { create(:project, sprint_sharing: "") }
  shared_let(:no_sharing_project) { create(:project, sprint_sharing: "no_sharing") }
  shared_let(:all_projects_sharer) { create(:project, sprint_sharing: "share_all_projects") }
  shared_let(:subprojects_sharer) { create(:project, sprint_sharing: "share_subprojects") }
  shared_let(:receiver) { create(:project, sprint_sharing: "receive_shared") }

  describe ".share_sprints_with_all_projects" do
    it "returns projects that share with all projects" do
      expect(Project.share_sprints_with_all_projects).to contain_exactly(all_projects_sharer)
    end
  end

  describe ".share_sprints_with_subprojects" do
    it "returns projects that share with subprojects" do
      expect(Project.share_sprints_with_subprojects).to contain_exactly(subprojects_sharer)
    end
  end

  describe ".receive_shared_sprints" do
    it "returns projects that receive shared sprints" do
      expect(Project.receive_shared_sprints).to contain_exactly(receiver)
    end
  end

  describe ".not_sharing_sprints" do
    it "returns projects with no sharing" do
      expect(Project.not_sharing_sprints).to contain_exactly(
        project_without_settings,
        project_with_empty_settings,
        no_sharing_project
      )
    end
  end
end
