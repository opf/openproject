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

RSpec.describe ResourceWorkPackageTimeline do
  shared_let(:project) { create(:project) }
  shared_let(:user) { create(:user) }
  shared_let(:planner) { create(:resource_planner, project:, principal: user) }

  it "is an allowed child of a resource planner" do
    expect(ResourcePlanner.allowed_children).to include("ResourceWorkPackageTimeline")
  end

  it "persists as a child of a planner with a default work package query" do
    view = described_class.new(name: "Timeline", parent: planner, project:, principal: user)
    view.query = view.build_default_query
    view.query.name = view.name

    expect(view.save).to be(true)
    expect(view.work_packages).to be_empty
  end

  it "rejects a non-work-package query" do
    view = described_class.new(name: "Timeline", parent: planner, project:, principal: user)
    view.query = UserQuery.new(project:, principal: user)

    expect(view).not_to be_valid
    expect(view.errors).to be_added(:query, :must_be_work_package_query)
  end

  it "names its query with the timeline i18n key" do
    view = described_class.new(name: "Epic Planning", parent: planner, project:, principal: user)
    view.query = view.build_default_query
    view.apply_query_configuration(filters_json: nil, filter_mode: "automatic")

    expect(view.query.name).to eq(I18n.t("resource_management.work_package_timeline.query_name", name: "Epic Planning"))
  end
end
