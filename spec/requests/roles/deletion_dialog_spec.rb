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

RSpec.describe "GET /roles/:id/deletion_dialog", :aggregate_failures, :skip_csrf, type: :rails_request do
  shared_let(:admin) { create(:admin) }

  subject(:response_body) do
    get deletion_dialog_role_path(role), as: :turbo_stream

    expect(response).to have_http_status(:ok)
    response.body
  end

  before { login_as(admin) }

  # The project names are rendered apart from the principal's name so they can be
  # de-emphasised, so they are asserted on the muted element rather than the whole body.
  def muted_texts
    Nokogiri::HTML(response_body).css(".color-fg-muted").map { it.text.squish }
  end

  context "when the role is not in use" do
    let!(:role) { create(:project_role, name: "Reviewer") }

    it "asks for a plain confirmation" do
      expect(response_body).to include("Are you sure you want to delete the role &quot;Reviewer&quot;?")
      expect(response_body).not_to include("op-roles--delete-dialog-members")
    end
  end

  context "when members hold the role in a single project" do
    let!(:project) { create(:project, name: "Apollo") }
    let!(:role) { create(:project_role) }
    let!(:user) { create(:user, firstname: "Jo", lastname: "Barnes", member_with_roles: { project => [role] }) }

    it "lists the member with its project" do
      expect(response_body).to include("This role is still attributed to 1 member:")
      expect(response_body).to include("Jo Barnes")
      expect(muted_texts).to include("(Project: Apollo)")
    end

    it "states how many members lose project access" do
      expect(response_body)
        .to include("Out of these users, 1 will lose access to projects in which this was their only role. " \
                    "Are you sure you want to delete this role?")
    end

    it "does not link to the memberships overview while the full list is shown" do
      expect(response_body).not_to include("op-roles--delete-dialog-overview-link")
    end
  end

  context "when every member of the role holds another role too" do
    let!(:project) { create(:project, name: "Apollo") }
    let!(:role) { create(:project_role) }
    let!(:other_role) { create(:project_role) }
    let!(:user) { create(:user, member_with_roles: { project => [role, other_role] }) }

    it "says nobody loses access" do
      expect(response_body)
        .to include("None of these users will lose access to any of their projects. " \
                    "Are you sure you want to delete this role?")
    end
  end

  context "when a member holds the role in fewer projects than are truncated" do
    let!(:role) { create(:project_role) }
    let!(:projects) { [create(:project, name: "Gemini"), create(:project, name: "Mercury")] }
    let!(:user) do
      create(:user, firstname: "Lee", lastname: "Park", member_with_roles: projects.index_with { [role] })
    end

    it "lists every project without a remainder" do
      expect(response_body).to include("Lee Park")
      expect(muted_texts).to include("(Projects: Gemini, Mercury)")
    end
  end

  context "when a member holds the role in several projects" do
    let!(:role) { create(:project_role) }
    let!(:projects) { (1..5).map { |i| create(:project, name: "Project #{i}") } }
    let!(:user) do
      create(:user,
             firstname: "Ada",
             lastname: "Stone",
             member_with_roles: projects.index_with { [role] })
    end

    it "lists three projects and truncates the rest" do
      expect(response_body).to include("Ada Stone")
      expect(muted_texts).to include("(Projects: Project 1, Project 2, Project 3 and 2 others)")
    end
  end

  context "when the role is in use by more members than are listed" do
    let!(:project) { create(:project) }
    let!(:role) { create(:project_role) }

    before do
      stub_const("Roles::DeleteDialog::ContentComponent::PRINCIPAL_LIMIT", 1)
      create_list(:user, 2) { |user| create(:member, principal: user, project:, roles: [role]) }
    end

    it "shows totals instead of the member list" do
      expect(response_body).to include("2 users in 1 project")
      expect(response_body).not_to include("op-roles--delete-dialog-members")
    end

    it "links to the memberships overview filtered by the role" do
      filters = [{ role_id: { operator: "=", values: [role.id.to_s] } }].to_json

      expect(response_body).to include(I18n.t("roles.delete_dialog.show_memberships"))
      expect(response_body).to include(CGI.escapeHTML(admin_members_path(filters:)))
    end
  end

  context "when the role is a global role" do
    let!(:role) { create(:global_role) }
    let!(:user) { create(:user, firstname: "Kim", lastname: "Novak", global_roles: [role]) }

    it "lists the user without any project" do
      expect(response_body).to include("This role is still attributed to 1 member:")
      expect(response_body).to include("Kim Novak")
      expect(response_body).not_to include("Project:")
    end

    it "just asks for confirmation without spelling out what is lost" do
      expect(response_body).to include("Are you sure you want to delete this role?")
      expect(response_body).not_to include("Out of these users")
    end

    context "and more users hold it than are listed" do
      before do
        stub_const("Roles::DeleteDialog::ContentComponent::PRINCIPAL_LIMIT", 1)
        create(:user, global_roles: [role])
      end

      it "shows the user total without any project count and links to the overview" do
        filters = [{ role_id: { operator: "=", values: [role.id.to_s] } }].to_json

        expect(response_body).to include("2 users")
        expect(response_body).not_to include("2 users in")
        expect(response_body).to include(CGI.escapeHTML(admin_members_path(filters:)))
      end
    end
  end
end
