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

require "spec_helper"

RSpec.describe SquashTMIntegration::ProjectLink do
  it "belongs to a project" do
    link = create(:squashtm_project_link)

    expect(link.project).to be_a(Project)
  end

  it "allows only one link per project" do
    existing = create(:squashtm_project_link)

    duplicate = build(:squashtm_project_link, project: existing.project)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors).to be_added(:project_id, :taken, value: existing.project_id)
  end

  it "is removed together with its project" do
    link = create(:squashtm_project_link)

    expect { link.project.destroy }.to change(described_class, :count).by(-1)
  end
end
