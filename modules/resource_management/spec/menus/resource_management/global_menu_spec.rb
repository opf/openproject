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

  shared_let(:project) { create(:project, name: "Alpha", enabled_module_names: %w[resource_management]) }

  shared_let(:user) do
    create(:user,
           member_with_permissions: { project => %i[view_resource_planners] },
           global_permissions: %i[view_global_resource_planners])
  end

  shared_let(:own_planner) do
    create(:resource_planner, :global, principal: user, name: "My planner")
  end
  shared_let(:shared_planner) do
    create(:resource_planner, :global, principal: create(:user), public: true, name: "Shared planner")
  end
  shared_let(:project_planner) do
    create(:resource_planner, project:, principal: user, name: "Project planner")
  end

  subject(:menu_items) { described_class.new(params: {}).menu_items }

  before { login_as(user) }

  def group(header) = menu_items.find { |item| item.header == header }

  def titles(header) = group(header)&.children&.map(&:title)

  it "lists the global planners, split into public and private" do
    expect(titles(I18n.t("resource_management.sidebar.public"))).to eq(["Shared planner"])
    expect(titles(I18n.t("resource_management.sidebar.private"))).to eq(["My planner"])
  end

  it "links a planner into the global scope" do
    expect(group(I18n.t("resource_management.sidebar.private")).children.first.href)
      .to eq(resource_planner_path(own_planner))
  end

  it "does not list project planners: the global area is about global ones" do
    expect(menu_items.flat_map { |item| item.children.map(&:title) }).not_to include("Project planner")
    expect(menu_items.map(&:header)).not_to include("Alpha")
  end

  context "without the global permission" do
    before { login_as(create(:user, member_with_permissions: { project => %i[view_resource_planners] })) }

    it "lists no planners at all" do
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
        create(:user, member_with_permissions: { project => %i[view_resource_planners
                                                               assign_users_to_generic_allocations] })
      end

      before { login_as(staffer) }

      it "is the first group and links to global staffing" do
        expect(menu_items.first.header).to be_nil
        expect(menu_items.first.children.map(&:href)).to eq([resource_management_staffing_path])
      end
    end
  end
end
