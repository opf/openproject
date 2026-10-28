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

require "rails_helper"

RSpec.describe Grids::Widgets::Members, type: :component do
  include Rails.application.routes.url_helpers

  def render_component(...)
    render_inline(described_class.new(...))
  end

  let(:project) { build_stubbed(:project) }
  let(:user) { build_stubbed(:user) }

  current_user { user }

  subject(:rendered_component) do
    render_component(project)
  end

  shared_examples "empty-state without action" do
    it "renders blankslate without action button" do
      expect(rendered_component).to have_test_selector(empty_selector)
      expect(rendered_component).to have_text(empty_message)
      expect(rendered_component).to have_no_test_selector("members-widget-add-button")
    end
  end

  shared_examples "empty-state with action" do
    it "renders blankslate with action button" do
      expect(rendered_component).to have_test_selector("members-widget-empty")
      expect(rendered_component).to have_text("This widget is currently empty.")
      expect(rendered_component).to have_test_selector("members-widget-add-button")
    end
  end

  context "when user cannot view members" do
    let(:empty_selector) { "members-widget-no-permission" }
    let(:empty_message)  { "This widget is not available." }

    it_behaves_like "empty-state without action"
  end

  context "with no members" do
    let(:empty_selector) { "members-widget-empty" }
    let(:empty_message)  { "This widget is currently empty." }

    context "when user can view but cannot manage members" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_members, project:)
        end
      end

      it_behaves_like "empty-state without action"
    end

    context "when user can view and manage members" do
      before do
        mock_permissions_for(user) do |mock|
          mock.allow_in_project(:view_members, :manage_members, project:)
        end
      end

      it_behaves_like "empty-state with action"
    end
  end

  context "with members" do
    let(:project) { create(:project) }
    let(:user) { create(:admin) }

    let!(:member) do
      create(:user, member_with_permissions: { project => [:view_members] })
    end

    before do
      member
    end

    it "renders turbo-frame wrapper" do
      expect(rendered_component).to have_element :"turbo-frame"
    end

    it "renders members items", :aggregate_failures do
      expect(rendered_component).to have_element class: "op-widget-box--body" do |body|
        expect(body).to have_element :"opce-principal"
      end
    end

    it "renders link to view all members" do
      expect(rendered_component).to have_test_selector("members-widget-footer") do |footer|
        expect(footer).to have_link href: project_members_path(project)
      end
    end
  end

  describe "data fetching" do
    let(:project) { create(:project) }
    let(:user) do
      bob = create(:user, lastname: "Bob")
      create(:member, principal: bob, project:,
                      roles: [
                        create(:project_role, name: "Bob-Role", permissions: [:view_members])
                      ])

      bob
    end

    before do
      role = create(:project_role, name: "Developers")
      alice = create(:user, lastname: "Alice")

      # create another project, with alice and the same role
      create(:member, principal: alice, project: create(:project), roles: [role])

      create(:member, principal: alice, project:,
                      roles: [
                        role,
                        create(:project_role, name: "Alice-Role")
                      ])

      # Peter is in the project, but locked!
      peter = create(:user, :locked, lastname: "Peter")
      create(:member, principal: peter, project:,
                      roles: [
                        create(:project_role, name: "Peter-Role")
                      ])

      create_list(:user, 3, member_with_roles: { project => [role] })
    end

    subject(:roles) { described_class.new(project).members_by_role }

    it "fetches data for roles" do
      # ensure roles are sorted by name
      expect(roles.pluck(:name)).to eq(["Alice-Role", "Bob-Role", "Developers"])

      roles.each do |role_data|
        members = role_data[:members]

        expect(members.to_a.size).to be <= 3
        expect(members.map(&:id)).to eq(members.map(&:id).uniq), "Expected principals to be uniq"
      end

      expect(roles.find { |r| r[:name] == "Developers" }[:members].count).to eq(3)
    end
  end
end
