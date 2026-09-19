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

RSpec.describe ResourceManagement::GlobalMenu, with_ee: %i[resource_management] do
  include Rails.application.routes.url_helpers

  shared_let(:alpha) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management]) }
  shared_let(:beta) { create(:project, name: "Beta", enabled_module_names: %w[resource_management]) }
  # Sorts first by name but last in the hierarchy, so the two orderings disagree.
  shared_let(:beta_child) do
    create(:project, name: "Aardvark", parent: beta, enabled_module_names: %w[resource_management])
  end
  shared_let(:invisible) { create(:project, name: "Invisible", enabled_module_names: %w[resource_management]) }

  shared_let(:user) do
    create(:user, member_with_permissions: { alpha => %i[view_resource_planners],
                                             beta => %i[view_resource_planners],
                                             beta_child => %i[view_resource_planners] })
  end

  shared_let(:alpha_planner) { create(:resource_planner, project: alpha, principal: user, name: "Alpha planner") }
  shared_let(:beta_planner) { create(:resource_planner, project: beta, principal: user, name: "Beta planner") }
  shared_let(:child_planner) do
    create(:resource_planner, project: beta_child, principal: user, name: "Child planner")
  end
  shared_let(:invisible_planner) do
    create(:resource_planner, project: invisible, principal: create(:user), public: true, name: "Invisible planner")
  end

  subject(:menu_items) { described_class.new(params: {}).menu_items }

  before { login_as(user) }

  def group(header) = menu_items.find { |item| item.header == header }

  def titles(header) = group(header)&.children&.map(&:title)

  it "lists a group per project the user has visible planners in" do
    expect(menu_items.map(&:header)).to include("Alpha", "Beta", "Aardvark")
    expect(titles("Alpha")).to eq(["Alpha planner"])
    expect(titles("Beta")).to eq(["Beta planner"])
    expect(titles("Aardvark")).to eq(["Child planner"])
  end

  it "orders the project groups by hierarchy rather than by name" do
    expect(menu_items.map(&:header)).to eq(%w[Alpha Beta Aardvark])
  end

  it "links a planner to its own project" do
    expect(group("Alpha").children.first.href)
      .to eq(project_resource_planner_path(alpha, alpha_planner))
  end

  it "omits projects the user cannot see resource planners in" do
    expect(menu_items.map(&:header)).not_to include("Invisible")
    expect(menu_items.flat_map { |item| item.children.map(&:title) }).not_to include("Invisible planner")
  end

  context "without the global permission" do
    it "omits the global planner groups" do
      expect(menu_items.map(&:header))
        .not_to include(I18n.t("resource_management.sidebar.public"),
                        I18n.t("resource_management.sidebar.private"))
    end
  end

  describe "staffing" do
    it "is absent without the permission" do
      expect(menu_items.map(&:header)).not_to include(nil)
    end

    context "when the user may staff in a project" do
      shared_let(:staffer) do
        create(:user, member_with_permissions: { alpha => %i[view_resource_planners
                                                             assign_users_to_generic_allocations] })
      end

      before { login_as(staffer) }

      it "is the first group and links to global staffing" do
        expect(menu_items.first.header).to be_nil
        expect(menu_items.first.children.map(&:href)).to eq([staffing_path])
      end
    end
  end
end
