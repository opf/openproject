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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "../spec_helper"

RSpec.describe Project, "#cost_types_available?" do
  let(:project) { create(:project) }

  before { CostType.destroy_all }

  it "is true when at least one cost type is for all projects" do
    create(:cost_type, for_all_projects: true)
    expect(project.cost_types_available?).to be true
  end

  it "is true when a cost type is explicitly enabled in the project" do
    cost_type = create(:cost_type, for_all_projects: false)
    CostTypesProject.create!(project:, cost_type:)
    expect(project.cost_types_available?).to be true
  end

  it "is false when there are no cost types enabled in the project" do
    create(:cost_type, for_all_projects: false)
    expect(project.cost_types_available?).to be false
  end

  it "ignores soft-deleted cost types" do
    create(:cost_type, :deleted, for_all_projects: true)
    expect(project.cost_types_available?).to be false
  end
end
