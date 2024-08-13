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

RSpec.describe "repositories/stats" do
  let(:project) { create(:project) }

  before do
    assign(:project, project)
  end

  describe "requested by a user with view_commit_author_statistics permission" do
    before do
      assign(:show_commits_per_author, true)
      render
    end

    it "embeds the commits per author graph" do
      expect(rendered).to include("commits_per_author")
    end
  end

  describe "requested by a user without view_commit_author_statistics permission" do
    before do
      assign(:show_commits_per_author, false)
      render
    end

    it "does not embed the commits per author graph" do
      expect(rendered).not_to include("commits_per_author")
    end
  end
end
