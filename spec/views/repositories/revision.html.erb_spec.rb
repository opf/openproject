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

RSpec.describe "repositories/revision" do
  let(:user) { create(:admin) }
  let(:project) { create(:project) }
  let(:repository) { create(:repository_git, project:) }
  let(:changeset) { create(:changeset, repository:) }

  before do
    login_as(user)
    assign(:project, project)
    assign(:repository, repository)
    assign(:changeset, changeset)
  end

  it "renders the revision with file changes without frozen string errors (Bug #64508)" do
    changeset.file_changes.create!(action: "A", path: "/foo/bar/test.txt")

    render
    expect(rendered).to include("/foo/bar/test.txt")
  end
end
